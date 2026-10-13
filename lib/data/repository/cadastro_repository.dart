import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

/// Repositório de cadastro de novos usuários (pré-login).
///
/// Usa [http] diretamente em vez de [NetworkCaller] porque o cadastro
/// ocorre antes do login (sem token de autenticação) e o
/// `NetworkCaller.postRequest` injeta automaticamente campos de
/// contexto (empresa/aplicativo/audit) que não fazem sentido aqui e
/// que o endpoint `registrar-aluno` não está na lista de exceções.
class CadastroRepository {
  Map<String, dynamic> _interpretarCadastro(http.Response response) {
    final sucessoHttp = response.statusCode >= 200 && response.statusCode < 300;
    Map<String, dynamic>? dados;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) dados = decoded;
    } on FormatException {
      // Respostas vazias ou HTML nao confirmam a criacao de uma conta.
    }
    final erroServidor = dados?['error'];
    final confirmado = sucessoHttp &&
        (erroServidor == null || erroServidor == false) &&
        dados?['id'] != null &&
        dados?['loginId'] != null;
    final contexto = 'Cadastro ${response.request?.url}: HTTP ${response.statusCode}';
    if (confirmado) {
      AppLogger.i.info('$contexto confirmado');
      return {...dados!, 'error': false};
    }
    AppLogger.i.warn('$contexto nao confirmado');
    return {
      ...?dados,
      'error': true,
      'message': dados?['message']?.toString() ??
          'Nao foi possivel confirmar o cadastro (HTTP ${response.statusCode}). Tente novamente.',
    };
  }

  /// Registra um novo aluno. Retorna o JSON decodificado da resposta,
  /// tanto em caso de sucesso (201) quanto de erro (400/409/500).
  Future<Map<String, dynamic>> registrarAluno(
      Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse(ApiLinks.registrarAluno),
        headers: {'Content-Type': 'application/json;charset=UTF-8'},
        body: jsonEncode(body),
      );

      return _interpretarCadastro(response);
    } catch (e) {
      AppLogger.i.warn('Falha na requisicao de cadastro de aluno: ${ApiLinks.registrarAluno}');
      return {
        'error': true,
        'message': 'Não foi possível conectar ao servidor: $e',
      };
    }
  }

  /// Lista os personais disponíveis para escolha durante o cadastro.
  Future<List<Map<String, dynamic>>> listarPersonaisDisponiveis() async {
    final response = await http.get(
      Uri.parse(ApiLinks.personaisDisponiveis),
      headers: {'Content-Type': 'application/json;charset=UTF-8'},
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Falha ao buscar personais disponíveis (${response.statusCode})');
    }

    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json.cast<Map<String, dynamic>>();
  }

  /// Registra um novo personal trainer. Retorna o JSON decodificado da
  /// resposta, tanto em caso de sucesso (201) quanto de erro (400/409/500).
  Future<Map<String, dynamic>> registrarPersonal(
      Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse(ApiLinks.registrarPersonal),
        headers: {'Content-Type': 'application/json;charset=UTF-8'},
        body: jsonEncode(body),
      );

      return _interpretarCadastro(response);
    } catch (e) {
      AppLogger.i.warn('Falha na requisicao de cadastro de personal: ${ApiLinks.registrarPersonal}');
      return {
        'error': true,
        'message': 'Não foi possível conectar ao servidor: $e',
      };
    }
  }

  /// Lista as academias disponíveis para o personal escolher durante o
  /// cadastro.
  Future<List<Map<String, dynamic>>> listarAcademiasDisponiveis() async {
    final response = await http.get(
      Uri.parse(ApiLinks.academiasDisponiveis),
      headers: {'Content-Type': 'application/json;charset=UTF-8'},
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Falha ao buscar academias disponíveis (${response.statusCode})');
    }

    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json.cast<Map<String, dynamic>>();
  }
}
