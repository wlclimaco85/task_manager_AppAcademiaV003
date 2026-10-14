import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';
import 'package:task_manager_flutter/ui/widgets/detalhes_sessao_treino.dart';

void main() {
  testWidgets('mostra cargas reais e diferencia series nao concluidas', (tester) async {
    const sessao = SessaoTreinoRegistroModel(id: 's', treinoId: 't', divisaoLetra: 'A',
      divisaoNome: 'Peito', alunoId: 'aluno', dataHoraInicio: '2026-10-14T15:00:00',
      dataHoraFim: '2026-10-14T15:30:00', duracaoSegundos: 1800,
      feedbackAluno: 'Treino bom', exerciciosExecutados: [
        ExercicioExecutadoRegistroModel(exercicioId: 'e', exercicioNome: 'Supino',
          grupoMuscular: 'Peitoral', series: [
            SerieRegistroModel(numero: 1, cargaRealKg: 22.5, repeticoesRealizadas: 9,
              descansoUtilizadoSegundos: 60),
            SerieRegistroModel(numero: 2, cargaRealKg: 20, repeticoesRealizadas: 8, concluida: false),
          ]),
      ]);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: DetalhesSessaoTreino(sessao: sessao))));
    expect(find.text('Supino'), findsOneWidget);
    expect(find.textContaining('22.5 kg • 9 repetições • Concluída'), findsOneWidget);
    expect(find.textContaining('20.0 kg • 8 repetições • Não concluída'), findsOneWidget);
    expect(find.text('Observação: Treino bom'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
