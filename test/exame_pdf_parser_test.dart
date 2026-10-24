import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/utils/exame_pdf_parser.dart';

/// Pedacos de texto da pagina 1 do laudo real (posicao vertical y, horizontal x).
/// Extraidos com a mesma biblioteca do app (Syncfusion).
final _pagina1 = <({double y, double x, String texto})>[
  (y: 234, x: 36, texto: 'HEMOGRAMA'),
  (y: 287, x: 36, texto: 'Eritrograma Valores de referência'),
  (y: 304, x: 136, texto: 'Resultados'),
  (y: 316, x: 36, texto: 'Eritrócitos..: 7,60 milhões/uL De 4,30 a 5,30 milhões/uL'),
  (y: 330, x: 36, texto: 'Hemoglobina..: 16,8 g/dL De 13,5 a 17,5 g/dL'),
  (y: 344, x: 36, texto: 'Hematócrito..: 51,7 %'),
  (y: 344, x: 367, texto: 'De 38,8 a 50,0 %'),
  (y: 358, x: 36, texto: 'VCM..........: 68,0 fL'),
  (y: 358, x: 367, texto: 'De 81,2 a 98,3 fL'),
  (y: 373, x: 36, texto: 'HCM..........: 22,1 pg De 26,0 a 34,0 pg'),
  (y: 387, x: 36, texto: 'CHCM.........: 32,4 g/dL De 31,0 a 36,0 g/dL'),
  (y: 401, x: 36, texto: 'RDW..........: 18,6 %'),
  (y: 401, x: 367, texto: 'De 11,0 a 15,0 %'),
  (y: 423, x: 36, texto: 'Observações: Presença de anisocitose.'),
  (y: 457, x: 36, texto: 'Leucograma Valores de referência'),
  (y: 473, x: 142, texto: 'Resultados'),
  (y: 485, x: 36, texto: 'Leucócitos...: 5.640 /uL'),
  (y: 485, x: 367, texto: 'De 3.500 a 10.500 /uL'),
  (y: 499, x: 36, texto: 'Bastonetes...: 0,0 % 0 /uL'),
  (y: 499, x: 365, texto: 'De 0 a 840 /uL'),
  (y: 514, x: 36, texto: 'Segmentados..: 59,7 % 3.370 /uL De 1.700 a 8.000 /uL'),
  (y: 528, x: 36, texto: 'Eosinófilos..: 4,8 % 270 /uL De 0 a 500 /uL'),
  (y: 542, x: 36, texto: 'Basófilos....: 0,4 % 20 /uL'),
  (y: 542, x: 365, texto: 'De 0 a 200 /uL'),
  (y: 556, x: 36, texto: 'Linfócitos...: 28,0 % 1.580 /uL'),
  (y: 556, x: 365, texto: 'De 1.000 a 4.500 /uL'),
  (y: 593, x: 36, texto: 'Monócitos....: 7,1 % 400 /uL'),
  (y: 593, x: 365, texto: 'De 200 a 900 /uL'),
  (y: 629, x: 36, texto: 'Série Plaquetária Valores de referência'),
  (y: 646, x: 142, texto: 'Resultados'),
  (y: 658, x: 36, texto: 'Plaquetas....: 277.000 /uL De 150.000 a 450.000 /uL'),
  (y: 715, x: 36, texto: 'Coleta: 17/10/2026 - 08:34 Liberação: 17/10/2026 - 13:54'),
];

void main() {
  final linhas = ExameLaudoParser.montarLinhas(_pagina1);

  test('junta os pedacos da mesma altura em uma linha', () {
    expect(linhas.any((l) => l.contains('Hematócrito..: 51,7 %') && l.contains('De 38,8 a 50,0 %')), isTrue);
  });

  test('eritrograma: 7 itens com valor, referencia e cor certos', () {
    final itens = ExameLaudoParser.lerHemograma(linhas).where((e) => e.grupo == 'Eritrograma').toList();

    expect(itens.map((e) => e.nome).toList(),
        ['Eritrócitos', 'Hemoglobina', 'Hematócrito', 'VCM', 'HCM', 'CHCM', 'RDW']);
    expect(itens.map((e) => e.valor).toList(), [7.6, 16.8, 51.7, 68.0, 22.1, 32.4, 18.6]);
    expect(itens.map((e) => e.status).toList(), [
      'vermelho', 'verde', 'vermelho', 'amarelo', 'amarelo', 'verde', 'vermelho',
    ]);
    expect(itens.last.refMin, 11.0);
    expect(itens.last.refMax, 15.0);
    expect(itens.every((e) => e.dataExame == '2026-10-17'), isTrue);
  });

  test('leucograma: itens em /uL com a faixa da mesma linha', () {
    final itens = ExameLaudoParser.lerHemograma(linhas).where((e) => e.grupo == 'Leucograma').toList();

    expect(itens.map((e) => e.nome).toList(), [
      'Leucócitos', 'Bastonetes', 'Segmentados', 'Eosinófilos', 'Basófilos', 'Linfócitos', 'Monócitos',
    ]);
    expect(itens.map((e) => e.valor).toList(), [5640, 0, 3370, 270, 20, 1580, 400]);
    expect(itens.first.refMin, 3500);
    expect(itens.first.refMax, 10500);
    expect(itens.every((e) => e.status == 'verde'), isTrue);
  });

  test('plaquetas: 277.000 /uL dentro de 150.000-450.000 = verde', () {
    final itens = ExameLaudoParser.lerHemograma(linhas).where((e) => e.grupo == 'Plaquetas').toList();

    expect(itens.length, 1);
    expect(itens.single.valor, 277000);
    expect(itens.single.refMin, 150000);
    expect(itens.single.refMax, 450000);
    expect(itens.single.status, 'verde');
  });

  test('medica e laboratorio: convenio com laboratorio e unidade sem laboratorio', () {
    final lamel = [
      'Médico : ANA FLAVIA BOSCO SOUZA                              Atendimento : 24/10/2023 - 07:41',
      'Convênio: UNIMED EXTERNO - LABORATORIO LAMEL - RDA 120009    Qtd. de exames : 25',
    ];
    expect(ExameLaudoParser.medicoDoLaudo(lamel), 'Ana Flavia Bosco Souza');
    expect(ExameLaudoParser.laboratorioDoLaudo(lamel), 'Laboratório Lamel');

    final desterro = [
      'Médico : GEORGE HENRIQUE CALAPODOPULOS                     Atendimento : 17/10/2026 - 07:40',
      'Convênio: UNIMED EXTERNO - CNPJ NOVO - RDA 120113          Qtd. de exames : 39',
      'Unidade : NOSSA SENHORA DO DESTERRO- CNES 8469741          Página  : 1/37',
    ];
    expect(ExameLaudoParser.medicoDoLaudo(desterro), 'George Henrique Calapodopulos');
    expect(ExameLaudoParser.laboratorioDoLaudo(desterro), 'Nossa Senhora do Desterro');
  });

  test('observacao com ponto unico nao vira item', () {
    final itens = ExameLaudoParser.lerHemograma(linhas);
    expect(itens.where((e) => e.nome.contains('anisocitose')), isEmpty);
  });
}
