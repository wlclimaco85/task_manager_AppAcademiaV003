import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/ui/widgets/apresentacao_eu_atleta.dart';

void main() {
  for (final largura in [400.0, 1440.0]) {
    testWidgets(
        'apresentação responsiva ${largura.toInt()}px preserva login e CTA',
        (t) async {
      t.view.physicalSize = Size(largura, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      var cadastros = 0;
      await t.pumpWidget(MaterialApp(
          home: Scaffold(
              body: ApresentacaoEuAtleta(
        pixCopiaCola: '',
        onCriarConta: () => cadastros++,
        login: const Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Faça login para continuar'),
          TextField(decoration: InputDecoration(labelText: 'E-mail')),
          TextField(decoration: InputDecoration(labelText: 'Senha')),
        ]),
      ))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.text('APP + SITE • GRATUITOS'), findsOneWidget);
      expect(find.text('Demonstração — dados de exemplo'), findsNWidgets(3));
      expect(find.byType(TextField), findsNWidgets(2));
      await t.tap(find.text('Criar conta grátis').first);
      await t.pump();
      expect(cadastros, 1);
      await t.tap(find.text('Entrar'));
      await t.pumpAndSettle();
      expect(
          find.text('Faça login para continuar').hitTestable(), findsOneWidget);
      await t.enterText(
          find.widgetWithText(TextField, 'E-mail'), 'aluno@exemplo.invalid');
      expect(find.text('aluno@exemplo.invalid'), findsOneWidget);
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      await Scrollable.ensureVisible(
          t.element(find.text('QR Code disponível em breve')),
          alignment: 0.5);

      await t.pumpAndSettle();
      expect(find.text('QR Code disponível em breve').hitTestable(),
          findsOneWidget);
      expect(find.text('Copiar código Pix'), findsNothing);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('Pix só oferece código fornecido e slot real de QR', (t) async {
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ApresentacaoEuAtleta(
      login: const Text('Login'),
      onCriarConta: () {},
      pixCopiaCola: 'codigo-configurado-no-teste',
      pixQr:
          const SizedBox(width: 100, height: 100, child: Text('QR fornecido')),
    ))));
    await t.pumpAndSettle();
    expect(find.text('QR Code disponível em breve'), findsNothing);
    expect(find.text('codigo-configurado-no-teste'), findsOneWidget);
    expect(find.text('QR fornecido'), findsOneWidget);
    expect(find.text('Copiar código Pix'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
