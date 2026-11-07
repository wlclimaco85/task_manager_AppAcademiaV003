import 'package:task_manager_flutter/data/models/fitness/dashboard_fitness_model.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

/// Leitura do dashboard do personal ou da academia para um mes (AAAA-MM).
class DashboardFitnessService {
  DashboardFitnessService._();

  /// Lanca [Exception] com mensagem para a tela quando a leitura falha.
  static Future<DashboardFitnessModel> carregar({required bool academia, required String mes}) async {
    final url = academia ? ApiLinks.fitnessAcademiaDashboard(mes) : ApiLinks.fitnessPersonalDashboard(mes);
    try {
      final resposta = await NetworkCaller().getRequest(url);
      if (!resposta.isSuccess) {
        AppLogger.i.warn('[DashboardFitness] Leitura falhou: HTTP ${resposta.statusCode}');
        final mensagem = resposta.body?['message']?.toString();
        throw Exception(mensagem ?? 'Não foi possível carregar o dashboard (HTTP ${resposta.statusCode}).');
      }
      final data = resposta.body?['data'];
      if (data is! Map) {
        throw Exception('Resposta do dashboard fora do formato esperado.');
      }
      return DashboardFitnessModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e, stack) {
      AppLogger.i.error('[DashboardFitness] Falha ao carregar $mes: $e', stack);
      rethrow;
    }
  }
}
