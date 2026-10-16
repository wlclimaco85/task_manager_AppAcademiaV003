import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

void main() {
  test('login e cadastro respeitam o mesmo backend local ou explicito', () {
    const backend = String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'http://127.0.0.1:9001',
    );
    const contextPath = String.fromEnvironment(
      'BACKEND_CONTEXT_PATH',
      defaultValue: '/boletobancos',
    );
    final resolvedBackend = backend.isEmpty ? 'http://127.0.0.1:9001' : backend;
    final base = '$resolvedBackend$contextPath';

    expect(ApiLinks.baseUrl, base);
    expect(ApiLinks.login, '$base/rest/auth/login');
    expect(ApiLinks.registrarAluno, '$base/rest/auth/registrar-aluno');
    expect(ApiLinks.registrarPersonal, '$base/rest/auth/registrar-personal');
    expect(ApiLinks.academiasDisponiveis, '$base/rest/auth/academias-disponiveis');
    expect(ApiLinks.personaisDisponiveis, '$base/rest/auth/personais-disponiveis');
    for (final endpoint in [
      ApiLinks.login, ApiLinks.registrarAluno, ApiLinks.registrarPersonal,
      ApiLinks.academiasDisponiveis, ApiLinks.personaisDisponiveis,
    ]) {
      final uri = Uri.parse(endpoint);
      expect(uri.host, isNotEmpty, reason: endpoint);
      expect(uri.scheme, anyOf('http', 'https'));
    }
  });

  test('chat respeita o websocket local ou explicito', () {
    const websocket = String.fromEnvironment(
      'WS_BACKEND_URL',
      defaultValue: 'ws://127.0.0.1:9001/boletobancos',
    );
    expect(ApiLinks.chatStart('10', '20'),
        '${websocket.isEmpty ? 'ws://127.0.0.1:9001/boletobancos' : websocket}/ws-chat?user=10&sector=20');
  });
}
