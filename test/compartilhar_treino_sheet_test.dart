import 'package:image/image.dart' as img;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/ui/widgets/compartilhar_treino_sheet.dart';

void main() {
  testWidgets('compartilhamento opcional mostra foto e permite sair sem publicar', (tester) async {
    var fechou = false;
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CompartilharTreinoSheet(
      treino: 'Treino A', minutos: 30, series: 8, rpe: 7, tonelagemKg: 500,
      onFechar: () => fechou = true))));
    expect(find.text('Adicionar foto'), findsOneWidget);
    expect(find.text('Tirar foto'), findsOneWidget);
    expect(find.text('Compartilhar foto do treino'), findsOneWidget);
    expect(find.text('500 kg de volume total'), findsOneWidget);
    expect(find.text('Conheca o Eu Atleta:'), findsOneWidget);
    expect(find.text('https://eu-atleta-web-production.up.railway.app/'), findsOneWidget);
    await tester.tap(find.text('Agora não / Fechar'));
    expect(fechou, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('foto escolhida e salva antes de aparecer e limite e tres', (tester) async {
    final dir = Directory.systemTemp.createTempSync('foto_treino_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final png = base64Encode(img.encodeJpg(img.Image(width: 8, height: 8)));
    final arquivo = File('${dir.path}/foto.png');
    arquivo.writeAsBytesSync(base64Decode(png));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/image_picker'),
        (call) async => arquivo.path);
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/image_picker'), null));
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var salvas = <String>[];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CompartilharTreinoSheet(
      treino: 'Treino B', minutos: 4, series: 8, rpe: 9, tonelagemKg: 500,
      onFotosAlteradas: (fotos) async => salvas = List.of(fotos),
      onFechar: () {}))));
    for (var i = 0; i < 3; i++) {
      await tester.ensureVisible(find.text('Adicionar foto'));
      await tester.tap(find.text('Adicionar foto'));
      for (var tentativa = 0; tentativa < 100 && salvas.length < i + 1; tentativa++) {
        await tester.pump();
        await tester.runAsync(() async =>
          Future<void>.delayed(const Duration(milliseconds: 50)));
      }
      await tester.pumpAndSettle();
      expect(salvas.length, i + 1);
    }
    expect(find.text('Fotos do treino: 3/3'), findsOneWidget);
    final botao = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Adicionar foto'));
    expect(botao.onPressed, isNull);
    await tester.ensureVisible(find.text('Remover foto'));
    await tester.tap(find.text('Remover foto'));
    await tester.pumpAndSettle();
    expect(salvas.length, 2);
    expect(find.text('Fotos do treino: 2/3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('foto inicial e renderizada no card antes do compartilhamento', (tester) async {
    final foto = base64Encode(img.encodeJpg(img.Image(width: 24, height: 16)));
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CompartilharTreinoSheet(
      treino: 'Treino com foto', minutos: 35, series: 10, rpe: 7, tonelagemKg: 700,
      fotosIniciais: [foto], onFechar: () {}))));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Foto 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('botoes Instagram e Facebook aparecem na sheet de compartilhamento', (tester) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CompartilharTreinoSheet(
      treino: 'Treino C', minutos: 45, series: 12, rpe: 8, tonelagemKg: 750,
      onFechar: () {}))));
    await tester.pumpAndSettle();
    expect(find.text('Compartilhar em:'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
    // Botões devem estar habilitados (não ocupado)
    final btnInsta = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Instagram'));
    final btnFace = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Facebook'));
    expect(btnInsta.onPressed, isNotNull);
    expect(btnFace.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sempre marca @euatletafitnes no card e copia legenda com perfil oficial', (tester) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? textoCopiado;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          textoCopiado = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CompartilharTreinoSheet(
      treino: 'Treino Hipertrofia', minutos: 50, series: 15, rpe: 8, tonelagemKg: 1200,
      onFechar: () {}))));
    await tester.pumpAndSettle();

    // No card visual
    expect(find.text('@euatletafitnes'), findsOneWidget);

    // Clicar em "Copiar legenda"
    await tester.tap(find.text('Copiar legenda'));
    await tester.pumpAndSettle();

    expect(textoCopiado, isNotNull);
    expect(textoCopiado, contains('@euatletafitnes'));
    expect(textoCopiado, contains('https://www.instagram.com/euatletafitnes/'));
    expect(textoCopiado,
        contains('https://eu-atleta-web-production.up.railway.app/'));
    // Sem personal informado, não adiciona linha de personal
    expect(textoCopiado, isNot(contains('Personal:')));
  });

  testWidgets('marca o personal no card e na legenda quando fornecido', (tester) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? textoCopiado;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          textoCopiado = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CompartilharTreinoSheet(
      treino: 'Treino Pernas', minutos: 60, series: 18, rpe: 9, tonelagemKg: 2000,
      personalNome: 'Carlos Treinador',
      personalInstagram: '@carlos.coach',
      onFechar: () {}))));
    await tester.pumpAndSettle();

    // No card visual
    expect(find.text('@euatletafitnes'), findsOneWidget);
    expect(find.text('Personal: @carlos.coach'), findsOneWidget);

    // Campo de personal na UI para ajuste se desejado
    expect(find.widgetWithText(TextField, 'Marcar Personal (Instagram)'), findsOneWidget);

    // Copiar legenda e verificar que inclui ambos
    await tester.tap(find.text('Copiar legenda'));
    await tester.pumpAndSettle();

    expect(textoCopiado, isNotNull);
    expect(textoCopiado, contains('@euatletafitnes'));
    expect(textoCopiado, contains('https://www.instagram.com/euatletafitnes/'));
    expect(textoCopiado, contains('Personal: @carlos.coach'));
  });

  testWidgets('deriva arroba automaticamente do nome do personal se nao tiver arroba especifica', (tester) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? textoCopiado;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          textoCopiado = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CompartilharTreinoSheet(
      treino: 'Treino Costas', minutos: 40, series: 12, rpe: 7, tonelagemKg: 950,
      personalNome: 'Ana Paula Silva',
      onFechar: () {}))));
    await tester.pumpAndSettle();

    // No card visual deriva @ana_paula_silva
    expect(find.text('Personal: @ana_paula_silva'), findsOneWidget);

    await tester.tap(find.text('Copiar legenda'));
    await tester.pumpAndSettle();

    expect(textoCopiado, contains('Personal: @ana_paula_silva'));
    expect(textoCopiado, contains('@euatletafitnes'));
  });
}
