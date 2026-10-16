import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/services/auth_service.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

/// Apenas builds de teste que solicitam explicitamente uma nova autenticação.
/// Nunca remove histórico, fichas nem a fila offline.
Future<void> prepararSessaoBuildLocal({
  bool forcarLogin = const bool.fromEnvironment('FORCE_LOGIN_ON_START'),
}) async {
  if (!forcarLogin) return;
  try {
    await AuthService().clearToken();
    await AuthUtility.clearUserInfo();
  } catch (error, stack) {
    AppLogger.i.error('Falha ao preparar autenticação do build local.', stack);
    rethrow;
  }
}
