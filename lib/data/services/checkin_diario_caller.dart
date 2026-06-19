import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

import '../models/checkin_diario_model.dart';

/// Caller HTTP do check-in diario. Segue o padrao de SaudeDiariaCaller.
///
/// Os endpoints de fitness NAO sao envelopados pelo backend, entao o parsing
/// e delegado ao fromJson defensivo de [CheckinDiario].
class CheckinDiarioCaller {
  /// Busca o checkin do dia. Retorna null em qualquer falha (nao lanca),
  /// para permitir fallback gracioso na UI.
  Future<CheckinDiario?> fetchResumo({DateTime? data}) async {
    try {
      final url = data != null
          ? '${ApiLinks.fitnessCheckinDiario}?data=${_formatarData(data)}'
          : ApiLinks.fitnessCheckinDiario;

      final NetworkResponse response = await NetworkCaller().getRequest(url);

      if (response.isSuccess && response.body != null) {
        return CheckinDiario.fromJson(
          Map<String, dynamic>.from(response.body!),
        );
      }
    } catch (e) {
      // Falha silenciosa: a UI cai no fallback local.
      return null;
    }
    return null;
  }

  /// Salva (upsert) o checkin do dia via PUT. Retorna o checkin atualizado ou
  /// null em falha.
  Future<CheckinDiario?> salvarResumo(CheckinDiario checkin) async {
    try {
      final body = <String, dynamic>{
        'dataRegistro': _formatarData(checkin.dataRegistro),
        'humor': checkin.humor,
        'observacao': checkin.observacao,
      };

      final NetworkResponse response = await NetworkCaller()
          .putRequest(ApiLinks.fitnessCheckinDiario, body);

      if (response.isSuccess && response.body != null) {
        return CheckinDiario.fromJson(
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
