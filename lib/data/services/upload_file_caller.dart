import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui; // ← Adicione esta importação

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

class UploadFileCaller {
  Future<int> uploadFiles(
    String itemId,
    Map<String, List<PlatformFile>> filesToUpload,
  ) async {
    final String authToken = '${AuthUtility.userInfo?.token}';

    if (filesToUpload.isEmpty) return 0;

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiLinks.uploadFile),
      );

      request.fields['itemId'] = itemId;

      for (final entry in filesToUpload.entries) {
        final String fieldName = entry.key;
        final List<PlatformFile> files = entry.value;

        for (final platformFile in files) {
          Uint8List fileBytes;

          if (platformFile.bytes != null) {
            fileBytes = platformFile.bytes!;
          } else if (platformFile.path != null) {
            File ioFile = File(platformFile.path!);
            fileBytes = await ioFile.readAsBytes();
          } else {
            continue;
          }

          request.files.add(
            http.MultipartFile.fromBytes(
              fieldName,
              fileBytes,
              filename: platformFile.name,
            ),
          );
        }
      }

      // Adicionar headers de autenticação
      if (authToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      // Enviar a requisição
      final response = await request.send();

      // Verificar resposta
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final decoded = jsonDecode(responseBody);
        return decoded['fileId'] ?? 0;
      } else {
        final errorBody = await response.stream.bytesToString();
        print('Erro no upload (${response.statusCode}): $errorBody');
      }
    } catch (e) {
      print('Exceção durante o upload: $e');
    }
    return 0;
  }

  Future<int> uploadFiless({
    required PlatformFile file,
    required int empresaId,
    int? parceiroId,
    int? diretorioId,
  }) async {
    final String authToken = '${AuthUtility.userInfo?.token}';
    final uri = Uri.parse(ApiLinks.uploadFile);

    try {
      // 🔹 Cria a requisição multipart
      var request = http.MultipartRequest('POST', uri);

      // ---- Campos obrigatórios do BE ----
      request.fields['fileName'] = file.name;
      request.fields['fileType'] = file.extension ?? 'application/octet-stream';
      request.fields['diretorio'] =
          jsonEncode({'id': diretorioId ?? 1}); // exemplo padrão
      request.fields['empresa'] = jsonEncode({'id': empresaId});
      request.fields['parceiro'] = jsonEncode({'id': parceiroId ?? 0});

      // ---- Adiciona o arquivo ----
      final Uint8List fileBytes =
          file.bytes ?? await File(file.path!).readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file', // precisa bater com o @RequestParam("file")
        fileBytes,
        filename: file.name,
      ));

      // ---- Header de autenticação ----
      if (authToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      print('📤 Enviando arquivo: ${file.name} (${file.size} bytes)');
      print('🧾 Campos: ${request.fields}');

      // ---- Envia a requisição ----
      final response = await request.send();

      // ---- Lê o corpo da resposta ----
      final responseBody = await response.stream.bytesToString();
      print('📨 Resposta (${response.statusCode}): $responseBody');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(responseBody);
        return decoded['fileId'] ?? 0;
      } else {
        print('❌ Erro no upload: ${response.statusCode}');
      }
    } catch (e) {
      print('🚨 Exceção no upload: $e');
    }

    return 0;
  }

  Future<int> downloadFile(int fileId, String fileName) async {
    try {
      final String authToken = '${AuthUtility.userInfo?.token}';

      final response = await http.get(
        Uri.parse(
          ApiLinks.downloadFile(fileId.toString()),
        ),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        await Share.shareXFiles(
          [XFile(file.path, mimeType: fileName.split('.').last)],
          sharePositionOrigin: ui.Rect.largest,
        );

        print('Download realizado com sucesso');
      } else {
        print('Falha no download: ${response.statusCode}');
      }
      return response.statusCode;
    } catch (e) {
      print('Erro no download: $e');
    }
    return 0;
  }

  Future<void> registerFileOpened(int fileId) async {
    try {
      final token = '${AuthUtility.userInfo?.token}';
      final url = Uri.parse(ApiLinks.registerFileOpened(fileId.toString()));

      final res = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        print('📄 Registro de abertura enviado com sucesso para $fileId');
      } else {
        print('⚠️ Falha ao registrar abertura (${res.statusCode})');
      }
    } catch (e) {
      print('❌ Erro ao registrar arquivo aberto: $e');
    }
  }
}
