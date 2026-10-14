import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:task_manager_flutter/data/models/fitness/exercicio_model.dart';
import 'package:task_manager_flutter/data/models/fitness/nutricao_farmaco_model.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';

/// PDFs imprimíveis da ficha de treino e da dieta (A4, legíveis em P&B).
/// Layout definido pelo agente de UX/UI: capa com legenda, uma divisão por
/// página, registro semanal para anotar a caneta e guia de execução.
class FichaDietaPdf {
  FichaDietaPdf._();

  static const _verde = PdfColor.fromInt(0xFF059669);
  static const _ambar = PdfColor.fromInt(0xFFF59E0B);
  static const _texto = PdfColor.fromInt(0xFF0F172A);
  static const _cinza = PdfColor.fromInt(0xFF64748B);
  static const _faixa = PdfColor.fromInt(0xFFF8FAFC);
  static const _borda = PdfColor.fromInt(0xFFCBD5E1);
  static const _barra = PdfColor.fromInt(0xFF334155);

  static const avisoTreino =
      'Siga as orientações do seu personal. Sentiu dor, pare o exercício.';
  static const avisoDieta =
      'Plano individual. Siga as orientações do seu nutricionista.';

  // ───────────────────────── formatação (testável) ─────────────────────────

  /// "4 × 10-12" ou "3 × até a falha".
  static String seriesReps(int series, String repeticoes) {
    final reps = repeticoes.trim();
    return reps.toLowerCase() == 'falha'
        ? '$series × até a falha'
        : '$series × ${reps.isEmpty ? '-' : reps}';
  }

  /// "60 s" ou "1 min 30 s".
  static String descanso(int segundos) {
    if (segundos <= 0) return '—';
    if (segundos <= 60) return '$segundos s';
    final min = segundos ~/ 60, seg = segundos % 60;
    return seg == 0 ? '$min min' : '$min min $seg s';
  }

  static String carga(double kg) {
    if (kg <= 0) return '—';
    return kg == kg.roundToDouble() ? '${kg.toInt()} kg' : '${dec(kg, 1)} kg';
  }

  /// Número com vírgula decimal (pt-BR).
  static String dec(double v, int casas) => v.toStringAsFixed(casas).replaceAll('.', ',');

  /// Rótulo legível do objetivo da dieta.
  static String objetivoDieta(String objetivo) => switch (objetivo.toLowerCase()) {
        'emagrecimento' => 'Emagrecimento',
        'hipertrofia' => 'Hipertrofia',
        'manutencao' => 'Manutenção',
        'recomposicao' => 'Recomposição corporal',
        _ => objetivo,
      };

  /// Extrai a medida caseira da descrição do catálogo ("Porção caseira: X.").
  static String? medidaCaseira(String? descricao) {
    if (descricao == null) return null;
    final m = RegExp(r'Porção caseira:\s*(.+?)\.?\s*(\n|$)').firstMatch(descricao);
    return m?.group(1)?.trim();
  }

  /// Data ISO (yyyy-MM-dd) para dd/MM/yyyy.
  static String data(String? iso) {
    if (iso == null || iso.length < 10) return '—';
    final p = iso.substring(0, 10).split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
  }

