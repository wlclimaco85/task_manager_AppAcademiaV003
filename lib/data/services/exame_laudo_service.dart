import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/tenant_context.dart';

/// Envia laudos (PDF + itens lidos no app) e le o historico por item.
class ExameLaudoService {
  static const Duration _tempoLimite = Duration(seconds: 60);

  Map<String, String> get _headers {
    final token = AuthUtility.userInfo.token;
    return {
      ...TenantContext.jsonHeaders,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Grava o laudo: [pdfBase64] e os itens ja lidos no app (valor, referencia, cor).
  Future<void> enviar({
    required String dataExame,
    required String nomeArquivo,
    required String pdfBase64,
    required List<Map<String, dynamic>> itens,
  }) async {
    final resposta = await http
        .post(
          Uri.parse(TenantContext.applyToUrl(ApiLinks.fitnessExameLaudos)),
          headers: _headers,
          body: jsonEncode({
            'dataExame': dataExame,
            'nomeArquivo': nomeArquivo,
            'pdfBase64': pdfBase64,
            'itens': itens,
          }),
        )
        .timeout(_tempoLimite);
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw StateError(_mensagemErro(resposta.statusCode, resposta.body));
    }
  }

  /// Serie por item: cada exame com as datas, valores e cores.
  Future<List<Map<String, dynamic>>> series() async {
    final resposta = await http
        .get(Uri.parse(TenantContext.applyToUrl(ApiLinks.fitnessExameLaudosSeries)),
            headers: _headers)
        .timeout(_tempoLimite);
    if (resposta.statusCode != 200) {
      throw StateError(_mensagemErro(resposta.statusCode, resposta.body));
    }
    final lista = jsonDecode(utf8.decode(resposta.bodyBytes)) as List<dynamic>;
    return lista.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  String _mensagemErro(int status, String corpo) {
    if (status == 401 || status == 403) return 'Sua sessão expirou. Entre novamente.';
    if (status == 400) return 'O laudo não pôde ser salvo: confira o arquivo.';
    return 'Não foi possível salvar o laudo agora. Tente novamente.';
  }
}
