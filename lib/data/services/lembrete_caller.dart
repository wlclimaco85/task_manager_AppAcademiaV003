import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

import '../models/lembrete_model.dart';

/// Caller HTTP de lembretes (medicamento/suplemento/habito/outro). Segue o
/// padrao de MedidaCorporalCaller.
///
/// Os endpoints de fitness NAO sao envelopados pelo backend, entao o parsing
/// e delegado ao fromJson defensivo de [Lembrete].
class LembreteCaller {
  /// Busca os lembretes ativos. Retorna null em qualquer falha (nao lanca),
  /// para permitir fallback gracioso na UI (lista vazia).
  Future<List<Lembrete>?> fetchLembretes({bool? ativo}) async {
    try {
      final url = ativo != null
          ? '${ApiLinks.fitnessLembretes}?ativo=$ativo'
          : ApiLinks.fitnessLembretes;

      final NetworkResponse response = await NetworkCaller().getRequest(url);

      if (response.isSuccess && response.body != null) {
        final raw = response.body!['data'] ?? response.body;
        if (raw is List) {
          return raw
              .whereType<Map>()
              .map((item) => Lembrete.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      }
    } catch (e) {
      // Falha silenciosa: a UI cai no fallback local (lista vazia).
      return null;
    }
    return null;
  }

  /// Cria um novo lembrete via POST. Retorna o lembrete criado ou null em
  /// falha.
  Future<Lembrete?> criarLembrete(Lembrete lembrete) async {
    try {
      final NetworkResponse response = await NetworkCaller().postRequest(
        ApiLinks.fitnessLembretes,
        lembrete.toJson(),
      );

      if (response.isSuccess && response.body != null) {
        return Lembrete.fromJson(Map<String, dynamic>.from(response.body!));
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Marca o lembrete como concluido hoje via PUT (sem body, idempotente).
  /// Retorna true em sucesso, false em falha.
  Future<bool> concluirLembrete(int id) async {
    try {
      final NetworkResponse response = await NetworkCaller()
          .putRequest('${ApiLinks.fitnessLembretes}/$id/concluir', {});

      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  /// Inativa o lembrete via PATCH (sem body). Retorna true em sucesso, false
  /// em falha.
  Future<bool> inativarLembrete(int id) async {
    try {
      final NetworkResponse response = await NetworkCaller()
          .patchRequest('${ApiLinks.fitnessLembretes}/$id/inativar', {});

      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }
}
