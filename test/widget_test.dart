import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/aplicativo_model.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/models/role_model.dart';
import 'package:task_manager_flutter/ui/screens/bottom_navbar_screen.dart';

void main() {
  tearDown(() {
    AuthUtility.userInfo = LoginModel();
  });

  testWidgets('Hub Fitness renderiza textos principais do MVP',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    AuthUtility.userInfo = LoginModel(
      token: 'token-test',
      login: Login(
        tipoLogin: LoginEnum.APP_ACADEMIA,
        aplicativo: Aplicativo(nome: 'App Academia'),
        roles: [Role(key: 'ROLE_ACADEMIA')],
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: BottomNavBarScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hub Fitness'), findsOneWidget);
    expect(find.text('Resumo do aluno, treinos e evolucao'), findsOneWidget);
    expect(find.text('Saude do aluno hoje'), findsOneWidget);
    // A lista e preguicosa: a secao comunitaria fica fora da tela ate rolar.
    await tester.scrollUntilVisible(
      find.text('Participacao comunitaria desligada'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Participacao comunitaria desligada'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    // Menu Alunos e exclusivo do personal: login de academia nao o ve.
    expect(find.text('Alunos'), findsNothing);
    expect(find.text('Treinos'), findsAtLeastNWidgets(1));
    // Metas depende de permissao do perfil (SecurityMatrix): nao e verificado neste smoke test.
  });
}
