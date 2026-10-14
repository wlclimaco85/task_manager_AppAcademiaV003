import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/ui/screens/personal_workspace_screen.dart';
import 'package:task_manager_flutter/ui/screens/sem_acesso_screen.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/models/role_model.dart';
import 'package:task_manager_flutter/data/utils/fitness_access.dart';

void main() {
  testWidgets('aluno nao abre workspace nem alunos de demonstracao', (tester) async {
    final anterior = AuthUtility.userInfo;
    addTearDown(() => AuthUtility.userInfo = anterior);
    AuthUtility.userInfo = LoginModel(login: Login(tipoLogin: LoginEnum.APP_ALUNO));
    await tester.pumpWidget(const MaterialApp(home: PersonalWorkspaceScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(SemAcessoScreen), findsOneWidget);
    expect(find.text('Lucas Mendonça'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  test('aluno nao gerencia alunos mesmo com role personal herdada', () {
    expect(podeGerenciarAlunos(LoginModel(login: Login(
      tipoLogin: LoginEnum.APP_ALUNO,
      roles: [Role(key: 'ROLE_PERSONAL')],
    ))), isFalse);
  });
  test('personal gerencia alunos por tipo ou role', () {
    expect(podeGerenciarAlunos(LoginModel(login: Login(
      tipoLogin: LoginEnum.APP_PERSONAL,
    ))), isTrue);
    expect(podeGerenciarAlunos(LoginModel(login: Login(
      roles: [Role(key: 'ROLE_PERSONAL')],
    ))), isTrue);
    expect(podeGerenciarAlunos(LoginModel()), isFalse);
  });
}
