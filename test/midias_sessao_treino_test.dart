import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
import 'package:task_manager_flutter/ui/widgets/midias_sessao_treino.dart';
import 'package:task_manager_flutter/ui/widgets/detalhes_sessao_treino.dart';
import 'package:task_manager_flutter/ui/screens/fitness/treinos_hub_screen.dart';

const _video = 'https://youtu.be/dQw4w9WgXcQ';
const _drive = 'https://drive.google.com/file/d/videoTeste123/view';
const _sessao = SessaoTreinoRegistroModel(
    id: 's',
    treinoId: 'ficha',
    divisaoLetra: 'A',
    divisaoNome: 'Costas',
    alunoId: '101',
    dataHoraInicio: '2026-10-15T12:00:00',
    dataHoraFim: '2026-10-15T12:30:00',
    duracaoSegundos: 1800,
    feedbackAluno: 'Observação real',
    rpe: 8,
    exerciciosExecutados: [
      ExercicioExecutadoRegistroModel(
          exercicioId: 'e',
          exercicioNome: 'Remada',
          grupoMuscular: 'Costas',
          series: [
            SerieRegistroModel(
                numero: 1, cargaRealKg: 35, repeticoesRealizadas: 12),
          ]),
    ]);

String _foto() => base64Encode(img.encodeJpg(img.Image(width: 20, height: 20)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthUtility.userInfo = LoginModel();
  });
  tearDown(() => AuthUtility.userInfo = LoginModel());

  test('modelo preserva 3 fotos e 3 links e lê vídeo legado', () {
    final foto = _foto();
    final sessao = SessaoTreinoRegistroModel.fromMap({
      ..._sessao.toMap(),
      'fotosBase64': [foto, foto, foto],
      'videosUrls': [_video, _drive, 'https://youtu.be/abcdefghijk'],
    });
    final volta = SessaoTreinoRegistroModel.fromJson(sessao.toJson());
    expect(volta.fotosDoTreino, [foto, foto, foto]);
    expect(volta.videosDoTreino.length, 3);
    final antiga = SessaoTreinoRegistroModel.fromMap({
      ..._sessao.toMap(),
      'videoUrl': _video,
    });
    expect(antiga.videosDoTreino, [_video]);
    expect(antiga.fotosDoTreino, isEmpty);
    expect(
        SessaoTreinoRegistroModel.fromMap({
          ...antiga.toMap(),
          'videoUrl': null,
          'videosUrls': <String>[],
        }).videosDoTreino,
        isEmpty);
  });

  test(
      'foto é JPEG compacto de até150KB e valida limites sem aceitar links genéricos',
      () async {
    final arquivo =
        Uint8List.fromList(img.encodePng(img.Image(width: 1600, height: 900)));
    final foto = await prepararFotoTreino(arquivo);
    final bytes = base64Decode(foto);
    expect(bytes.length, lessThanOrEqualTo(maxBytesFotoTreino));
    final imagem = img.decodeJpg(bytes)!;
    expect(imagem.width, lessThanOrEqualTo(1280));
    expect(validarMidiasSessaoTreino([foto, foto, foto], [_video, _drive]),
        isNull);
    expect(validarMidiasSessaoTreino([foto, foto, foto, foto], []), isNotNull);
    expect(validarMidiasSessaoTreino([], [_video, _video, _video, _video]),
        isNotNull);
    expect(validarMidiasSessaoTreino(['invalida'], []), isNotNull);
    expect(validarMidiasSessaoTreino([], ['https://example.invalid/video']),
        isNotNull);
    await expectLater(prepararFotoTreino(Uint8List.fromList([1, 2, 3])),
        throwsFormatException);
  });

  test(
      'edição offline não duplica sessão, preserva cargas e sincroniza imagens no retorno',
      () async {
    AuthUtility.userInfo = LoginModel(token: 'conta101', login: Login(id: 101));
    SharedPreferences.setMockInitialValues({
      'appacademia_sessoes_treino_v1_conta_101': jsonEncode([_sessao.toMap()]),
    });
    var offline = true;
    final servidor = <String, Map<String, dynamic>>{};
    final client = MockClient((req) async {
      if (offline) throw http.ClientException('offline');
      if (!req.url.path.contains('/documentos/sessoes')) {
        return http.Response('{}', 200);
      }
      final conta = req.headers['authorization'] ?? '';
      if (req.method == 'PUT') {
        servidor[conta] = jsonDecode(req.body);
        return http.Response(req.body, 200);
      }
      return http.Response(
          jsonEncode({
            'data': servidor.containsKey(conta) ? [servidor[conta]] : []
          }),
          200);
    });
    await http.runWithClient(() async {
      final repo = FitnessOfflineRepository();
      final foto = _foto();
      await repo.atualizarSessaoMidias('s',
          fotosBase64: [foto], videosUrls: [_video, _drive]);
      var prefs = await SharedPreferences.getInstance();
      final locais = jsonDecode(
          prefs.getString('appacademia_sessoes_treino_v1_conta_101')!) as List;
      expect(locais.length, 1);
      expect(locais.single['fotosBase64'], [foto]);
      expect(locais.single['feedbackAluno'], _sessao.feedbackAluno);
      expect(locais.single['exerciciosExecutados'],
          _sessao.toMap()['exerciciosExecutados']);
      expect(
          jsonDecode(
              prefs.getString('fitness_pendentes_sessoes_conta_101')!)['s'],
          isNotNull);
      offline = false;
      final sincronizada = (await repo.getSessoesConcluidas()).single;
      expect(sincronizada.fotosDoTreino, [foto]);
      expect(sincronizada.sincronizado, isTrue);
      SharedPreferences.setMockInitialValues({});
      final restaurada = (await repo.getSessoesConcluidas()).single;
      expect(restaurada.fotosDoTreino, [foto]);
      expect(restaurada.videosDoTreino, [_video, _drive]);
      expect(
          restaurada.exerciciosExecutados.single.series.single.cargaRealKg, 35);
      AuthUtility.userInfo =
          LoginModel(token: 'conta102', login: Login(id: 102));
      expect(await repo.getSessoesConcluidas(), isEmpty);
    }, () => client);
  });

  test(
      'troca de conta durante edição conserva cache e fila da conta original sem enviar pela outra',
      () async {
    AuthUtility.userInfo = LoginModel(token: 'conta101', login: Login(id: 101));
    SharedPreferences.setMockInitialValues({
      'appacademia_sessoes_treino_v1_conta_101': jsonEncode([_sessao.toMap()]),
    });
    var requisicoes = 0;
    final client = MockClient((req) async {
      requisicoes++;
      return http.Response(jsonEncode({'data': []}), 200);
    });
    await http.runWithClient(() async {
      final gravacao = FitnessOfflineRepository().atualizarSessaoMidias('s',
          fotosBase64: [_foto()], videosUrls: [_video]);
      AuthUtility.userInfo =
          LoginModel(token: 'conta102', login: Login(id: 102));
      await gravacao;
      final prefs = await SharedPreferences.getInstance();
      expect(requisicoes, 0);
      final cacheA = jsonDecode(
          prefs.getString('appacademia_sessoes_treino_v1_conta_101')!);
      final filaA =
          jsonDecode(prefs.getString('fitness_pendentes_sessoes_conta_101')!);
      expect(cacheA.single['fotosBase64'], [_foto()]);
      expect(filaA['s']['videosUrls'], [_video]);
      expect(
          prefs.getString('appacademia_sessoes_treino_v1_conta_102'), isNull);
      expect(prefs.getString('fitness_pendentes_sessoes_conta_102'), isNull);
    }, () => client);
  });

  testWidgets('detalhes mostram fotos e permitem editar vídeos e removê-los',
      (t) async {
    t.view.physicalSize = const Size(400, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final sessao = SessaoTreinoRegistroModel.fromMap({
      ..._sessao.toMap(),
      'fotosBase64': [_foto()],
      'videoUrl': _video,
    });
    SharedPreferences.setMockInitialValues({
      'appacademia_sessoes_treino_v1': jsonEncode([sessao.toMap()]),
    });
    await t.pumpWidget(MaterialApp(
        home: Scaffold(body: DetalhesSessaoTreino(sessao: sessao))));
    await t.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    await t.ensureVisible(find.text('Editar fotos e vídeos'));
    await t.tap(find.text('Editar fotos e vídeos'));
    await t.pumpAndSettle();
    await t.enterText(
        find.widgetWithText(TextFormField, 'Link do vídeo 1 (opcional)'),
        _drive);
    await t.tap(find.text('Salvar mídias'));
    await t.pumpAndSettle();
    var salvas = await FitnessOfflineRepository().getSessoesConcluidas();
    expect(salvas.single.videosDoTreino, [_drive]);
    expect(salvas.single.fotosDoTreino, sessao.fotosDoTreino);
    await t.ensureVisible(find.text('Editar fotos e vídeos'));
    await t.tap(find.text('Editar fotos e vídeos'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Remover link 1'));
    await t.tap(find.byTooltip('Remover foto 1'));
    await t.tap(find.text('Salvar mídias'));
    await t.pumpAndSettle();
    salvas = await FitnessOfflineRepository().getSessoesConcluidas();
    expect(salvas.single.videosDoTreino, isEmpty);
    expect(salvas.single.fotosDoTreino, isEmpty);
    expect(salvas.single.exerciciosExecutados.single.series.single.cargaRealKg,
        35);
    expect(t.takeException(), isNull);
  });

  testWidgets('histórico mostra miniatura no cartão e abre a foto inteira',
      (t) async {
    final sessao = SessaoTreinoRegistroModel.fromMap({
      ..._sessao.toMap(),
      'fotosBase64': [_foto()],
    });
    SharedPreferences.setMockInitialValues({
      'appacademia_sessoes_treino_v1': jsonEncode([sessao.toMap()]),
    });
    await t.pumpWidget(const MaterialApp(home: TreinosHubScreen()));
    await t.pumpAndSettle();
    await t.tap(find.text('Histórico Offline'));
    await t.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('1 fotos • 0 vídeos'), findsOneWidget);
    await t.tap(find.byType(Image));
    await t.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    final imagem = t.widgetList<Image>(find.byType(Image)).last;
    expect(imagem.fit, BoxFit.contain);
    expect(t.takeException(), isNull);
  });
}
