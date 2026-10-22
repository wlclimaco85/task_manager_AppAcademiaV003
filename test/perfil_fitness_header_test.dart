import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/app.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/services/fitness_push_notification_service.dart';
import 'package:task_manager_flutter/ui/widgets/authenticated_header_shell.dart';
import 'package:task_manager_flutter/ui/widgets/fitness_notificacoes_sheet.dart';
import 'package:task_manager_flutter/ui/widgets/perfil_fitness_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Nome longo cabe no celular e ausência de foto usa iniciais',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 240,
          child: PerfilFitnessHeader(
            nome: 'Washington Climaco de Albuquerque com nome longo',
            perfil: 'Aluno',
          ),
        ),
      ),
    ));
    expect(find.text('WL'), findsOneWidget);
    expect(find.text('Aluno'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Header mostra só dados do aluno, sem status do personal',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: PerfilFitnessHeader(
          nome: 'Aluno QA 10',
          perfil: 'Aluno',
        ),
      ),
    ));
    expect(find.text('Aluno QA 10'), findsOneWidget);
    expect(find.text('Aluno'), findsOneWidget);
    expect(find.text('Online'), findsNothing);
    expect(find.text('Offline'), findsNothing);
    expect(find.textContaining('Personal:'), findsNothing);
    expect(find.textContaining('Último treino'), findsNothing);
  });

  testWidgets('Conta sem nome não inventa identidade', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: PerfilFitnessHeader(nome: '', perfil: 'Personal'),
      ),
    ));
    expect(find.text('Minha conta'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mostra sino, contador e alerta de cadastro com exclamação',
      (tester) async {
    var abriuNotificacoes = false;
    var abriuCadastro = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PerfilFitnessHeader(
          nome: 'Lis Valentine',
          perfil: 'Aluno',
          cadastroIncompleto: true,
          notificacoesNaoLidas: 3,
          onNotificacoes: () => abriuNotificacoes = true,
          onCadastroIncompleto: () => abriuCadastro = true,
        ),
      ),
    ));

    expect(find.byKey(const Key('abrir_notificacoes')), findsOneWidget);
    expect(find.byKey(const Key('cadastro_incompleto_header')), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    // O ícone deve ser exclamação (Icons.priority_high), NÃO interrogação
    expect(find.byIcon(Icons.priority_high), findsOneWidget);
    expect(find.byIcon(Icons.question_mark), findsNothing);

    await tester.tap(find.byKey(const Key('abrir_notificacoes')));
    await tester.tap(find.byKey(const Key('cadastro_incompleto_header')));
    expect(abriuNotificacoes, isTrue);
    expect(abriuCadastro, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Diálogo avisa claramente que falta fazer a avaliação inicial',
      (tester) async {
    var clicouFazerAgora = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => mostrarDialogoAvaliacaoInicialPendente(
              context,
              onFazerAgora: () => clicouFazerAgora = true,
            ),
            child: const Text('Abrir Diálogo'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Abrir Diálogo'));
    await tester.pumpAndSettle();

    expect(find.text('Avaliação Inicial Pendente'), findsOneWidget);
    expect(find.text('Falta você fazer a sua avaliação inicial!'), findsOneWidget);
    expect(find.text('Fazer Avaliação Agora'), findsOneWidget);

    await tester.tap(find.text('Fazer Avaliação Agora'));
    await tester.pumpAndSettle();

    expect(clicouFazerAgora, isTrue);
  });

  testWidgets('Central de Notificações exibe os detalhes completos da notificação',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final notifService = FitnessPushNotificationService();
    await notifService.agendarNotificacao(
      FitnessNotificationItem(
        id: 'notif_1',
        titulo: 'Complete seu cadastro inicial',
        corpo: 'Inclua sua foto e medidas para acompanhar sua evolução completa.',
        dataHora: DateTime.now(),
        tipo: 'cadastro_inicial',
      ),
    );

    var abriuAvaliacao = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => mostrarCentralNotificacoes(
              context,
              onAtualizarIndicadores: () {},
              onAbrirAvaliacaoInicial: () => abriuAvaliacao = true,
            ),
            child: const Text('Abrir Notificações'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Abrir Notificações'));
    await tester.pumpAndSettle();

    expect(find.text('Notificações'), findsOneWidget);
    expect(find.text('Complete seu cadastro inicial'), findsOneWidget);
    expect(find.text('Inclua sua foto e medidas para acompanhar sua evolução completa.'), findsOneWidget);
    expect(find.text('Fazer Avaliação →'), findsOneWidget);

    await tester.tap(find.text('Fazer Avaliação →'));
    await tester.pumpAndSettle();

    expect(abriuAvaliacao, isTrue);
  });

  testWidgets('clique no ! e no sino dentro do AuthenticatedHeaderShell abre dialogo e central de notificacoes',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AuthUtility.setUserInfo(LoginModel(
      token: 'token_teste',
      login: Login(id: 100, nome: 'Lis Valentine', tipoLogin: LoginEnum.APP_ALUNO),
    ));

    final notifService = FitnessPushNotificationService();
    await notifService.agendarNotificacao(
      FitnessNotificationItem(
        id: 'notif_teste_1',
        titulo: 'Complete seu cadastro inicial',
        corpo: 'Falta cadastrar fotos e medidas corporais.',
        dataHora: DateTime.now(),
        tipo: 'cadastro_inicial',
      ),
    );

    await tester.pumpWidget(MaterialApp(
      navigatorKey: TaskManagerApp.globalKey,
      builder: (context, child) => AuthenticatedHeaderShell(
        onSair: () {},
        onEditar: () {},
        child: child ?? const SizedBox.shrink(),
      ),
      home: const Scaffold(
        body: Center(child: Text('Tela Inicio')),
      ),
    ));
    await tester.pumpAndSettle();

    // 1. Clicar no badge !
    expect(find.byKey(const Key('cadastro_incompleto_header')), findsOneWidget);
    await tester.tap(find.byKey(const Key('cadastro_incompleto_header')));
    await tester.pumpAndSettle();

    expect(find.text('Avaliação Inicial Pendente'), findsOneWidget);
    expect(find.text('Falta você fazer a sua avaliação inicial!'), findsOneWidget);

    // Fechar diálogo
    await tester.tap(find.text('Lembrar mais tarde'));
    await tester.pumpAndSettle();

    // 2. Clicar no sino de notificações
    expect(find.byKey(const Key('abrir_notificacoes')), findsOneWidget);
    await tester.tap(find.byKey(const Key('abrir_notificacoes')));
    await tester.pumpAndSettle();

    expect(find.text('Notificações'), findsOneWidget);
    expect(find.text('Complete seu cadastro inicial'), findsAtLeastNWidgets(1));
    expect(find.text('Falta cadastrar fotos e medidas corporais.'), findsOneWidget);
  });
}
