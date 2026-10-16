import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/exercicio_model.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
import 'package:task_manager_flutter/ui/widgets/prescricao_exercicio_inline.dart';

const principal =
    ExercicioModel(id: 'a', nome: 'Exercício A', grupoMuscular: 'Peitoral');
const parceiro =
    ExercicioModel(id: 'b', nome: 'Exercício B', grupoMuscular: 'Costas');
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'biset exige parceiro e salva duas prescrições sem virar alternativa',
      (t) async {
    final itens = <ItemTreinoModel>[];
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: PrescricaoExercicioInline(
                    exercicio: principal,
                    catalogo: const [principal, parceiro],
                    onAdicionar: itens.add)))));
    await t.tap(find.text('Fazer biset'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Adicionar ao treino'));
    await t.pumpAndSettle();
    await t.tap(find.text('Adicionar ao treino'));
    await t.pumpAndSettle();
    expect(itens, isEmpty);
    expect(find.text('Escolha o segundo exercício'), findsOneWidget);
    final grupo = find.widgetWithText(
        DropdownButtonFormField<String>, 'Grupo muscular do biset');
    await t.ensureVisible(grupo);
    await t.tap(grupo);
    await t.pumpAndSettle();
    await t.tap(find.text('Costas').last);
    await t.pumpAndSettle();
    final menu = find.byType(DropdownButtonFormField<String>).last;
    await t.ensureVisible(menu);
    await t.tap(menu);
    await t.pumpAndSettle();
    expect(find.text('Exercício A • Peitoral'), findsNothing);
    await t.tap(find.text('Exercício B • Costas').last);
    await t.pumpAndSettle();
    await t.enterText(
        find.widgetWithText(TextFormField, 'Carga do biset (kg)'), '15');
    await t.enterText(
        find.widgetWithText(TextFormField, 'Repetições do biset'), '10');
    await t.ensureVisible(find.text('Adicionar ao treino'));
    await t.pumpAndSettle();
    await t.tap(find.text('Adicionar ao treino'));
    final item = itens.single;
    expect(item.tecnica, 'Bi-set');
    expect(item.exerciciosAlternativos, isEmpty);
    expect(item.exercicioBiset!.exercicioId, 'b');
    expect(item.exercicioBiset!.series, 4);
    expect(item.exercicioBiset!.repeticoes, '10');
    expect(item.exercicioBiset!.cargaSugeridaKg, 15);
    expect(ItemTreinoModel.fromMap(item.toMap()).toMap(), item.toMap());
    expect(t.takeException(), isNull);
  });
  testWidgets('desligar biset não grava associação escondida', (t) async {
    final itens = <ItemTreinoModel>[];
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: PrescricaoExercicioInline(
                    exercicio: principal,
                    catalogo: const [principal, parceiro],
                    onAdicionar: itens.add)))));
    await t.tap(find.text('Fazer biset'));
    await t.pumpAndSettle();
    await t.tap(find.text('Fazer biset'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Adicionar ao treino'));
    await t.pumpAndSettle();
    await t.tap(find.text('Adicionar ao treino'));
    expect(itens.single.exercicioBiset, isNull);
    expect(itens.single.tecnica, 'Normal');
  });
  testWidgets('religar biset zera carga e não salva valor antigo escondido',
      (t) async {
    final itens = <ItemTreinoModel>[];
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: PrescricaoExercicioInline(
                    exercicio: principal,
                    catalogo: const [principal, parceiro],
                    onAdicionar: itens.add)))));
    await t.tap(find.text('Fazer biset'));
    await t.pumpAndSettle();
    await t.enterText(
        find.widgetWithText(TextFormField, 'Carga do biset (kg)'), '40');
    await t.ensureVisible(find.text('Fazer biset'));
    await t.pumpAndSettle();
    await t.tap(find.text('Fazer biset'));
    await t.pumpAndSettle();
    await t.tap(find.text('Fazer biset'));
    await t.pumpAndSettle();
    final carga = find.widgetWithText(TextFormField, 'Carga do biset (kg)');
    expect(t.widget<TextFormField>(carga).initialValue, '0');
    final grupo = find.widgetWithText(
        DropdownButtonFormField<String>, 'Grupo muscular do biset');
    await t.ensureVisible(grupo);
    await t.tap(grupo);
    await t.pumpAndSettle();
    await t.tap(find.text('Costas').last);
    await t.pumpAndSettle();
    final menu = find.byType(DropdownButtonFormField<String>).last;
    await t.ensureVisible(menu);
    await t.tap(menu);
    await t.pumpAndSettle();
    await t.tap(find.text('Exercício B • Costas').last);
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Adicionar ao treino'));
    await t.pumpAndSettle();
    await t.tap(find.text('Adicionar ao treino'));
    expect(itens.single.exercicioBiset!.cargaSugeridaKg, 0);
  });
  test('ficha offline preserva biset e ficha antiga segue normal', () async {
    SharedPreferences.setMockInitialValues({});
    const item = ItemTreinoModel(
        id: 'a',
        exercicioId: 'a',
        exercicioNome: 'A',
        grupoMuscular: 'Peitoral',
        tecnica: 'Bi-set',
        exercicioBiset: ItemTreinoModel(
            id: 'b',
            exercicioId: 'b',
            exercicioNome: 'B',
            grupoMuscular: 'Costas',
            cargaSugeridaKg: 15));
    const plano = PlanoTreinoModel(
        id: 'f',
        titulo: 'Ficha',
        alunoId: '1',
        alunoNome: 'Aluno',
        personalId: 'p',
        dataInicio: '2026-10-16',
        divisoes: [
          DivisaoTreinoModel(id: 'a', letra: 'A', nome: 'A', exercicios: [item])
        ]);
    final repo = FitnessOfflineRepository();
    await repo.salvarPlanoTreino(plano);
    final salvo = (await repo.getPlanosTreino()).single;
    expect(
        salvo.divisoes.single.exercicios.single.exercicioBiset!.cargaSugeridaKg,
        15);
    expect(ItemTreinoModel.fromMap({'id': 'legado'}).exercicioBiset, isNull);
  });
}