  static String _hoje(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Percentual planejado sobre a meta (0 quando não há meta).
  static int percentualMeta(double planejado, double meta) =>
      meta <= 0 ? 0 : (planejado * 100 / meta).round();

  static bool _tecnicaAvancada(String t) =>
      t.trim().isNotEmpty && t.trim().toLowerCase() != 'normal';

  // ───────────────────────── tema ─────────────────────────

  static Future<pw.ThemeData> _tema() async {
    Future<pw.Font> f(String nome) async =>
        pw.Font.ttf(await rootBundle.load('assets/fonts/$nome'));
    return pw.ThemeData.withFont(
      base: await f('Roboto-Regular.ttf'),
      bold: await f('Roboto-Bold.ttf'),
      italic: await f('Roboto-Italic.ttf'),
    );
  }

  static pw.PageTheme _pagina(pw.ThemeData tema) => pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 34, 42, 34),
        theme: tema,
      );

  static pw.Widget _cabecalho(String direita) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 4),
        margin: const pw.EdgeInsets.only(bottom: 10),
        decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _verde, width: 0.8))),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('MEU TREINO',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _verde)),
          pw.Text(direita, style: const pw.TextStyle(fontSize: 9, color: _cinza)),
        ]),
      );

  static pw.Widget _rodape(pw.Context ctx, String aviso, DateTime emissao) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 8),
        padding: const pw.EdgeInsets.only(top: 4),
        decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _borda, width: 0.5))),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text(aviso, style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: _cinza)),
          pw.Text('Emitido em ${_hoje(emissao)} · Pág. ${ctx.pageNumber} de ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: _cinza)),
        ]),
      );

  static pw.Widget _titulo(String t, {double size = 14}) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(t, style: pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold, color: _texto)),
      );

  static pw.Widget _cel(String t,
          {bool bold = false, double size = 9.5, pw.TextAlign align = pw.TextAlign.left, PdfColor? cor}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3),
        child: pw.Text(t,
            textAlign: align,
            style: pw.TextStyle(
                fontSize: size,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: cor ?? _texto)),
      );

  static pw.TableRow _cabecalhoTabela(List<String> colunas, {List<pw.TextAlign>? alinhamentos}) =>
      pw.TableRow(
        repeat: true,
        decoration: const pw.BoxDecoration(color: _verde),
        children: [
          for (var i = 0; i < colunas.length; i++)
            _cel(colunas[i],
                bold: true,
                cor: PdfColors.white,
                align: alinhamentos?[i] ?? pw.TextAlign.left),
        ],
      );

  static const _bordaTabela = pw.TableBorder(
    horizontalInside: pw.BorderSide(color: _borda, width: 0.5),
    bottom: pw.BorderSide(color: _borda, width: 0.5),
    left: pw.BorderSide(color: _borda, width: 0.5),
    right: pw.BorderSide(color: _borda, width: 0.5),
  );

  // ───────────────────────── ficha de treino ─────────────────────────

  static Future<Uint8List> fichaTreino(
    PlanoTreinoModel plano, {
    Map<String, ExercicioModel> catalogo = const {},
    DateTime? emissao,
  }) async {
    final tema = await _tema();
    final quando = emissao ?? DateTime.now();
    final doc = pw.Document(title: plano.titulo, author: 'Meu Treino');
    final direita = '${plano.alunoNome} · ${plano.titulo}';

    pw.MultiPage pagina(List<pw.Widget> Function(pw.Context) build) => pw.MultiPage(
          pageTheme: _pagina(tema),
          header: (_) => _cabecalho(direita),
          footer: (ctx) => _rodape(ctx, avisoTreino, quando),
          build: build,
        );

    // 1. Capa e resumo + legenda.
    doc.addPage(pagina((_) => [
          _titulo(plano.titulo, size: 18),
          pw.Row(children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: _verde, width: 1)),
              child: pw.Text(plano.objetivo.toUpperCase(),
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _verde)),
            ),
            pw.SizedBox(width: 10),
            pw.Text('Aluno: ${plano.alunoNome}   ·   Início: ${data(plano.dataInicio)}'
                '${plano.dataValidade != null ? '   ·   Validade: ${data(plano.dataValidade)}' : ''}',
                style: const pw.TextStyle(fontSize: 10)),
          ]),
          pw.SizedBox(height: 14),
          _titulo('Divisões do treino', size: 12),
          for (final d in plano.divisoes)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 4),
              padding: const pw.EdgeInsets.all(6),
              decoration: const pw.BoxDecoration(
                  color: _faixa, border: pw.Border(left: pw.BorderSide(color: _verde, width: 3))),
              child: pw.Text('Treino ${d.letra}: ${d.nome}  ·  ${d.exercicios.length} exercício(s)',
                  style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
            ),
          pw.SizedBox(height: 18),
          _legendaTreino(),
        ]));

    // 2. Uma divisão por página.
    for (final d in plano.divisoes) {
      doc.addPage(pagina((_) => [
            _titulo('Treino ${d.letra} — ${d.nome}'),
            _tabelaDivisao(d, catalogo),
            pw.SizedBox(height: 14),
            _titulo('Registro semanal', size: 11),
            pw.Text('Anote a carga e as repetições que você fez na última série.',
                style: const pw.TextStyle(fontSize: 9, color: _cinza)),
            pw.SizedBox(height: 4),
            _registroSemanal(d),
          ]));
    }

    // 3. Guia dos exercícios (passo a passo + erros comuns).
    final guia = <pw.Widget>[];
    for (final d in plano.divisoes) {
      final itens = d.exercicios.where((e) => (catalogo[e.exercicioId]?.descricao ?? '').isNotEmpty);
      if (itens.isEmpty) continue;
      guia.add(_titulo('Treino ${d.letra}', size: 12));
      for (final item in itens) {
        guia.add(_blocoGuia(item, catalogo[item.exercicioId]!));
      }
    }
    if (guia.isNotEmpty) {
      doc.addPage(pagina((_) => [_titulo('Guia dos exercícios — como executar', size: 16), ...guia]));
    }
    return doc.save();
  }

  static pw.Widget _tabelaDivisao(DivisaoTreinoModel d, Map<String, ExercicioModel> catalogo) {
    final linhas = <pw.TableRow>[
      _cabecalhoTabela(['#', 'Exercício', 'Séries × Reps', 'Carga', 'Descanso', 'Técnica']),
    ];
    for (var i = 0; i < d.exercicios.length; i++) {
      final e = d.exercicios[i];
      final cat = catalogo[e.exercicioId];
      final video = (e.videoUrl?.isNotEmpty ?? false) ? e.videoUrl : cat?.videoUrl;
      linhas.add(pw.TableRow(
        decoration: pw.BoxDecoration(color: i.isOdd ? _faixa : PdfColors.white),
        children: [
          _cel('${i + 1}', bold: true),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(e.exercicioNome, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text([e.grupoMuscular, if (cat?.equipamento != null) cat!.equipamento!].join(' · '),
                  style: const pw.TextStyle(fontSize: 8.5, color: _cinza)),
              if (e.exerciciosAlternativos.isNotEmpty)
                pw.Text('Alt.: ${e.exerciciosAlternativos.join(', ')}', style: const pw.TextStyle(fontSize: 8.5)),
              if ((e.observacoes ?? '').isNotEmpty)
                pw.Text(e.observacoes!, style: pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic)),
              if (video != null)
                pw.UrlLink(
                  destination: video,
                  child: pw.Text('Vídeo: $video',
                      style: const pw.TextStyle(
                          fontSize: 8, color: _verde, decoration: pw.TextDecoration.underline)),
                ),
            ]),
          ),
          _cel(seriesReps(e.series, e.repeticoes), bold: true, size: 11),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(carga(e.cargaSugeridaKg), style: const pw.TextStyle(fontSize: 9.5)),
              if (e.cargaSugeridaKg > 0)
                pw.Text('(sugerida)', style: const pw.TextStyle(fontSize: 8, color: _cinza)),
            ]),
          ),
          _cel(descanso(e.descansoSegundos)),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3),
            child: _tecnicaAvancada(e.tecnica)
                ? pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: _ambar, width: 1)),
                    child: pw.Text(e.tecnica.toUpperCase(),
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  )
                : pw.Text('Normal', style: const pw.TextStyle(fontSize: 9.5)),
          ),
        ],
      ));
    }
    return pw.Table(
      border: _bordaTabela,
      columnWidths: const {
        0: pw.FlexColumnWidth(0.5),
        1: pw.FlexColumnWidth(4),
        2: pw.FlexColumnWidth(1.6),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(1.1),
        5: pw.FlexColumnWidth(1.3),
      },
      children: linhas,
    );
  }

  static pw.Widget _registroSemanal(DivisaoTreinoModel d) {
    pw.Widget caixa() => pw.Container(
          height: 26,
          padding: const pw.EdgeInsets.all(3),
          child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('kg ________', style: const pw.TextStyle(fontSize: 8, color: _cinza)),
            pw.Text('reps ______', style: const pw.TextStyle(fontSize: 8, color: _cinza)),
          ]),
        );
    return pw.Table(
      border: pw.TableBorder.all(color: _borda, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1.5),
        4: pw.FlexColumnWidth(1.5),
      },
      children: [
        _cabecalhoTabela(['Exercício', 'Sem 1', 'Sem 2', 'Sem 3', 'Sem 4']),
        for (var i = 0; i < d.exercicios.length; i++)
          pw.TableRow(children: [
            _cel('${i + 1}. ${d.exercicios[i].exercicioNome}', size: 9),
            caixa(), caixa(), caixa(), caixa(),
          ]),
      ],
    );
  }

  static pw.Widget _blocoGuia(ItemTreinoModel item, ExercicioModel ex) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('>> ${item.exercicioNome}${ex.nivelTexto != null ? '  [${ex.nivelTexto}]' : ''}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 8, top: 2),
            child: pw.Text(ex.descricao, style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.5)),
          ),
          if ((ex.errosComuns ?? '').isNotEmpty)
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 3),
              padding: const pw.EdgeInsets.all(4),
              decoration: const pw.BoxDecoration(
                  color: _faixa, border: pw.Border(left: pw.BorderSide(color: _ambar, width: 2))),
              child: pw.Text('(!) Erro comum: ${ex.errosComuns}',
                  style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
            ),
        ]),
      );

  static pw.Widget _legendaTreino() {
    const itens = [
      ['Série', 'um bloco de repetições seguidas, sem parar.'],
      ['Repetição (reps)', 'quantas vezes você faz o movimento na série. "10-12" = pare entre 10 e 12.'],
      ['Até a falha', 'repita até não conseguir fazer mais uma com boa forma.'],
      ['Carga', 'peso sugerido. Ajuste para que as últimas repetições fiquem difíceis.'],
      ['Descanso', 'pausa entre uma série e a próxima.'],
      ['Bi-set', 'dois exercícios seguidos, sem descanso entre eles.'],
      ['Drop-set', 'ao chegar na falha, reduza ~20% do peso e continue.'],
      ['Rest-pause', 'chegue à falha, descanse 10–15 s e faça mais repetições.'],
      ['Pirâmide', 'aumente o peso e diminua as repetições a cada série.'],
    ];
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _borda, width: 1)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _titulo('Como ler esta ficha', size: 12),
        for (final i in itens)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.RichText(
                text: pw.TextSpan(style: const pw.TextStyle(fontSize: 9.5), children: [
              pw.TextSpan(text: '${i[0]}: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.TextSpan(text: i[1]),
            ])),
          ),
      ]),
    );
  }

  // ───────────────────────── dieta ─────────────────────────

  static Future<Uint8List> dieta(
    DietaProtocoloModel dieta, {
    String alunoNome = '',
    Map<String, AlimentoModel> alimentos = const {},
    DateTime? emissao,
  }) async {
    final tema = await _tema();
    final quando = emissao ?? DateTime.now();
    final doc = pw.Document(title: dieta.titulo, author: 'Meu Treino');
    final direita = [if (alunoNome.isNotEmpty) alunoNome, dieta.titulo].join(' · ');

    double soma(double Function(RefeicaoModel) f) =>
        dieta.refeicoes.fold(0.0, (t, r) => t + f(r));

    doc.addPage(pw.MultiPage(
      pageTheme: _pagina(tema),
      header: (_) => _cabecalho(direita),
      footer: (ctx) => _rodape(ctx, avisoDieta, quando),
      build: (_) => [
        _titulo(dieta.titulo, size: 18),
        pw.Text('Objetivo: ${objetivoDieta(dieta.objetivo)}   ·   Início: ${data(dieta.dataInicio)}'
            '${dieta.dataFim != null ? '   ·   Fim: ${data(dieta.dataFim)}' : ''}',
            style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 12),
        _titulo('Meta do dia', size: 12),
        _tabelaMeta([
          ['Calorias', 'kcal', dieta.caloriasMeta, soma((r) => r.totalCalorias)],
          ['Proteínas', 'g', dieta.proteinasMeta, soma((r) => r.totalProteinas)],
          ['Carboidratos', 'g', dieta.carboidratosMeta, soma((r) => r.totalCarboidratos)],
          ['Gorduras', 'g', dieta.gordurasMeta, soma((r) => r.totalGorduras)],
        ]),
        pw.SizedBox(height: 12),
        _comoSeguirDieta(),
        if ((dieta.observacoes ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text('Observações: ${dieta.observacoes}', style: pw.TextStyle(fontSize: 9.5, fontStyle: pw.FontStyle.italic)),
        ],
        pw.SizedBox(height: 18),
        for (final r in dieta.refeicoes) ..._blocoRefeicao(r, alimentos),
      ],
    ));
    return doc.save();
  }

  static pw.Widget _tabelaMeta(List<List<Object>> linhas) {
    const largura = 110.0;
    return pw.Table(
      border: _bordaTabela,
      columnWidths: const {
        0: pw.FlexColumnWidth(1.6),
        1: pw.FlexColumnWidth(1.1),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.4),
        4: pw.FixedColumnWidth(largura + 8),
      },
      children: [
        _cabecalhoTabela(['Nutriente', 'Meta', 'Planejado', '% da meta', 'Barra']),
        for (final l in linhas)
          () {
            final nome = l[0] as String, un = l[1] as String;
            final meta = l[2] as double, plan = l[3] as double;
            final pct = percentualMeta(plan, meta);
            final sinal = meta <= 0 ? '' : (pct > 110 ? ' (acima)' : (pct < 90 ? ' (abaixo)' : ''));
            return pw.TableRow(children: [
              _cel(nome, bold: true),
              _cel(meta > 0 ? '${meta.toStringAsFixed(0)} $un' : '—', align: pw.TextAlign.right),
              _cel('${plan.toStringAsFixed(0)} $un', align: pw.TextAlign.right),
              _cel(meta > 0 ? '$pct%$sinal' : '—', bold: sinal.isNotEmpty),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Container(
                  width: largura,
                  height: 8,
                  alignment: pw.Alignment.centerLeft,
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: _barra, width: 0.75)),
                  child: pw.Container(
                      width: largura * (pct.clamp(0, 100) / 100), height: 8, color: _barra),
                ),
              ),
            ]);
          }(),
      ],
    );
  }

  static pw.Widget _comoSeguirDieta() {
    const dicas = [
      'Pese os alimentos já prontos (cozidos). Sem balança, use a medida caseira.',
      'Troque alimentos só dentro do mesmo grupo (arroz por macarrão ou batata), em quantidade parecida.',
      'Beba cerca de 35 ml de água por kg de peso ao dia, distribuídos ao longo do dia.',
      'Respeite os horários aproximados (tolerância de ± 1 h).',
      'Na dúvida, fale com seu nutricionista.',
    ];
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _borda, width: 1)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _titulo('Como seguir esta dieta', size: 12),
        for (final d in dicas)
          pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text('• $d', style: const pw.TextStyle(fontSize: 9.5))),
      ]),
    );
  }

  static List<pw.Widget> _blocoRefeicao(RefeicaoModel r, Map<String, AlimentoModel> alimentos) {
    const direita = pw.TextAlign.right;
    return [
      pw.Container(
        margin: const pw.EdgeInsets.only(top: 10, bottom: 4),
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: const pw.BoxDecoration(
            color: _faixa, border: pw.Border(left: pw.BorderSide(color: _verde, width: 3))),
        child: pw.Row(children: [
          pw.Text(r.horario, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 10),
          pw.Text(r.nome, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ]),
      ),
      pw.Table(
        border: _bordaTabela,
        columnWidths: const {
          0: pw.FlexColumnWidth(3.2),
          1: pw.FlexColumnWidth(1.2),
          2: pw.FlexColumnWidth(2.8),
          3: pw.FlexColumnWidth(0.9),
          4: pw.FlexColumnWidth(0.8),
          5: pw.FlexColumnWidth(0.8),
          6: pw.FlexColumnWidth(0.8),
        },
        children: [
          _cabecalhoTabela(['Alimento', 'Quantidade', 'Medida caseira', 'kcal', 'P', 'C', 'G'],
              alinhamentos: const [
                pw.TextAlign.left, pw.TextAlign.left, pw.TextAlign.left,
                direita, direita, direita, direita,
              ]),
          for (var i = 0; i < r.itens.length; i++)
            () {
              final it = r.itens[i];
              final medida = medidaCaseira(alimentos[it.alimentoId]?.descricao);
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: i.isOdd ? _faixa : PdfColors.white),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3),
                    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text(it.alimentoNome, style: const pw.TextStyle(fontSize: 9.5)),
                      if ((it.observacao ?? '').isNotEmpty)
                        pw.Text(it.observacao!, style: pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic)),
                    ]),
                  ),
                  _cel('${it.quantidadeGramas.toStringAsFixed(0)} g', bold: true),
                  _cel(medida != null ? '~ $medida' : '—', size: 9),
                  _cel(it.calorias.toStringAsFixed(0), align: direita),
                  _cel(dec(it.proteinas, 1), align: direita),
                  _cel(dec(it.carboidratos, 1), align: direita),
                  _cel(dec(it.gorduras, 1), align: direita),
                ],
              );
            }(),
          pw.TableRow(
            decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: _texto, width: 1))),
            children: [
              _cel('Total da refeição', bold: true),
              _cel(''),
              _cel(''),
              _cel(r.totalCalorias.toStringAsFixed(0), bold: true, align: direita),
              _cel(dec(r.totalProteinas, 1), bold: true, align: direita),
              _cel(dec(r.totalCarboidratos, 1), bold: true, align: direita),
              _cel(dec(r.totalGorduras, 1), bold: true, align: direita),
            ],
          ),
        ],
      ),
    ];
  }
}
