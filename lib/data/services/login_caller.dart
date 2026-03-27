import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

class LoginCaller {
  /// 🔹 Busca todos os logins de uma empresa
  Future<List<Map<String, dynamic>>> fetchUsuariosEmpresa(
      int? empresaId) async {
    if (empresaId == null) return [];

    try {
      final response = await NetworkCaller().getRequest(ApiLinks.allLogins);

      if (response.isSuccess && response.body != null) {
        final List<dynamic> dados = response.body!['data']['dados'] ?? [];
        return dados
            .map((e) => {
                  'value': e['id'],
                  'label': "${e['nome']} (${e['email'] ?? ''})",
                })
            .toList();
      }
    } catch (e) {
      debugPrint('Erro ao buscar logins: $e');
    }
    return [];
  }
}
