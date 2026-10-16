import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
import 'package:task_manager_flutter/ui/screens/fitness/biblioteca_exercicios_screen.dart';
import 'package:task_manager_flutter/ui/screens/fitness/montador_treino_screen.dart';

void main() {
  testWidgets('remover atualiza contagem, permite reincluir e abre detalhes no celular', (t) async {
    SharedPreferences.setMockInitialValues({});
    final catalogo = await t.runAsync(() => FitnessOfflineRepository().getExercicios());
    final ex = catalogo!.first;
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final removidos = <String>[];
    final adicionados = <ItemTreinoModel>[];
    await t.pumpWidget(MaterialApp(home: BibliotecaExerciciosScreen(
      modoSelecao: true, tituloFicha: 'Ficha', divisaoDestino: 'Treino A',
      exerciciosNaDivisao: {ex.id},
      exerciciosNaFicha: {ex.id: ['Treino A', 'Treino B']},
      onPrescrever: adicionados.add, onRemover: removidos.add,
    )));
    await t.pumpAndSettle();
    final concluir = find.widgetWithText(FilledButton, 'Concluir seleção (1)');
    expect(t.getSize(concluir).height, greaterThanOrEqualTo(52));
    expect(t.getBottomRight(concluir).dy, lessThanOrEqualTo(844));
    expect(find.byType(FloatingActionButton), findsNothing);
    await t.tap(find.text('Descrição e vídeo').first);
    await t.pumpAndSettle();
    expect(find.text('Execução Biomecânica:'), findsOneWidget);
    expect(find.text('Assistir demonstração'), findsOneWidget);
    await t.ensureVisible(find.text('Fechar Detalhes'));
    await t.tap(find.text('Fechar Detalhes'));
    await t.pumpAndSettle();
    await t.tap(find.text('Remover').first);
    await t.pumpAndSettle();
    expect(removidos, [ex.id]);
    expect(find.text('Concluir seleção (0)'), findsOneWidget);
    expect(find.textContaining('Na ficha • Treino B'), findsOneWidget);
    await t.tap(find.text(ex.nome).first);
    await t.pumpAndSettle();
    await t.drag(find.byType(ListView).first, const Offset(0, -650));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Adicionar ao treino'));
    await t.pumpAndSettle();
    await t.tap(find.text('Adicionar ao treino'));
    await t.pumpAndSettle();
    expect(adicionados.single.series, 4);
    expect(adicionados.single.repeticoes, '8 a 12');
    expect(find.text('Adicionar ao treino'), findsNothing);
    expect(find.text('Concluir seleção (1)'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('remoção na biblioteca é salva apenas na divisão de destino', (t) async {
    SharedPreferences.setMockInitialValues({});
    final catalogo = await t.runAsync(() => FitnessOfflineRepository().getExercicios());
    final ex = catalogo!.first;
    final item = ItemTreinoModel(id: 'item', exercicioId: ex.id,
      exercicioNome: ex.nome, grupoMuscular: ex.grupoMuscular);
    final plano = PlanoTreinoModel(id: 'ficha', titulo: 'Ficha', alunoId: 'aluno',
      alunoNome: 'Aluno', personalId: 'p', dataInicio: '2026-10-16',
      divisoes: [
        DivisaoTreinoModel(id: 'a', letra: 'A', nome: 'A', exercicios: [item]),
        DivisaoTreinoModel(id: 'b', letra: 'B', nome: 'B', exercicios: [item]),
      ]);
    t.view.physicalSize = const Size(600, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(home: MontadorTreinoScreen(planoParaEditar: plano)));
    await t.pumpAndSettle();
    await t.tap(find.text('Adicionar Exercício no Treino A'));
    await t.pumpAndSettle();
    await t.tap(find.text('Remover').first);
    await t.pumpAndSettle();
    await t.tap(find.text('Concluir seleção (0)'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Salvar Ficha'));
    await t.pumpAndSettle();
    final salvo = (await FitnessOfflineRepository().getPlanosTreino()).singleWhere((p) => p.id == 'ficha');
    expect(salvo.divisoes.first.exercicios, isEmpty);
    expect(salvo.divisoes.last.exercicios.single.exercicioId, ex.id);
    expect(t.takeException(), isNull);
  });
}
