import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/utils/exame_pdf_parser.dart';

/// Trecho real do eritrograma do laudo (layout do laboratorio: valor na linha anterior ao nome).
const _eritrograma = [
  'Eritrograma        Resultados                          Valores de referencia',
  '                          7,60 milhões/uL',
  'Eritrócitos..:            16,8 g/dL                    De 4,30 a 5,30 milhões/uL',
  'Hemoglobina..:            51,7 %                       De 13,5 a 17,5 g/dL',
  'Hematócrito..:            68,0 fL                      De 38,8 a 50,0 %',
  'VCM..........:            22,1 pg                      De 81,2 a 98,3 fL',
  'HCM..........:            32,4 g/dL                    De 26,0 a 34,0 pg',
  'CHCM.........:            18,6 %                       De 31,0 a 36,0 g/dL',
  'RDW..........:                                         De 11,0 a 15,0 %',
  '                    Presenca de anisocitose.',
];

void main() {
  test('le os 7 itens do eritrograma com valor, referencia e cor certos', () {
    final itens = ExameLaudoParser.lerSecao(_eritrograma);

    expect(itens.map((e) => e.nome).toList(), [
      'Eritrócitos', 'Hemoglobina', 'Hematócrito', 'VCM', 'HCM', 'CHCM', 'RDW',
    ]);
    expect(itens.map((e) => e.valor).toList(), [7.6, 16.8, 51.7, 68.0, 22.1, 32.4, 18.6]);
    expect(itens.map((e) => e.status).toList(), [
      'vermelho', // 7,60 acima de 5,30
      'verde',    // 16,8 dentro de 13,5-17,5
      'vermelho', // 51,7 acima de 50,0
      'amarelo',  // 68,0 abaixo de 81,2
      'amarelo',  // 22,1 abaixo de 26,0
      'verde',    // 32,4 dentro de 31,0-36,0
      'vermelho', // 18,6 acima de 15,0 (exemplo do usuario)
    ]);
  });

  test('frase de observacao com ponto unico nao vira item', () {
    final itens = ExameLaudoParser.lerSecao(_eritrograma);
    expect(itens.where((e) => e.nome.contains('anisocitose')), isEmpty);
  });
}
