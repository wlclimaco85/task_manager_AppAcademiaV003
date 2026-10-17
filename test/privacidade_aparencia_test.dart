import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/services/preferencia_tema_service.dart';
import 'package:task_manager_flutter/ui/screens/fitness/privacidade_aparencia_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferenciaTema.tema.value = TemaApp.padrao;
  });

  testWidgets('mostra as tres opcoes de tema', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PrivacidadeAparenciaScreen()));
    await tester.pump();

    expect(find.text('Aparência'), findsOneWidget);
    expect(find.byKey(const Key('tema_padrao')), findsOneWidget);
    expect(find.byKey(const Key('tema_branco')), findsOneWidget);
    expect(find.byKey(const Key('tema_preto')), findsOneWidget);
  });

  testWidgets('escolher preto troca o tema do app', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PrivacidadeAparenciaScreen()));
    await tester.pump();
    await tester.tap(find.byKey(const Key('tema_preto')));
    await tester.pump();

    expect(PreferenciaTema.tema.value, TemaApp.preto);
  });
}
