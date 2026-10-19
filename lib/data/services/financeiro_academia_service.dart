import 'package:task_manager_flutter/data/models/fitness/financeiro_academia_model.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

/// Financeiro da academia: mensalidades dos alunos matriculados, com baixa manual.
/// O servidor e a fonte da verdade; nada e guardado no aparelho.
class FinanceiroAcademiaService {
  FinanceiroAcademiaService._();

  /// Lista o mes (AAAA-MM). Devolve null se a rede ou o servidor falharem.
  static Future<FinanceiroAcademiaMes?> buscar(String mes) async {
    try {
      final resposta = await NetworkCaller().getRequest(ApiLinks.financeiroAcademia(mes));
      final data = resposta.body?['data'];
      if (!resposta.isSuccess || data is! Map) {
        AppLogger.i.warn('[FinanceiroAcademia] Servidor recusou a lista de $mes (status ${resposta.statusCode}).');
        return null;
      }
      return FinanceiroAcademiaMes.fromMap(Map<String, dynamic>.from(data));
    } catch (e) {
      AppLogger.i.warn('[FinanceiroAcademia] Falha ao buscar $mes: $e');
      return null;
    }
  }

  /// Marca ou desfaz o pagamento do aluno no mes. Devolve false se o servidor recusar.
  static Future<bool> darBaixa({
    required String mes,
    required String alunoId,
    required bool pago,
  }) async {
    try {
      final resposta = await NetworkCaller().putRequest(
        ApiLinks.financeiroAcademiaBaixa(mes, alunoId),
        {'pago': pago},
      );
      if (!resposta.isSuccess) {
        AppLogger.i.warn('[FinanceiroAcademia] Baixa recusada (aluno $alunoId, $mes, status ${resposta.statusCode}).');
        return false;
      }
      return true;
    } catch (e) {
      AppLogger.i.warn('[FinanceiroAcademia] Falha ao dar baixa (aluno $alunoId, $mes): $e');
      return false;
    }
  }
}
