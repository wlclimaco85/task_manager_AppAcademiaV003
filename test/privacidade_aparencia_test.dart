import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/models/role_model.dart';
import 'package:task_manager_flutter/data/services/preferencia_tema_service.dart';
import 'package:task_manager_flutter/ui/screens/fitness/privacidade_aparencia_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferenciaTema.tema.value = TemaApp.padrao;
    AuthUtility.userInfo = LoginModel();
  });

  testWidgets('mostra as tres opcoes de tema', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PrivacidadeAparenciaScreen()));
    await tester.pump();

    expect(find.text('Aparência'), findsOneWidget);
    expect(find.byKey(const Key('tema_padrao')), findsOneWidget);
    expect(find.byKey(const Key('tema_branco')), findsOneWidget);
    expect(find.byKey(const Key('tema_preto')), findsOneWidget);
  });

  testWidgets('escolher preto troca o tema do app', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PrivacidadeAparenciaScreen()));
    await tester.pump();
    await tester.tap(find.byKey(const Key('tema_preto')));
    await tester.pump();

    expect(PreferenciaTema.tema.value, TemaApp.preto);
  });

  testWidgets('mostra secao de privacidade para o personal com vitrine e LGPD', (tester) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Simula Personal logado
    AuthUtility.userInfo = LoginModel(
      login: Login(
        tipoLogin: LoginEnum.APP_PERSONAL,
        roles: [Role(key: 'ROLE_PERSONAL', description: 'Personal')],
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: PrivacidadeAparenciaScreen()));
    await tester.pump();

    // Seção de privacidade do personal deve estar presente
    expect(find.text('Privacidade e Visibilidade Profissional'), findsOneWidget);
    expect(find.byKey(const Key('privacidade_visivel_vitrine')), findsOneWidget);
    expect(find.byKey(const Key('privacidade_receber_solicitacoes')), findsOneWidget);
    expect(find.byKey(const Key('privacidade_exibir_whatsapp')), findsOneWidget);
    expect(find.byKey(const Key('privacidade_exibir_instagram')), findsOneWidget);
    expect(find.byKey(const Key('privacidade_personal_salvar')), findsOneWidget);

    // Card de LGPD deve estar presente
    expect(find.text('Segurança e LGPD'), findsOneWidget);
    expect(find.text('Ler Política de Privacidade e Termos de Uso'), findsOneWidget);
  });

  testWidgets('mostra secao de privacidade para o aluno com permissoes e LGPD', (tester) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Simula Aluno logado
    AuthUtility.userInfo = LoginModel(
      login: Login(
        tipoLogin: LoginEnum.APP_ALUNO,
        roles: [Role(key: 'ROLE_ALUNO', description: 'Aluno')],
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: PrivacidadeAparenciaScreen()));
    await tester.pump();

    // Seção de privacidade do aluno deve estar presente
    expect(find.text('Privacidade'), findsOneWidget);
    expect(find.byKey(const Key('privacidade_treino')), findsOneWidget);
    expect(find.byKey(const Key('privacidade_dieta')), findsOneWidget);
    expect(find.byKey(const Key('privacidade_salvar')), findsOneWidget);
    expect(find.text('Segurança e LGPD'), findsOneWidget);
  });

  testWidgets('abre modal de Politica de Privacidade ao clicar no link de LGPD', (tester) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PrivacidadeAparenciaScreen()));
    await tester.pump();

    final linkLgpd = find.text('Ler Política de Privacidade e Termos de Uso');
    expect(linkLgpd, findsOneWidget);

    await tester.ensureVisible(linkLgpd);
    await tester.tap(linkLgpd);
    await tester.pumpAndSettle();

    expect(find.text('Política de Privacidade e LGPD'), findsOneWidget);
    expect(find.text('Entendido'), findsOneWidget);

    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();

    expect(find.text('Política de Privacidade e LGPD'), findsNothing);
  });
}
