import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/login_screen.dart';
import 'package:task_manager_flutter/ui/widgets/doacao_pix_qr.dart';
import 'package:task_manager_flutter/data/constants/doacao_config.dart';

void main() {
  test('Pix recebido tem CRC valido e alteracao e rejeitada', () {
    expect(codigoPixValido(pixDoacaoEuAtleta), isTrue);
    expect(codigoPixValido('${pixDoacaoEuAtleta.substring(0, pixDoacaoEuAtleta.length - 4)}0000'), isFalse);
    expect(codigoPixValido(''), isFalse);
  });
  testWidgets('landing preserva validacao login e cadastro no celular', (t) async {
    t.view.physicalSize = const Size(400, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(const MaterialApp(home: LoginScreen()));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Acessar'));
    await t.tap(find.text('Acessar'));
    await t.pumpAndSettle();
    expect(find.text('Por favor, insira o email'), findsOneWidget);
    expect(find.text('Por favor, insira a senha'), findsOneWidget);
    await t.ensureVisible(find.text('Criar conta').last);
    await t.tap(find.text('Criar conta').last);
    await t.pumpAndSettle();
    expect(find.text('Como você deseja se cadastrar?'), findsOneWidget);
    expect(find.text('Aluno'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('prints ampliam e copiar Pix usa exatamente codigo fornecido', (t) async {
    t.view.physicalSize = const Size(1440, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    String? copiado;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copiado = call.arguments['text'];
        return null;
      });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));
    await t.pumpWidget(const MaterialApp(home: LoginScreen()));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Copiar código Pix'));
    await t.tap(find.text('Copiar código Pix'));
    await t.pumpAndSettle();
    expect(copiado, pixDoacaoEuAtleta);
    expect(find.byType(DoacaoPixQr), findsOneWidget);
    await t.ensureVisible(find.text('Ampliar tela').first);
    await t.tap(find.text('Ampliar tela').first);
    await t.pumpAndSettle();
    expect(find.text('Veja sua evolução • demonstração'), findsOneWidget);
    await t.tap(find.text('Fechar'));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

}
