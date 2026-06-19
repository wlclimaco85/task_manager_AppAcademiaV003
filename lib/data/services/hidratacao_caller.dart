import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

import '../models/hidratacao_model.dart';

/// Caller HTTP de hidratacao. Modulo ja existente no backend (nao desta
/// fase), contrato confirmado em HidratacaoController.java. Segue o padrao
/// de SaudeDiariaCaller.
class HidratacaoCaller {
  /// Busca o resumo de hidratacao do dia. Retorna null em qualquer falha
  /// (nao lanca), para permitir fallback gracioso na UI.
  Future<ResumoHidratacao?> fetchResumo({DateTime? data}) async {
    try {
      final url = data != null
          ? '${ApiLinks.fitnessHidratacaoResumo}?data=${_formatarData(data)}'
          : ApiLinks.fitnessHidratacaoResumo;

      final NetworkResponse response = await NetworkCaller().getRequest(url);

      if (response.isSuccess && response.body != null) {
        return ResumoHidratacao.fromJson(
          Map<String, dynamic>.from(response.body!),
        );
      }
    } catch (e) {
      // Falha silenciosa: a UI cai no fallback local.
      return null;
    }
    return null;
  }

  /// Registra o consumo de agua via POST. Retorna true em sucesso, false em
  /// falha.
  Future<bool> registrarConsumo(int quantidadeMl) async {
    try {
      final body = <String, dynamic>{
        'quantidadeMl': quantidadeMl,
      };

      final NetworkResponse response = await NetworkCaller()
          .postRequest(ApiLinks.fitnessHidratacaoRegistros, body);

      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  /// Formata a data como YYYY-MM-DD (contrato do backend).
  String _formatarData(DateTime d) {
    final mes = d.month.toString().padLeft(2, '0');
    final dia = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mes-$dia';
  }
}
