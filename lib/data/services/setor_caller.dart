import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

import '../models/setor_model.dart';

class SetorCaller {
  Future<List<Setor>> fetchAllSetores() async {
    List<Setor> list = [];
    try {
      final NetworkResponse response = await NetworkCaller().getRequest(
        ApiLinks.allSetores,
      );

      if (response.isSuccess && response.body != null) {
        final data = response.body!['data']['dados'] ?? [];
        list = (data as List).map((item) => Setor.fromJson(item)).toList();
      }
    } catch (e) {
      print('Erro ao carregar setores: $e');
      throw Exception('Erro ao carregar setores: $e');
    }
    return list;
  }

  Future<List<Map<String, dynamic>>> fetchSetorDropdown() async {
    final setores = await fetchAllSetores();
    return setores.map((s) => {'value': s.id, 'label': s.nome}).toList();
  }
}
