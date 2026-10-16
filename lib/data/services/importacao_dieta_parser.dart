import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class LinhaImportacaoDieta {
  final int numeroLinha;
  final String refeicao, horario, alimento;
  final double quantidadeGramas;

  /// Valores explicitamente informados por 100 g; nunca estimados.
  final double? calorias, proteinas, carboidratos, gorduras, fibras;
  final List<String> avisos;

  const LinhaImportacaoDieta(
      {required this.numeroLinha,
      required this.refeicao,
      required this.horario,
      required this.alimento,
      required this.quantidadeGramas,
      this.calorias,
      this.proteinas,
      this.carboidratos,
      this.gorduras,
      this.fibras,
      this.avisos = const []});
  bool get temMacrosCompletos =>
      calorias != null &&
      proteinas != null &&
      carboidratos != null &&
      gorduras != null;
  bool get macrosInformados =>
      calorias != null ||
      proteinas != null ||
      carboidratos != null ||
      gorduras != null ||
      fibras != null;
}

class ResultadoImportacaoDieta {
  final List<LinhaImportacaoDieta> linhas;
  final List<String> avisos;
  const ResultadoImportacaoDieta(this.linhas, this.avisos);
}

/// Importa somente tabelas explícitas: não faz OCR nem inventa nutrientes.
class ImportacaoDietaParser {
  static const limiteBytes = 10 * 1024 * 1024;
  static const limiteLinhas = 500;
  static const limitePaginas = 50;
  static const _obrigatorias = [
    'refeicao',
    'horario',
    'alimento',
    'quantidade_g'
  ];

  Future<ResultadoImportacaoDieta> parse(
      String nomeArquivo, Uint8List bytes) async {
    if (bytes.isEmpty) throw const FormatException('O arquivo está vazio.');
    if (bytes.length > limiteBytes) {
      throw const FormatException('O arquivo deve ter no máximo 10 MB.');
    }
    final extensao = nomeArquivo.toLowerCase().split('.').last;
    List<List<String>> tabela;
    try {
      switch (extensao) {
        case 'csv':
          String texto;
          try {
            texto = utf8.decode(bytes);
          } on FormatException {
            texto = latin1.decode(bytes);
          }
          tabela = _texto(texto);
          break;
        case 'xlsx':
          final arquivo = Excel.decodeBytes(bytes);
          final candidatas = arquivo.tables.values
              .where((s) => s.rows.any((r) =>
                  r.any((v) => v?.value.toString().trim().isNotEmpty == true)))
              .toList();
          if (candidatas.length != 1) {
            throw const FormatException(
                'Use uma única aba preenchida na planilha.');
          }
          tabela = candidatas.single.rows
              .map((r) => r.map((v) => v?.value.toString() ?? '').toList())
              .toList();
          break;
        case 'pdf':
          final documento = PdfDocument(inputBytes: bytes);
          try {
            if (documento.pages.count > limitePaginas) {
              throw const FormatException(
                  'O PDF deve ter no máximo 50 páginas.');
            }
            final texto = PdfTextExtractor(documento).extractText();
            if (texto.trim().isEmpty) {
              throw const FormatException(
                  'PDF sem texto selecionável. PDFs escaneados não são aceitos; exporte uma tabela CSV ou Excel.');
            }
            tabela = _texto(texto, pdf: true);
          } finally {
            documento.dispose();
          }
          break;
        default:
          throw const FormatException(
              'Formato não suportado. Escolha Excel (.xlsx), CSV ou PDF com texto selecionável.');
      }
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException(
          'Não foi possível ler o arquivo. Verifique se está íntegro e no formato indicado.');
    }
    return _validar(tabela);
  }

