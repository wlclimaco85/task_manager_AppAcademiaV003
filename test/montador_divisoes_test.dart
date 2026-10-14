import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/ui/screens/fitness/montador_treino_screen.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';

void main() {
  testWidgets('adiciona remove repetidamente e salva titulo alterado', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: MontadorTreinoScreen()));
    await tester.tap(find.byTooltip('Adicionar divisão de treino'));
    await tester.pumpAndSettle();
    expect(find.text('Treino B (0)'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Adicionar divisão de treino'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Treino B (0)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remover divisão selecionada'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Adicionar divisão de treino'));
    await tester.pumpAndSettle();
    expect(find.text('Treino B (0)'), findsOneWidget);
    expect(find.text('Treino C (0)'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Título da Ficha de Treino'), 'Minha ficha renomeada');
    await tester.tap(find.byTooltip('Salvar Ficha'));
    await tester.pumpAndSettle();
    final plano = (await FitnessOfflineRepository().getPlanosTreino())
        .firstWhere((p) => p.titulo == 'Minha ficha renomeada');
    expect(plano.divisoes.map((d) => d.letra), ['A', 'C', 'B']);
    expect(tester.takeException(), isNull);
  });
}
