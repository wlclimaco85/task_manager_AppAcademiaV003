import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/ui/widgets/authenticated_header_shell.dart';

void main() {
  testWidgets('identidade permanece nas rotas e desaparece ao deslogar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final antes = AuthUtility.userInfo;
    addTearDown(() => AuthUtility.userInfo = antes);
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(navigatorKey: nav,
      builder: (_, child) => AuthenticatedHeaderShell(child: child!,
        onSair: () { AuthUtility.clearUserInfo(); }),
      home: const Scaffold(body: Text('Inicio'))));
    expect(find.text('Sair'), findsNothing);
    await AuthUtility.setUserInfo(LoginModel(token: 'token_teste',
      login: Login(nome: 'Washington Luis', tipoLogin: LoginEnum.APP_ALUNO)));
    await tester.pumpAndSettle();
    expect(find.text('Washington Luis'), findsOneWidget);
    nav.currentState!.push(MaterialPageRoute(builder: (_) =>
      const Scaffold(body: Text('Treinos'))));
    await tester.pumpAndSettle();
    expect(find.text('Washington Luis'), findsOneWidget);
    expect(find.text('Treinos'), findsOneWidget);
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(find.text('Washington Luis'), findsNothing);
    expect(AuthUtility.userInfo.token, isNull);
    expect((await SharedPreferences.getInstance()).containsKey('user_data'), isFalse);
    expect(tester.takeException(), isNull);
  });
}
