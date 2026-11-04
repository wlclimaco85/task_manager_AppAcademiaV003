import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
import 'package:task_manager_flutter/ui/screens/fitness/montador_treino_screen.dart';
import 'package:task_manager_flutter/ui/screens/fitness/treinos_hub_screen.dart';
import 'package:task_manager_flutter/ui/screens/fitness/player_treino_ao_vivo_screen.dart';

MockClient servidor({List<PlanoTreinoModel> planos = const []}) {
  final fichas = {for (final p in planos) p.id: p.toMap()};
  return MockClient((request) async {
    if (request.url.path.contains('/documentos/planos')) {
      if (request.method == 'PUT') {
        final ficha = Map<String, dynamic>.from(jsonDecode(request.body));
        fichas[ficha['id']] = ficha;
        return http.Response(request.body, 200);
      }
      return http.Response(jsonEncode({'data': fichas.values.toList()}), 200);
    }
    return http.Response('{"data":[]}', 200);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonte = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    await fonte.load();
  });
  setUp(() {
    final anterior = AuthUtility.userInfo;
    addTearDown(() => AuthUtility.userInfo = anterior);
    SharedPreferences.setMockInitialValues({});
    AuthUtility.userInfo = LoginModel(token: 'teste', login: Login(
      id: 10, nome: 'Aluno Teste', tipoLogin: LoginEnum.APP_ALUNO));
  });

  for (final largura in [390.0, 1200.0]) {
    testWidgets('aluno monta salva e reabre treino próprio em largura $largura', (tester) async {
      tester.view.physicalSize = Size(largura, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: TreinosHubScreen()));
        await tester.pumpAndSettle();
        expect(find.text('Montar meu treino'), findsOneWidget);
        expect(find.text('Modelos / Templates'), findsOneWidget);
        await tester.tap(find.text('Montar meu treino'));
        await tester.pumpAndSettle();
        expect(find.byType(MontadorTreinoScreen), findsOneWidget);
        await tester.enterText(find.widgetWithText(TextField, 'Título da Ficha de Treino'), 'Meu treino próprio');
        await tester.tap(find.byTooltip('Salvar Ficha'));
        await tester.pumpAndSettle();
        expect(find.text('Meu treino próprio'), findsOneWidget);
        final salvo = (await FitnessOfflineRepository().getPlanosTreino()).single;
        expect(salvo.alunoId, '10');
        expect(salvo.personalId, isEmpty);
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        await tester.pumpWidget(const MaterialApp(home: TreinosHubScreen()));
        await tester.pumpAndSettle();
        expect(find.text('Meu treino próprio'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }, () => servidor());
    });
  }

  testWidgets('personal mantém prescrição e modelos', (tester) async {
    AuthUtility.userInfo = LoginModel(token: 'teste', login: Login(
      id: 20, tipoLogin: LoginEnum.APP_PERSONAL));
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: TreinosHubScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Prescrever Treino'), findsOneWidget);
      expect(find.text('Modelos / Templates'), findsOneWidget);
      expect(find.text('Montar meu treino'), findsNothing);
    }, () => servidor());
  });

  testWidgets('aluno encontra ficha salva como template e inicia treino sem perder prescrição', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const plano = PlanoTreinoModel(id: 'proprio', alunoId: '10',
      alunoNome: 'Aluno Teste', personalId: '', titulo: 'Meu treino salvo',
      dataInicio: '2026-11-03', divisoes: [DivisaoTreinoModel(id: 'a',
        letra: 'A', nome: 'Treino A', exercicios: [ItemTreinoModel(id: 'item',
          exercicioId: 'supino', exercicioNome: 'Supino reto', grupoMuscular: 'Peitoral',
          series: 4, repeticoes: '8 a 12', cargaSugeridaKg: 10)])]);
    final cliente = servidor(planos: const [plano]);
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: TreinosHubScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar Prescrição'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      await tester.tap(find.byTooltip('Salvar Ficha'));
      await tester.pumpAndSettle();
      final salvo = (await FitnessOfflineRepository().getPlanosTreino()).single;
      expect(salvo.isTemplate, isTrue);
      await tester.tap(find.text('Modelos / Templates'));
      await tester.pumpAndSettle();
      expect(find.text('Meu treino salvo'), findsOneWidget);
      expect(salvo.divisoes.single.exercicios.single.toMap(),
          plano.divisoes.single.exercicios.single.toMap());
      await tester.tap(find.text('Treinar'));
      await tester.pumpAndSettle();
      expect(find.byType(PlayerTreinoAoVivoScreen), findsOneWidget);
      expect(find.text('Supino reto'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();
    }, () => cliente);
  });

  testWidgets('aluno continua sem editar ficha prescrita pelo personal', (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: TreinosHubScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Ficha do personal'), findsOneWidget);
      expect(find.text('Editar Prescrição'), findsNothing);
      expect(find.text('Renomear ficha'), findsNothing);
    }, () => servidor(planos: const [PlanoTreinoModel(id: 'prescrita',
      alunoId: '10', alunoNome: 'Aluno Teste', personalId: '20',
      titulo: 'Ficha do personal', dataInicio: '2026-11-03', divisoes: [])]));
  });
}
