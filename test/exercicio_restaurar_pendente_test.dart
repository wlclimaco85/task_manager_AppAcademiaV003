import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/services/exercicio_conta_sync.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';

/// Com login e servidor fora do ar, restaurar e editar ficam na fila e nao se perdem.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ExercicioContaSync.autenticadoForcado = true;
    ExercicioContaSync.cliente = MockClient((_) async => http.Response('', 500));
  });

  tearDown(() {
    ExercicioContaSync.autenticadoForcado = null;
    ExercicioContaSync.cliente = http.Client();
  });

  test('restaurar sem confirmacao do servidor fica pendente na fila', () async {
    final repo = FitnessOfflineRepository();
    final confirmado = await repo.restaurarExercicio('ex_supino_reto');

    expect(confirmado, isFalse);
    final prefs = await SharedPreferences.getInstance();
    final pendentes = jsonDecode(prefs.getString('exercicios_pendentes_v1')!) as Map<String, dynamic>;
    expect(pendentes['ex_supino_reto']['origem'], 'EXCLUIR');
  });

  test('video editado offline aparece e some depois de restaurar', () async {
    final repo = FitnessOfflineRepository();
    final geral = (await repo.getExercicios()).firstWhere((e) => e.id == 'ex_supino_reto');
    await repo.atualizarVideoExercicio('ex_supino_reto', 'https://youtu.be/MEU_TESTE');

    final editado = (await repo.getExercicios()).firstWhere((e) => e.id == 'ex_supino_reto');
    expect(editado.videoUrl, 'https://youtu.be/MEU_TESTE');

    await repo.restaurarExercicio('ex_supino_reto');
    final restaurado = (await repo.getExercicios()).firstWhere((e) => e.id == 'ex_supino_reto');
    expect(restaurado.videoUrl, geral.videoUrl);
  });
}
