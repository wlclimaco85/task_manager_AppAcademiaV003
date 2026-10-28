import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/utils/api_links.dart';

/// Resultado de um passo da recuperacao de senha por codigo enviado por e-mail.
class RecuperacaoResultado {
  final bool ok;
  final String mensagem;
  const RecuperacaoResultado(this.ok, this.mensagem);
}

/// Recuperacao de senha por CODIGO de 6 digitos enviado ao e-mail do usuario:
/// 1) [solicitarCodigo] -> POST /rest/auth/recuperar-senha (resposta generica, nao revela se o e-mail existe)
/// 2) [validarCodigo]   -> POST /rest/auth/validar-codigo (o codigo vale 15 min, 5 tentativas)
/// 3) [redefinirSenha]  -> POST /rest/auth/redefinir-senha (so troca a senha se o codigo estiver certo)
class RecuperacaoSenhaService {
  RecuperacaoSenhaService._();

  static const _timeout = Duration(seconds: 30);
  static const _falhaRede = 'Não foi possível conectar. Verifique a internet e tente novamente.';

  static Future<RecuperacaoResultado> solicitarCodigo(String email) => _post(
        ApiLinks.recuperarSenha,
        {'email': email.trim()},
        'Não foi possível enviar o código. Tente novamente em instantes.',
      );

  static Future<RecuperacaoResultado> validarCodigo(String email, String codigo) => _post(
        ApiLinks.validarCodigo,
        {'email': email.trim(), 'codigo': codigo.trim()},
        'Código inválido ou expirado.',
      );

  static Future<RecuperacaoResultado> redefinirSenha(String email, String codigo, String novaSenha) => _post(
        ApiLinks.redefinirSenha,
        {'email': email.trim(), 'codigo': codigo.trim(), 'novaSenha': novaSenha},
        'Não foi possível alterar a senha. Tente novamente.',
      );

  /// Minimo de 8 caracteres, com pelo menos uma letra e um numero (mesma regra do backend).
  static bool senhaValida(String senha) =>
      senha.length >= 8 && RegExp(r'[A-Za-z]').hasMatch(senha) && RegExp(r'\d').hasMatch(senha);

  static Future<RecuperacaoResultado> _post(String url, Map<String, dynamic> corpo, String falhaPadrao) async {
    try {
      final resposta = await http
          .post(
            Uri.parse(url),
            headers: const {'Content-Type': 'application/json;charset=UTF-8'},
            body: jsonEncode(corpo),
          )
          .timeout(_timeout);
      final mensagem = _mensagemDoServidor(resposta);
      if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
        return RecuperacaoResultado(true, mensagem ?? '');
      }
      return RecuperacaoResultado(false, mensagem ?? falhaPadrao);
    } on TimeoutException {
      return const RecuperacaoResultado(false, 'Tempo esgotado. Tente novamente.');
    } catch (_) {
      return const RecuperacaoResultado(false, _falhaRede);
    }
  }

  static String? _mensagemDoServidor(http.Response resposta) {
    try {
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes, allowMalformed: true));
      if (dados is Map && dados['message'] is String) {
        return dados['message'] as String;
      }
    } catch (_) {}
    return null;
  }
}
