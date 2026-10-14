import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/models/saude_diaria_model.dart';
import 'package:task_manager_flutter/data/services/fitness_360_local_store.dart';

void main() {
  // Resposta real de GET /api/fitness/resumo para a aluna com peso no cadastro.
  Map<String, dynamic> resumo({Object? pesoKg, Object? pesoMetaKg}) => {
        'data': '2026-10-14',
        'passos': 0,
        'distanciaKm': 0.0,
        'caloriasAtivas': 0,
        'treinoMinutos': 0,
        'batimentos': null,
        'sonoMinutos': 0,
        'pesoKg': pesoKg,
        'pesoMetaKg': pesoMetaKg,
        'alturaCm': null,
        'historicoSemanal': <dynamic>[],
      };

  test('Hub usa o peso real vindo da API', () {
    final summary =
        Fitness360Summary.fromApi(ResumoSaudeDiaria.fromJson(resumo(pesoKg: 62.5)));

    expect(summary.weightKg, 62.5);
    expect(summary.pesoTitulo, 'Corpo 62.5 kg');
  });

  test('sem peso nao mostra valor de demonstracao', () {
    final summary = Fitness360Summary.fromApi(ResumoSaudeDiaria.fromJson(resumo()));

    expect(summary.weightKg, isNull);
    expect(summary.pesoTitulo, 'Corpo sem registro');
    expect(summary.metaPesoTexto, 'Meta não definida');
  });

  test('meta de peso real aparece quando informada', () {
    final summary = Fitness360Summary.fromApi(
        ResumoSaudeDiaria.fromJson(resumo(pesoKg: 70, pesoMetaKg: 65)));

    expect(summary.metaPesoTexto, 'Meta 65.0 kg');
  });
}
