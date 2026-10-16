import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/models/fitness/execucao_biset_treino.dart';
import 'package:task_manager_flutter/data/models/fitness/execucao_alternativas_treino.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';

void main() {
  const b = ItemTreinoModel(
      id: 'b',
      exercicioId: 'b',
      exercicioNome: 'Segundo',
      grupoMuscular: 'Costas',
      series: 2);
  const a = ItemTreinoModel(
      id: 'a',
      exercicioId: 'a',
      exercicioNome: 'Primeiro',
      grupoMuscular: 'Peito',
      series: 2,
      tecnica: 'Bi-set',
      exercicioBiset: b);
  SerieRegistroModel serie(int n, [bool feita = false]) => SerieRegistroModel(
      numero: n, cargaRealKg: 10, repeticoesRealizadas: 8, concluida: feita);

  test('alternância A1/B1/A2/B2 mantém registros e histórico separados', () {
    final biset = ExecucaoBisetTreino([a]);
    final execucao = ExecucaoAlternativasTreino(biset.exercicios);
    final registros = {
      0: [serie(1), serie(2)],
      1: [serie(1), serie(2)]
    };
    for (final passo in [
      (indice: 0, serie: 0),
      (indice: 1, serie: 0),
      (indice: 0, serie: 1),
      (indice: 1, serie: 1)
    ]) {
      expect(biset.proximaSerie(0, registros), passo);
      registros[passo.indice]![passo.serie] = serie(passo.serie + 1, true);
      execucao.marcarSerie(passo.indice, passo.serie, true);
    }
    expect(biset.proximaSerie(1, registros), isNull);
    final historico = execucao.historico(registros);
    expect(historico.map((e) => e.exercicioId), ['a', 'b']);
    expect(historico.map((e) => e.series.length), [2, 2]);
    final retomada = ExecucaoAlternativasTreino(biset.exercicios);
    expect(retomada.restaurar(execucao.toMap()), isTrue);
    expect(retomada.historico(registros).map((e) => e.exercicioId), ['a', 'b']);
  });

  test('ficha antiga mantém índices e quantidade sem inventar séries', () {
    final simples = ExecucaoBisetTreino([b]);
    expect(simples.exercicios, [b]);
    expect(simples.parceiros, isEmpty);
    expect(
        simples.proximaSerie(0, {
          0: [serie(1)]
        }),
        isNull);
    final biset = ExecucaoBisetTreino([a]);
    final registros = {
      0: [serie(1, true)],
      1: [serie(1, true), serie(2)]
    };
    expect(biset.proximaSerie(0, registros), (indice: 1, serie: 1));
    expect(registros[0]!.length, 1);
  });
}
