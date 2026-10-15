import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/models/fitness/execucao_alternativas_treino.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/data/models/fitness/exercicio_model.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';

void main() {
  const original = ItemTreinoModel(
      id: 'item1',
      exercicioId: 'puxada',
      exercicioNome: 'Puxada',
      grupoMuscular: 'Costas',
      series: 3,
      cargaSugeridaKg: 40,
      exerciciosAlternativos: ['Remada']);
  const alternativa = ExercicioModel(
      id: 'remada',
      nome: 'Remada',
      grupoMuscular: 'Costas',
      videoUrl: 'https://example.invalid/video');
  const serie =
      SerieRegistroModel(numero: 1, cargaRealKg: 40, repeticoesRealizadas: 10);
  test('troca preserva identidade das séries feitas e grava exercício real',
      () {
    final estado = ExecucaoAlternativasTreino([original]);
    estado.marcarSerie(0, 0, true);
    estado.selecionar(0, alternativa);
    estado.marcarSerie(0, 1, true);
    expect(estado.atual(0).videoUrl, alternativa.videoUrl);
    expect(estado.atual(0).cargaSugeridaKg, 0);
    final registros = estado.historico({
      0: [
        serie,
        const SerieRegistroModel(
            numero: 2, cargaRealKg: 20, repeticoesRealizadas: 12),
        const SerieRegistroModel(
            numero: 3,
            cargaRealKg: 0,
            repeticoesRealizadas: 12,
            concluida: false),
      ]
    });
    expect(registros.map((r) => r.exercicioId), ['puxada', 'remada']);
    expect(registros[0].series.single.cargaRealKg, 40);
    expect(registros[1].series.single.numero, 2);
    expect(registros[1].series.single.cargaRealKg, 20);
    expect(registros[1].observacaoAluno, 'Alternativa de Puxada');
    estado.selecionar(0, null);
    expect(estado.atual(0).exercicioId, 'puxada');
    expect(estado.realizados[0]![1]!.exercicioId, 'remada');
  });
  test('rascunho JSON restaura alternativa e identidade de cada série', () {
    final estado = ExecucaoAlternativasTreino([original]);
    estado.marcarSerie(0, 0, true);
    estado.selecionar(0, alternativa);
    estado.marcarSerie(0, 1, true);
    final restaurado = ExecucaoAlternativasTreino([original]);
    expect(
        restaurado.restaurar(jsonDecode(jsonEncode(estado.toMap()))), isTrue);
    expect(restaurado.atual(0).exercicioId, 'remada');
    expect(restaurado.realizados[0]![0]!.exercicioId, 'puxada');
    expect(restaurado.realizados[0]![1]!.exercicioId, 'remada');
    restaurado.marcarSerie(0, 0, false);
    expect(restaurado.realizados[0]!.containsKey(0), isFalse);
  });
  test(
      'não permite alternativa fora da ficha nem restaura prescrição diferente',
      () {
    final estado = ExecucaoAlternativasTreino([original]);
    expect(
        () => estado.selecionar(
            0,
            const ExercicioModel(
                id: 'agachamento',
                nome: 'Agachamento',
                grupoMuscular: 'Pernas')),
        throwsArgumentError);
    final outro = ExecucaoAlternativasTreino([
      const ItemTreinoModel(
          id: 'item1',
          exercicioId: 'outro',
          exercicioNome: 'Outro',
          grupoMuscular: 'Costas')
    ]);
    expect(outro.restaurar(estado.toMap()), isFalse);
  });
}
