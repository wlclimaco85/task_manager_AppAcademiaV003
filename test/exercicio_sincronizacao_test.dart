import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/services/exercicio_conta_sync.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';

/// Caminhos de sucesso e de falha da sincronizacao com o servidor (cliente simulado).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Servidor simulado: guarda o que recebeu por PUT e devolve no GET.
  final guardados = <String, Map<String, dynamic>>{};

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ExercicioContaSync.autenticadoForcado = true;
    guardados.clear();
  });

  tearDown(() {
    ExercicioContaSync.autenticadoForcado = null;
    ExercicioContaSync.cliente = http.Client();
  });

  void servidor(int statusDaEscrita, {int statusDaLeitura = 200}) {
    ExercicioContaSync.cliente = MockClient((req) async {
      if (req.method == 'GET') {
        final meus = guardados.values.toList();
        return http.Response(jsonEncode({'meus': meus, 'doPersonal': []}), statusDaLeitura);
      }
      if (req.method == 'PUT' && statusDaEscrita == 200) {
        final corpo = jsonDecode(req.body) as Map<String, dynamic>;
        guardados[corpo['id'].toString()] = {
          'exercicioId': corpo['id'], 'origem': corpo['origem'], 'dados': corpo,
        };
      }
      return http.Response('{}', statusDaEscrita);
    });
  }

  test('exclusao confirmada (200) sai da fila e restaurar retorna true', () async {
    servidor(200);
    final repo = FitnessOfflineRepository();

    final confirmado = await repo.restaurarExercicio('ex_supino_reto');

    expect(confirmado, isTrue);
    final prefs = await SharedPreferences.getInstance();
    final pendentes = jsonDecode(prefs.getString('exercicios_pendentes_v1') ?? '{}') as Map;
    expect(pendentes.containsKey('ex_supino_reto'), isFalse);
  });

  test('exclusao recusada pelo servidor (500) continua na fila', () async {
    servidor(500);
    final repo = FitnessOfflineRepository();

    final confirmado = await repo.restaurarExercicio('ex_supino_reto');

    expect(confirmado, isFalse);
    final prefs = await SharedPreferences.getInstance();
    final pendentes = jsonDecode(prefs.getString('exercicios_pendentes_v1')!) as Map;
    expect(pendentes['ex_supino_reto']['origem'], 'EXCLUIR');
  });

  test('pendencia de edicao e reenviada na proxima carga e sai da fila com 200', () async {
    servidor(500);
    final repo = FitnessOfflineRepository();
    await repo.atualizarVideoExercicio('ex_supino_reto', 'https://youtu.be/PENDENTE');
    var prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('exercicios_pendentes_v1')!)['ex_supino_reto'], isNotNull);

    servidor(200);
    final lista = await repo.getExercicios();

    prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('exercicios_pendentes_v1')!)['ex_supino_reto'], isNull);
    expect(lista.firstWhere((e) => e.id == 'ex_supino_reto').videoUrl, 'https://youtu.be/PENDENTE');
  });

  test('sem login nao grava pendencia e recusa a edicao', () async {
    ExercicioContaSync.autenticadoForcado = false;
    final repo = FitnessOfflineRepository();

    await expectLater(repo.atualizarVideoExercicio('ex_supino_reto', 'https://youtu.be/X'),
        throwsA(isA<StateError>()));
    expect(await repo.restaurarExercicio('ex_supino_reto'), isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('exercicios_pendentes_v1'), isNull);
  });

  test('entrada malformada na fila nao derruba a lista nem apaga as demais pendencias', () async {
    SharedPreferences.setMockInitialValues({
      'exercicios_pendentes_v1': jsonEncode({
        'ex_quebrado': {'exercicioId': 'ex_quebrado', 'origem': 'BASE'},
        'ex_supino_reto': {
          'exercicioId': 'ex_supino_reto',
          'origem': 'BASE',
          'dados': {'id': 'ex_supino_reto', 'origem': 'BASE', 'videoUrl': 'https://youtu.be/VALIDO'},
        },
      }),
    });
    servidor(200);
    final repo = FitnessOfflineRepository();

    final lista = await repo.getExercicios();

    expect(lista.any((e) => e.id == 'ex_supino_reto'), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('exercicios_pendentes_v1')!)['ex_supino_reto'], isNull,
        reason: 'pendencia valida enviada e removida');
  });

  test('falha de leitura do servidor acende o aviso; leitura ok apaga', () async {
    servidor(200, statusDaLeitura: 500);
    expect(await ExercicioContaSync.carregar(), isNull);
    expect(ExercicioContaSync.ultimaLeituraFalhou, isTrue);

    servidor(200);
    expect(await ExercicioContaSync.carregar(), isNotNull);
    expect(ExercicioContaSync.ultimaLeituraFalhou, isFalse);
  });

  test('origem fora de BASE, CUSTOM e EXCLUIR e descartada da fila', () async {
    SharedPreferences.setMockInitialValues({
      'exercicios_pendentes_v1': jsonEncode({
        'ex_x': {'exercicioId': 'ex_x', 'origem': 'ADMIN', 'dados': {'id': 'ex_x'}},
      }),
    });
    servidor(200);
    await FitnessOfflineRepository().getExercicios();

    final prefs = await SharedPreferences.getInstance();
    final restante = jsonDecode(prefs.getString('exercicios_pendentes_v1') ?? '{}') as Map;
    expect(restante.containsKey('ex_x'), isFalse);
  });

  test('carregar devolve null quando o servidor falha (usa o cache local)', () async {
    servidor(200, statusDaLeitura: 500);

    expect(await ExercicioContaSync.carregar(), isNull);
  });
}
