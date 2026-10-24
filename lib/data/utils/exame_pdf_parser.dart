/// Item de exame lido do laudo: valor, faixa de referencia, grupo e data da coleta.
class ExameItemLido {
  final String nome;
  final double valor;
  final String unidade;
  final double? refMin;
  final double? refMax;
  final String grupo;
  final String? dataExame;

  const ExameItemLido({
    required this.nome,
    required this.valor,
    required this.unidade,
    this.refMin,
    this.refMax,
    this.grupo = 'Hemograma',
    this.dataExame,
  });

  /// Regra: acima da referencia = vermelho; abaixo = amarelo; dentro = verde.
  String get status {
    if (refMin == null || refMax == null) return 'sem_referencia';
    if (valor > refMax!) return 'vermelho';
    if (valor < refMin!) return 'amarelo';
    return 'verde';
  }
}

/// Le os blocos do hemograma (eritrograma, leucograma e serie plaquetaria)
/// a partir das linhas de texto extraidas do PDF do laboratorio.
class ExameLaudoParser {
  static final _regexLinhaNome = RegExp(r'^\s*([A-Za-zÀ-ÿ][A-Za-zÀ-ÿ ]*?)\s*\.{2,}\s*:?\s*(.*)$');
  static final _regexValorUnidade = RegExp(r'(-?\d{1,3}(?:\.\d{3})*(?:,\d+)?|-?\d+(?:,\d+)?)\s*([^\s\d].*?)?\s*$');
  static final _regexReferencia = RegExp(r'De\s+(\d+(?:[.,]\d+)?)\s+a\s+(\d+(?:[.,]\d+)?)\s*(.*)$');
  static final _regexRefUL = RegExp(r'De\s+([\d.]+)\s+a\s+([\d.]+)\s*/\s*uL');
  static final _regexAbsUL = RegExp(r'([\d.]+(?:,\d+)?)\s*/\s*uL');
  static final _regexNomeLeuco = RegExp(r'^\s*([A-Za-zÀ-ÿ][A-Za-zÀ-ÿ ]*?)\s*(?:\.{2,}|:)');
  static final _regexPlaquetas = RegExp(
      r'Plaquetas\s*\.{2,}\s*:?\s*([\d.]+(?:,\d+)?)\s*/\s*uL\s*De\s+([\d.]+)\s+a\s+([\d.]+)');
  static final _regexColeta = RegExp(r'Coleta:\s*(\d{2})/(\d{2})/(\d{4})');

  static double? _numero(String texto) {
    final limpo = texto.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(limpo);
  }

  static final _regexMedico = RegExp(r'M[ée]dico\s*:\s*(.+?)\s{2,}');
  static final _regexLaboratorioConvenio = RegExp(r'LABORATORIO\s+(.+?)\s*-\s*RDA', caseSensitive: false);
  static final _regexUnidade = RegExp(r'Unidade\s*:\s*(.+?)\s*-\s*CNES', caseSensitive: false);

  /// Nome da medica solicitante, a partir da linha "Medico : NOME  Atendimento : ...".
  static String? medicoDoLaudo(List<String> linhas) {
    for (final linha in linhas) {
      final m = _regexMedico.firstMatch(linha);
      if (m != null) return _titulo(m.group(1)!);
    }
    return null;
  }

  /// Laboratorio: o nome que aparece no convenio ("LABORATORIO LAMEL"); senao, o nome da unidade.
  static String? laboratorioDoLaudo(List<String> linhas) {
    for (final linha in linhas) {
      final m = _regexLaboratorioConvenio.firstMatch(linha);
      if (m != null) return 'Laboratório ${_titulo(m.group(1)!)}';
    }
    for (final linha in linhas) {
      final m = _regexUnidade.firstMatch(linha);
      if (m != null) return _titulo(m.group(1)!);
    }
    return null;
  }

  /// "ANA FLAVIA BOSCO SOUZA" -> "Ana Flavia Bosco Souza".
  static const _preposicoes = {'de', 'do', 'da', 'dos', 'das', 'e'};

  static String _titulo(String texto) {
    final palavras = texto.trim().toLowerCase().split(RegExp(r'\s+'));
    return [
      for (var i = 0; i < palavras.length; i++)
        (i > 0 && _preposicoes.contains(palavras[i]))
            ? palavras[i]
            : (palavras[i].isEmpty ? palavras[i] : palavras[i][0].toUpperCase() + palavras[i].substring(1)),
    ].join(' ');
  }

  /// Data da coleta no formato yyyy-MM-dd, a partir da primeira linha "Coleta:" a partir de [inicio].
  static String? dataColeta(List<String> linhas, int inicio) {
    for (var i = inicio; i < linhas.length; i++) {
      final m = _regexColeta.firstMatch(linhas[i]);
      if (m != null) return '${m.group(3)}-${m.group(2)}-${m.group(1)}';
    }
    return null;
  }

