import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

class BaixaCaller {
  /// ✅ Desfazer baixa de conta (tipo = "pagar" ou "receber")
  static Future<NetworkResponse> desfazerBaixa({
    required String tipo, // "pagar" ou "receber"
    required int id,
  }) async {
    if (tipo != 'pagar' && tipo != 'receber') {
      throw ArgumentError('Tipo inválido: deve ser "pagar" ou "receber".');
    }
    String url = ApiLinks.desfazerContaReceber(id.toString());
    if (tipo == 'pagar') {
      url = ApiLinks.desfazerContaPagar(id.toString());
    }
    try {
      final NetworkResponse response = await NetworkCaller().postRequest(
        url,
        {"id": id},
      );

      if (response.isSuccess) {
        // Success is handled in the calling widget which will update its state
        debugPrint('Notification marked as read successfully');
      } else {
        debugPrint('Failed to mark notification as read');
      }

      return response;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }
}
