import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';

void main() {
  String sessao(String id, String data) => jsonEncode({'id': id, 'dataHoraInicio': data});

  test('treinos sem conta sao juntados aos da conta, sem duplicar pelo id', () {
    final conta = '[${sessao('s_05', '2026-11-05')},${sessao('s_03', '2026-11-03')}]';
    final generico = '[${sessao('s_02', '2026-11-02')},${sessao('s_03', '2026-11-03')}]';

    final mesclado = FitnessOfflineRepository.mesclarSessoesOrfas(conta, generico);
    final ids = (jsonDecode(mesclado!) as List).map((e) => e['id']).toList();

    expect(ids, ['s_05', 's_03', 's_02']);
  });

  test('sem treinos na conta, o generico passa inteiro para a conta', () {
    final mesclado = FitnessOfflineRepository.mesclarSessoesOrfas(null, '[${sessao('s_02', '2026-11-02')}]');
    expect((jsonDecode(mesclado!) as List).single['id'], 's_02');
  });

  test('dados ilegiveis devolvem null e nao sao apagados', () {
    expect(FitnessOfflineRepository.mesclarSessoesOrfas('[nao-e-json', '[]'), isNull);
    expect(FitnessOfflineRepository.mesclarSessoesOrfas('[]', 'lixo'), isNull);
  });
}
