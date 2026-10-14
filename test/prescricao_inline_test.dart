import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/ui/screens/fitness/biblioteca_exercicios_screen.dart';

void main() {
  testWidgets('inclui varios exercicios sem sair da biblioteca', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() => FitnessOfflineRepository().getExercicios());
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final itens = <ItemTreinoModel>[];
    await tester.pumpWidget(MaterialApp(home: BibliotecaExerciciosScreen(
      modoSelecao: true, onPrescrever: itens.add)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supino Reto com Barra').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Observação para o aluno'), 'Movimento controlado');
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supino Inclinado com Halteres').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supino Declinado com Barra').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar ao treino'));
    await tester.pumpAndSettle();
    expect(find.text('Concluir (1)'), findsOneWidget);
    expect(itens.single.observacoes, 'Movimento controlado');
    expect(itens.single.exerciciosAlternativos,
      ['Supino Inclinado com Halteres', 'Supino Declinado com Barra']);
    expect(ItemTreinoModel.fromMap(itens.single.toMap()).toMap(), itens.single.toMap());
    expect(find.text('Observação para o aluno'), findsOneWidget);
    await tester.tap(find.text('Adicionar ao treino'));
    await tester.pumpAndSettle();
    expect(itens.length, 2);
    expect(find.text('Concluir (2)'), findsOneWidget);
    expect(find.byType(BibliotecaExerciciosScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('ficha antiga sem alternativas continua compativel', () {
    expect(ItemTreinoModel.fromMap({'id': 'antigo'}).exerciciosAlternativos, isEmpty);
  });
}
