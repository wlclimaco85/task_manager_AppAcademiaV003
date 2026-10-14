import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/ui/widgets/compartilhar_treino_sheet.dart';

void main() {
  testWidgets('compartilhamento opcional mostra foto e permite sair sem publicar', (tester) async {
    var fechou = false;
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CompartilharTreinoSheet(
      treino: 'Treino A', minutos: 30, series: 8, rpe: 7, tonelagemKg: 500,
      onFechar: () => fechou = true))));
    expect(find.text('Adicionar foto'), findsOneWidget);
    expect(find.text('Tirar foto'), findsOneWidget);
    expect(find.text('Compartilhar foto do treino'), findsOneWidget);
    expect(find.text('500 kg de volume total'), findsOneWidget);
    expect(find.text('Android: https://play.google.com/store/apps'), findsOneWidget);
    expect(find.text('iPhone: https://apps.apple.com/br/'), findsOneWidget);
    await tester.tap(find.text('Agora não / Fechar'));
    expect(fechou, isTrue);
    expect(tester.takeException(), isNull);
  });
}
