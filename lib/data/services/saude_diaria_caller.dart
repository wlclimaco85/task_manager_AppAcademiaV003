import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

import '../models/saude_diaria_model.dart';

/// Caller HTTP da Home Saúde. Segue o padrão de ComunicadoCaller.
///
/// Os endpoints de fitness NÃO são envelopados pelo backend, então o parsing
/// é delegado ao fromJson defensivo de [ResumoSaudeDiaria].
class SaudeDiariaCaller {
  /// Busca o resumo diário de saúde. Retorna null em qualquer falha (não lança),
  /// para permitir fallback gracioso na Home.
  Future<ResumoSaudeDiaria?> fetchResumo({DateTime? data}) async {
    try {
      final url = data != null
          ? '${ApiLinks.fitnessResumo}?data=${_formatarData(data)}'
          : ApiLinks.fitnessResumo;

      final NetworkResponse response =
          await NetworkCaller().getRequest(url);

      if (response.isSuccess && response.body != null) {
        return ResumoSaudeDiaria.fromJson(
          Map<String, dynamic>.from(response.body!),
        );
      }
    } catch (e) {
      // Falha silenciosa: a Home cai no store local.
      return null;
    }
    return null;
  }

  /// Salva o resumo diário via PUT. Retorna o resumo atualizado ou null em falha.
  Future<ResumoSaudeDiaria?> salvarResumo(ResumoSaudeDiaria resumo) async {
    try {
      final body = <String, dynamic>{
        'data': _formatarData(resumo.data),
        'passos': resumo.passos,
        'treinoMinutos': resumo.treinoMinutos,
        'batimentos': resumo.batimentos,
        'sonoMinutos': resumo.sonoMinutos,
        'pesoKg': resumo.pesoKg,
        'pesoMetaKg': resumo.pesoMetaKg,
      };

      final NetworkResponse response =
          await NetworkCaller().putRequest(ApiLinks.fitnessResumo, body);

      if (response.isSuccess && response.body != null) {
        return ResumoSaudeDiaria.fromJson(
          Map<String, dynamic>.from(response.body!),
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Formata a data como YYYY-MM-DD (contrato do backend).
  String _formatarData(DateTime d) {
    final mes = d.month.toString().padLeft(2, '0');
    final dia = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mes-$dia';
  }
}
