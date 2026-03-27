import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/venda_model.dart';
import 'package:task_manager_flutter/data/models/negotiation_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/ui/screens/LoginPopup_screens.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:http/http.dart' as http;

class VendasCaller {
  Future<List<Produto>> fetchCotacoes(BuildContext context) async {
    List<Produto>? model = [];
    ProdutoModel models;
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.allVendas);

      if (response.statusCode == 200 && response.body != null) {
        models = ProdutoModel.fromJson(response.body!);
        model.addAll(models.produtos ?? []);
      } else {
        print('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      print('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar cotações: $e');
    }
    return model;
  }

  Future<List<Product>> fetchItensAVenda(BuildContext context) async {
    List<Product>? model = [];
    ProductModel models;
    try {
      final NetworkResponse response = await NetworkCaller().getRequests(
          '${ApiLinks.fecthItensAVenda}${AuthUtility.userInfo?.data?.id}',
          context);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        models = ProductModel.fromJson(response.body!);
        model.addAll(models.produtos ?? []);
      } else {
        print('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      print('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar itens à venda: $e');
    }
    return model;
  }

  Future<List<Product>> fetchItensACompra(BuildContext context) async {
    List<Product>? model = [];
    ProductModel models;
    try {
      if (AuthUtility.userInfo?.data?.id == 1) {
        // AQUI CHAMAR O LOGIN
        await showDialog(
          context: context,
          builder: (BuildContext context) => const LoginPopup(),
        );
      } else {
        final NetworkResponse response = await NetworkCaller().getRequests(
            '${ApiLinks.fecthItensACompra}${AuthUtility.userInfo?.data?.id}',
            context);
        String jsonString;

        if (response.statusCode == 200 && response.body != null) {
          jsonString = json.encode(response.body);
          models = ProductModel.fromJson(response.body!);
          model.addAll(models.produtos ?? []);
        } else if (response.statusCode == 403) {
          // Mova o código que depende do BuildContext para este método.
        } else {
          print('Erro: Nenhum dado retornado');
        }
      }
    } catch (e) {
      print('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar itens à compra: $e');
    }
    return model;
  }

  Future<List<Product>> fetchItensANegocias(BuildContext context) async {
    List<Product>? model = [];
    ProductModel models;
    try {
      final NetworkResponse response = await NetworkCaller().getRequests(
          '${ApiLinks.fecthItensANegociar}${AuthUtility.userInfo?.data?.id}',
          context);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        models = ProductModel.fromJson(response.body!);
        model.addAll(models.produtos ?? []);
      } else {
        print('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      print('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar itens a negociar: $e');
    }
    return model;
  }

  Future<List<Account>> fetchClassificacao(BuildContext context) async {
    List<Account>? model = [];
    ClassificacaoResponse models;
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequests(ApiLinks.allClassificacao, context);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        models = ClassificacaoResponse.fromJson(response.body!);
        model.addAll(models.data ?? []);
      } else {
        print('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      print('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar classificações: $e');
    }
    return model;
  }

  Future<List<Produto>> fetchProdutoDetails(
      BuildContext context, int id) async {
    List<Produto>? model = [];
    ProdutoModel models;
    try {
      final NetworkResponse response = await NetworkCaller().getRequest(
        '${ApiLinks.fecthProdutosById}$id',
      );
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        models = ProdutoModel.fromJson(response.body!);
        model.addAll(models.produtos ?? []);
      } else {
        print('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      print('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar cotações: $e');
    }
    return model;
  }

  void downloadContrato(int contratoId, BuildContext context) async {
    final url = "${ApiLinks.downloadContrato}/$contratoId";

    // Get the token (replace with your actual AuthUtility method)
    final token =
        AuthUtility.userInfo?.token; // Assuming userInfo.token is available

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json', // Important: Add Accept header
        },
      );

      if (response.statusCode == 200) {
        // ... (rest of your download and open file logic)

        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/contrato_$contratoId.pdf');
        await file
            .writeAsBytes(response.bodyBytes); // Write the bytes to the file

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Download concluído! Abrindo o contrato...')),
        );

        OpenFilex.open(file.path); // Open the file
      } else {
        print(
            'Error: ${response.statusCode} - ${response.body}'); // Print error details
        // Try to decode the error response body (if it's JSON)
        try {
          final errorData = jsonDecode(response.body);
          print('Error Data: $errorData'); // Print decoded error data
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Erro ao baixar contrato: ${errorData['message'] ?? 'Erro desconhecido'}')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao baixar contrato')),
          );
        }
      }
    } catch (e) {
      print('Error during download: $e'); // Catch and log any exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao baixar contrato')),
      );
    }
  }

  Future<List<Product>> confirmarNegociacao(
      BuildContext context, int negociacaoId) async {
    List<Product>? model = [];
    ProductModel models;
    try {
      final NetworkResponse response = await NetworkCaller().getRequests(
          "${ApiLinks.confirmarNegociacao}/$negociacaoId", context);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sucesso!!!')),
        );
      } else {
        print('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      print('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar itens à venda: $e');
    }
    return model;
  }

  Future<List<Product>> confirmarRecusar(
      BuildContext context, int negociacaoId) async {
    List<Product>? model = [];
    ProductModel models;
    try {
      final NetworkResponse response = await NetworkCaller()
          .getRequests("${ApiLinks.confirmarRecusar}/$negociacaoId", context);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sucesso!!!')),
        );
      } else {
        print('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      print('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar itens à venda: $e');
    }
    return model;
  }

  Future<Map<String, dynamic>?> enviarContraProposta(
    BuildContext context,
    int negociacaoId,
    int vendaId,
    int compradorId,
    int vendedorId,
    double qtdSacos,
    double vlrSacos,
  ) async {
    final body = {
      'negociacaoId': negociacaoId,
      'vendaId': vendaId,
      'compradorId': compradorId,
      'vendedorId': vendedorId,
      'qtdSacos': qtdSacos,
      'vlrSacos': vlrSacos,
    };

    try {
      final NetworkResponse response =
          await NetworkCaller().getRequests(ApiLinks.contraProposta, context);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sucesso!!!')),
        );
      } else {
        print('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      print('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar itens à venda: $e');
    }
    return null;
  }
}
