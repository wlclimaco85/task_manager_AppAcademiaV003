import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/ui/screens/fitness_personal_screens.dart';
import 'package:task_manager_flutter/data/services/nutricao_farmaco_offline_repository.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/ui/widgets/nutricao_editores.dart';
import 'package:task_manager_flutter/ui/widgets/personal_aluno_sheet.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthUtility.userInfo = LoginModel();
  });
  for (final tipo in ['suplemento', 'dieta', 'aluno']) {
    testWidgets('Esc fecha $tipo com campo focado sem desmontagem invalida',
        (t) async {
      await t.pumpWidget(MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () {
                        if (tipo == 'aluno') {
                          showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => const PersonalAlunoSheet());
                        } else {
                          showDialog(
                              context: context,
                              builder: (_) => tipo == 'suplemento'
                                  ? const SuplementoEditor()
                                  : const DietaEditor());
                        }
                      },
                      child: const Text('Abrir'))))));
      await t.tap(find.text('Abrir'));
      await t.pumpAndSettle();
      if (tipo == 'aluno') {
        await t.tap(find.text('Não, cadastrar aluno'));
        await t.pumpAndSettle();
      }
      await t.tap(find.byType(TextFormField).first);
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.byType(tipo == 'aluno' ? PersonalAlunoSheet : AlertDialog),
          findsNothing);
    });
  }
  testWidgets('Esc fecha dropdown, refeicao e dieta em sequencia', (t) async {
    await t.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showDialog(
                        context: context, builder: (_) => const DietaEditor()),
                    child: const Text('Abrir'))))));
    await t.tap(find.text('Abrir'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Adicionar refeição'));
    await t.tap(find.text('Adicionar refeição'));
    await t.pumpAndSettle();
    await t.tap(find.byType(DropdownButtonFormField<String>));
    await t.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }
  });
  testWidgets('Esc repetido enquanto menu do suplemento fecha', (t) async {
    await t.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const SuplementoEditor()),
                    child: const Text('Abrir'))))));
    await t.tap(find.text('Abrir'));
    await t.pumpAndSettle();
    await t.tap(find.byType(DropdownButtonFormField<String>).last);
    await t.pumpAndSettle();
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
  testWidgets('Esc no registro de altura preserva dependencias ate fechar',
      (t) async {
    t.view.physicalSize = const Size(1000, 1500);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await http.runWithClient(() async {
      await t.pumpWidget(const MaterialApp(home: CorpoScreen()));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Informar altura'));
      await t.tap(find.text('Informar altura'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, '180');
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }, () => MockClient((_) async => http.Response('[]', 200)));
  });
  testWidgets('Esc fecha alimento focado e depois refeicao e dieta', (t) async {
    t.view.physicalSize = const Size(1000, 1500);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.runAsync(() => NutricaoFarmacoOfflineRepository().getAlimentos());
    await t.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showDialog(
                        context: context, builder: (_) => const DietaEditor()),
                    child: const Text('Abrir'))))));
    await t.tap(find.text('Abrir'));
    await t.pumpAndSettle();
    await t.tap(find.text('Adicionar refeição'));
    await t.pumpAndSettle();
    await t.tap(find.text('Adicionar alimento'));
    await t.pumpAndSettle();
    await t.enterText(
        find.widgetWithText(TextField, 'Buscar alimento'), 'arroz');
    await t.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNWidgets(3));
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNWidgets(2));
    for (var i = 0; i < 2; i++) {
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }
    expect(find.byType(AlertDialog), findsNothing);
  });
}
