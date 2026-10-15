import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('ficha sobrevive limpeza do dispositivo e fica isolada por conta', () async {
    final antes = AuthUtility.userInfo;
    addTearDown(() => AuthUtility.userInfo = antes);
    SharedPreferences.setMockInitialValues({});
    AuthUtility.userInfo = LoginModel(token: 'conta_a', login: Login(id: 101));
    final servidor = <String, Map<String, dynamic>>{};
    final client = MockClient((req) async {
      final conta = req.headers['authorization'] ?? '';
      if (req.method == 'PUT') {
        servidor[conta] = jsonDecode(req.body);
        return http.Response(req.body, 200);
      }
      return http.Response(jsonEncode({'data': servidor.containsKey(conta)
          ? [servidor[conta]] : []}), 200);
    });
    await http.runWithClient(() async {
      const plano = PlanoTreinoModel(id: 'ficha', alunoId: '101', alunoNome: 'Aluno',
        personalId: '', titulo: 'Minha ficha alterada', dataInicio: '2026-10-14', divisoes: [
          DivisaoTreinoModel(id: 'a', letra: 'A', nome: 'Treino A', exercicios: [
            ItemTreinoModel(id: 'item_b', exercicioId: 'b', exercicioNome: 'Segundo escolhido',
              grupoMuscular: 'Costas', cargaSugeridaKg: 35, observacoes: 'Controle',
              exerciciosAlternativos: ['Alternativa cadastrada']),
            ItemTreinoModel(id: 'item_a', exercicioId: 'a', exercicioNome: 'Primeiro escolhido',
              grupoMuscular: 'Costas', cargaSugeridaKg: 20),
          ]),
        ]);
      await FitnessOfflineRepository().salvarPlanoTreino(plano);
      SharedPreferences.setMockInitialValues({});
      final recuperado = (await FitnessOfflineRepository().getPlanosTreino()).single;
      expect(recuperado.titulo, 'Minha ficha alterada');
      expect(recuperado.divisoes.single.exercicios.map((e) => e.id), ['item_b', 'item_a']);
      expect(recuperado.toMap(), plano.toMap());
      AuthUtility.userInfo = LoginModel(token: 'conta_b', login: Login(id: 102));
      expect(await FitnessOfflineRepository().getPlanosTreino(), isEmpty);
    }, () => client);
  });
}