  /// Junta os pedacos de texto que estao na mesma altura do PDF em uma linha, em ordem da esquerda para a direita.
  /// Ex.: "Hematocrito..: 51,7 %" + "De 38,8 a 50,0 %" viram uma unica linha.
  static List<String> montarLinhas(List<({double y, double x, String texto})> pedacos) {
    final ordenados = [...pedacos]..sort((a, b) => a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x));
    final linhas = <String>[];
    final partes = <String>[];
    double? yAtual;
    for (final p in ordenados) {
      if (yAtual == null || (p.y - yAtual).abs() > 2) {
        if (partes.isNotEmpty) linhas.add(partes.join(' '));
        partes.clear();
        yAtual = p.y;
      }
      partes.add(p.texto.trim());
    }
    if (partes.isNotEmpty) linhas.add(partes.join(' '));
    return linhas;
  }

  /// Eritrograma: cada linha traz nome, valor, unidade e a faixa "De x a y" na mesma linha.
  static List<ExameItemLido> lerSecao(List<String> linhas, {String grupo = 'Eritrograma', String? dataExame}) {
    final itens = <ExameItemLido>[];
    for (final linha in linhas) {
      final m = _regexLinhaNome.firstMatch(linha);
      if (m == null) continue;
      final resto = m.group(2) ?? '';
      final ref = _regexReferencia.firstMatch(resto);
      final antesDaFaixa = ref == null ? resto : resto.substring(0, ref.start);
      final valorMatch = _regexValorUnidade.firstMatch(antesDaFaixa.trim());
      if (valorMatch == null) continue;
      final valor = _numero(valorMatch.group(1)!);
      if (valor == null) continue;
      itens.add(ExameItemLido(
        nome: m.group(1)!.trim(),
        valor: valor,
        unidade: (valorMatch.group(2) ?? '').trim(),
        refMin: ref == null ? null : _numero(ref.group(1)!),
        refMax: ref == null ? null : _numero(ref.group(2)!),
        grupo: grupo,
        dataExame: dataExame,
      ));
    }
    return itens;
  }

  /// Leucograma: cada linha traz nome, valor absoluto (/uL) e faixa "De x a y /uL" na mesma linha.
  /// Linhas sem faixa ou sem nome (ex.: rotulos soltos) sao ignoradas.
  static List<ExameItemLido> lerLeucograma(List<String> linhas, {String? dataExame}) {
    final itens = <ExameItemLido>[];
    for (final linha in linhas) {
      final ref = _regexRefUL.firstMatch(linha);
      final nome = _regexNomeLeuco.firstMatch(linha);
      if (ref == null || nome == null) continue;
      final semFaixa = linha.replaceFirst(_regexRefUL, '');
      final absolutos = _regexAbsUL.allMatches(semFaixa).toList();
      if (absolutos.isEmpty) continue;
      final valor = _numero(absolutos.last.group(1)!);
      if (valor == null) continue;
      itens.add(ExameItemLido(
        nome: nome.group(1)!.trim(),
        valor: valor,
        unidade: '/uL',
        refMin: _numero(ref.group(1)!),
        refMax: _numero(ref.group(2)!),
        grupo: 'Leucograma',
        dataExame: dataExame,
      ));
    }
    return itens;
  }

  /// Serie plaquetaria: uma linha "Plaquetas....: 277.000 /uL De 150.000 a 450.000 /uL".
  static List<ExameItemLido> lerPlaquetas(List<String> linhas, {String? dataExame}) {
    final itens = <ExameItemLido>[];
    for (final linha in linhas) {
      final m = _regexPlaquetas.firstMatch(linha);
      if (m == null) continue;
      final valor = _numero(m.group(1)!);
      if (valor == null) continue;
      itens.add(ExameItemLido(
        nome: 'Plaquetas',
        valor: valor,
        unidade: '/uL',
        refMin: _numero(m.group(2)!),
        refMax: _numero(m.group(3)!),
        grupo: 'Plaquetas',
        dataExame: dataExame,
      ));
    }
    return itens;
  }

  /// Le o hemograma inteiro: eritrograma, leucograma e plaquetas, cada um com a data da sua coleta.
  static List<ExameItemLido> lerHemograma(List<String> linhas) {
    final inicioEritro = linhas.indexWhere((l) => l.contains('Eritrograma'));
    final inicioLeuco = linhas.indexWhere((l) => l.contains('Leucograma'));
    final inicioPlaq = linhas.indexWhere((l) => l.contains('Plaquetária') || l.contains('Série Plaquet'));
    final dataEritro = inicioEritro < 0 ? null : dataColeta(linhas, inicioEritro);

    final itens = <ExameItemLido>[];
    if (inicioEritro >= 0) {
      final fim = inicioLeuco > inicioEritro ? inicioLeuco : linhas.length;
      itens.addAll(lerSecao(linhas.sublist(inicioEritro, fim), dataExame: dataEritro));
    }
    if (inicioLeuco >= 0) {
      final fim = inicioPlaq > inicioLeuco ? inicioPlaq : linhas.length;
      itens.addAll(lerLeucograma(linhas.sublist(inicioLeuco, fim),
          dataExame: dataColeta(linhas, inicioLeuco)));
    }
    if (inicioPlaq >= 0) {
      itens.addAll(lerPlaquetas(linhas.sublist(inicioPlaq), dataExame: dataColeta(linhas, inicioPlaq)));
    }
    return itens;
  }
}
