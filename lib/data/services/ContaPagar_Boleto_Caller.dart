import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // ✅ MediaType
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

class ContaPagarBoletoCaller {
  /// Retorna o JSON do backend (para mostrar no popup).
  /// Se você preferir bool, dá pra trocar, mas assim fica perfeito pro popup.
  Future<Map<String, dynamic>?> importarBoleto({
    required File pdfFile,
    required String descricao,
    required double valor,
    required String dataVencimentoIso, // yyyy-MM-dd
    required int empresaId,
    String? parceiroNome,
    String? parceiroDocumento,
    int? formaPagamentoId,
    String? observacao,
    String? numeroNota,
  }) async {
    try {
      final token = AuthUtility.userInfo?.token;
      if (token == null || token.isEmpty) {
        debugPrint('Token ausente. Faça login novamente.');
        return null;
      }

      final uri =
          Uri.parse(ApiLinks.contasPagarBoleto); // ✅ use sua constante pronta

      final request = http.MultipartRequest('POST', uri);

      // ✅ Headers obrigatórios
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Campo JSON "data"
      final data = <String, dynamic>{
        "descricao": descricao,
        "valor": valor,
        "dataVencimento": dataVencimentoIso,
        "empresaId": empresaId,
        "parceiroNome": parceiroNome,
        "parceiroDocumento": parceiroDocumento,
        "formaPagamentoId": formaPagamentoId,
        "observacao": observacao,
        "numeroNota": numeroNota,
      };

      request.files.add(
        http.MultipartFile.fromString(
          'data',
          jsonEncode(data),
          contentType: MediaTypeHelper.jsonUtf8(),
          filename: 'data.json',
        ),
      );

      // Arquivo PDF
      request.files.add(
        await http.MultipartFile.fromPath(
          'pdf',
          pdfFile.path,
          contentType: MediaTypeHelper.pdf(),
          filename: pdfFile.path.split('/').last,
        ),
      );

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        debugPrint('Importação OK: $body');

        if (body.isEmpty) return <String, dynamic>{};
        final decoded = jsonDecode(body);

        // ✅ garante Map
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);

        return <String, dynamic>{"raw": decoded};
      } else {
        debugPrint('Erro importar boleto: ${streamed.statusCode} - $body');
        return null;
      }
    } catch (e) {
      debugPrint('Erro importar boleto: $e');
      return null;
    }
  }
}

/// ✅ Helper correto para content-type (precisa do package http_parser)
class MediaTypeHelper {
  static MediaType jsonUtf8() =>
      MediaType('application', 'json', {'charset': 'utf-8'});
  static MediaType pdf() => MediaType('application', 'pdf');
}
