import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
import 'package:task_manager_flutter/ui/screens/fitness/montador_treino_screen.dart';

void main() {
  testWidgets('arrastar preserva campos e permite reordenar nos dois sentidos',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final itens = List.generate(3, (i) => ItemTreinoModel(
      id: 'item_$i', exercicioId: 'ex_$i', exercicioNome: 'Exercicio $i',
      grupoMuscular: 'Costas', repeticoes: '${10 + i}',
      cargaSugeridaKg: 20.0 + i, series: 3 + i,
    ));
    final plano = PlanoTreinoModel(
      id: 'teste', alunoId: 'aluno', alunoNome: 'Aluno', personalId: 'personal',
      titulo: 'Ficha teste', dataInicio: '2026-10-14',
      divisoes: [DivisaoTreinoModel(id: 'a', letra: 'A', nome: 'A', exercicios: itens)],
    );
    await tester.pumpWidget(MaterialApp(home: MontadorTreinoScreen(planoParaEditar: plano)));
    await tester.pumpAndSettle();
    final antes = tester.getTopLeft(find.text('Exercicio 1')).dy;
    await tester.drag(find.byType(ReorderableDragStartListener).first, const Offset(0, 170));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Exercicio 0')).dy,
        greaterThan(tester.getTopLeft(find.text('Exercicio 1')).dy));
    expect(tester.getTopLeft(find.text('Exercicio 1')).dy, lessThan(antes));
    final card = find.ancestor(of: find.text('Exercicio 0'), matching: find.byType(Card));
    final campos = tester.widgetList<TextFormField>(find.descendant(of: card, matching: find.byType(TextFormField))).toList();
    expect(campos.map((c) => c.initialValue), ['10', '20']);
    await tester.drag(find.byType(ReorderableDragStartListener).at(1), const Offset(0, -170));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Exercicio 0')).dy,
        lessThan(tester.getTopLeft(find.text('Exercicio 1')).dy));
    expect(plano.divisoes.single.exercicios.map((e) => e.id), ['item_0', 'item_1', 'item_2']);
    await tester.drag(find.byType(ReorderableDragStartListener).first, const Offset(0, 170));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Salvar Ficha'));
    await tester.pumpAndSettle();
    final salvo = (await FitnessOfflineRepository().getPlanosTreino())
        .singleWhere((p) => p.id == 'teste');
    expect(salvo.divisoes.single.exercicios.map((e) => e.id),
        ['item_1', 'item_0', 'item_2']);
    expect(salvo.divisoes.single.exercicios[1].toMap(), itens[0].toMap());
    expect(tester.takeException(), isNull);
  });
}
