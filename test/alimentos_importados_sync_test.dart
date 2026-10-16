import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/models/fitness/nutricao_farmaco_model.dart';
import 'package:task_manager_flutter/data/services/nutricao_farmaco_offline_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const alimento = AlimentoModel(
      id: 'importado',
      nome: 'Alimento informado',
      categoria: 'geral',
      calorias: 100,
      proteinas: 5,
      carboidratos: 10,
      gorduras: 4,
      fibras: 2);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthUtility.userInfo = LoginModel(token: 'teste', login: Login(id: 101));
  });
  tearDown(() {
    AuthUtility.userInfo = LoginModel();
  });
  test('fila offline duravel sem duplicar e isolada por conta', () async {
    await http.runWithClient(() async {
      final repo = NutricaoFarmacoOfflineRepository();
      await repo.salvarAlimentosImportados([alimento]);
      await repo.salvarAlimentosImportados([alimento]);
      final prefs = await SharedPreferences.getInstance();
      expect(
          (jsonDecode(prefs.getString('fitness_pendentes_alimentos_conta_101')!)
                  as Map)
              .length,
          1);
      expect(
          (await repo.getAlimentos()).where((a) => a.id == alimento.id).length,
          1);
      AuthUtility.userInfo = LoginModel(token: 'teste', login: Login(id: 102));
      expect(
          (await repo.getAlimentos()).any((a) => a.id == alimento.id), false);
    }, () => MockClient((_) async => http.Response('{}', 503)));
  });
  test('sincroniza alimentos e recupera apos limpar cache', () async {
    final remotos = <String, dynamic>{};
    await http.runWithClient(() async {
      final repo = NutricaoFarmacoOfflineRepository();
      await repo.salvarAlimentosImportados([alimento]);
      SharedPreferences.setMockInitialValues({});
      final recuperado =
          (await repo.getAlimentos()).singleWhere((a) => a.id == alimento.id);
      expect(recuperado.fibras, 2);
      expect(recuperado.calorias, 100);
    },
        () => MockClient((q) async {
              if (q.method == 'PUT') {
                final a = jsonDecode(q.body);
                remotos[a['id']] = a;
                return http.Response(q.body, 200);
              }
              return http.Response(
                  jsonEncode({'data': remotos.values.toList()}), 200);
            }));
  });
  test('rejeita nutrientes invalidos antes de persistir', () async {
    await expectLater(
        NutricaoFarmacoOfflineRepository().salvarAlimentosImportados([
          const AlimentoModel(
              id: 'invalido',
              nome: 'Item',
              categoria: 'geral',
              calorias: -1,
              proteinas: 0,
              carboidratos: 0,
              gorduras: 0)
        ]),
        throwsArgumentError);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('appacademia_alimentos_importados_v1_conta_101'),
        isNull);
  });
}
