import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/models/fitness/graficos_fitness_dados.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';
import 'package:task_manager_flutter/data/services/fitness_360_local_store.dart';
import 'package:task_manager_flutter/ui/widgets/fitness_graficos_hub.dart';

SessaoTreinoRegistroModel treino(String id, DateTime data) =>
    SessaoTreinoRegistroModel(
        id: id,
        treinoId: 'ficha',
        divisaoLetra: 'A',
        divisaoNome: 'Peito',
        alunoId: 'aluno',
        dataHoraInicio: data.toIso8601String(),
        dataHoraFim: data.add(const Duration(minutes: 30)).toIso8601String(),
        duracaoSegundos: 1800,
        rpe: 8,
        exerciciosExecutados: const [
          ExercicioExecutadoRegistroModel(
              exercicioId: 'supino',
              exercicioNome: 'Supino',
              grupoMuscular: 'Peito',
              series: [
                SerieRegistroModel(
                    numero: 1, cargaRealKg: 20, repeticoesRealizadas: 10),
                SerieRegistroModel(
                    numero: 2,
                    cargaRealKg: 100,
                    repeticoesRealizadas: 10,
                    concluida: false)
              ]),
        ]);
void main() {
  test(
      'graficos usam somente registros do periodo e series concluidas, sem duplicar sessoes',
      () {
    final hoje = DateTime(2026, 10, 14, 18);
    final sessao = treino('s1', hoje.subtract(const Duration(hours: 1)));
    final dados = GraficosFitnessDados(sessoes: [
      sessao,
      sessao,
      treino('antigo', DateTime(2026, 1, 1))
    ], registros: [
      Fitness360Record(
          id: 1,
          type: 'corpo',
          title: 'Peso',
          value: '100,5 kg',
          note: '',
          createdAt: hoje)
    ], diario: [
      {'data': '2026-10-14', 'pesoKg': 100}
    ]);
    final series = dados.series(dias: 7, agora: hoje, exercicioId: 'supino');
    SerieFitness porTitulo(String titulo) =>
        series.singleWhere((s) => s.titulo == titulo);
    expect(porTitulo('Evolução de Peso').pontos.single.valor, 100.5);
    expect(
        porTitulo('Quantidade de treinos')
            .pontos
            .fold<double>(0, (v, p) => v + p.valor),
        1);
    expect(porTitulo('Volume realizado').pontos.single.valor, 200);
    expect(porTitulo('Séries concluídas').pontos.single.valor, 1);
    expect(porTitulo('Repetições realizadas').pontos.single.valor, 10);
    expect(porTitulo('Carga do exercício').pontos.single.valor, 20);
    expect(porTitulo('Duração dos treinos').pontos.single.valor, 30);
  });
  test('conta vazia nao recebe pontos inventados', () {
    const dados = GraficosFitnessDados(sessoes: [], registros: []);
    expect(
        dados
            .series(dias: 30, agora: DateTime.now())
            .every((s) => s.pontos.isEmpty),
        isTrue);
  });
  testWidgets('hub renderiza graficos com um unico registro sem erro',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dados = GraficosFitnessDados(sessoes: [
      treino('s', DateTime.now().subtract(const Duration(hours: 1)))
    ], registros: [
      Fitness360Record(
          id: 1,
          type: 'corpo',
          title: 'Peso',
          value: '100 kg',
          note: '',
          createdAt: DateTime.now())
    ]);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ListView(
                children: [FitnessGraficosHub(dados: Future.value(dados))]))));
    await tester.pumpAndSettle();
    expect(find.text('Minha evolução'), findsOneWidget);
    expect(find.text('Quantidade de treinos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
