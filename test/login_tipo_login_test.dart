import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/utils/security_matrix.dart';

void main() {
  group('Login.fromJson tipoLogin', () {
    test('aceita nome do enum enviado pelo backend (@JsonValue)', () {
      final login = Login.fromJson({'id': 1, 'tipoLogin': 'APP_ALUNO'});
      expect(login.tipoLogin, LoginEnum.APP_ALUNO);
    });

    test('aceita value inteiro salvo na sessao local', () {
      final login = Login.fromJson({'id': 1, 'tipoLogin': 4});
      expect(login.tipoLogin, LoginEnum.APP_ALUNO);
    });

    test('aceita value como string numerica', () {
      final login = Login.fromJson({'id': 1, 'tipoLogin': '1'});
      expect(login.tipoLogin, LoginEnum.APP_PERSONAL);
    });

    test('valor invalido ou ausente cai no padrao APP_ABRACO', () {
      expect(Login.fromJson({'id': 1, 'tipoLogin': 'XYZ'}).tipoLogin,
          LoginEnum.APP_ABRACO);
      expect(Login.fromJson({'id': 1}).tipoLogin, LoginEnum.APP_ABRACO);
    });
  });

  test('aluno recem-cadastrado (sem aplicativo) acessa o hub fitness', () {
    // Payload real do POST /rest/auth/login para autocadastro de aluno.
    final model = LoginModel.fromJson({
      'status': 'success',
      'token': 't',
      'login': {
        'id': 997,
        'nome': 'washington luis',
        'tipoLogin': 'APP_ALUNO',
        'roles': [
          {'id': 144, 'description': 'ALUNO', 'available': true, 'key': 'ROLE_ALUNO'}
        ],
      },
      'permissoes': [],
    });

    final sec = SecurityMatrix.of(model);
    expect(sec.canView(AppScreen.fitness), isTrue);
    expect(sec.canView(AppScreen.treinos), isTrue);
  });
}
