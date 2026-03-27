import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

class DiretorioCaller {
  Future<List<Map<String, dynamic>>> fetchDiretoriosDropdown() async {
    final response = await NetworkCaller().getRequest(ApiLinks.allDiretorios);
    if (response.isSuccess && response.body != null) {
      final data = response.body!['data']['dados'] ?? [];
      return (data as List)
          .map((item) => {
                'value': item['id'],
                'label': item['nome'],
              })
          .toList();
    }
    return [];
  }
}
