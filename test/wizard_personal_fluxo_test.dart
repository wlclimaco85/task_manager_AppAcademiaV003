import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/wizard_personal_screen.dart';

/// Percorre os 5 passos do wizard do personal e confere o corpo enviado à API.
void main() {
  Map<String, dynamic>? enviado;

  final cliente = MockClient((req) async {
    if (req.url.path.endsWith('academias-disponiveis')) {
      return http.Response(
          jsonEncode([
            {'id': 153, 'nome': 'SmartFit - Shopping Uberaba'},
            {'id': 158, 'nome': 'Smart Fit'},
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    }
    if (req.url.path.endsWith('registrar-personal')) {
      enviado = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response(jsonEncode({'id': 1, 'loginId': 2, 'message': 'ok'}), 201,
          headers: {'content-type': 'application/json'});
    }
    return http.Response('{}', 404);
  });

  Future<void> preencher(WidgetTester t, String rotulo, String texto) async {
    await t.enterText(find.widgetWithText(TextFormField, rotulo), texto);
    await t.pump();
  }

  Future<void> continuar(WidgetTester t) async {
    await t.tap(find.byKey(const Key('btn_wizard_continuar')));
    await t.pumpAndSettle();
  }

  setUp(() {
    enviado = null;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('retoma o rascunho salvo no passo em que parou', (t) async {
    SharedPreferences.setMockInitialValues({
      'rascunho_cadastro_personal_v1': jsonEncode({
        'passo': 2,
        'nome': 'Ana Personal',
        'email': 'ana@example.invalid',
        'faixas': [
          {'academiaId': null, 'localNome': 'Online', 'dias': [0, 2], 'inicio': '19:00', 'fim': '21:00'}
        ],
      }),
    });
    await http.runWithClient(() async {
      await t.pumpWidget(const MaterialApp(home: WizardPersonalScreen()));
      await t.pumpAndSettle();
    }, () => cliente);

    expect(find.text('Passo 3 de 5 · Onde e quando você atende'), findsOneWidget);
    expect(find.text('Seg, Qua · 19:00–21:00'), findsOneWidget);
    expect(find.textContaining('Retomamos seu cadastro'), findsOneWidget);
  });

  testWidgets('cadastro completo envia CREF, WhatsApp, valor avulso, horarios e planos', (t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 2.5;
    addTearDown(t.view.reset);

    await http.runWithClient(() async {
      await t.pumpWidget(const MaterialApp(home: WizardPersonalScreen()));
      await t.pumpAndSettle();

      // Passo 1: nao avanca vazio.
      await continuar(t);
      expect(find.text('Passo 1 de 5 · Sua conta'), findsOneWidget);
      expect(find.text('Informe seu nome completo'), findsOneWidget);

      await preencher(t, 'Nome completo *', 'Carlos Personal');
      await preencher(t, 'E-mail *', 'carlos@example.invalid');
      await preencher(t, 'Senha *', 'segredo1');
      await preencher(t, 'Confirmar senha *', 'segredo1');
      await preencher(t, 'CPF *', '52998224725');
      await preencher(t, 'Telefone *', '34999990000');
      await preencher(t, 'Instagram (opcional)', '@carlos.personal');
      await preencher(t, 'Link da bio (opcional)', 'https://example.invalid/carlos');
      await continuar(t);
      expect(find.text('Passo 2 de 5 · Registro e contato'), findsOneWidget);

      // Passo 2: CREF + WhatsApp (mesmo do telefone, ja preenchido).
      await t.enterText(find.byKey(const Key('campo_cref_numero')), '12345');
      await t.tap(find.byKey(const Key('campo_cref_uf')));
      await t.pumpAndSettle();
      await t.tap(find.text('MG').last);
      await t.pumpAndSettle();
      expect(find.text('Seu CREF: 012345-G/MG'), findsOneWidget);
      await continuar(t);

      // Passo 3: exige um local; adiciona academia Seg–Sex 06:00–10:00.
      await continuar(t);
      expect(find.text('Adicione pelo menos um local de atendimento'), findsOneWidget);
      await t.tap(find.byKey(const Key('btn_add_academia')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('editor_academia')));
      await t.pumpAndSettle();
      await t.tap(find.text('SmartFit - Shopping Uberaba').last);
      await t.pumpAndSettle();
      await t.tap(find.text('Seg–Sex'));
      await t.pump();
      await t.tap(find.byKey(const Key('btn_salvar_faixa')));
      await t.pumpAndSettle();
      expect(find.text('Seg–Sex · 06:00–10:00'), findsOneWidget);
      expect(find.text('Principal'), findsOneWidget);
      await continuar(t);

      // Passo 4: valor avulso obrigatorio + preset de plano.
      await continuar(t);
      expect(find.text('Informe o valor da aula avulsa'), findsOneWidget);
      await t.enterText(find.byKey(const Key('campo_valor_avulso')), '7000');
      await t.tap(find.text('Mensal 2x/semana'));
      await t.pumpAndSettle();
      await preencher(t, 'Valor do plano por mês *', '25000');
      expect(find.text(r'≈ R$ 31,25 por aula'), findsOneWidget);
      await continuar(t);

      // Passo 5: revisao; sem a declaracao nao envia.
      expect(find.text('Passo 5 de 5 · Revisão'), findsOneWidget);
      expect(find.text('CREF 012345-G/MG'), findsWidgets);
      await t.tap(find.byKey(const Key('btn_wizard_continuar')));
      await t.pumpAndSettle();
      expect(find.text('Confirme a declaração para concluir.'), findsOneWidget);
      expect(enviado, isNull);

      // Rascunho salvo no aparelho nunca contem a senha.
      final prefs = await SharedPreferences.getInstance();
      final rascunho = prefs.getString('rascunho_cadastro_personal_v1')!;
      expect(rascunho, isNot(contains('segredo1')));
      expect(rascunho, contains('Carlos Personal'));
      expect(rascunho, contains('carlos.personal'));
      expect(rascunho, contains('https://example.invalid/carlos'));

      await t.tap(find.byKey(const Key('chk_declaracao')));
      await t.pump();
      await t.tap(find.byKey(const Key('btn_wizard_continuar')));
      await t.pumpAndSettle();
      expect(prefs.getString('rascunho_cadastro_personal_v1'), isNull,
          reason: 'rascunho apagado apos cadastro concluido');
    }, () => cliente);

    expect(enviado, isNotNull);
    expect(enviado!['instagram'], 'carlos.personal');
    expect(enviado!['linkBio'], 'https://example.invalid/carlos');
    expect(enviado!['cref'], '012345-G/MG');
    expect(enviado!['whatsapp'], '5534999990000');
    expect(enviado!['vlrAula'], 70.0);
    expect(enviado!['academiaId'], 153);
    expect(enviado!['atendimentos'], [
      {
        'academiaId': 153,
        'dias': ['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira'],
        'inicio': '06:00',
        'fim': '10:00',
      }
    ]);
    expect(enviado!['planos'], [
      {'nome': 'Mensal 2x/semana', 'descricao': '', 'valor': 250.0, 'qtdAula': 8}
    ]);
  });
}
