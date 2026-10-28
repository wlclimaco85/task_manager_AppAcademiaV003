import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/data/services/recuperacao_senha_service.dart';

http.Response _json(Map<String, dynamic> corpo, int status) => http.Response(
      jsonEncode(corpo),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  test('solicitarCodigo chama /rest/auth/recuperar-senha so com o e-mail', () async {
    late http.Request enviado;
    final cliente = MockClient((req) async {
      enviado = req;
      return _json({'message': 'ok'}, 200);
    });

    final r = await http.runWithClient(
        () => RecuperacaoSenhaService.solicitarCodigo(' atleta@exemplo.com '), () => cliente);

    expect(r.ok, isTrue);
    expect(enviado.method, 'POST');
    expect(enviado.url.path, endsWith('/rest/auth/recuperar-senha'));
    expect(jsonDecode(enviado.body), {'email': 'atleta@exemplo.com'});
  });

  test('validarCodigo e redefinirSenha enviam o contrato do backend', () async {
    final pedidos = <http.Request>[];
    final cliente = MockClient((req) async {
      pedidos.add(req);
      return req.url.path.endsWith('validar-codigo')
          ? _json({'valido': false, 'message': 'Código inválido ou expirado.'}, 400)
          : _json({'message': 'Senha alterada com sucesso.'}, 200);
    });

    final invalido = await http.runWithClient(
        () => RecuperacaoSenhaService.validarCodigo('a@x.com', ' 123456 '), () => cliente);
    final trocada = await http.runWithClient(
        () => RecuperacaoSenhaService.redefinirSenha('a@x.com', '123456', 'NovaSenha123'), () => cliente);

    expect(invalido.ok, isFalse);
    expect(invalido.mensagem, 'Código inválido ou expirado.');
    expect(jsonDecode(pedidos[0].body), {'email': 'a@x.com', 'codigo': '123456'});
    expect(trocada.ok, isTrue);
    expect(pedidos[1].url.path, endsWith('/rest/auth/redefinir-senha'));
    expect(jsonDecode(pedidos[1].body), {'email': 'a@x.com', 'codigo': '123456', 'novaSenha': 'NovaSenha123'});
  });

  test('erro de rede e resposta sem corpo viram mensagem util; senhaValida segue a regra do backend', () async {
    final semCorpo = MockClient((_) async => http.Response('', 500));
    final semRede = MockClient((_) async => throw http.ClientException('sem rede'));

    final r1 = await http.runWithClient(() => RecuperacaoSenhaService.validarCodigo('a@x.com', '111111'), () => semCorpo);
    final r2 = await http.runWithClient(() => RecuperacaoSenhaService.solicitarCodigo('a@x.com'), () => semRede);

    expect(r1.mensagem, 'Código inválido ou expirado.');
    expect(r2.mensagem, contains('conectar'));
    expect(RecuperacaoSenhaService.senhaValida('Abcdefg1'), isTrue);
    expect(RecuperacaoSenhaService.senhaValida('abcdefgh'), isFalse);
    expect(RecuperacaoSenhaService.senhaValida('Ab1'), isFalse);
  });

  test('telas de recuperacao do V003 usam o service e nao o servidor de exemplo teamrabbil', () {
    expect(File('lib/data/utils/api_links.dart').readAsStringSync(), isNot(contains('recoverVerifyEmail')));
    for (final tela in ['email_verification_screeen', 'otp_varification', 'reset_screen']) {
      final fonte = File('lib/ui/screens/auth_screens/$tela.dart').readAsStringSync();
      expect(fonte, contains('RecuperacaoSenhaService.'), reason: tela);
      expect(fonte, isNot(contains('NetworkCaller')), reason: tela);
    }
  });
}
