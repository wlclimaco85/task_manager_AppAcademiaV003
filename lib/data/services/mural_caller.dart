import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

import '../models/mural_model.dart';

/// Caller HTTP do mural da comunidade. Segue o padrão de SaudeDiariaCaller.
///
/// O endpoint de fitness NÃO é envelopado pelo backend, então o parsing é
/// delegado ao fromJson defensivo de [MuralPost]. Os métodos retornam
/// null/lista vazia em qualquer falha (nunca lançam), para permitir fallback
/// gracioso na UI.
class MuralCaller {
  /// Busca os posts do mural. Retorna null em qualquer falha.
  Future<List<MuralPost>?> fetchPosts() async {
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.fitnessMuralPosts);

      if (response.isSuccess && response.body != null) {
        final raw = response.body!['data'] ?? response.body;
        if (raw is List) {
          return raw
              .whereType<Map>()
              .map((item) => MuralPost.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Cria um novo post no mural. Retorna o post criado ou null em falha.
  Future<MuralPost?> criarPost(String conteudo) async {
    try {
      final NetworkResponse response = await NetworkCaller().postRequest(
        ApiLinks.fitnessMuralPosts,
        {'conteudo': conteudo},
      );

      if (response.isSuccess && response.body != null) {
        return MuralPost.fromJson(
          Map<String, dynamic>.from(response.body!),
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
