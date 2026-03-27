// lib/dashboard/api_client.dart (atualizado)
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/dashboard_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/utils.dart';

class DashboardApiClient {
  DashboardApiClient();
  final token =
      AuthUtility.userInfo?.token; // Assuming userInfo.token is available

  final int empresaId =
      pegarEmpresaLogada(); // Exemplo fixo, ajustar conforme necessário
  final int? parceiroId =
      pegarEmpresaLogada(); // Exemplo fixo, ajustar conforme necessário
  Map<String, String> _qp([Map<String, String>? extra]) {
    final m = {
      'empresaId': empresaId.toString(),
      if (parceiroId != null) 'parceiroId': parceiroId.toString(),
    };
    if (extra != null) m.addAll(extra);
    return m;
  }

  Future<List<FinancePoint>> fetchFinanceSeries({int months = 6}) async {
    final uri = Uri.parse(ApiLinks.getFinance)
        .replace(queryParameters: _qp({'months': '$months'}));

    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    debugPrint('[fetchFinanceSeries] status=${res.statusCode}');
    debugPrint('[fetchFinanceSeries] body=${res.body}');

    if (res.statusCode == 204) return [];
    if (res.statusCode != 200) {
      throw Exception('Finance series error ${res.statusCode}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw StateError(
          '[fetchFinanceSeries] payload não é uma lista: ${decoded.runtimeType}');
    }

    return decoded.map((e) {
      if (e is! Map) {
        debugPrint(
            '[fetchFinanceSeries] item não é Map: ${e.runtimeType} -> $e');
        return FinancePoint('', 0, 0);
      }
      final map = Map<String, dynamic>.from(e);

      debugPrint('[fetchFinanceSeries] item types: '
          'month=${map['month']?.runtimeType}, '
          'receivable=${map['receivable']?.runtimeType}, '
          'payable=${map['payable']?.runtimeType}');

      return FinancePoint.fromJson(map); // usa os helpers tolerantes
    }).toList();
  }

  Future<TicketStatusCounts> fetchTicketStatusCounts() async {
    final res = await http.get(
      Uri.parse(ApiLinks.statusCounts),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    debugPrint('[fetchTicketStatusCounts] status=${res.statusCode}');
    debugPrint('[fetchTicketStatusCounts] body=${res.body}');

    if (res.statusCode != 200) {
      throw Exception('Ticket counts error ${res.statusCode}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw StateError(
          '[fetchTicketStatusCounts] payload não é objeto: ${decoded.runtimeType}');
    }

    final map = Map<String, dynamic>.from(decoded);

    debugPrint('[fetchTicketStatusCounts] field types: '
        'open=${map['open']?.runtimeType}, '
        'inProgress=${map['inProgress']?.runtimeType}, '
        'closed=${map['closed']?.runtimeType}');

    return TicketStatusCounts.fromJson(map); // usa _toInt seguro
  }

  Future<List<ChatsDailyPoint>> fetchChatsDaily({int days = 7}) async {
    final res = await http.get(
      Uri.parse(ApiLinks.chatDailys)
          .replace(queryParameters: {'days': '$days'}),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    debugPrint('[fetchChatsDaily] status=${res.statusCode}');
    debugPrint('[fetchChatsDaily] body=${res.body}');

    if (res.statusCode == 204) return [];
    if (res.statusCode != 200) {
      throw Exception('Chats daily error ${res.statusCode}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw StateError(
          '[fetchChatsDaily] payload não é lista: ${decoded.runtimeType}');
    }

    return decoded.map((e) {
      if (e is! Map) {
        debugPrint('[fetchChatsDaily] item não é Map: ${e.runtimeType} -> $e');
        return ChatsDailyPoint(DateTime.now(), 0);
      }
      final map = Map<String, dynamic>.from(e);

      debugPrint('[fetchChatsDaily] item types: '
          'date=${map['date']?.runtimeType}, '
          'openChats=${map['openChats']?.runtimeType}');

      return ChatsDailyPoint.fromJson(map);
    }).toList();
  }
}
