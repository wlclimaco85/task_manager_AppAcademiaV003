import 'dart:convert';
import 'package:task_manager_flutter/data/models/cotacao_model.dart';
import 'package:task_manager_flutter/data/models/dollar_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';

class CotacaoCaller {
  Future<List<Cotacao>> fetchCotacoes() async {
    List<Cotacao>? model = [];
    CotacaoModel models;
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.allCotacoes);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        models = CotacaoModel.fromJson(response.body!);
        model.addAll(models.data ?? []);

        // if (model != null && model.data != null) {
        //   newsList.addAll(model.data!);
        // }
        // Use jsonString conforme necessário
      } else {
        // Trate o caso onde o data é nulo
      }
    } catch (e) {
      print('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar cotações: $e');
    }
    return model;
  }

  Future<List<Dollar>> fetchCotacoesDollar() async {
    List<Dollar>? model = [];
    DollarModel models;
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.fecthAllCotacaoDollar);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        models = DollarModel.fromJson(response.body!);
        model.addAll(models.data ?? []);

        // if (model != null && model.data != null) {
        //   newsList.addAll(model.data!);
        // }
        // Use jsonString conforme necessário
      } else {
        // Trate o caso onde o data é nulo
      }
    } catch (e) {
      print('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar cotações: $e');
    }
    return model;
  }
}
