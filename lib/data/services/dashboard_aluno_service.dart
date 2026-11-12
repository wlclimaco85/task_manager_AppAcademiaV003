import 'package:task_manager_flutter/data/models/fitness/dashboard_aluno_model.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

/// Leitura do dashboard do proprio aluno para um mes (AAAA-MM).
class DashboardAlunoService {
  DashboardAlunoService._();

  /// Lanca [Exception] com mensagem para a tela quando a leitura falha.
  static Future<DashboardAlunoModel> carregar({required String mes}) async {
    try {
      final resposta = await NetworkCaller().getRequest(ApiLinks.fitnessAlunoDashboard(mes));
      if (!resposta.isSuccess) {
        AppLogger.i.warn('[DashboardAluno] Leitura falhou: HTTP ${resposta.statusCode}');
        final mensagem = resposta.body?['message']?.toString();
        throw Exception(mensagem ?? 'Não foi possível carregar o seu dashboard (HTTP ${resposta.statusCode}).');
      }
      final data = resposta.body?['data'];
      if (data is! Map) {
        throw Exception('Resposta do dashboard fora do formato esperado.');
      }
      return DashboardAlunoModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e, stack) {
      AppLogger.i.error('[DashboardAluno] Falha ao carregar $mes: $e', stack);
      rethrow;
    }
  }
}
