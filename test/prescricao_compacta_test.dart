import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/models/fitness/exercicio_model.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/ui/widgets/prescricao_exercicio_inline.dart';

const principal =
    ExercicioModel(id: 'a', nome: 'Puxada', grupoMuscular: 'Costas');
const costas = ExercicioModel(id: 'b', nome: 'Remada', grupoMuscular: 'Costas');
const triceps =
    ExercicioModel(id: 'c', nome: 'Tríceps corda', grupoMuscular: 'Tríceps');
void main() {
  Future<void> montar(WidgetTester t, List<ItemTreinoModel> itens) =>
      t.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: PrescricaoExercicioInline(
                      exercicio: principal,
                      grupoAlternativas: 'Costas',
                      catalogo: const [principal, costas, triceps],
                      onAdicionar: itens.add)))));
  Future<void> tocar(WidgetTester t, Finder finder) async {
    await t.ensureVisible(finder);
    await t.pumpAndSettle();
    await t.tap(finder);
    await t.pumpAndSettle();
  }

  testWidgets('biset começa no grupo ativo e permite escolher outro grupo',
      (t) async {
    final itens = <ItemTreinoModel>[];
    await montar(t, itens);
    await tocar(t, find.text('Fazer biset'));
    final grupo = find.widgetWithText(
        DropdownButtonFormField<String>, 'Grupo muscular do biset');
    expect(t.widget<DropdownButtonFormField<String>>(grupo).initialValue,
        'Costas');
    final exercicio = find.widgetWithText(
        DropdownButtonFormField<String>, 'Exercício do biset');
    await tocar(t, exercicio);
    expect(find.text('Remada • Costas'), findsOneWidget);
    expect(find.text('Tríceps corda • Tríceps'), findsNothing);
    await tocar(t, find.text('Remada • Costas'));
    await tocar(t, grupo);
    await tocar(t, find.text('Tríceps').last);
    await tocar(t, exercicio);
    expect(find.text('Remada • Costas'), findsNothing);
    await tocar(t, find.text('Tríceps corda • Tríceps').last);
    await tocar(t, find.text('Adicionar ao treino'));
    expect(itens.single.exercicioBiset!.exercicioId, 'c');
    expect(t.takeException(), isNull);
  });
  testWidgets('alternativas só aparecem quando ligadas e não gravam escondidas',
      (t) async {
    final itens = <ItemTreinoModel>[];
    await montar(t, itens);
    expect(find.text('Alternativa 1'), findsNothing);
    final switchAlt = find.text('Se a máquina estiver ocupada');
    await tocar(t, switchAlt);
    final alt =
        find.widgetWithText(DropdownButtonFormField<String>, 'Alternativa 1');
    await tocar(t, alt);
    expect(find.text('Tríceps corda'), findsNothing);
    await tocar(t, find.text('Remada').last);
    await tocar(t, switchAlt);
    expect(find.text('Alternativa 1'), findsNothing);
    await tocar(t, find.text('Adicionar ao treino'));
    expect(itens.single.exerciciosAlternativos, isEmpty);
    await tocar(t, switchAlt);
    await tocar(t, find.text('Adicionar ao treino'));
    expect(itens.last.exerciciosAlternativos, ['Remada']);
    expect(t.takeException(), isNull);
  });
  testWidgets('botões usam o valor digitado e salvam séries carga e descanso',
      (t) async {
    final itens = <ItemTreinoModel>[];
    await montar(t, itens);
    await t.enterText(find.widgetWithText(TextFormField, 'Séries'), '5');
    await tocar(t, find.byTooltip('Aumentar Séries'));
    await t.enterText(find.widgetWithText(TextFormField, 'Carga (kg)'), '12,5');
    await tocar(t, find.byTooltip('Diminuir Carga (kg)'));
    await tocar(t, find.byTooltip('Aumentar Descanso (s)'));
    await tocar(t, find.text('Adicionar ao treino'));
    expect(itens.single.series, 6);
    expect(itens.single.cargaSugeridaKg, 11.5);
    expect(itens.single.descansoSegundos, 65);
    expect(itens.single.repeticoes, '8 a 12');
    expect(t.takeException(), isNull);
  });
  testWidgets('prescrição mantém duas colunas em celular e sem overflow',
      (t) async {
    t.view.physicalSize = const Size(360, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await montar(t, []);
    final series = find.widgetWithText(TextFormField, 'Séries');
    final reps = find.widgetWithText(TextFormField, 'Repetições');
    expect(t.getTopLeft(series).dy, t.getTopLeft(reps).dy);
    await tocar(t, find.text('Fazer biset'));
    expect(t.takeException(), isNull);
  });
}
