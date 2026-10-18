import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/login_screen.dart';
import 'package:task_manager_flutter/ui/screens/bottom_navbar_screen.dart';
import 'package:task_manager_flutter/ui/screens/fitness/cadastro_inicial_screen.dart';

/// Ponta a ponta contra o backend local REAL (sem mock de rede).
///
/// Roda so quando as credenciais de uma conta de aluno de teste sao passadas:
///   flutter test test/e2e/cadastro_inicial_e2e_test.dart \
///     --dart-define=E2E_EMAIL=... --dart-define=E2E_SENHA=... \
///     --dart-define=BACKEND_CONTEXT_PATH=/boletobancos
///
/// Aluno sem personal: o "!" deve aparecer; medidas gravadas no servidor.
/// A foto nao e coberta aqui: o seletor de imagem e nativo do aparelho.
const String _email = String.fromEnvironment('E2E_EMAIL');
const String _senha = String.fromEnvironment('E2E_SENHA');

/// flutter_test bloqueia HTTP real por padrao; o E2E precisa da rede de verdade.
void _liberarRedeReal() => HttpOverrides.global = null;

/// Espera um widget aparecer deixando o tempo real correr (o HTTP acontece fora do fake clock).
Future<void> _esperar(WidgetTester tester, Finder alvo, {int segundos = 30}) async {
  final limite = DateTime.now().add(Duration(seconds: segundos));
  while (DateTime.now().isBefore(limite)) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
    if (alvo.evaluate().isNotEmpty) return;
  }
  fail('Widget nao apareceu a tempo: $alvo');
}

Future<void> _esperarSumir(WidgetTester tester, Finder alvo, {int segundos = 30}) async {
  final limite = DateTime.now().add(Duration(seconds: segundos));
  while (DateTime.now().isBefore(limite)) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
    if (alvo.evaluate().isEmpty) return;
  }
  fail('Widget nao saiu da tela a tempo: $alvo');
}

Future<void> _digitar(WidgetTester tester, String rotulo, String valor) async {
  final campo = find.widgetWithText(TextField, rotulo);
  await tester.ensureVisible(campo);
  await tester.enterText(campo, valor);
  await tester.pump();
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    _liberarRedeReal();
  });

  testWidgets('aluno sem personal: "!" aparece e as medidas vao para o servidor',
      skip: _email.isEmpty || _senha.isEmpty, // sem --dart-define o teste fica de fora
      (tester) async {
    // Celular de referencia (390x844 logico, densidade 1) para o layout da tela de login.
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Login pela tela real.
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(0), _email);
    await tester.enterText(find.byType(TextFormField).at(1), _senha);
    await tester.ensureVisible(find.text('Acessar'));
    await tester.tap(find.text('Acessar'));
    await _esperar(tester, find.byType(BottomNavBarScreen));

    // 2. O Hub Fitness abre pelo destino "Mais"; o lembrete fica nele e leva ao cadastro inicial.
    await tester.tap(find.text('Mais').last);
    final lembrete = find.byKey(const Key('lembrete_cadastro_inicial'));
    await _esperar(tester, lembrete);
    await tester.tap(lembrete);
    await _esperar(tester, find.byType(CadastroInicialScreen));
    await _esperar(tester, find.byKey(const Key('cadastro_inicial_progresso')));

    // 3. Sem personal: "!" ao lado da foto.
    expect(find.text('!'), findsOneWidget, reason: 'Aluno sem personal deve ver o "!"');

    // 4. Preenche as 7 medidas e salva.
    await _digitar(tester, 'Peso (kg)', '71,5');
    await _digitar(tester, 'Altura (cm)', '178');
    await _digitar(tester, 'Cintura (cm)', '84');
    await _digitar(tester, 'Quadril (cm)', '98');
    await _digitar(tester, 'Braço (cm)', '33');
    await _digitar(tester, 'Coxa (cm)', '56');
    await _digitar(tester, 'Panturrilha (cm)', '37');
    expect(find.text('7 de 8 campos preenchidos'), findsOneWidget);

    await tester.tap(find.text('Salvar'));
    // Salvar com sucesso fecha a tela; sem sucesso ela continua aberta com aviso.
    await _esperarSumir(tester, find.byType(CadastroInicialScreen));

    // 5. Ao voltar, o lembrete so pede a foto (medidas gravadas no servidor).
    await _esperar(tester, find.textContaining('Faltam: Foto'));
  });
}
