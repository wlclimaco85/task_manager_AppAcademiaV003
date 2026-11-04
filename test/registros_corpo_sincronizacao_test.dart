import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/services/fitness_360_local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthUtility.userInfo = LoginModel(token: 'conta101', login: Login(id: 101));
  });
  tearDown(() => AuthUtility.userInfo = LoginModel());

  test('peso registrado durante sincronização permanece no histórico e no cache', () async {
    final iniciouLeitura = Completer<void>();
    final resposta = Completer<http.Response>();
    final cliente = MockClient((_) {
      iniciouLeitura.complete();
      return resposta.future;
    });
    await http.runWithClient(() async {
      final leitura = Fitness360LocalStore.records(type: 'corpo');
      await iniciouLeitura.future;
      final novo = await Fitness360LocalStore.addRecord(type: 'corpo', title: 'Peso',
          value: '101,65 kg', dataRegistro: DateTime(2026, 10, 25));
      resposta.complete(http.Response('{"data":[]}', 200));
      expect((await leitura).map((r) => r.id), [novo.id]);
      final prefs = await SharedPreferences.getInstance();
      final cache = jsonDecode(prefs.getString('fitness360.records.v1_conta_101')!) as List;
      expect(cache.single['value'], '101,65 kg');
    }, () => cliente);
  });

  test('sincronização não restaura registro removido do servidor', () async {
    final antigo = Fitness360Record(id: 1, type: 'corpo', title: 'Peso', value: '100 kg',
        note: '', createdAt: DateTime(2026, 10, 24));
    SharedPreferences.setMockInitialValues({
      'fitness360.records.v1_conta_101': jsonEncode([antigo.toJson()]),
    });
    final cliente = MockClient((_) async => http.Response('{"data":[]}', 200));
    await http.runWithClient(() async {
      expect(await Fitness360LocalStore.records(), isEmpty);
    }, () => cliente);
  });

  test('resposta anterior à edição não substitui fotos recém-salvas', () async {
    final antigo = Fitness360Record(id: 1, type: 'corpo', title: 'Peso', value: '100 kg',
        note: '', createdAt: DateTime(2026, 10, 24));
    SharedPreferences.setMockInitialValues({
      'fitness360.records.v1_conta_101': jsonEncode([antigo.toJson()]),
    });
    final iniciouLeitura = Completer<void>();
    final resposta = Completer<http.Response>();
    final cliente = MockClient((_) {
      iniciouLeitura.complete();
      return resposta.future;
    });
    await http.runWithClient(() async {
      final leitura = Fitness360LocalStore.records();
      await iniciouLeitura.future;
      await Fitness360LocalStore.atualizarFotosRegistro(1, ['foto-real']);
      resposta.complete(http.Response(jsonEncode({'data': [antigo.toJson()]}), 200));
      expect((await leitura).single.fotosBase64, ['foto-real']);
    }, () => cliente);
  });

  test('troca de conta durante leitura não devolve medidas da conta anterior', () async {
    final antigo = Fitness360Record(id: 1, type: 'corpo', title: 'Peso', value: '100 kg',
        note: '', createdAt: DateTime(2026, 10, 24));
    SharedPreferences.setMockInitialValues({
      'fitness360.records.v1_conta_101': jsonEncode([antigo.toJson()]),
    });
    final iniciouLeitura = Completer<void>();
    final resposta = Completer<http.Response>();
    final cliente = MockClient((_) {
      iniciouLeitura.complete();
      return resposta.future;
    });
    await http.runWithClient(() async {
      final leitura = Fitness360LocalStore.records();
      await iniciouLeitura.future;
      AuthUtility.userInfo = LoginModel(token: 'conta102', login: Login(id: 102));
      resposta.complete(http.Response('{"data":[]}', 200));
      expect(await leitura, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('fitness360.records.v1_conta_102'), isNull);
    }, () => cliente);
  });

  test('registro iniciado em uma conta não grava peso na outra', () async {
    final iniciouLeitura = Completer<void>();
    final resposta = Completer<http.Response>();
    final cliente = MockClient((_) {
      iniciouLeitura.complete();
      return resposta.future;
    });
    await http.runWithClient(() async {
      final gravacao = Fitness360LocalStore.addRecord(type: 'corpo', title: 'Peso', value: '101 kg');
      final verificacao = expectLater(gravacao, throwsStateError);
      await iniciouLeitura.future;
      AuthUtility.userInfo = LoginModel(token: 'conta102', login: Login(id: 102));
      resposta.complete(http.Response('{"data":[]}', 200));
      await verificacao;
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('fitness360.records.v1_conta_102'), isNull);
      expect(prefs.getString('fitness_pendentes_registros_conta_102'), isNull);
    }, () => cliente);
  });
}
