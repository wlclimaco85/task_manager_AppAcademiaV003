import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

import '../models/exame_registro_model.dart';

/// Caller HTTP de registros de exame. Segue o padrao de SaudeDiariaCaller.
///
/// Os endpoints de fitness NAO sao envelopados pelo backend, entao o parsing
/// e delegado ao fromJson defensivo de [ExameRegistro].
class ExameRegistroCaller {
  /// Busca os exames registrados no intervalo informado. Retorna null em
  /// qualquer falha (nao lanca), para permitir fallback gracioso na UI.
  Future<List<ExameRegistro>?> fetchExames({
    DateTime? inicio,
    DateTime? fim,
  }) async {
    try {
      final params = <String>[];
      if (inicio != null) params.add('inicio=${_formatarData(inicio)}');
      if (fim != null) params.add('fim=${_formatarData(fim)}');
      final url = params.isNotEmpty
          ? '${ApiLinks.fitnessExames}?${params.join('&')}'
          : ApiLinks.fitnessExames;

      final NetworkResponse response = await NetworkCaller().getRequest(url);

      if (response.isSuccess && response.body != null) {
        final raw = response.body!['data'] ?? response.body;
        if (raw is List) {
          return raw
              .whereType<Map>()
              .map((item) =>
                  ExameRegistro.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      }
    } catch (e) {
      // Falha silenciosa: a UI cai no fallback local (lista vazia).
      return null;
    }
    return null;
  }

  /// Registra um novo exame via POST. Retorna o exame criado ou null em
  /// falha.
  Future<ExameRegistro?> registrarExame(ExameRegistro exame) async {
    try {
      final NetworkResponse response = await NetworkCaller().postRequest(
        ApiLinks.fitnessExames,
        exame.toJson(),
      );

      if (response.isSuccess && response.body != null) {
        return ExameRegistro.fromJson(
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
