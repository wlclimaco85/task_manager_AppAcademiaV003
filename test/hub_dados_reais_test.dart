import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/models/hidratacao_model.dart';
import 'package:task_manager_flutter/data/models/saude_diaria_model.dart';
import 'package:task_manager_flutter/data/services/fitness_360_local_store.dart';

void main() {
  // Formato real de GET /api/fitness/resumo.
  ResumoSaudeDiaria resumo({
    int passos = 0,
    int treino = 0,
    int sono = 0,
    double km = 0,
    int kcal = 0,
    int? bpm,
    double? peso,
    int? altura,
    List<Map<String, dynamic>> historico = const [],
  }) =>
      ResumoSaudeDiaria.fromJson({
        'data': '2026-10-14',
        'passos': passos,
        'distanciaKm': km,
        'caloriasAtivas': kcal,
        'treinoMinutos': treino,
        'batimentos': bpm,
        'sonoMinutos': sono,
        'pesoKg': peso,
        'pesoMetaKg': null,
        'alturaCm': altura,
        'historicoSemanal': historico,
      });

  test('usa distancia e calorias reais da API (sem formula)', () {
    final s = Fitness360Summary.fromApi(resumo(km: 3.2, kcal: 410, treino: 45));

    expect(s.distanceKm, 3.2);
    expect(s.activeCalories, 410);
    expect(s.trainingMinutes, 45);
  });

  test('aluno sem registros nao recebe numeros de demonstracao', () {
    final s = Fitness360Summary.fromApi(resumo());

    expect(s.distanceKm, 0);
    expect(s.activeCalories, 0);
    expect(s.heartRate, isNull);
    expect(s.habitsDone, 0);
    expect(s.activeDaysWeek, 0);
    expect(s.sonoTitulo, 'Sono sem registro');
    expect(s.cardioTitulo, 'Cardio sem registro');
    expect(s.imcTexto, 'IMC sem altura');
  });

  test('habitos do dia contam treino, passos, sono, agua e check-in', () {
    final s = Fitness360Summary.fromApi(
      resumo(passos: 5000, treino: 30, sono: 420),
      hidratacaoMetaAtingida: true,
      checkinFeito: true,
    );

    expect(s.habitsDone, 5);
    expect(s.habitsTotal, 5);
  });

  test('dias ativos vem do historico semanal sem duplicar hoje', () {
    final s = Fitness360Summary.fromApi(resumo(passos: 100, historico: [
      {'data': '2026-10-12', 'passos': 3000, 'treinoMinutos': 0, 'sonoMinutos': 0},
      {'data': '2026-10-13', 'passos': 0, 'treinoMinutos': 0, 'sonoMinutos': 400},
      {'data': '2026-10-14', 'passos': 100, 'treinoMinutos': 0, 'sonoMinutos': 0},
    ]));

    expect(s.activeDaysWeek, 2);
    expect(s.diasAtivosTexto, '2/7 dias ativos');
    expect(s.weeklyProgress, closeTo(2 / 7, 0.001));
  });

  test('cardio, sono e IMC reais quando ha dados', () {
    final s = Fitness360Summary.fromApi(
        resumo(bpm: 64, sono: 450, peso: 62.5, altura: 165));

    expect(s.cardioTitulo, 'Cardio 64 bpm');
    expect(s.sonoTitulo, 'Sono 7h 30m');
    expect(s.sonoSubtitulo, '93% da meta de 8h');
    expect(s.imcTexto, 'IMC 23.0');
  });

  test('meta de hidratacao atingida so com meta configurada', () {
    expect(hidratacaoMetaAtingida(null), isFalse);
    expect(hidratacaoMetaAtingida(const ResumoHidratacao(totalMl: 2000)), isFalse);
    expect(
        hidratacaoMetaAtingida(
            const ResumoHidratacao(totalMl: 1500, metaDiariaMl: 2000)),
        isFalse);
    expect(
        hidratacaoMetaAtingida(
            const ResumoHidratacao(totalMl: 2100, metaDiariaMl: 2000)),
        isTrue);
  });
}
