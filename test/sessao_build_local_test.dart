import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/services/sessao_build_local.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final forcar in [false, true]) {
    test('forçar login=$forcar preserva histórico e fila offline', () async {
      SharedPreferences.setMockInitialValues({
        'user_data': 'sessão anterior',
        'auth_token': 'token anterior',
        'appacademia_sessoes_treino_v1_conta_101': '[{"id":"treino-real"}]',
        'fitness_pendentes_sessoes_conta_101': '{"treino-real":{}}',
      });
      await prepararSessaoBuildLocal(forcarLogin: forcar);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_data'), forcar ? isNull : 'sessão anterior');
      expect(prefs.getString('auth_token'), forcar ? isNull : 'token anterior');
      expect(prefs.getString('appacademia_sessoes_treino_v1_conta_101'),
          '[{"id":"treino-real"}]');
      expect(prefs.getString('fitness_pendentes_sessoes_conta_101'),
          '{"treino-real":{}}');
    });
  }
}
