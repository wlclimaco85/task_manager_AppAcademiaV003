import 'package:task_manager_flutter/data/models/fitness/graficos_fitness_dados.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';
import 'package:task_manager_flutter/data/services/fitness_360_local_store.dart';

/// Exclusivo para capturas/testes. Não importado pelo aplicativo nem salvo em API.
class DadosDemoEuAtleta {
  final DateTime hoje;
  DadosDemoEuAtleta(this.hoje);

  List<SessaoTreinoRegistroModel> get sessoes => [
    for (var i = 0; i < 28; i++)
      if (i % 7 != 2 && i % 7 != 5 && i % 7 != 6)
        SessaoTreinoRegistroModel(
          id: 'demo_sessao_$i', treinoId: 'demo_ficha', alunoId: 'demo_apresentacao',
          divisaoLetra: ['A', 'B', 'C'][i % 3],
          divisaoNome: ['Peito e tríceps', 'Costas e bíceps', 'Pernas completo'][i % 3],
          dataHoraInicio: hoje.subtract(Duration(days: 27 - i)).toIso8601String(),
          dataHoraFim: hoje.subtract(Duration(days: 27 - i)).add(Duration(minutes: 38 + i % 12)).toIso8601String(),
          duracaoSegundos: (38 + i % 12) * 60, rpe: 7 + i % 3,
          feedbackAluno: i % 3 == 0 ? 'Movimento controlado e boa execução.' : 'Treino concluído. Cargas registradas.',
          sincronizado: true,
          exerciciosExecutados: [
            for (var e = 0; e < 4; e++)
              ExercicioExecutadoRegistroModel(
                exercicioId: 'demo_ex_$e',
                exercicioNome: ['Supino reto com barra', 'Remada baixa no triângulo', 'Agachamento livre', 'Desenvolvimento com halteres'][e],
                grupoMuscular: ['Peitoral', 'Costas', 'Quadríceps', 'Ombros'][e],
                series: [for (var s = 0; s < 3 + i % 2; s++)
                  SerieRegistroModel(numero: s + 1,
                    cargaRealKg: 20.0 + e * 5 + (i ~/ 4) * 2.5,
                    repeticoesRealizadas: 8 + (s + i) % 5)],
              ),
          ],
        ),
  ];

  List<Fitness360Record> get medidas => [
    for (var i = 0; i < 28; i += 3)
      Fitness360Record(id: 100 + i, type: 'corpo', title: 'Peso',
        value: '${(84.2 - i * 0.08 + (i % 4) * 0.05).toStringAsFixed(1)} kg',
        note: 'Dado de demonstração', createdAt: hoje.subtract(Duration(days: 27 - i))),
  ];

  GraficosFitnessDados get graficos => GraficosFitnessDados(
    sessoes: sessoes, registros: [
      ...medidas,
      for (var i = 0; i < 28; i += 2) ...[
        Fitness360Record(id: 200 + i, type: 'atividade', title: 'Caminhada',
          value: '${(2.5 + (i % 5) * 0.6).toStringAsFixed(1)} km',
          note: 'Demonstração', createdAt: hoje.subtract(Duration(days: 27 - i))),
        Fitness360Record(id: 300 + i, type: 'batimento', title: 'Repouso',
          value: '${65 + i % 8} bpm', note: 'Demonstração',
          createdAt: hoje.subtract(Duration(days: 27 - i))),
      ],
    ], diario: [
      for (var i = 0; i < 28; i++)
        {'data': hoje.subtract(Duration(days: 27 - i)).toIso8601String(),
          'sonoMinutos': 410 + i % 7 * 12, 'passos': 5800 + i % 9 * 580},
    ]);

  PlanoTreinoModel get plano => PlanoTreinoModel(
    id: 'demo_ficha', alunoId: 'demo_apresentacao', alunoNome: 'Conta de demonstração',
    personalId: '', titulo: 'Evolução • força e constância', objetivo: 'Condicionamento',
    dataInicio: hoje.subtract(const Duration(days: 27)).toIso8601String().split('T').first,
    divisoes: [for (var d = 0; d < 3; d++)
      DivisaoTreinoModel(id: 'demo_div_$d', letra: ['A', 'B', 'C'][d],
        nome: ['Peito e tríceps', 'Costas e bíceps', 'Pernas completo'][d],
        exercicios: [for (var e = 0; e < 4; e++)
          ItemTreinoModel(id: 'demo_item_${d}_$e', exercicioId: 'demo_ex_$e',
            exercicioNome: ['Supino reto com barra', 'Remada baixa no triângulo', 'Agachamento livre', 'Desenvolvimento com halteres'][e],
            grupoMuscular: ['Peitoral', 'Costas', 'Quadríceps', 'Ombros'][e],
            cargaSugeridaKg: 25 + e * 5.0,
            observacoes: 'Execução controlada. Respeite seu ritmo.')]),
    ],
  );
}
