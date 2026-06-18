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
    expect(find.text('Participacao comunitaria desligada'), findsOneWidget);
    expect(find.byType(ReorderableListView), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Alunos'), findsOneWidget);
    expect(find.text('Treinos'), findsAtLeastNWidgets(1));
    expect(find.text('Metas'), findsAtLeastNWidgets(1));
  });
}
