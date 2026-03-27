import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

import '../models/comunicados_model.dart';

class ComunicadoCaller {
  Future<List<Comunicado>> fetchAllComunicados() async {
    List<Comunicado> list = [];
    try {
      final NetworkResponse response = await NetworkCaller().getRequest(
        ApiLinks.allComunicados,
      );

      if (response.isSuccess && response.body != null) {
        final data = response.body!['data']['dados'] ?? [];
        list = (data as List).map((item) => Comunicado.fromJson(item)).toList();
      }
    } catch (e) {
      print('Erro ao carregar comunicados: $e');
      throw Exception('Erro ao carregar comunicados: $e');
    }
    return list;
  }

  Future<List<Map<String, dynamic>>> fetchComunicadoDropdown() async {
    final comunicados = await fetchAllComunicados();
    return comunicados.map((c) => {'value': c.id, 'label': c.titulo}).toList();
  }

  /// Retorna todos os comunicados
  Future<List<Comunicado>> fetchAllComunicadoss() async {
    final response = await NetworkCaller().getRequest(ApiLinks.allComunicados);
    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map((item) => Comunicado.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  /// Cria um novo comunicado
  Future<bool> createComunicado(Comunicado comunicado) async {
    final response = await NetworkCaller().postRequest(
      ApiLinks.createComunicado,
      comunicado.toJson(),
    );
    return response.isSuccess;
  }

  /// Atualiza comunicado existente
  Future<bool> updateComunicado(Comunicado comunicado) async {
    final response = await NetworkCaller().putRequest(
      "${ApiLinks.updateComunicado}/${comunicado.id}",
      comunicado.toJson(),
    );
    return response.isSuccess;
  }

  /// Exclui comunicado
  Future<bool> deleteComunicado(int id) async {
    final response = await NetworkCaller().deleteRequest(
      "${ApiLinks.deleteComunicado}/$id",
    );
    return response.isSuccess;
  }
}
