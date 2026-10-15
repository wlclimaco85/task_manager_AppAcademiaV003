import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'logo_eu_atleta.dart';

/// Gera os PNGs da logo (rodar a partir da raiz do projeto):
///   flutter test tool/logo/gerar_logo_test.dart
void main() {
  Future<void> salvar(WidgetTester t, String caminho, int lado,
      {double raio = 0.22,
      double escala = 1.0,
      bool fundo = true,
      bool simbolo = true}) async {
    await t.runAsync(() async {
      final rec = ui.PictureRecorder();
      LogoEuAtleta.desenhar(ui.Canvas(rec), lado.toDouble(), raio: raio, escala: escala, fundo: fundo, simbolo: simbolo);
      final img = await rec.endRecording().toImage(lado, lado);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      final arq = File(caminho);
      await arq.parent.create(recursive: true);
      await arq.writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  testWidgets('gera logo Eu Atleta em todos os tamanhos', (t) async {
    await salvar(t, 'assets/images/logo_eu_atleta.png', 512);

    const android = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
    for (final e in android.entries) {
      await salvar(t, 'android/app/src/main/res/mipmap-${e.key}/ic_launcher.png', e.value);
    }

    // Android 8+: icone adaptativo (108dp; simbolo dentro da zona segura de 66dp).
    const adaptivo = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432};
    for (final e in adaptivo.entries) {
      final base = 'android/app/src/main/res/mipmap-${e.key}';
      await salvar(t, '$base/ic_launcher_background.png', e.value, raio: 0, simbolo: false);
      await salvar(t, '$base/ic_launcher_foreground.png', e.value, escala: 0.78, fundo: false);
    }

    // iOS: icone quadrado e opaco (o sistema aplica o arredondamento).
    const ios = {
      'Icon-App-20x20@1x': 20, 'Icon-App-20x20@2x': 40, 'Icon-App-20x20@3x': 60,
      'Icon-App-29x29@1x': 29, 'Icon-App-29x29@2x': 58, 'Icon-App-29x29@3x': 87,
      'Icon-App-40x40@1x': 40, 'Icon-App-40x40@2x': 80, 'Icon-App-40x40@3x': 120,
      'Icon-App-60x60@2x': 120, 'Icon-App-60x60@3x': 180,
      'Icon-App-76x76@1x': 76, 'Icon-App-76x76@2x': 152,
      'Icon-App-83.5x83.5@2x': 167, 'Icon-App-1024x1024@1x': 1024,
    };
    for (final e in ios.entries) {
      await salvar(t, 'ios/Runner/Assets.xcassets/AppIcon.appiconset/${e.key}.png', e.value,
          raio: 0);
    }

    await salvar(t, 'web/favicon.png', 32);
    await salvar(t, 'web/icons/Icon-192.png', 192);
    await salvar(t, 'web/icons/Icon-512.png', 512);
    await salvar(t, 'web/icons/Icon-maskable-192.png', 192, raio: 0, escala: 0.8);
    await salvar(t, 'web/icons/Icon-maskable-512.png', 512, raio: 0, escala: 0.8);
  });
}
