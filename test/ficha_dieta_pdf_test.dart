import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/models/fitness/exercicio_model.dart';
import 'package:task_manager_flutter/data/models/fitness/nutricao_farmaco_model.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/data/services/pdf/ficha_dieta_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('formatacao', () {
    test('series e repeticoes', () {
      expect(FichaDietaPdf.seriesReps(4, '10-12'), '4 × 10-12');
      expect(FichaDietaPdf.seriesReps(3, 'Falha'), '3 × até a falha');
    });

    test('descanso e carga', () {
      expect(FichaDietaPdf.descanso(60), '60 s');
      expect(FichaDietaPdf.descanso(90), '1 min 30 s');
      expect(FichaDietaPdf.descanso(120), '2 min');
      expect(FichaDietaPdf.descanso(0), '—');
      expect(FichaDietaPdf.carga(20), '20 kg');
      expect(FichaDietaPdf.carga(12.5), '12,5 kg');
      expect(FichaDietaPdf.dec(3.8, 1), '3,8');
      expect(FichaDietaPdf.objetivoDieta('recomposicao'), 'Recomposição corporal');
      expect(FichaDietaPdf.carga(0), '—');
    });

    test('medida caseira vem da descricao do catalogo', () {
      expect(
          FichaDietaPdf.medidaCaseira(
              'Porção caseira: 1 escumadeira cheia (≈ 90 g).\nDestaque nutricional: x'),
          '1 escumadeira cheia (≈ 90 g)');
      expect(FichaDietaPdf.medidaCaseira(null), isNull);
    });

    test('percentual da meta e datas', () {
      expect(FichaDietaPdf.percentualMeta(1800, 2000), 90);
      expect(FichaDietaPdf.percentualMeta(100, 0), 0);
      expect(FichaDietaPdf.data('2026-10-14'), '14/10/2026');
    });
  });

  // Captura avisos do pacote pdf (ex.: glifo inexistente na fonte).
  Future<List<String>> capturarAvisos(Future<void> Function() acao) async {
    final avisos = <String>[];
    await runZoned(acao, zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => avisos.add(line),
    ));
    return avisos;
  }

  test('ficha de treino gera PDF valido sem glifos faltando', () async {
    const plano = PlanoTreinoModel(
      id: 'p1',
      alunoId: 'a1',
      alunoNome: 'Ana Aluna',
      personalId: 'pe1',
      titulo: 'Hipertrofia ABC',
      objetivo: 'Hipertrofia',
      dataInicio: '2026-10-14',
      dataValidade: '2026-12-14',
      divisoes: [
        DivisaoTreinoModel(id: 'd1', letra: 'A', nome: 'Peito e Tríceps', exercicios: [
          ItemTreinoModel(
            id: 'i1',
            exercicioId: 'ex_supino_reto',
            exercicioNome: 'Supino Reto com Barra',
            grupoMuscular: 'Peitoral',
            series: 4,
            repeticoes: '10-12',
            cargaSugeridaKg: 20,
            descansoSegundos: 90,
            tecnica: 'Drop-set',
            exerciciosAlternativos: ['Supino na Máquina'],
            videoUrl: 'https://youtu.be/pCPyqW60Wuk',
          ),
          ItemTreinoModel(
            id: 'i2',
            exercicioId: 'ex_triceps_corda',
            exercicioNome: 'Tríceps na Polia com Corda',
            grupoMuscular: 'Tríceps',
            series: 3,
            repeticoes: 'Falha',
            cargaSugeridaKg: 0,
            descansoSegundos: 60,
            tecnica: 'Normal',
          ),
        ]),
      ],
    );
    const catalogo = {
      'ex_supino_reto': ExercicioModel(
        id: 'ex_supino_reto',
        nome: 'Supino Reto com Barra',
        grupoMuscular: 'Peitoral',
        equipamento: 'Barra',
        nivel: 1,
        descricao: '1. Deite no banco.\n2. Feche as escápulas.\n3. Desça a barra até o peito.',
        errosComuns: 'Descolar a lombar do banco.',
      ),
    };

    late List<int> bytes;
    final avisos = await capturarAvisos(() async {
      bytes = await FichaDietaPdf.fichaTreino(plano, catalogo: catalogo, emissao: DateTime(2026, 10, 14));
    });

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(avisos.where((a) => a.toLowerCase().contains('font')), isEmpty, reason: avisos.join('\n'));
    Directory('build/pdf_teste').createSync(recursive: true);
    File('build/pdf_teste/ficha_treino.pdf').writeAsBytesSync(bytes);
  });

  test('dieta gera PDF valido com medida caseira', () async {
    const dieta = DietaProtocoloModel(
      id: 'd1',
      alunoId: 'a1',
      titulo: 'Recomposição 2000 kcal',
      objetivo: 'recomposicao',
      caloriasMeta: 2000,
      proteinasMeta: 150,
      carboidratosMeta: 200,
      gordurasMeta: 60,
      dataInicio: '2026-10-14',
      observacoes: 'Evitar frituras.',
      refeicoes: [
        RefeicaoModel(id: 'r1', nome: 'Almoço', horario: '12:30', itens: [
          ItemRefeicaoModel(alimentoId: 'alim_1', alimentoNome: 'Arroz Branco Cozido',
              quantidadeGramas: 150, calorias: 192, proteinas: 3.8, carboidratos: 42.2, gorduras: 0.3),
          ItemRefeicaoModel(alimentoId: 'alim_9', alimentoNome: 'Peito de Frango Grelhado',
              quantidadeGramas: 120, calorias: 191, proteinas: 38.4, carboidratos: 0, gorduras: 3,
              observacao: 'Temperar com ervas'),
        ]),
      ],
    );
    const alimentos = {
      'alim_1': AlimentoModel(id: 'alim_1', nome: 'Arroz Branco Cozido', categoria: 'carboidratos',
          calorias: 128, proteinas: 2.5, carboidratos: 28.1, gorduras: 0.2,
          descricao: 'Porção caseira: 1 escumadeira cheia (≈ 90 g).\nDestaque nutricional: x'),
    };

    late List<int> bytes;
    final avisos = await capturarAvisos(() async {
      bytes = await FichaDietaPdf.dieta(dieta, alunoNome: 'Ana Aluna', alimentos: alimentos,
          emissao: DateTime(2026, 10, 14));
    });

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(avisos.where((a) => a.toLowerCase().contains('font')), isEmpty, reason: avisos.join('\n'));
    File('build/pdf_teste/dieta.pdf').writeAsBytesSync(bytes);
  });
}
