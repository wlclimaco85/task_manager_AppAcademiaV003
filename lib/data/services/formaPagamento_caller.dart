import 'package:task_manager_flutter/data/models/forma_pagamento_model.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

class FormaPagamentoCaller {
  /// 🔹 Busca e retorna a lista de objetos FormaPagamento
  Future<List<FormaPagamento>> fetchAllFormasPagamento() async {
    List<FormaPagamento> list = [];
    try {
      final NetworkResponse response = await NetworkCaller().getRequest(
        ApiLinks.allFormasPagamento,
      );

      if (response.isSuccess && response.body != null) {
        final data = response.body!['data']['dados'] ?? [];
        list = (data as List)
            .map((item) => FormaPagamento.fromJson(item))
            .toList();
      }
    } catch (e) {
      print('Erro ao carregar formas de pagamento: $e');
      throw Exception('Erro ao carregar formas de pagamento: $e');
    }
    return list;
  }

  /// 🔹 Usa fetchAllFormasPagamento e converte para lista de Map
  Future<List<Map<String, dynamic>>> fetchFormasPagamentoDropDown() async {
    final formasPagamento = await fetchAllFormasPagamento();
    return formasPagamento
        .map((fp) => {'value': fp.id, 'label': fp.nome})
        .toList();
  }
}
