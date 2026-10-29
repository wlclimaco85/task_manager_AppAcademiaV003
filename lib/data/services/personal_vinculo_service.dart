import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

/// Vinculo do aluno com o personal que o acompanha.
class PersonalVinculoService {
  PersonalVinculoService._();

  /// Aluno deixa o personal: as fichas dele ficam inativas e o personal e avisado.
  /// Devolve false quando o servidor recusa; a mensagem vai para o log e a tela mostra o erro.
  static Future<bool> deixarPersonal() async {
    try {
      final resposta = await NetworkCaller()
          .postRequest(ApiLinks.permissoesDeixarPersonal, const {});
      if (resposta.isSuccess) return true;
      AppLogger.i.warn(
          '[PersonalVinculo] Deixar personal recusado: HTTP ${resposta.statusCode}');
      return false;
    } catch (e, stack) {
      AppLogger.i.error('[PersonalVinculo] Falha ao deixar o personal: $e', stack);
      return false;
    }
  }
}
