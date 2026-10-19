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
    expect(find.text('Android: https://play.google.com/store/apps'), findsOneWidget);
    expect(find.text('iPhone: https://apps.apple.com/br/'), findsOneWidget);
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

}
