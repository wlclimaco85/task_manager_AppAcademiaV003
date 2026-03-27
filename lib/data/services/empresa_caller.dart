import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

class EmpresaCaller {
  // 🔄 Métodos auxiliares para dropdowns
  static Future<List<Map<String, dynamic>>> loadEmpresas() async {
    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.allEmpresas);
    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map((item) =>
              {'value': item['id'], 'label': item['nomeFantasia'].toString()})
          .toList();
    }
    return [];
  }
}
