import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/ui/widgets/fitness_menu_page.dart';

void main() {
  testWidgets('Voltar retorna da tela do Mais para a tela anterior', (tester) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(navigatorKey: nav,
      home: const Scaffold(body: Text('Inicio'))));
    nav.currentState!.push(MaterialPageRoute(builder: (_) => const FitnessMenuPage(
      child: Scaffold(backgroundColor: Colors.black, body: Text('Personal')))));
    await tester.pumpAndSettle();
    expect(find.text('Voltar'), findsOneWidget);
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Personal'), findsNothing);
  });
}
