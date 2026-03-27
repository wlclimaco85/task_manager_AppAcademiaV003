import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/utils.dart';

class FileCaller {
  Future<List<Map<String, dynamic>>> fetchDiretorios() async {
    final response = await NetworkCaller().getRequest(ApiLinks.allDiretorios);
    if (response.isSuccess && response.body != null) {
      final data = response.body!['data']['dados'] ?? [];
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchArquivosPorDiretorio(
      int diretorioId) async {
    final response = await NetworkCaller()
        .getRequest("${ApiLinks.allArquivos}/$diretorioId");
    if (response.isSuccess && response.body != null) {
      final data = response.body!['data']['dados'] ?? [];
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  /// 🔹 Inserir arquivo (upload com parceiro e empresa)
  Future<bool> insertFileAttachment({
    required Uint8List fileBytes,
    required String fileName,
    required String fileType,
    required int diretorioId,
    required int parceiroId,
  }) async {
    // Pega empresa logada
    final empresaId = await pegarEmpresaLogada();
    final String authToken = '${AuthUtility.userInfo?.token}';

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiLinks.uploadFile),
      );

      // Adicionar headers de autenticação
      if (authToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

      request.fields['fileName'] = fileName;
      request.fields['fileType'] = fileType;
      request.fields['diretorio'] = jsonEncode({"id": diretorioId});
      request.fields['empresa'] = jsonEncode({"id": empresaId});
      request.fields['parceiro'] = jsonEncode({"id": parceiroId});

      request.headers['Content-Type'] = 'multipart/form-data';
      request.headers['Accept'] = 'application/json';

      final response = await request.send();

      if (response.statusCode == 200) {
        return true;
      } else {
        final msg = await response.stream.bytesToString();
        print("Erro upload: ${response.statusCode} => $msg");
        return false;
      }
    } catch (e) {
      print("Erro ao enviar arquivo: $e");
      return false;
    }
  }

  Future<bool> deleteArquivo(int id) async {
    final response =
        await NetworkCaller().deleteRequest("${ApiLinks.deleteArquivo}/$id");
    return response.isSuccess;
  }

  Future<bool> marcarComoLido(int id) async {
    final response =
        await NetworkCaller().putRequest(ApiLinks.updateArquivoLido(id), {});
    return response.isSuccess;
  }

  /// 🔹 Inserção (upload) completa via multipart
  Future<bool> insertFileAttachmendt({
    required Uint8List fileBytes,
    required String fileName,
    required String fileType,
    required int diretorioId,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiLinks.uploadArquivo),
      );

      // Adiciona o arquivo
      request.files.add(http.MultipartFile.fromBytes('fileData', fileBytes,
          filename: fileName));

      // Adiciona os campos extras da entidade
      request.fields['fileName'] = fileName;
      request.fields['fileType'] = fileType;
      request.fields['diretorioId'] = diretorioId.toString();

      // Faz o envio
      final response = await request.send();

      if (response.statusCode == 200) {
        return true;
      } else {
        final respText = await response.stream.bytesToString();
        print("Erro ao enviar: ${response.statusCode} -> $respText");
        return false;
      }
    } catch (e) {
      print("Erro ao enviar arquivo: $e");
      return false;
    }
  }
}
