import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/tenant_context.dart';

/// Resultado do envio: id do laudo salvo e os laudos anteriores que ele substituiu (mesmo PDF).
class LaudoEnviado {
  final int? id;
  final List<int> substituidos;

  const LaudoEnviado(this.id, this.substituidos);
}

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
  Future<LaudoEnviado> enviar({
    required String dataExame,
    required String nomeArquivo,
    required String pdfBase64,
    required List<Map<String, dynamic>> itens,
    String? medico,
    String? laboratorio,
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
            'medico': medico,
            'laboratorio': laboratorio,
          }),
        )
        .timeout(_tempoLimite);
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw StateError(_mensagemErro(resposta.statusCode, resposta.body));
    }
    final corpo = jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
    final substituidos = [for (final s in (corpo['substituidos'] as List? ?? const [])) (s as num).toInt()];
    return LaudoEnviado((corpo['id'] as num?)?.toInt(), substituidos);
  }

  /// Apaga todos os laudos desta conta no servidor. Retorna quantos foram removidos.
  Future<int> limparTodos() async {
    final resposta = await http
        .delete(Uri.parse(TenantContext.applyToUrl('${ApiLinks.fitnessExameLaudos}/todos')), headers: _headers)
        .timeout(_tempoLimite);
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw StateError(_mensagemErro(resposta.statusCode, resposta.body));
    }
    final corpo = jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
    return (corpo['removidos'] as num?)?.toInt() ?? 0;
  }

  /// Laudos do aluno no servidor (id, dataExame, medico).
  Future<List<Map<String, dynamic>>> listar() async {
    final resposta = await http
        .get(Uri.parse(TenantContext.applyToUrl(ApiLinks.fitnessExameLaudos)), headers: _headers)
        .timeout(_tempoLimite);
    if (resposta.statusCode != 200) {
      throw StateError(_mensagemErro(resposta.statusCode, resposta.body));
    }
    final lista = jsonDecode(utf8.decode(resposta.bodyBytes)) as List<dynamic>;
    return lista.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Remove o laudo no servidor. Os itens saem junto, e o grafico deixa de mostra-los.
  Future<void> excluir(int laudoId) async {
    final resposta = await http
        .delete(
          Uri.parse(TenantContext.applyToUrl('${ApiLinks.fitnessExameLaudos}/$laudoId')),
          headers: _headers,
        )
        .timeout(_tempoLimite);
    if (resposta.statusCode == 404) return; // ja nao existe no servidor
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw StateError(_mensagemErro(resposta.statusCode, resposta.body));
    }
  }

  /// Exame salvo antes do vinculo com o servidor: acha o laudo pela data e pela medica.
  /// Nulo se nao existe laudo; erro se houver mais de um candidato (nao apaga nada por palpite).
  Future<int?> localizarLaudoLegado({required String dataExame, String? medico}) async {
    final candidatos = (await listar()).where((l) =>
        l['dataExame']?.toString() == dataExame &&
        (medico == null || l['medico']?.toString() == medico)).toList();
    if (candidatos.isEmpty) return null;
    if (candidatos.length > 1) {
      throw StateError('Há mais de um laudo com esta data e médica. Exclua pelo servidor.');
    }
    return (candidatos.first['id'] as num).toInt();
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
