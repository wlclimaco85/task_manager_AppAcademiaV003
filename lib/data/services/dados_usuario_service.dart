import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

/// Cadastro de dados pessoais (dadospessoais) do usuario logado.
///
/// O backend regrava a entidade inteira no PUT. Por isso o corpo do envio parte
/// do cadastro atual e so troca os campos que o usuario editou.
class DadosUsuarioService {
  DadosUsuarioService._();

  static const List<String> camposEditaveis = [
    'nome',
    'email',
    'telefone1',
    'telefone2',
    'cep',
    'logradouro',
    'numero',
    'bairro',
    'cidade',
    'estado',
    'pais',
  ];

  /// Busca o cadastro atual. Devolve null se a rede falhar ou o registro nao existir.
  static Future<Map<String, dynamic>?> buscar(int id) async {
    try {
      final resposta =
          await NetworkCaller().getRequest(ApiLinks.dadosPessoaisPorId('$id'));
      if (!resposta.isSuccess) {
        AppLogger.i.warn(
            '[DadosUsuario] Busca do cadastro $id falhou (status ${resposta.statusCode}).');
        return null;
      }
      return extrairDados(resposta.body);
    } catch (e) {
      AppLogger.i.warn('[DadosUsuario] Erro ao buscar cadastro $id: $e');
      return null;
    }
  }

  /// Envia o cadastro. Devolve true somente com resposta de sucesso do servidor.
  static Future<bool> salvar(int id, Map<String, dynamic> corpo) async {
    try {
      final resposta = await NetworkCaller()
          .putRequest(ApiLinks.atualizarDadosPessoais('$id'), corpo);
      if (!resposta.isSuccess) {
        AppLogger.i.warn(
            '[DadosUsuario] Salvar cadastro $id recusado (status ${resposta.statusCode}).');
      }
      return resposta.isSuccess;
    } catch (e) {
      AppLogger.i.warn('[DadosUsuario] Erro ao salvar cadastro $id: $e');
      return false;
    }
  }

  /// Extrai o primeiro registro de `{"data": {"dados": [ {...} ]}}`.
  @visibleForTesting
  static Map<String, dynamic>? extrairDados(dynamic body) {
    final corpo = body is String ? jsonDecode(body) : body;
    final data = corpo is Map ? corpo['data'] : null;
    final dados = data is Map ? data['dados'] : null;
    if (dados is List && dados.isNotEmpty && dados.first is Map) {
      return Map<String, dynamic>.from(dados.first as Map);
    }
    return null;
  }

  /// Copia o cadastro atual e aplica so os campos editados.
  /// Campos fora de [camposEditaveis] (ex.: CPF, id) nunca mudam aqui.
  static Map<String, dynamic> montarCorpo(
    Map<String, dynamic> atual,
    Map<String, String> edicao, {
    String? fotoDataUri,
  }) {
    final corpo = Map<String, dynamic>.from(atual);
    for (final campo in camposEditaveis) {
      final valor = edicao[campo];
      if (valor != null) corpo[campo] = valor.trim();
    }
    if (fotoDataUri != null) corpo['photo'] = fotoDataUri;
    return corpo;
  }
}
