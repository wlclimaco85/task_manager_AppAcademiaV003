import 'dart:convert';

import 'package:task_manager_flutter/data/models/documento_model.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

class DocumentoService {
  final String baseUrl = ApiLinks.fecthAllDocumentos;

  Future<List<Documento>> getDocumentosPorData(DateTime data) async {
    List<Documento>? model = [];
    DocumentoModel models;
    final NetworkResponse response = await NetworkCaller().getRequest(
      '$baseUrl/data/${data.toIso8601String().substring(0, 10)}',
    );

    print(
      'Response Status: $baseUrl/data/${data.toIso8601String().substring(0, 10)}',
    );
    if (response.statusCode == 200) {
      models = DocumentoModel.fromJson(response.body!);
      model.addAll(models.data ?? []);
      return model;
    } else {
      throw Exception('Falha ao carregar documentos');
    }
  }

  Future<List<Documento>> getDocumentosPorMesAno(int mes, int ano) async {
    List<Documento>? model = [];
    DocumentoModel models;
    final NetworkResponse response = await NetworkCaller().getRequest(
      '$baseUrl/mes/$mes/ano/$ano',
    );

    if (response.statusCode == 200) {
      models = DocumentoModel.fromJson(response.body!);
      model.addAll(models.data ?? []);
      return model;
    } else {
      throw Exception('Falha ao carregar documentos');
    }
  }

  Future<List<DateTime>> getDatasComDocumentos(int mes, int ano) async {
    List<Documento>? model = [];
    DocumentoModel models;
    final NetworkResponse response = await NetworkCaller().getRequest(
      '$baseUrl/datas/mes/$mes/ano/$ano',
    );

    if (response.statusCode == 200) {
      models = DocumentoModel.fromJson(response.body!);
      model.addAll(models.data ?? []);
      return (models.data ?? [])
          .map<DateTime>(
            (ts) =>
                DateTime.fromMillisecondsSinceEpoch(int.parse(ts.toString())),
          )
          .toList();
    } else {
      throw Exception('Falha ao carregar datas com documentos');
    }
  }

  Future<Documento> criarDocumento(Documento documento) async {
    final response = await NetworkCaller().postRequest(
      baseUrl,
      documento.toJson(),
    );

    if (response.statusCode == 200) {
      return Documento.fromJson(json.decode(response.body?['data']['dados']));
    } else {
      throw Exception('Falha ao criar documento');
    }
  }

  //-----

  Future<List<DateTime>> getDatasComDocumentosNovos(
    int mes,
    int ano,
    int usuarioId,
  ) async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      '$baseUrl/datas/novos/mes/$mes/ano/$ano',
    );

    print('$baseUrl/datas/novos/mes/$mes/ano/$ano');

    if (response.statusCode == 200) {
      final body = response.body;

      // O backend deve devolver lista de datas em formato String
      final List<DateTime> datas = (body?['data']['dados'] as List<dynamic>)
          .map<DateTime>((d) => DateTime.parse(d.toString()))
          .toList();

      return datas;
    } else {
      throw Exception('Falha ao carregar datas com documentos novos');
    }
  }

  Future<List<DateTime>> getDatasComDocumentosLidos(
    int mes,
    int ano,
    int usuarioId,
  ) async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      '$baseUrl/datas/lidos/mes/$mes/ano/$ano',
    );

    if (response.statusCode == 200) {
      final body = response.body;

      final List<DateTime> datas = (body?['data']['dados'] as List<dynamic>)
          .map<DateTime>((d) => DateTime.parse(d.toString()))
          .toList();

      return datas;
    } else if (response.statusCode == 400) {
      return [];
    } else {
      throw Exception('Falha ao carregar datas com documentos lidos');
    }
  }

  Future<void> marcarComoLido(int documentoId, int usuarioId) async {
    final NetworkResponse response = await NetworkCaller().postRequest(
      '$baseUrl/$documentoId/ler',
      {}, // corpo vazio
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao marcar documento como lido');
    }
  }

  Future<bool> verificarSeLido(int documentoId, int usuarioId) async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      '$baseUrl/$documentoId/lido/',
    );

    if (response.statusCode == 200) {
      return response.body?['data'] as bool? ?? false;
    } else {
      return false;
    }
  }
}
