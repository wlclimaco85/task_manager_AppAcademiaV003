import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/data/repository/cadastro_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final repository = CadastroRepository();
  final cadastros = {
    'aluno': repository.registrarAluno,
    'personal': repository.registrarPersonal,
  };
  for (final listagem in {
    'academias-disponiveis': repository.listarAcademiasDisponiveis,
    'personais-disponiveis': repository.listarPersonaisDisponiveis,
  }.entries) {
    test('lista ${listagem.key} usando URL absoluta', () async {
      final dados = await http.runWithClient(
        listagem.value,
        () => MockClient((request) async {
          expect(request.url.host, isNotEmpty);
          expect(request.url.path, endsWith('/rest/auth/${listagem.key}'));
          return http.Response('[{"id":1,"nome":"Cadastro de teste"}]', 200);
        }),
      );
      expect(dados.single['id'], 1);
    });
  }

  for (final cadastro in cadastros.entries) {
    group(cadastro.key, () {
      for (final caso in [
        (404, '{"error":"Not Found"}'),
        (500, '{"message":"Falha ao salvar"}'),
        (400, '{"error":false,"id":1,"loginId":2}'),
        (201, ''),
        (200, '<html>Erro</html>'),
        (200, '{"error":true,"id":1,"loginId":2}'),
        (201, '{"message":"Sucesso"}'),
      ]) {
        test('nao confirma conta para HTTP ${caso.$1}: ${caso.$2}', () async {
          final result = await http.runWithClient(
            () => cadastro.value({'nome': 'Teste'}),
            () => MockClient((request) async =>
                http.Response(caso.$2, caso.$1, request: request)),
          );
          expect(result['error'], isTrue);
          expect(result['message'], isNotEmpty);
        });
      }

      test('confirma 201 com identificadores do contrato real', () async {
        final result = await http.runWithClient(
          () => cadastro.value({'nome': 'Teste'}),
          () => MockClient((request) async => http.Response(
              jsonEncode({'id': 1, 'loginId': 2, 'message': 'Cadastro realizado'}),
              201,
              request: request)),
        );
        expect(result['error'], isFalse);
        expect(result['loginId'], 2);
      });
    });
  }
}
