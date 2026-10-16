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
    expect(find.text('Concluir seleção (1)'), findsOneWidget);
    expect(itens.single.observacoes, 'Movimento controlado');
    expect(itens.single.exerciciosAlternativos,
      ['Supino Inclinado com Halteres', 'Supino Declinado com Barra']);
    expect(ItemTreinoModel.fromMap(itens.single.toMap()).toMap(), itens.single.toMap());
    expect(find.text('Observação para o aluno'), findsNothing);
    expect(itens.single.series, 4);
    expect(itens.single.repeticoes, '8 a 12');
    await tester.tap(find.text('Supino Inclinado com Halteres').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar ao treino'));
    await tester.pumpAndSettle();
    expect(itens.length, 2);
    expect(find.text('Concluir seleção (2)'), findsOneWidget);
    expect(find.byType(BibliotecaExerciciosScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('mostra ficha e inclusoes e limita alternativas ao filtro muscular', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final catalogo = await tester.runAsync(() => FitnessOfflineRepository().getExercicios());
    final rosca = catalogo!.firstWhere((e) => e.nome == 'Rosca Direta com Barra W');
    final outra = catalogo.firstWhere((e) => e.nome == 'Rosca Alternada com Halteres');
    tester.view.physicalSize = const Size(500, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final adicionados = <ItemTreinoModel>[];
    await tester.pumpWidget(MaterialApp(home: BibliotecaExerciciosScreen(
      modoSelecao: true, tituloFicha: 'Ficha real', divisaoDestino: 'Treino B',
      exerciciosNaFicha: {rosca.id: ['Treino B'], outra.id: ['Treino A']},
      exerciciosNaDivisao: {rosca.id}, onPrescrever: adicionados.add)));
    await tester.pumpAndSettle();
    expect(find.text('Ficha: Ficha real\nDestino: Treino B'), findsOneWidget);
    await tester.tap(find.text('Bíceps'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Na ficha • Treino B'), findsOneWidget);
    expect(find.text('Incluído'), findsOneWidget);
    await tester.tap(find.text(rosca.nome));
    await tester.pumpAndSettle();
    expect(find.text('Adicionar ao treino'), findsNothing);
    await tester.tap(find.text(outra.nome));
    await tester.pumpAndSettle();
    final menus = tester.widgetList<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>)).toList();
    // Abre o menu real: peito/costas não podem aparecer no filtro de bíceps.
    expect(menus.length, 2);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    expect(find.text('Supino Reto com Barra'), findsNothing);
    expect(find.text('Puxada Frontal na Polia'), findsNothing);
    expect(find.text('Rosca Martelo').last, findsOneWidget);
    await tester.tap(find.text('Rosca Martelo').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Adicionar ao treino'));
    await tester.tap(find.text('Adicionar ao treino'));
    await tester.pumpAndSettle();
    expect(adicionados.single.exerciciosAlternativos, ['Rosca Martelo']);
    await tester.drag(find.byType(ListView).first, const Offset(0, 1200));
    await tester.pumpAndSettle();
    expect(find.text('Incluído'), findsNWidgets(2));
    expect(find.textContaining('Na ficha • Treino A, Treino B'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('ficha antiga sem alternativas continua compativel', () {
    expect(ItemTreinoModel.fromMap({'id': 'antigo'}).exerciciosAlternativos, isEmpty);
  });
}
