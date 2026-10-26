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

  // Sigla curta (FSH, LH, DHT). Palavra longa depois do traco nao e sigla: vira parte do nome.
  static final _regexCabSiglaPrimeiro = RegExp(r'^([A-Z][A-Z0-9]{1,4})\s+-\s+[A-ZÀ-Ý]');
  static final _regexCabSiglaUltima = RegExp(r'^[A-ZÀ-Ý][A-ZÀ-Ý ]+?\s+-\s+([A-Z][A-Z0-9]{1,4})$');
  static final _regexCabCaixaAlta = RegExp(r'^[A-ZÀ-Ý][A-ZÀ-Ý0-9 ]{2,60} - [A-ZÀ-Ý][A-ZÀ-Ý0-9 ]{1,60}$');
  static final _regexResultadoNumerico = RegExp(
      r'^Resultado:\s*(?:(?:Inferior|Menor|Superior|Maior)\s+(?:a|que)\s+)?'
      r'(-?\d{1,3}(?:\.\d{3})*(?:,\d+)?|-?\d+(?:,\d+)?)\s*(.*)$');
  static final _regexValorReferencia = RegExp(r'^Valor de Refer[eê]ncia:\s*(.*)$', caseSensitive: false);
  static final _regexFaixaTexto = RegExp(r'(\d+(?:[.,]\d+)?)\s+a\s+(\d+(?:[.,]\d+)?)\b');
  static final _regexLimiteSuperior = RegExp(
      r'(?:Inferior(?:\s+ou\s+igual)?\s+a|Menor(?:\s+ou\s+igual)?\s+(?:que|a)|<)\s*(\d+(?:[.,]\d+)?)',
      caseSensitive: false);
  static const _siglasHormonais = {'FSH', 'LH', 'TSH', 'T3', 'T4', 'ESTRADIOL', 'PROGESTERONA',
    'PROLACTINA', 'TESTOSTERONA', 'CORTISOL', 'INSULINA'};

  /// Sigla do analito no cabecalho "FSH - HORMONIO ..." ou "HORMONIO ... - LH". Null se a linha nao for cabecalho.
  static String? _cabecalhoAnalito(String linha) {
    final primeiro = _regexCabSiglaPrimeiro.firstMatch(linha);
    if (primeiro != null) return primeiro.group(1);
    final ultima = _regexCabSiglaUltima.firstMatch(linha);
    if (ultima != null) return ultima.group(1);
    // "TESTOSTERONA LIVRE - DILUIDA": sem sigla, o nome impresso no laudo e usado inteiro.
    if (_regexCabCaixaAlta.hasMatch(linha)) return linha;
    return null;
  }

  /// Grupo para os filtros da tela: Hormonal, Lipidico, Glicemia ou Outros (pela sigla/nome do analito).
  static String grupoDoAnalito(String nome) {
    final palavras = nome.toUpperCase().split(RegExp(r'[^A-ZÀ-Ý0-9]+'));
    if (palavras.any((p) => p.startsWith('HORM') || _siglasHormonais.contains(p))) return 'Hormonal';
    if (palavras.any((p) => p.startsWith('COLESTEROL') || p.startsWith('TRIGLICER') || p == 'LDL' || p == 'HDL')) {
      return 'Lipídico';
    }
    if (palavras.any((p) => p.startsWith('GLIC'))) return 'Glicemia';
    return 'Outros';
  }

  /// Resultados de laudos "SIGLA - NOME" + "Resultado: valor unidade" (paineis hormonais, lipidico etc.).
  /// Resultado qualitativo ("Inferior a 0,11") entra com o limite informado. Faixa de referencia so quando
  /// existe uma unica faixa na linha "Valor de Referencia"; faixas por sexo ficam sem referencia.
  static List<ExameItemLido> lerResultados(List<String> linhas,
      {String? dataExame, Set<int> ignorar = const {}}) {
    final itens = <ExameItemLido>[];
    String? nome;
    ({String nome, double valor, String unidade, String? data})? pendente;

    void fecharPendente() {
      final p = pendente;
      if (p == null) return;
      itens.add(ExameItemLido(
          nome: p.nome, valor: p.valor, unidade: p.unidade, grupo: grupoDoAnalito(p.nome), dataExame: p.data));
      pendente = null;
    }

    for (var i = 0; i < linhas.length; i++) {
      if (ignorar.contains(i)) continue;
      final linha = linhas[i].trim();
      // Data da coleta que vem depois deste resultado (cada exame termina com "Coleta: ...").
      final data = _coletaDoResultado(linhas, i) ?? dataExame;

      final cabecalho = _cabecalhoAnalito(linha);
      if (cabecalho != null) {
        fecharPendente();
        nome = cabecalho;
        continue;
      }
      if (_regexValorReferencia.hasMatch(linha) && pendente != null) {
        final p = pendente!;
        final ref = _referenciaDoBloco(linhas, i);
        itens.add(ExameItemLido(
          nome: p.nome,
          valor: p.valor,
          unidade: p.unidade,
          refMin: ref?.min,
          refMax: ref?.max,
          grupo: grupoDoAnalito(p.nome),
          dataExame: p.data,
        ));
        pendente = null;
        continue;
      }
      final resultado = _regexResultadoNumerico.firstMatch(linha);
      if (resultado != null) {
        fecharPendente();
        final valor = _numero(resultado.group(1)!);
        if (valor != null && nome != null) {
          pendente = (nome: nome, valor: valor, unidade: (resultado.group(2) ?? '').trim(), data: data);
        }
        nome = null;
        continue;
      }
      // "Nome: valor unidade" numa linha so, sem faixa (ex.: "Hb A1c: 5,4 %", "COLESTEROL TOTAL : 211 mg/dL").
      final inline = _regexInlineValor.firstMatch(linha);
      if (inline != null && !_regexFaixaNaLinha.hasMatch(linha)) {
        fecharPendente();
        final valor = _numero(inline.group(2)!);
        if (valor != null) {
          final nomeInline = inline.group(1)!.replaceAll(RegExp(r'[\s.:]+$'), '').trim();
          itens.add(ExameItemLido(
              nome: nomeInline,
              valor: valor,
              unidade: inline.group(3)!.trim(),
              grupo: grupoDoAnalito(nomeInline),
              dataExame: data));
        }
        nome = null;
        continue;
      }
      // Varios pares "nome: valor unidade" numa linha so (ex.: espermograma: "Progressiva rapida: 54 % Imovel: 36 %").
      final pares = _pares(linha);
      if (pares.isNotEmpty && !_regexFaixaNaLinha.hasMatch(linha)) {
        fecharPendente();
        for (final p in pares) {
          itens.add(ExameItemLido(
              nome: p.nome, valor: p.valor, unidade: p.unidade, grupo: grupoDoAnalito(p.nome), dataExame: data));
        }
        nome = null;
        continue;
      }
      // Nome do exame em linha propria, seguido de "Material:", "Método:" ou "Resultado:".
      if (_regexNomeLinha.hasMatch(linha) && _seguidaPorDetalhe(linhas, i)) {
        fecharPendente();
        nome = linha;
      }
    }
    fecharPendente();
    return itens;
  }

  /// Faixa do bloco "Valor de Referencia" que comeca na linha [i]. So vale quando o bloco tem UMA
  /// faixa (ou um limite "Inferior a X", tratado como 0 ate X). Blocos com varias faixas (sexo, idade,
  /// fase do ciclo) ficam sem referencia: a faixa certa depende de dados que o app nao tem aqui.
  static ({double? min, double? max})? _referenciaDoBloco(List<String> linhas, int i) {
    final primeira = _regexValorReferencia.firstMatch(linhas[i].trim());
    if (primeira == null) return null;
    final trechos = [primeira.group(1)!];
    for (var j = i + 1; j < linhas.length && j <= i + 12; j++) {
      final l = linhas[j].trim();
      if (l.isEmpty) continue;
      if (_fronteiraDeItem(l)) break;
      trechos.add(l);
    }
    final faixas = [for (final t in trechos) ..._regexFaixaTexto.allMatches(t)];
    final limites = [for (final t in trechos) ..._regexLimiteSuperior.allMatches(t)];
    if (faixas.length + limites.length != 1) return null;
    if (faixas.length == 1) {
      final f = faixas.single;
      return (min: _numero(f.group(1)!), max: _numero(f.group(2)!));
    }
    final max = _numero(limites.single.group(1)!);
    return max == null ? null : (min: 0.0, max: max);
  }

  /// Linha que inicia outro trecho do laudo (resultado, cabecalho de exame, material, coleta).
  static bool _fronteiraDeItem(String linha) =>
      _regexResultadoNumerico.hasMatch(linha) ||
      _cabecalhoAnalito(linha) != null ||
      linha.startsWith('Material:') ||
      linha.startsWith('Método') ||
      _regexColeta.hasMatch(linha);

  /// Coleta do resultado da linha [i]: a seguinte; se nao houver, a anterior mais proxima.
  static String? _coletaDoResultado(List<String> linhas, int i) {
    final seguinte = dataColeta(linhas, i);
    if (seguinte != null) return seguinte;
    for (var j = i; j >= 0; j--) {
      final m = _regexColeta.firstMatch(linhas[j]);
      if (m != null) return '${m.group(3)}-${m.group(2)}-${m.group(1)}';
    }
    return null;
  }

  /// Nome em linha propria (so letras, sem ":" nem digitos) seguido de detalhe do exame.
  static final _regexNomeLinha = RegExp(r'^[A-ZÀ-Ý][A-Za-zÀ-ÿ0-9 .,()/\-]{2,69}$');
  static final _regexInlineValor = RegExp(
      r'^([A-Za-zÀ-ÿ][A-Za-zÀ-ÿ0-9 .,()/\-]{1,60}?)\s*[:.]*\s*'
      r'(-?\d{1,3}(?:\.\d{3})*(?:,\d+)?|-?\d+(?:,\d+)?)\s+'
      r'(%|[A-Za-zµμ]+/[A-Za-zµμ0-9²]+)$');
  /// Linha com faixa ou limite (De/a/Até/Inferior/Superior/sexo/idade): nao e um resultado isolado.
  static final _regexFaixaNaLinha = RegExp(
      r'(\bDe\b|\bde\b|\ba\b|Até|Inferior|Superior|Homens|Mulheres|anos|meses|trimestre|semanas)');

  static final _regexPar = RegExp(r'([A-Za-zÀ-ÿ][A-Za-zÀ-ÿ .\-]{1,40}?)[.:]+\s*(\d[\d.]*(?:,\d+)?)\s*(%|/mL|/uL)');

  static List<({String nome, double valor, String unidade})> _pares(String linha) {
    if (!RegExp(r'%|/mL|/uL').hasMatch(linha)) return const [];
    return [
      for (final m in _regexPar.allMatches(linha))
        if (_numero(m.group(2)!) != null)
          (
            nome: m.group(1)!.replaceAll(RegExp(r'[\s.]+$'), '').trim(),
            valor: _numero(m.group(2)!)!,
            unidade: m.group(3)!,
          ),
    ];
  }

  static bool _seguidaPorDetalhe(List<String> linhas, int i) {
    if (i + 1 >= linhas.length) return false;
    final prox = linhas[i + 1].trimLeft();
    return prox.startsWith('Material') ||
        prox.startsWith('Resultado') ||
        prox.startsWith('Método') ||
        prox.startsWith('Metodo');
  }

  /// Le tudo de uma pagina: o hemograma (blocos Eritrograma..Coleta) e os demais exames fora desses blocos.
  static List<ExameItemLido> lerLaudo(List<String> linhas) {
    final hemograma = _indicesHemograma(linhas);
    final itens = [
      if (hemograma.isNotEmpty) ...lerHemograma(linhas),
      ...lerResultados(linhas, ignorar: hemograma, dataExame: dataColeta(linhas, 0)),
    ];
    return _semDuplicados(itens);
  }

  /// O mesmo resultado impresso duas vezes (mesma data, valor, unidade e primeira palavra do nome) entra uma vez so.
  static List<ExameItemLido> _semDuplicados(List<ExameItemLido> itens) {
    final vistos = <String>{};
    return [
      for (final item in itens)
        if (vistos.add('${item.dataExame}|${item.valor}|${item.unidade}|'
            '${item.nome.toUpperCase().split(RegExp(r'[\s\-]+')).first}'))
          item,
    ];
  }

  /// Linhas ocupadas pelo bloco do hemograma: do primeiro "Eritrograma"/"HEMOGRAMA" ate o proximo "Coleta:".
  static Set<int> _indicesHemograma(List<String> linhas) {
    final usados = <int>{};
    var i = 0;
    while (i < linhas.length) {
      if (!linhas[i].contains('Eritrograma') && !linhas[i].contains('HEMOGRAMA')) {
        i++;
        continue;
      }
      var fim = i;
      while (fim < linhas.length && !_regexColeta.hasMatch(linhas[fim])) {
        fim++;
      }
      fim = fim < linhas.length ? fim : linhas.length - 1;
      for (var j = i; j <= fim; j++) {
        usados.add(j);
      }
      i = fim + 1;
    }
    return usados;
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
