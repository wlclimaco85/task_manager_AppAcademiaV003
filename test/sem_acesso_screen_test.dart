import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/ui/screens/sem_acesso_screen.dart';

void main() {
  tearDown(() => AuthUtility.userInfo = LoginModel());

  testWidgets('textos da tela Sem Acesso legiveis sobre fundo claro',
      (tester) async {
    AuthUtility.userInfo = LoginModel(login: Login(nome: 'Aluno Teste'));

    await tester.pumpWidget(const MaterialApp(home: SemAcessoScreen()));

    Color corDe(String inicio) =>
        tester.widget<Text>(find.textContaining(inicio)).style!.color!;

    expect(corDe('Olá, Aluno Teste'), GridColors.textPrimary);
    expect(corDe('Você ainda não possui'), GridColors.textSecondary);
    expect(corDe('Entre em contato'), GridColors.textSecondary);
  });
}
