import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/ui/widgets/fitness_graficos_hub.dart';
import 'package:task_manager_flutter/ui/screens/fitness/treinos_hub_screen.dart';
import 'dados_demo_eu_atleta.dart';

// Somente captura: estilos explícitos dos botões omitem fontFamily e o
// flutter_tester então usa Ahem. Normaliza apenas a fonte dos parágrafos;
// mantém os textos, tamanhos, pesos e a fonte própria dos ícones.
InlineSpan _fonteReal(InlineSpan span) {
  if (span is! TextSpan) return span;
  final estilo = span.style ?? const TextStyle();
  return TextSpan(
    text: span.text,
    style: estilo.fontFamily == null || estilo.fontFamily == 'Ahem'
        ? estilo.copyWith(fontFamily: 'Roboto')
        : estilo,
    children: span.children?.map(_fonteReal).toList(),
    recognizer: span.recognizer,
    semanticsLabel: span.semanticsLabel,
  );
}

bool _normalizarParagrafos(RenderObject objeto, Rect viewport) {
  if (objeto is RenderOffstage && objeto.offstage) return false;
  var alterado = false;
  if (objeto is RenderParagraph && objeto.hasSize) {
    final inicio = objeto.localToGlobal(Offset.zero);
    if ((inicio & objeto.size).overlaps(viewport)) {
      objeto.text = _fonteReal(objeto.text);
      alterado = true;
    }
  }
  objeto.visitChildren((filho) {
    if (_normalizarParagrafos(filho, viewport)) alterado = true;
  });
  // Recalcula os ancestrais que medem o texto, inclusive IntrinsicWidth.
  // Não marca boundaries fora do viewport que ainda não possuem layer.
  if (alterado) objeto.markNeedsLayout();
  return alterado;
}

Future<void> _pintarComFonteReal(WidgetTester tester) async {
  // O primeiro frame inicia os tickers; o segundo encerra a troca de aba.
  await tester.pump(Duration.zero, EnginePhase.build);
  tester.binding.rootPipelineOwner.flushLayout();
  await tester.pump(const Duration(milliseconds: 500), EnginePhase.build);
  for (var passagem = 0; passagem < 3; passagem++) {
    tester.binding.rootPipelineOwner.flushLayout();
    for (final view in tester.binding.renderViews) {
      _normalizarParagrafos(view, Offset.zero & view.size);
    }
    tester.binding.rootPipelineOwner
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();
  }
  // Compoe o frame completo para atualizar as transformações das camadas.
  await tester.pump();
}

void main() {
  testWidgets('gera capturas reais com massa isolada de demonstracao',
      (t) async {
    final fonte = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    await t.runAsync(fonte.load);
    await t.runAsync(() => (FontLoader('Ahem')
          ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf')))
        .load());
    await t.runAsync(() => (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load());
    final demo =
        DadosDemoEuAtleta(DateTime.now().subtract(const Duration(hours: 1)));
    expect(demo.sessoes.length, 16);
    SharedPreferences.setMockInitialValues({
      'appacademia_planos_treino_v1': jsonEncode([demo.plano.toMap()]),
      'appacademia_sessoes_treino_v1':
          jsonEncode(demo.sessoes.reversed.map((s) => s.toMap()).toList()),
    });
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final key = GlobalKey();
    Widget tela(Widget child) => MaterialApp(
        theme: ThemeData(
            fontFamily: 'Roboto',
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xFF059669))),
        home: RepaintBoundary(
            key: key,
            child: Scaffold(
                body: Column(children: [
              Container(
                  width: double.infinity,
                  color: const Color(0xFF064E3B),
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                      'EU ATLETA  •  DEMONSTRAÇÃO\nDados de exemplo — nenhuma conta real',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold))),
              Expanded(child: child),
            ]))));
    Future<void> salvar(String nome,
        {String diretorio = 'assets/images'}) async {
      await _pintarComFonteReal(t);
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await t.runAsync(() async {
        final imagem = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await imagem.toByteData(format: ui.ImageByteFormat.png);
        Directory(diretorio).createSync(recursive: true);
        File('$diretorio/$nome.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        imagem.dispose();
      });
    }

    t.view.physicalSize = const Size(1000, 2150);
    await t.pumpWidget(
        tela(SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FitnessGraficosHub(dados: Future.value(demo.graficos)))),
        phase: EnginePhase.build);
    await salvar('demo_hub');
    await t.pumpWidget(const SizedBox());
    t.view.physicalSize = const Size(430, 900);
    await t.pumpWidget(tela(const TreinosHubScreen()),
        phase: EnginePhase.build);
    await t.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 150)));
    await salvar('demo_treinos');
    await t.tap(find.text('Histórico Offline'));
    await salvar('demo_historico');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
