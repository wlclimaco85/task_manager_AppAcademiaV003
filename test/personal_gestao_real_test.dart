import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/models/fitness/personal_gestao_model.dart';
import 'package:task_manager_flutter/data/services/personal_gestao_offline_repository.dart';
import 'package:task_manager_flutter/ui/widgets/personal_aluno_sheet.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/wizard_personal_screen.dart';
import 'package:task_manager_flutter/ui/screens/personal_workspace_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthUtility.userInfo = LoginModel();
  });
  test('aluno novo sem ficha, frequencia, mensalidade ou historico inventado',
      () {
    final aluno =
        PersonalAlunoGestaoModel.fromMap({'id': 'a', 'nome': 'Aluno'});
    expect(aluno.treinoAtualNome, isNull);
    expect(aluno.frequenciaContratada, 0);
    expect(aluno.frequenciaSemanalMedia, 0);
    expect(aluno.valorMensalidade, 0);
    expect(aluno.statusMensalidade, StatusMensalidadeAluno.pendente);
    expect(aluno.feedbacks, isEmpty);
  });
  test('plano conserva quantidade mensal sem converter para semana', () {
    final a = PersonalAlunoGestaoModel.fromMap({
      'id': 'a', 'nome': 'Ana', 'tipoCobranca': 'plano',
      'aulasPlanoMes': 10, 'frequenciaContratada': 0,
    });
    expect(a.resumoAulasContratadas, '10 aulas/mês');
    expect(a.copyWith(nome: 'Ana A').toMap()['aulasPlanoMes'], 10);
    expect(a.frequenciaContratada, 0);
  });
  testWidgets('respostas de vínculo têm contraste e busca aceita e-mail', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PersonalAlunoSheet())));
    await tester.pumpAndSettle();
    final chip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Sim, buscar e vincular'));
    expect(chip.labelStyle?.color, isNot(Colors.white));
    await tester.tap(find.text('Sim, buscar e vincular'));
    await tester.pumpAndSettle();
    expect(find.text('Nome, CPF, telefone ou e-mail'), findsOneWidget);
  });
  testWidgets('plano selecionado usa quantidade mensal sem exigir frequência semanal', (tester) async {
    tester.view.physicalSize = const Size(900, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    AuthUtility.userInfo = LoginModel(token: 'personal', login: Login(id: 901));
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PersonalAlunoSheet())));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Não, cadastrar aluno'));
      await tester.pumpAndSettle();
      expect(find.text('E-mail (opcional)'), findsOneWidget);
      await tester.tap(find.text('Valor mensal à parte'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plano cadastrado').last);
      await tester.pumpAndSettle();
      final plano = find.widgetWithText(DropdownButtonFormField<String>, 'Plano');
      await tester.tap(plano);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pacote mensal').last);
      await tester.pumpAndSettle();
      expect(find.text('10 aulas por mês incluídas no plano.'), findsOneWidget);
      expect(find.text('Frequência contratada (aulas por semana)'), findsNothing);
      expect(tester.takeException(), isNull);
    }, () => MockClient((r) async => http.Response(jsonEncode({
      'data': r.url.path.endsWith('/planos') ? [
        {'id': 1, 'nome': 'Pacote mensal', 'valor': 500, 'qtdAula': 10}
      ] : [],
    }), 200)));
  });
  test('contrato offline persiste, sincroniza e nao mistura contas', () async {
    AuthUtility.userInfo =
        LoginModel(token: 'personal_a', login: Login(id: 901));
    bool conectado = false;
    final servidor = <String, Map<String, dynamic>>{};
    await http.runWithClient(() async {
      final repo = PersonalGestaoOfflineRepository();
      const aluno = PersonalAlunoGestaoModel(
          id: 'aluno-local',
          nome: 'Pessoa',
          email: '',
          telefone: '34999999999',
          tipoCobranca: 'aula_avulsa',
          frequenciaContratada: 2,
          valorMensalidade: 80,
          diaVencimento: 15);
      await repo.salvarAluno(aluno);
      final offline = (await repo.getAlunos()).single;
      expect(offline.tipoCobranca, 'aula_avulsa');
      expect(offline.frequenciaContratada, 2);
      expect(offline.copyWith(nome: 'Pessoa editada').diaVencimento, 15);
      expect(await repo.getHistoricoAluno(aluno.id), isEmpty);
      conectado = true;
      await repo.sincronizarPendencias();
      SharedPreferences.setMockInitialValues({});
      final remoto = (await repo.getAlunos()).single;
      expect(remoto.valorMensalidade, 80);
      expect(remoto.frequenciaContratada, 2);
      AuthUtility.userInfo =
          LoginModel(token: 'personal_b', login: Login(id: 902));
      expect(await repo.getAlunos(), isEmpty);
    },
        () => MockClient((r) async {
              if (!conectado) throw http.ClientException('offline');
              final conta = r.headers['authorization'] ?? '';
              if (r.method == 'PUT') {
                servidor[conta] = Map<String, dynamic>.from(jsonDecode(r.body));
                return http.Response(r.body, 200);
              }
              return http.Response(
                  jsonEncode({
                    'data': servidor.containsKey(conta) ? [servidor[conta]] : []
                  }),
                  200);
            }));
  });
  testWidgets('novo aluno pergunta sobre conta antes de exibir cadastro',
      (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PersonalAlunoSheet())));
    await tester.pumpAndSettle();
    expect(find.text('O aluno já tem usuário no app?'), findsOneWidget);
    expect(find.text('Nome completo'), findsNothing);
    await tester.tap(find.text('Não, cadastrar aluno'));
    await tester.pumpAndSettle();
    expect(find.text('Nome completo'), findsOneWidget);
    expect(find.text('Forma de cobrança'), findsOneWidget);
    expect(
        find.text('Frequência contratada (aulas por semana)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('CEP do personal consulta e preenche endereco ao perder foco',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int consultas = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: WizardPersonalScreen()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Adicionar endereço (opcional)'));
      await tester.tap(find.text('Adicionar endereço (opcional)'));
      await tester.pumpAndSettle();
      final cep = find.widgetWithText(TextFormField, 'CEP');
      await tester.ensureVisible(cep);
      await tester.enterText(cep, '38010040');
      final logradouro = find.widgetWithText(TextFormField, 'Logradouro');
      await tester.ensureVisible(logradouro);
      await tester.tap(logradouro);
      await tester.pumpAndSettle();
      expect(consultas, 1);
      expect(find.text('Rua consultada'), findsOneWidget);
      expect(find.text('Uberaba'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((r) async {
              if (r.url.host == 'viacep.com.br') {
                consultas++;
                return http.Response(
                    jsonEncode({
                      'logradouro': 'Rua consultada',
                      'bairro': 'Centro',
                      'localidade': 'Uberaba',
                      'uf': 'MG'
                    }),
                    200);
              }
              return http.Response(jsonEncode({'data': []}), 200);
            }));
  });
  testWidgets('card oferece montar treino e historico vazio nao cria sessoes',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    AuthUtility.userInfo = LoginModel(
        token: 'personal',
        login: Login(id: 901, tipoLogin: LoginEnum.APP_PERSONAL));
    await http.runWithClient(() async {
      await tester
          .pumpWidget(const MaterialApp(home: PersonalWorkspaceScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Montar treino'), findsOneWidget);
      expect(find.text('Frequência e cobrança'), findsOneWidget);
      await tester.tap(find.text('Ver Histórico de Treinos e Cargas'));
      await tester.pumpAndSettle();
      expect(
          find.text('Nenhum treino concluído por este aluno.'), findsOneWidget);
      expect(find.textContaining('Supino'), findsNothing);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((r) async => http.Response(
            jsonEncode({
              'data': r.url.path.endsWith('/personal/alunos')
                  ? [
                      {'id': 'a', 'nome': 'Aluno real', 'telefone': ''}
                    ]
                  : []
            }),
            200)));
  });
}
