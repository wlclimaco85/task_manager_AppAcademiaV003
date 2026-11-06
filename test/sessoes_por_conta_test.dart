import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';

SessaoTreinoRegistroModel sessao(String id) => SessaoTreinoRegistroModel(
      id: id,
      treinoId: 'plano',
      divisaoLetra: 'C',
      divisaoNome: 'Treino C',
      alunoId: '101',
      dataHoraInicio: '2026-11-05T12:00:00',
      dataHoraFim: '2026-11-05T13:00:00',
      duracaoSegundos: 3600,
      sincronizado: false,
      exerciciosExecutados: const [],
    );

/// Sem token a sessao nao e valida: o login continua conhecido, mas autenticado e falso.
void semSessao(int loginId) => AuthUtility.userInfo = LoginModel(token: '', login: Login(id: loginId));

void comSessao(int loginId) => AuthUtility.userInfo = LoginModel(token: 'conta$loginId', login: Login(id: loginId));

Future<List<String>> lerIds() => http.runWithClient(
      () async => (await FitnessOfflineRepository().getSessoesConcluidas()).map((s) => s.id).toList(),
      () => MockClient((_) async => http.Response('{"data":[]}', 200)),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => AuthUtility.userInfo = LoginModel());

  test('treino feito sem sessao valida fica so com o login que o fez', () async {
    semSessao(101);
    await FitnessOfflineRepository().registrarSessaoConcluida(sessao('sessao_25'));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('appacademia_sessoes_treino_v1_pendente_101'), contains('sessao_25'));
    expect(prefs.getString('appacademia_sessoes_treino_v1'), isNull);
    expect(prefs.getString('appacademia_sessoes_treino_v1_conta_101'), isNull);
  });

  test('ao entrar, o login recebe seus treinos e outra conta nao', () async {
    semSessao(101);
    await FitnessOfflineRepository().registrarSessaoConcluida(sessao('sessao_25'));

    comSessao(101);
    expect(await lerIds(), contains('sessao_25'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('appacademia_sessoes_treino_v1_pendente_101'), isNull);
    expect(prefs.getString('appacademia_sessoes_treino_v1_conta_101'), contains('sessao_25'));

    comSessao(102);
    expect(await lerIds(), isNot(contains('sessao_25')));
  });

  test('treino de outro login pendente nao aparece para quem esta logado agora', () async {
    semSessao(102);
    await FitnessOfflineRepository().registrarSessaoConcluida(sessao('sessao_99'));

    comSessao(101);
    expect(await lerIds(), isNot(contains('sessao_99')));
  });

  test('dados legados sem dono migram uma unica vez para o login que entrar', () async {
    SharedPreferences.setMockInitialValues({
      'appacademia_sessoes_treino_v1': jsonEncode([sessao('sessao_legado').toMap()]),
    });
    comSessao(101);
    expect(await lerIds(), contains('sessao_legado'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('appacademia_sessoes_treino_v1'), isNull);
  });

  test('treino feito depois do logout fica com quem saiu, nunca sem dono nem com outra conta', () async {
    comSessao(101);
    await AuthUtility.clearUserInfo();
    await FitnessOfflineRepository().registrarSessaoConcluida(sessao('sessao_logout'));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('appacademia_sessoes_treino_v1_pendente_101'), contains('sessao_logout'));
    expect(prefs.getString('appacademia_sessoes_treino_v1'), isNull);

    comSessao(102);
    expect(await lerIds(), isNot(contains('sessao_logout')));

    comSessao(101);
    expect(await lerIds(), contains('sessao_logout'));

    // Depois de sair de novo, quem esta no aparelho sem login nao ve os treinos do ultimo dono.
    await AuthUtility.clearUserInfo();
    expect(await lerIds(), isNot(contains('sessao_logout')));
  });
}
