import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/chat_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';

class ChatCaller {
  Future<List<ChatMessage>> fetchChats(BuildContext context) async {
    List<ChatMessage>? model = [];
    ChatMessageModel models;
    try {
      DadosPessoal dp =
          AuthUtility.userInfo?.data?.codDadosPessoal ?? DadosPessoal();
      final eeee = '${ApiLinks.fecthChats}?user=${dp.email!}';
      print('URL de requisição: $eeee');

      final NetworkResponse response = await NetworkCaller()
          .getRequest('${ApiLinks.fecthChats}?user=${dp.email!}');

      if (response.statusCode == 200 && response.body != null) {
        models = ChatMessageModel.fromJson(response.body!);
        model.addAll(models.messages ?? []);
      } else {
        print('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      print('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar cotações: $e');
    }
    return model;
  }

  Future<List<ChatMessage>> fetchChatsById(
      BuildContext context, String chatId) async {
    List<ChatMessage>? model = [];
    ChatMessageModel models;
    try {
      print('URL de requisição: $chatId');

      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.fecthChatById + chatId);

      if (response.statusCode == 200 && response.body != null) {
        models = ChatMessageModel.fromJson(response.body!);
        model.addAll(models.messages ?? []);
      } else {
        print('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      print('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar cotações: $e');
    }
    return model;
  }
}
