import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';
import 'package:task_manager_flutter/data/services/fitness_360_local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Atividades Aeróbicas por Km e Tempo', () {
    test('Calcula e armazena atividade por tempo e km sem métrica de passos', () async {
      await Fitness360LocalStore.addRecord(
        type: 'atividade',
        title: 'Futebol',
        value: '60 min (570 kcal)',
        note: 'Partida com amigos • Alta intensidade',
      );

      await Fitness360LocalStore.addRecord(
        type: 'atividade',
        title: 'Caminhada',
        value: '5.2 km (55 min • 330 kcal)',
        note: 'Caminhada matinal ao ar livre',
      );

      final records = await Fitness360LocalStore.records(type: 'atividade');
      expect(records.length, greaterThanOrEqualTo(2));
      expect(records.any((r) => r.title == 'Futebol'), isTrue);
      expect(records.any((r) => r.value.contains('5.2 km')), isTrue);

      final summary = await Fitness360LocalStore.summary();
      expect(summary.distanceKm, greaterThanOrEqualTo(5.2));
      expect(summary.activeCalories, greaterThanOrEqualTo(570));
    });

    test('defaultHomeCards não possui mais sono e batimentos cardíacos mockados', () {
      expect(Fitness360LocalStore.defaultHomeCards.contains('sleep'), isFalse);
      expect(Fitness360LocalStore.defaultHomeCards.contains('heart'), isFalse);
    });
  });

  group('Histórico de Treinos e Ficha Pré-Treino', () {
    test('SessaoTreinoRegistroModel armazena exercícios, séries e cargas reais', () {
      const sessao = SessaoTreinoRegistroModel(
        id: 'sessao-teste-1',
        treinoId: 'plano-1',
        divisaoLetra: 'A',
        divisaoNome: 'Treino A - Peito e Tríceps',
        alunoId: 'aluno-1',
        dataHoraInicio: '08/10/2026 - 18:00',
        dataHoraFim: '18:50',
        duracaoSegundos: 3000,
        rpe: 9,
        exerciciosExecutados: [
          ExercicioExecutadoRegistroModel(
            exercicioId: 'supino-1',
            exercicioNome: 'Supino Reto com Barra',
            grupoMuscular: 'Peitoral',
            series: [
              SerieRegistroModel(numero: 1, cargaRealKg: 80, repeticoesRealizadas: 12),
              SerieRegistroModel(numero: 2, cargaRealKg: 100, repeticoesRealizadas: 8),
            ],
          ),
        ],
      );

      expect(sessao.exerciciosExecutados.length, 1);
      final supino = sessao.exerciciosExecutados.first;
      expect(supino.series.length, 2);
      expect(supino.series[0].cargaRealKg, 80.0);
      expect(supino.series[1].cargaRealKg, 100.0);
    });

    test('DivisaoTreinoModel permite consultar todos os exercícios e carga planejada antes de treinar', () {
      const div = DivisaoTreinoModel(
        id: 'div-a',
        letra: 'A',
        nome: 'Peito, Ombros e Tríceps',
        exercicios: [
          ItemTreinoModel(
            id: 'item-1',
            exercicioId: 'supino',
            exercicioNome: 'Supino Reto com Barra',
            grupoMuscular: 'Peitoral Maior',
            series: 4,
            repeticoes: '8 a 12',
            cargaSugeridaKg: 80.0,
            descansoSegundos: 90,
          ),
        ],
      );

      expect(div.exercicios.length, 1);
      final item = div.exercicios.first;
      expect(item.series, 4);
      expect(item.repeticoes, '8 a 12');
      expect(item.cargaSugeridaKg, 80.0);
      expect(item.descansoSegundos, 90);
    });
  });
}
