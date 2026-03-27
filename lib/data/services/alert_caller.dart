import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/alert_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';

class AlertCaller {
  Future<List<Alert>> fetchAllAlerts(BuildContext context) async {
    List<Alert>? model = [];
    AlertResponse models;
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequests(ApiLinks.allAlerts, context);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        models = AlertResponse.fromJson(response.body!);
        model.addAll(models.account ?? []);
      } else {
        print('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      print('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar cotações: $e');
    }
    return model;
  }

  Future<List<Alert>> fetchItensAVenda(BuildContext context) async {
    List<Alert>? model = [];
    AlertResponse models;
    if (AuthUtility.userInfo?.data?.id != null) {
      try {
        final NetworkResponse response = await NetworkCaller().getRequests(
            '${ApiLinks.alertFindByUser}${AuthUtility.userInfo?.data?.id}',
            context);
        String jsonString;

        if (response.statusCode == 200 && response.body != null) {
          jsonString = json.encode(response.body);
          models = AlertResponse.fromJson(response.body!);
          model.addAll(models.account ?? []);
        } else {
          print('Erro: Nenhum dado retornado');
        }
      } catch (e) {
        print('Erro: $e'); // Log do erro
        throw Exception('Erro ao carregar itens à venda: $e');
      }
      return model;
    }
    return model;
  }

  // New function to mark notification as read
  Future<void> markNotificationAsRead(int id) async {
    try {
      final NetworkResponse response = await NetworkCaller().postRequest(
        ApiLinks.allAlerts,
        {"id": id},
      );

      if (response.isSuccess) {
        // Success is handled in the calling widget which will update its state
        debugPrint('Notification marked as read successfully');
      } else {
        debugPrint('Failed to mark notification as read');
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
}
