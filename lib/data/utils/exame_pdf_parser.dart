/// Item de exame lido do laudo: valor, faixa de referencia e cor de status.
class ExameItemLido {
  final String nome;
  final double valor;
  final String unidade;
  final double? refMin;
  final double? refMax;

  const ExameItemLido({
    required this.nome,
    required this.valor,
    required this.unidade,
    this.refMin,
    this.refMax,
  });

  /// Regra: acima da referencia = vermelho; abaixo = amarelo; dentro = verde.
  String get status {
    if (refMin == null || refMax == null) return 'sem_referencia';
    if (valor > refMax!) return 'vermelho';
    if (valor < refMin!) return 'amarelo';
    return 'verde';
  }
}

/// Le uma secao de exame do texto extraido do PDF (layout do laboratorio).
///
/// No laudo, o valor de cada item fica na linha ANTERIOR a linha do nome
/// (o nome traz a faixa de referencia na mesma linha). Ex.: a linha
/// "Eritrocitos..: 16,8 g/dL  De 4,30 a 5,30" traz o valor de Hemoglobina.
class ExameLaudoParser {
  // Nome do item sempre vem com pelo menos dois pontos ("RDW..........:").
  static final _regexLinhaNome = RegExp(r'^\s*([A-Za-zÀ-ÿ][A-Za-zÀ-ÿ ]*?)\s*\.{2,}\s*:?\s*(.*)$');
  static final _regexValorUnidade = RegExp(r'(-?\d{1,3}(?:\.\d{3})*(?:,\d+)?|-?\d+(?:,\d+)?)\s*([^\s\d].*?)?\s*$');
  static final _regexReferencia = RegExp(r'De\s+(\d+(?:[.,]\d+)?)\s+a\s+(\d+(?:[.,]\d+)?)\s*(.*)$');

  static double? _numero(String texto) {
    final limpo = texto.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(limpo);
  }

  /// Devolve os itens da secao (ex.: Eritrograma), na ordem do laudo.
  static List<ExameItemLido> lerSecao(List<String> linhas) {
    final rotulos = <({String nome, String? referencia, String? unidadeRef, int linha})>[];
    for (var i = 0; i < linhas.length; i++) {
      final m = _regexLinhaNome.firstMatch(linhas[i]);
      if (m == null) continue;
      final resto = m.group(2) ?? '';
      final ref = _regexReferencia.firstMatch(resto);
      rotulos.add((
        nome: m.group(1)!.trim(),
        referencia: ref?.group(0),
        unidadeRef: ref?.group(3)?.trim(),
        linha: i,
      ));
    }

    final itens = <ExameItemLido>[];
    for (var k = 0; k < rotulos.length; k++) {
      final rotulo = rotulos[k];
      // Valor fica na linha anterior ao rotulo.
      final anterior = rotulo.linha - 1;
      if (anterior < 0) continue;
      final valorMatch = _regexValorUnidade.firstMatch(linhas[anterior]);
      if (valorMatch == null) continue;
      final valor = _numero(valorMatch.group(1)!);
      if (valor == null) continue;
      final unidade = (valorMatch.group(2) ?? '').trim();

      final ref = rotulo.referencia == null ? null : _regexReferencia.firstMatch(rotulo.referencia!);
      itens.add(ExameItemLido(
        nome: rotulo.nome,
        valor: valor,
        unidade: unidade,
        refMin: ref == null ? null : _numero(ref.group(1)!),
        refMax: ref == null ? null : _numero(ref.group(2)!),
      ));
    }
    return itens;
  }
}
