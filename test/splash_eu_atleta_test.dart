import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/ui/screens/splash_screens.dart';
import 'package:task_manager_flutter/ui/widgets/screen_background.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('abertura renderiza SVG e logo Eu Atleta sem imagem inválida', (t) async {
    SharedPreferences.setMockInitialValues({});
    await t.pumpWidget(const MaterialApp(home: SplashScreen()));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byType(SvgPicture), findsOneWidget);
    final logo = t.widget<Image>(find.byType(Image));
    expect((logo.image as AssetImage).assetName, 'assets/images/logo_eu_atleta.png');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox.shrink());
    await t.pump(const Duration(seconds: 4));
    expect(t.takeException(), isNull);
  });
  testWidgets('fundo compartilhado não envia SVG ao decoder raster', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(
      body: ScreenBackground(child: Text('Conteúdo')),
    )));
    await t.pumpAndSettle();
    expect(find.text('Conteúdo'), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(t.takeException(), isNull);
  });
}
