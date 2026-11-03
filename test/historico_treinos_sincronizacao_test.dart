import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
import 'package:task_manager_flutter/data/services/fitness_conta_sync.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/ui/screens/fitness/player_treino_ao_vivo_screen.dart';

SessaoTreinoRegistroModel sessao(int dia, double carga) => SessaoTreinoRegistroModel(
  id: 'sessao_$dia', treinoId: 'plano', divisaoLetra: 'A', divisaoNome: 'Treino A',
  alunoId: '101', dataHoraInicio: '2026-10-${dia}T10:00:00',
  dataHoraFim: '2026-10-${dia}T11:00:00', duracaoSegundos: 3600,
  sincronizado: true, exerciciosExecutados: [ExercicioExecutadoRegistroModel(
    exercicioId: 'supino', exercicioNome: 'Supino', grupoMuscular: 'Peito',
    series: [SerieRegistroModel(numero: 1, cargaRealKg: carga, repeticoesRealizadas: 10)],
  )],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthUtility.userInfo = LoginModel(token: 'conta101', login: Login(id: 101));
  });
  tearDown(() => AuthUtility.userInfo = LoginModel());

  test('histórico remoto recupera cache local inválido', () async {
    SharedPreferences.setMockInitialValues({
      'appacademia_sessoes_treino_v1_conta_101': 'invalido',
    });
    await http.runWithClient(() async {
      final sessoes = await FitnessOfflineRepository().getSessoesConcluidas();
      expect(sessoes.single.id, 'sessao_25');
    }, () => MockClient((_) async => http.Response(
      jsonEncode({'data': [sessao(25, 35).toMap()]}), 200)));
  });

  test('histórico e última carga seguem a data do treino, não a atualização remota', () async {
    // O backend ordena por atualizado_em: editar um treino antigo o coloca primeiro.
    final remotos = [sessao(24, 20), sessao(26, 40), sessao(25, 30)];
    final cliente = MockClient((_) async => http.Response(
      jsonEncode({'data': remotos.map((s) => s.toMap()).toList()}), 200));
    await http.runWithClient(() async {
      final repo = FitnessOfflineRepository();
      expect((await repo.getSessoesConcluidas()).map((s) => s.id),
          ['sessao_26', 'sessao_25', 'sessao_24']);
      final ultima = await repo.getUltimaExecucaoExercicio('supino', alunoId: '101');
      expect(ultima!.series.single.cargaRealKg, 40);
    }, () => cliente);
  });

  test('sincronização iniciada antes da conclusão não apaga o treino recém-salvo', () async {
    final iniciouLeitura = Completer<void>();
    final resposta = Completer<http.Response>();
    final cliente = MockClient((_) {
      iniciouLeitura.complete();
      return resposta.future;
    });
    await http.runWithClient(() async {
      final repo = FitnessOfflineRepository();
      final sincronizacao = repo.getSessoesConcluidas();
      await iniciouLeitura.future;
      await repo.registrarSessaoConcluida(sessao(25, 35));
      resposta.complete(http.Response('{"data":[]}', 200));
      expect((await sincronizacao).map((s) => s.id), ['sessao_25']);
      final prefs = await SharedPreferences.getInstance();
      final cache = jsonDecode(prefs.getString('appacademia_sessoes_treino_v1_conta_101')!) as List;
      expect(cache.single['id'], 'sessao_25');
      expect(jsonDecode(prefs.getString('fitness_pendentes_sessoes_conta_101')!)['sessao_25'], isNotNull);
    }, () => cliente);
  });

  testWidgets('player sem cache recupera a última carga de todos os exercícios', (t) async {
    t.view.physicalSize = const Size(800, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final anterior = sessao(25, 35).toMap();
    anterior['exerciciosExecutados'] = [
      ...anterior['exerciciosExecutados'],
      const ExercicioExecutadoRegistroModel(exercicioId: 'remada',
        exercicioNome: 'Remada', grupoMuscular: 'Costas', series: [
          SerieRegistroModel(numero: 1, cargaRealKg: 27, repeticoesRealizadas: 10),
        ]).toMap(),
    ];
    final cliente = MockClient((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return http.Response(jsonEncode({'data': [anterior]}), 200);
    });
    await http.runWithClient(() async {
      await t.pumpWidget(const MaterialApp(home: PlayerTreinoAoVivoScreen(
        alunoId: '101', planoId: 'plano', divisao: DivisaoTreinoModel(
          id: 'a', letra: 'A', nome: 'Treino', exercicios: [
            ItemTreinoModel(id: 's', exercicioId: 'supino', exercicioNome: 'Supino',
              grupoMuscular: 'Peito', series: 1, tecnica: 'Bi-set',
              exercicioBiset: ItemTreinoModel(id: 'r', exercicioId: 'remada',
                exercicioNome: 'Remada', grupoMuscular: 'Costas', series: 1)),
          ],
        ),
      )));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await t.pumpAndSettle();
      expect(find.text('35.0 kg'), findsOneWidget);
      expect(find.text('27.0 kg'), findsOneWidget);
      await t.pumpWidget(const MaterialApp(home: SizedBox()));
      await t.pumpAndSettle();
    }, () => cliente);
  });

  test('troca de conta durante sincronização não devolve histórico da conta anterior', () async {
    SharedPreferences.setMockInitialValues({
      'appacademia_sessoes_treino_v1_conta_101': jsonEncode([sessao(25, 35).toMap()]),
    });
    final iniciouLeitura = Completer<void>();
    final resposta = Completer<http.Response>();
    final cliente = MockClient((_) {
      iniciouLeitura.complete();
      return resposta.future;
    });
    await http.runWithClient(() async {
      final leitura = FitnessOfflineRepository().getSessoesConcluidas();
      await iniciouLeitura.future;
      AuthUtility.userInfo = LoginModel(token: 'conta102', login: Login(id: 102));
      resposta.complete(http.Response('{"data":[]}', 200));
      expect(await leitura, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('appacademia_sessoes_treino_v1_conta_102'), isNull);
    }, () => cliente);
  });

  test('conclusão iniciada em uma conta não é gravada na outra', () async {
    final iniciouLeitura = Completer<void>();
    final resposta = Completer<http.Response>();
    final cliente = MockClient((_) {
      iniciouLeitura.complete();
      return resposta.future;
    });
    await http.runWithClient(() async {
      final gravacao = FitnessOfflineRepository().registrarSessaoConcluida(sessao(25, 35));
      final verificacao = expectLater(gravacao, throwsStateError);
      await iniciouLeitura.future;
      AuthUtility.userInfo = LoginModel(token: 'conta102', login: Login(id: 102));
      resposta.complete(http.Response('{"data":[]}', 200));
      await verificacao;
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('appacademia_sessoes_treino_v1_conta_102'), isNull);
      expect(prefs.getString('fitness_pendentes_sessoes_conta_102'), isNull);
    }, () => cliente);
  });

  test('fila de sincronização captura a conta antes de aguardar o armazenamento', () async {
    final prefs = await SharedPreferences.getInstance();
    final cliente = MockClient((_) async => http.Response('{"data":[]}', 200));
    await http.runWithClient(() async {
      final gravacao = FitnessContaSync.salvar('sessoes', sessao(25, 35).toMap());
      AuthUtility.userInfo = LoginModel(token: 'conta102', login: Login(id: 102));
      await gravacao;
      expect(prefs.getString('fitness_pendentes_sessoes_conta_102'), isNull);
    }, () => cliente);
  });
}
