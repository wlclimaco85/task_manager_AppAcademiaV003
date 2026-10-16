import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:task_manager_flutter/data/services/importacao_dieta_parser.dart';

void main() {
  final parser = ImportacaoDietaParser();
  const header = 'refeicao;horario;alimento;quantidade_g';
  Future<ResultadoImportacaoDieta> csv(String s) =>
      parser.parse('dieta.csv', Uint8List.fromList(utf8.encode(s)));

  test('CSV BOM, português, decimal vírgula e aspas RFC4180', () async {
    final r = await csv(
        '\uFEFFRefeição;Horário;Alimento;Quantidade (g);calorias_100g;proteinas_100g;carboidratos_100g;gorduras_100g\nCafé;8:00;"Pão; integral ""especial""\ncaseiro";80,5;200;10,2;30;5');
    expect(r.linhas.single.alimento, 'Pão; integral "especial"\ncaseiro');
    expect(r.linhas.single.quantidadeGramas, 80.5);
    expect(r.linhas.single.horario, '08:00');
    expect(r.linhas.single.proteinas, 10.2);
    expect(r.linhas.single.temMacrosCompletos, isTrue);
  });
  test('CSV latin1 e tab', () async {
    final r = await parser.parse(
        'DIETA.CSV',
        Uint8List.fromList(latin1.encode(
            'refeição\thorário\talimento\tquantidade_g\nAlmoço\t12:00\tFeijão\t100')));
    expect(r.linhas.single.alimento, 'Feijão');
    expect(r.linhas.single.calorias, isNull);
    expect(r.avisos, isNotEmpty);
  });
  test('CSV separado por vírgula preserva vírgula decimal entre aspas',
      () async {
    final r = await csv(
        'refeicao,horario,alimento,quantidade_g\nJantar,20:00,Arroz,"100,5"');
    expect(r.linhas.single.quantidadeGramas, 100.5);
  });
  test('rejeita estrutura, unidade, macros ambíguos e números inválidos',
      () async {
    for (final s in [
      'alimento;quantidade_g\nArroz;100',
      '$header\nCafé;25:00;Ovo;100',
      '$header\nCafé;08:00;Ovo;0',
      '$header\nCafé;08:00;Ovo;1 colher',
      '$header\nCafé;08:00;Ovo;NaN',
      '$header\nCafé;08:00;Ovo;-3',
      '$header;calorias\nCafé;08:00;Ovo;100;50',
      '$header\nCafé;08:00;"Ovo;100',
      '$header\nCafé;08:00;"Ovo"extra;100',
      '$header\nCafé;08:00;Ovo;100;200',
    ]) {
      await expectLater(csv(s), throwsFormatException, reason: s);
    }
  });
  test('rejeita tipos, vazio, limite de bytes e linhas', () async {
    await expectLater(
        parser.parse('a.csv', Uint8List(0)), throwsFormatException);
    await expectLater(
        parser.parse('a.xls', Uint8List.fromList([1])), throwsFormatException);
    await expectLater(
        parser.parse('a.csv', Uint8List(ImportacaoDietaParser.limiteBytes + 1)),
        throwsFormatException);
    await expectLater(
        csv('$header\n${List.filled(501, 'Café;08:00;Ovo;100').join('\n')}'),
        throwsFormatException);
  });
  test('Excel real mantém quantidades e nutrientes por100g', () async {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];
    sheet.appendRow(
        ['refeicao', 'horario', 'alimento', 'quantidade_g', 'proteinas_100g']);
    sheet.appendRow(['Almoço', '12:00', 'Arroz', 125.5, 2.3]);
    final result =
        await parser.parse('dieta.xlsx', Uint8List.fromList(excel.encode()!));
    expect(result.linhas.single.quantidadeGramas, 125.5);
    expect(result.linhas.single.proteinas, 2.3);
    expect(result.linhas.single.calorias, isNull);
  });
  test('Excel com célula numérica de hora normaliza somente segundos 00',
      () async {
    Future<Uint8List> planilhaHora(double hora) async {
      final excel = Excel.createExcel();
      final sheet = excel[excel.getDefaultSheet()!];
      sheet.appendRow(['refeicao', 'horario', 'alimento', 'quantidade_g']);
      sheet.appendRow(['Café', hora, 'Ovo', 100]);
      final zip = ZipDecoder().decodeBytes(excel.encode()!);
      final arquivo = Archive();
      for (final item in zip.files) {
        var bytes = item.content as List<int>;
        if (item.name == 'xl/styles.xml') {
          final xml =
              utf8.decode(bytes).replaceAll('numFmtId="0"', 'numFmtId="21"');
          bytes = utf8.encode(xml);
        }
        if (item.name.startsWith('xl/worksheets/sheet') &&
            item.name.endsWith('.xml')) {
          final xml =
              utf8.decode(bytes).replaceFirst('<c r="B2"', '<c s="0" r="B2"');
          bytes = utf8.encode(xml);
        }
        arquivo.addFile(ArchiveFile(item.name, bytes.length, bytes));
      }
      return Uint8List.fromList(ZipEncoder().encode(arquivo)!);
    }

    final bytes = await planilhaHora(8 / 24);
    expect(
        Excel.decodeBytes(bytes)
            .tables
            .values
            .first
            .rows[1][1]!
            .value
            .toString(),
        '08:00:00');
    final r = await parser.parse('hora.xlsx', bytes);
    expect(r.linhas.single.horario, '08:00');
    await expectLater(
        parser.parse('hora.xlsx', await planilhaHora((8 * 3600 + 30) / 86400)),
        throwsFormatException);
    await expectLater(
        csv('$header\nCafé;08:00:01;Ovo;100'), throwsFormatException);
    await expectLater(csv('$header\nCafé;08:00:00;Ovo;100'), completes);
  });
  Future<Uint8List> pdf(String? text, {int paginas = 1}) async {
    final doc = PdfDocument();
    for (var i = 0; i < paginas; i++) {
      final page = doc.pages.add();
      if (text != null) {
        page.graphics.drawString(
            text, PdfStandardFont(PdfFontFamily.helvetica, 10),
            bounds: const Rect.fromLTWH(0, 0, 500, 700));
      }
    }
    final bytes = Uint8List.fromList(await doc.save());
    doc.dispose();
    return bytes;
  }

  test('PDF real com texto tabular selecionável', () async {
    final result = await parser.parse(
        'dieta.pdf', await pdf('$header\nAlmoco;12:00;Arroz;100'));
    expect(result.linhas.single.alimento, 'Arroz');
    expect(result.linhas.single.quantidadeGramas, 100);
  });
  test('PDF sem texto, não estruturado, corrompido e páginas excessivas',
      () async {
    await expectLater(
        parser.parse('a.pdf', await pdf(null)), throwsFormatException);
    await expectLater(
        parser.parse('a.pdf', await pdf('Plano alimentar sem tabela')),
        throwsFormatException);
    await expectLater(parser.parse('a.pdf', Uint8List.fromList([1, 2, 3])),
        throwsFormatException);
    await expectLater(parser.parse('a.pdf', await pdf(null, paginas: 51)),
        throwsFormatException);
    await expectLater(parser.parse('a.xlsx', Uint8List.fromList([1, 2, 3])),
        throwsFormatException);
  });
}