  List<List<String>> _texto(String texto, {bool pdf = false}) {
    texto = texto
        .replaceFirst('\uFEFF', '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    final primeira = texto
        .split('\n')
        .firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    if (primeira.isEmpty) return [];
    // O cabeçalho define o separador; vírgulas decimais nas linhas não interferem.
    var separador = ';';
    if (primeira.contains('\t')) {
      separador = '\t';
    } else if (!primeira.contains(';') && primeira.contains(',')) {
      separador = ',';
    } else if (pdf && !primeira.contains(';')) {
      final linhas = texto
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .map((l) => l.trim().split(RegExp(r'\s{2,}')))
          .toList();
      if (linhas.first.length < 4) {
        throw const FormatException(
            'PDF sem tabela reconhecível. Use o modelo com colunas refeicao;horario;alimento;quantidade_g, ou importe CSV/Excel.');
      }
      return linhas;
    }
    return _csv(texto, separador);
  }

  List<List<String>> _csv(String texto, String separador) {
    final linhas = <List<String>>[];
    var linha = <String>[];
    var campo = StringBuffer();
    var aspas = false;
    var fechouAspas = false;
    for (var i = 0; i < texto.length; i++) {
      final c = texto[i];
      if (aspas) {
        if (c == '"') {
          if (i + 1 < texto.length && texto[i + 1] == '"') {
            campo.write('"');
            i++;
          } else {
            aspas = false;
            fechouAspas = true;
          }
        } else {
          campo.write(c);
        }
      } else if (c == separador || c == '\n') {
        linha.add(campo.toString());
        campo = StringBuffer();
        fechouAspas = false;
        if (c == '\n') {
          linhas.add(linha);
          linha = [];
        }
      } else if (c == '"' && campo.isEmpty && !fechouAspas) {
        aspas = true;
      } else {
        if (c == '"' || (fechouAspas && c.trim().isNotEmpty)) {
          throw const FormatException(
              'CSV com aspas inválidas. Exporte novamente usando o modelo.');
        }
        if (!fechouAspas) campo.write(c);
      }
    }
    if (aspas) {
      throw const FormatException('CSV com campo entre aspas não fechado.');
    }
    linha.add(campo.toString());
    linhas.add(linha);
    return linhas;
  }

  ResultadoImportacaoDieta _validar(List<List<String>> tabela) {
    tabela = tabela.where((r) => r.any((c) => c.trim().isNotEmpty)).toList();
    if (tabela.length < 2) {
      throw const FormatException(
          'O arquivo precisa de cabeçalho e pelo menos um alimento.');
    }
    if (tabela.length - 1 > limiteLinhas) {
      throw const FormatException(
          'Importe no máximo 500 alimentos por arquivo.');
    }
    final cabecalho = tabela.first.map(_coluna).toList();
    for (final nome in _obrigatorias) {
      if (!cabecalho.contains(nome)) {
        throw FormatException(
            'Coluna obrigatória ausente: $nome. Use o modelo de importação.');
      }
    }
    final conhecidas = cabecalho
        .where((c) => _obrigatorias.contains(c) || c.endsWith('_100g'))
        .toList();
    if (conhecidas.toSet().length != conhecidas.length) {
      throw const FormatException('Há colunas repetidas no cabeçalho.');
    }
    final avisos = <String>[];
    if (cabecalho.any((c) => [
          'calorias',
          'proteinas',
          'carboidratos',
          'gorduras',
          'fibras'
        ].contains(c))) {
      throw const FormatException(
          'Informe nutrientes com base explícita por 100 g: calorias_100g, proteinas_100g, carboidratos_100g, gorduras_100g e fibras_100g. Valores por porção não serão interpretados como valores por 100 g.');
    }
    final resultado = <LinhaImportacaoDieta>[];
    for (var i = 1; i < tabela.length; i++) {
      final r = tabela[i];
      final numero = i + 1;
      if (r.length > cabecalho.length &&
          r.skip(cabecalho.length).any((c) => c.trim().isNotEmpty)) {
        throw FormatException(
            'Linha $numero: há mais valores que colunas. Confira o separador e as aspas.');
      }
      String valor(String c) {
        final p = cabecalho.indexOf(c);
        return p < 0 || p >= r.length ? '' : r[p].trim();
      }

      for (final c in _obrigatorias) {
        if (valor(c).isEmpty) {
          throw FormatException('Linha $numero: preencha $c.');
        }
      }
      var horario = valor('horario');
      // Excel pode retornar uma célula de hora como HH:mm:ss. Aceitamos
      // somente segundos zerados, preservando a precisão do modelo HH:mm.
      if (RegExp(r'^([01]?\d|2[0-3]):[0-5]\d:00$').hasMatch(horario)) {
        horario = horario.substring(0, horario.length - 3);
      }
      if (!RegExp(r'^([01]?\d|2[0-3]):[0-5]\d$').hasMatch(horario)) {
        throw FormatException(
            'Linha $numero: horário inválido. Use HH:mm (ex.: 08:00); segundos, se presentes, devem ser 00.');
      }
      double? numeroValor(String c, {bool obrigatorio = false}) {
        var v = valor(c);
        if (v.isEmpty && !obrigatorio) return null;
        // Sem unidades, milhares ou conversões ambíguas.
        if (!RegExp(r'^\d+(?:[.,]\d+)?$').hasMatch(v)) {
          throw FormatException(
              'Linha $numero: $c deve ser um número, sem unidade. Quantidades são em gramas.');
        }
        v = v.replaceAll(',', '.');
        final n = double.tryParse(v);
        if (n == null || !n.isFinite || n < 0 || (obrigatorio && n <= 0)) {
          throw FormatException('Linha $numero: valor inválido em $c.');
        }
        return n;
      }

      final linha = LinhaImportacaoDieta(
          numeroLinha: numero,
          refeicao: valor('refeicao'),
          horario: horario.padLeft(5, '0'),
          alimento: valor('alimento'),
          quantidadeGramas: numeroValor('quantidade_g', obrigatorio: true)!,
          calorias: numeroValor('calorias_100g'),
          proteinas: numeroValor('proteinas_100g'),
          carboidratos: numeroValor('carboidratos_100g'),
          gorduras: numeroValor('gorduras_100g'),
          fibras: numeroValor('fibras_100g'));
      resultado.add(linha);
    }
    if (resultado.any((l) => !l.temMacrosCompletos)) {
      avisos.add(
          'Há alimentos sem nutrientes completos por 100 g. Complete os dados dos alimentos novos antes de cadastrar; nenhum valor será estimado.');
    }
    return ResultadoImportacaoDieta(
        List.unmodifiable(resultado), List.unmodifiable(avisos));
  }

  String _coluna(String texto) {
    var s = texto.trim().toLowerCase();
    const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const para = 'aaaaaeeeeiiiiooooouuuuc';
    for (var i = 0; i < de.length; i++) {
      s = s.replaceAll(de[i], para[i]);
    }
    s = s
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    const aliases = {
      'refeicoes': 'refeicao',
      'tipo_refeicao': 'refeicao',
      'hora': 'horario',
      'nome_alimento': 'alimento',
      'alimentos': 'alimento',
      'quantidade_em_gramas': 'quantidade_g',
      'quantidade_gramas': 'quantidade_g',
      'gramas': 'quantidade_g',
      'peso_g': 'quantidade_g',
      'kcal_100g': 'calorias_100g',
      'energia_kcal_100g': 'calorias_100g',
      'proteina_100g': 'proteinas_100g',
      'carbo_100g': 'carboidratos_100g',
      'carbos_100g': 'carboidratos_100g',
      'carboidrato_100g': 'carboidratos_100g',
      'gordura_100g': 'gorduras_100g',
      'fibra_100g': 'fibras_100g'
    };
    return aliases[s] ?? s;
  }
}
