import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/services/exercicio_conta_sync.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';

/// Fluxo ponta a ponta com o servidor indo e voltando do ar. "Reiniciar o app" =
/// nova instancia do repositorio lendo so o armazenamento local.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late bool online;
  late Map<String, Map<String, dynamic>> servidor;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ExercicioContaSync.autenticadoForcado = true;
    online = true;
    servidor = {};
    ExercicioContaSync.cliente = MockClient((req) async {
      if (!online) throw http.ClientException('sem rede');
      if (req.method == 'GET') {
        return http.Response(jsonEncode({'meus': servidor.values.toList(), 'doPersonal': []}), 200);
      }
      if (req.method == 'PUT') {
        final corpo = jsonDecode(req.body) as Map<String, dynamic>;
        servidor[corpo['id'].toString()] = {'exercicioId': corpo['id'], 'origem': corpo['origem'], 'dados': corpo};
        return http.Response('{}', 200);
      }
      if (req.method == 'DELETE') {
        servidor.remove(req.url.pathSegments.last);
        return http.Response('{}', 200);
      }
      return http.Response('{}', 404);
    });
  });

  tearDown(() {
    ExercicioContaSync.autenticadoForcado = null;
    ExercicioContaSync.cliente = http.Client();
  });

  Future<String?> videoDe(FitnessOfflineRepository repo, String id) async =>
      (await repo.getExercicios()).firstWhere((e) => e.id == id).videoUrl;

  test('editar, reiniciar e reconectar: a edicao chega ao servidor', () async {
    final geral = await videoDe(FitnessOfflineRepository(), 'ex_supino_reto');

    // Sem rede, edita o video.
    online = false;
    await FitnessOfflineRepository().atualizarVideoExercicio('ex_supino_reto', 'https://youtu.be/OFFLINE');
    expect(await videoDe(FitnessOfflineRepository(), 'ex_supino_reto'), 'https://youtu.be/OFFLINE',
        reason: 'mostra a edicao sem rede');

    // "Reinicia o app" ainda sem rede: a edicao continua la.
    expect(await videoDe(FitnessOfflineRepository(), 'ex_supino_reto'), 'https://youtu.be/OFFLINE',
        reason: 'sobrevive ao reinicio');
    expect(servidor, isEmpty, reason: 'nada foi ao servidor ainda');

    // Volta a rede: a carga reenvia a pendencia.
    online = true;
    await videoDe(FitnessOfflineRepository(), 'ex_supino_reto');
    expect(servidor['ex_supino_reto']?['dados']?['videoUrl'], 'https://youtu.be/OFFLINE',
        reason: 'chegou ao servidor');
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('exercicios_pendentes_v1') ?? '{}'), isEmpty,
        reason: 'saiu da fila com confirmacao');
    expect(geral, isNotNull);
  });

  test('restaurar offline: volta ao geral mesmo apos reinicio e sincroniza ao reconectar', () async {
    // Video do cadastro geral antes de qualquer edicao.
    final geral = await videoDe(FitnessOfflineRepository(), 'ex_supino_reto');
    // Edicao ja confirmada pelo servidor.
    await FitnessOfflineRepository().atualizarVideoExercicio('ex_supino_reto', 'https://youtu.be/ONLINE');
    expect(servidor.containsKey('ex_supino_reto'), isTrue);

    // Sem rede, restaura: o geral aparece e a exclusao fica pendente.
    online = false;
    final confirmado = await FitnessOfflineRepository().restaurarExercicio('ex_supino_reto');
    expect(confirmado, isFalse);
    expect(await videoDe(FitnessOfflineRepository(), 'ex_supino_reto'), geral,
        reason: 'mostra o geral sem rede');
    expect(await videoDe(FitnessOfflineRepository(), 'ex_supino_reto'), geral,
        reason: 'continua assim apos reinicio');

    // Volta a rede: a exclusao chega ao servidor.
    online = true;
    await videoDe(FitnessOfflineRepository(), 'ex_supino_reto');
    expect(servidor.containsKey('ex_supino_reto'), isFalse, reason: 'servidor removeu a personalizacao');
  });

  test('sem rede desde o inicio: o app abre com o catalogo geral e nao trava', () async {
    online = false;
    final lista = await FitnessOfflineRepository().getExercicios();
    expect(lista.length, greaterThanOrEqualTo(100));
  });
}
