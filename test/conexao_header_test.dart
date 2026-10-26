import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/ui/widgets/authenticated_header_shell.dart';

void main() {
  group('ehFalhaDeConexao', () {
    test('falha de transporte conta como offline', () {
      expect(ehFalhaDeConexao(http.ClientException('sem rede')), isTrue);
      expect(ehFalhaDeConexao(TimeoutException('demorou')), isTrue);
    });

    test('resposta de erro do servidor NAO conta como offline', () {
      // StateError é o que o PerfilContaService lança para 401/403/500.
      expect(ehFalhaDeConexao(StateError('Sua sessão expirou. Entre novamente.')), isFalse);
      expect(ehFalhaDeConexao(StateError('Não foi possível carregar seu perfil.')), isFalse);
    });
  });
}
