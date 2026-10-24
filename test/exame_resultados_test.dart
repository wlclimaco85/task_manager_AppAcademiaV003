import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/utils/exame_pdf_parser.dart';

void main() {
  group('lerResultados (laudos fora do hemograma)', () {
    // Trechos reais do painel hormonal (FSH e LH), sem dados do paciente.
    final painelHormonal = [
      'FSH - HORMÔNIO FOLÍCULO ESTIMULANTE',
      'Material: Soro',
      'Método : Quimioluminescência',
      'Resultado: Inferior a 0,11 mUI/mL',
      'Valor de Referência: Homens: 0,95 a 11,95 mUI/mL',
      'Mulheres com menstruação normal:',
      'Fase Folicular.......: 3,03 a 8,08 mUI/mL',
      'HORMÔNIO LUTEINIZANTE - LH',
      'Resultado: Inferior a 0,12 mUI/mL',
      'Valor de Referência: Homens: 0,57 a 12,07 mUI/mL',
      'Coleta: 13/05/2026 - 07:24',
    ];

    test('le FSH e LH com valor do limite, unidade, grupo Hormonal e sem faixa por sexo', () {
      final itens = ExameLaudoParser.lerResultados(painelHormonal, dataExame: '2026-05-13');

      expect(itens.map((i) => i.nome), ['FSH', 'LH']);
      expect(itens[0].valor, 0.11);
      expect(itens[0].unidade, 'mUI/mL');
      expect(itens[0].grupo, 'Hormonal');
      expect(itens[0].refMin, isNull);
      expect(itens[0].refMax, isNull);
      expect(itens[0].status, 'sem_referencia');
      expect(itens[0].dataExame, '2026-05-13');
      expect(itens[1].valor, 0.12);
    });

    test('faixa unica na linha de referencia vira refMin/refMax (exemplo sintetico)', () {
      final itens = ExameLaudoParser.lerResultados([
        'GLICOSE - GLICOSE EM JEJUM',
        'Resultado: 92 mg/dL',
        'Valor de Referência: 70 a 99 mg/dL',
      ]);

      expect(itens.length, 1);
      expect(itens.first.refMin, 70);
      expect(itens.first.refMax, 99);
      expect(itens.first.grupo, 'Glicemia');
      expect(itens.first.status, 'verde');
    });

    test('resultado sem numero (ex.: Negativo) nao gera item', () {
      final itens = ExameLaudoParser.lerResultados([
        'HIV - ANTICORPOS',
        'Resultado: Não reagente',
      ]);
      expect(itens, isEmpty);
    });
  });

  group('grupoDoAnalito', () {
    test('agrupa hormonais, lipidicos e glicemia; o resto vai para Outros', () {
      expect(ExameLaudoParser.grupoDoAnalito('TESTOSTERONA'), 'Hormonal');
      expect(ExameLaudoParser.grupoDoAnalito('HORMÔNIO TIREOESTIMULANTE'), 'Hormonal');
      expect(ExameLaudoParser.grupoDoAnalito('COLESTEROL TOTAL'), 'Lipídico');
      expect(ExameLaudoParser.grupoDoAnalito('TRIGLICERÍDEOS'), 'Lipídico');
      expect(ExameLaudoParser.grupoDoAnalito('GLICOSE'), 'Glicemia');
      expect(ExameLaudoParser.grupoDoAnalito('FERRITINA'), 'Outros');
    });
  });
}
