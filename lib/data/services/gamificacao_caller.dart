import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

import '../models/gamificacao_model.dart';

/// Caller HTTP de gamificação (perfil de opt-in, conquistas e ranking).
/// Segue o padrão de SaudeDiariaCaller.
///
/// Os endpoints de fitness NÃO são envelopados pelo backend, então o parsing
/// é delegado ao fromJson defensivo de cada model. Todos os métodos retornam
/// null/lista vazia em qualquer falha (nunca lançam), para permitir fallback
/// gracioso na UI.
class GamificacaoCaller {
  /// Busca o perfil de gamificação (opt-ins de ranking/comunidade). Retorna
  /// null em qualquer falha.
  Future<GamificacaoPerfil?> fetchPerfil() async {
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.fitnessGamificacaoPerfil);

      if (response.isSuccess && response.body != null) {
        return GamificacaoPerfil.fromJson(
          Map<String, dynamic>.from(response.body!),
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Atualiza os opt-ins de ranking/comunidade via PUT. Envia apenas os
  /// campos informados (parciais). Retorna o perfil atualizado ou null em
  /// falha.
  Future<GamificacaoPerfil?> atualizarOptIns({
    bool? rankingOptIn,
    bool? comunidadeOptIn,
  }) async {
    try {
      final body = <String, dynamic>{
        if (rankingOptIn != null) 'rankingOptIn': rankingOptIn,
        if (comunidadeOptIn != null) 'comunidadeOptIn': comunidadeOptIn,
      };

      final NetworkResponse response = await NetworkCaller().putRequest(
        ApiLinks.fitnessGamificacaoPerfil,
        body,
      );

      if (response.isSuccess && response.body != null) {
        return GamificacaoPerfil.fromJson(
          Map<String, dynamic>.from(response.body!),
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Busca a lista de conquistas (obtidas e não obtidas). Retorna null em
  /// qualquer falha, para permitir fallback gracioso na UI.
  Future<List<ConquistaItem>?> fetchConquistas() async {
    try {
      final NetworkResponse response = await NetworkCaller()
          .getRequest(ApiLinks.fitnessGamificacaoConquistas);

      if (response.isSuccess && response.body != null) {
        final raw = response.body!['data'] ?? response.body;
        if (raw is List) {
          return raw
              .whereType<Map>()
              .map((item) =>
                  ConquistaItem.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Busca o ranking opcional (top N + posição do usuário). Retorna null em
  /// qualquer falha, para permitir fallback gracioso na UI.
  Future<List<RankingItem>?> fetchRanking() async {
    try {
      final NetworkResponse response = await NetworkCaller()
          .getRequest(ApiLinks.fitnessGamificacaoRanking);

      if (response.isSuccess && response.body != null) {
        final raw = response.body!['data'] ?? response.body;
        if (raw is List) {
          return raw
              .whereType<Map>()
              .map((item) =>
                  RankingItem.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
