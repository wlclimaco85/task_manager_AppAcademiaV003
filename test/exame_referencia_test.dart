import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/utils/exame_pdf_parser.dart';

void main() {
  test('faixa unica do laudo vira referencia min e max', () {
    final itens = ExameLaudoParser.lerResultados([
      'PCR',
      'Material: Soro',
      'Resultado:   7,50 mg/L',
      'Valor de Referência:  5,00 a 10,00 mg/L',
    ]);
    expect(itens, hasLength(1));
    expect(itens.single.refMin, 5.0);
    expect(itens.single.refMax, 10.0);
  });

  test('limite "Inferior a X" vira faixa de 0 ate X', () {
    final itens = ExameLaudoParser.lerResultados([
      'ALANINA AMINO TRANSFERASE - TGP',
      'Material: Soro',
      'Resultado:   25 U/L',
      'Valor de Referência:  Inferior a 45 U/L',
    ]);
    expect(itens.single.refMin, 0.0);
    expect(itens.single.refMax, 45.0);
  });

  test('bloco com varias faixas (sexo ou fase do ciclo) fica sem referencia', () {
    final itens = ExameLaudoParser.lerResultados([
      'FSH - HORMÔNIO FOLÍCULO ESTIMULANTE',
      'Resultado:   1,47 mUI/mL',
      'Valor de Referência: Homens: 0,95 a 11,95 mUI/mL',
      'Fase Folicular.......: 3,03 a 8,08 mUI/mL',
      'Fase lútea...........: 1,38 a 5,47 mUI/mL',
    ]);
    expect(itens.single.refMin, isNull);
    expect(itens.single.refMax, isNull);
  });
}
