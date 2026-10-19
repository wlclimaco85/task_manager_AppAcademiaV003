import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/services/aviso_falta_repository.dart';
import 'package:task_manager_flutter/data/services/fitness_push_notification_service.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/preferencia_tema_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    PreferenciaTema.tema.value = TemaApp.padrao;
  });

  group('Aviso de Falta na Aula (Aluno <-> Personal)', () {
    test('envio é confirmado pelo servidor e não é simulado em recebidos',
        () async {
      final api = _FakeAvisoFaltaApi();
      final repo = AvisoFaltaRepository(network: api);

      final aviso = await repo.enviar(
        remetenteId: 'aluno_1',
        remetenteNome: 'Carlos Aluno',
        remetenteTipo: 'aluno',
        destinatarioId: 'personal_99',
        destinatarioNome: 'Professor Rodrigo',
        dataAula: '2026-10-20',
        horario: '08:00',
        motivo: 'Consulta médica de rotina',
      );

      expect(aviso.id, isNotEmpty);
      expect(aviso.status, 'aguardando');
      expect(aviso.motivo, 'Consulta médica de rotina');

      final enviados = await repo.getEnviados();
      final recebidos = await repo.getRecebidos();
      expect(enviados, hasLength(1));
      expect(recebidos, isEmpty,
          reason: 'o remetente não pode receber o próprio aviso');
      expect(api.postagens, 1);
    });

    test('destinatário confirma no servidor que viu o aviso', () async {
      final api = _FakeAvisoFaltaApi()
        ..recebidos.add(_FakeAvisoFaltaApi.aviso(
          id: '88',
          remetenteTipo: 'personal',
          remetenteId: 'personal_99',
          remetenteNome: 'Professor Rodrigo',
          destinatarioId: 'aluno_1',
          destinatarioNome: 'Carlos Aluno',
        ));
      final repo = AvisoFaltaRepository(network: api);

      final antes = await repo.getRecebidos();
      expect(antes.single.foiVisto, isFalse);
      await repo.marcarComoVisto('88');
      final depois = await repo.getRecebidos();
      expect(depois.single.foiVisto, isTrue);
      expect(api.confirmacoes, 1);

      final notificacoes =
          await FitnessPushNotificationService().getNotificacoes();
      expect(notificacoes.any((n) => n.tipo == 'falta_personal'), isTrue);
    });
  });

  group('Notificações Aluno x Personal expandidas', () {
    test(
        'Mensalidade vencida, troca de treino, meta diária e feedbacks são gerados',
        () async {
      final service = FitnessPushNotificationService();

      await service.notificarMensalidadeVencida(
        personalNome: 'Rodrigo Personal',
        diaVencimento: 10,
      );

      await service.notificarTreinoAtualizado(
        personalNome: 'Rodrigo Personal',
        treinoTitulo: 'Hipertrofia Pernas B',
      );

      await service.notificarMetaDiaNaoCumprida();

      await service.notificarAvisoPersonal(
        personalNome: 'Rodrigo Personal',
        aviso: 'Academia abrirá em horário especial no feriado.',
      );

      await service.notificarAlunoFinalizouTreino(
        alunoNome: 'Carlos',
        treinoNome: 'Costas e Bíceps',
        tonelagemKg: 4250,
      );

      await service.notificarAlunoComentarioTreino(
        alunoNome: 'Carlos',
        treinoNome: 'Costas e Bíceps',
        comentario: 'Senti muito a pegada na remada cavalinho.',
      );

      final notificacoes = await service.getNotificacoes();
      expect(notificacoes.length, 6);

      expect(notificacoes.any((n) => n.tipo == 'mensalidade_vencendo'), isTrue);
      expect(notificacoes.any((n) => n.tipo == 'treino_atualizado'), isTrue);
      expect(
          notificacoes.any((n) => n.tipo == 'meta_dia_nao_cumprida'), isTrue);
      expect(notificacoes.any((n) => n.tipo == 'aviso_personal'), isTrue);
      expect(
          notificacoes.any((n) => n.tipo == 'aluno_treino_finalizado'), isTrue);
      expect(
          notificacoes.any((n) => n.tipo == 'aluno_comentario_treino'), isTrue);
    });
  });

  group('Validação dos 3 Temas Visuais (Padrão, Branco, Preto)', () {
    test(
        'GridColors e CustomColors se adaptam dinamicamente ao tema selecionado',
        () {
      // 1. Tema Padrão
      PreferenciaTema.tema.value = TemaApp.padrao;
      expect(GridColors.background, const Color(0xFFF8FAFC));
      expect(GridColors.card, const Color(0xFFFFFFFF));
      expect(GridColors.textPrimary, const Color(0xFF0F172A));

      // 2. Tema Branco Puro
      PreferenciaTema.tema.value = TemaApp.branco;
      expect(GridColors.background, const Color(0xFFFFFFFF));
      expect(GridColors.card, const Color(0xFFFFFFFF));
      expect(GridColors.textPrimary, const Color(0xFF0F172A));

      // 3. Tema Preto / Black
      PreferenciaTema.tema.value = TemaApp.preto;
      expect(GridColors.background, Colors.black);
      expect(GridColors.card, const Color(0xFF111827));
      expect(GridColors.textPrimary, const Color(0xFFF8FAFC));
      expect(GridColors.textSecondary, const Color(0xFF94A3B8));
      expect(GridColors.divider, const Color(0xFF334155));

      // Assegura que o contraste no tema preto evita letras brancas sobre fundo branco
      expect(GridColors.card.computeLuminance(), lessThan(0.2));
      expect(GridColors.textPrimary.computeLuminance(), greaterThan(0.8));
    });
  });
}

class _FakeAvisoFaltaApi extends NetworkCaller {
  final List<Map<String, dynamic>> recebidos = [];
  final List<Map<String, dynamic>> enviados = [];
  int postagens = 0;
  int confirmacoes = 0;

  static Map<String, dynamic> aviso({
    required String id,
    required String remetenteTipo,
    required String remetenteId,
    required String remetenteNome,
    required String destinatarioId,
    required String destinatarioNome,
    String motivo = '',
  }) =>
      {
        'id': id,
        'remetenteTipo': remetenteTipo,
        'remetenteId': remetenteId,
        'remetenteNome': remetenteNome,
        'destinatarioId': destinatarioId,
        'destinatarioNome': destinatarioNome,
        'dataAula': '2026-10-20',
        'horario': '08:00',
        'motivo': motivo,
        'enviadoEm': '2026-10-19T08:00:00',
        'status': 'aguardando',
        'vistoEm': null,
      };

  Map<String, dynamic> get _caixa => {
        'vinculado': true,
        'recebidos': recebidos,
        'enviados': enviados,
      };

  @override
  Future<NetworkResponse> getRequest(String url) async =>
      NetworkResponse(true, 200, {'data': _caixa});

  @override
  Future<NetworkResponse> postRequest(
      String url, Map<String, dynamic>? body) async {
    postagens++;
    final item = aviso(
      id: '${100 + postagens}',
      remetenteTipo: 'aluno',
      remetenteId: 'aluno_1',
      remetenteNome: 'Carlos Aluno',
      destinatarioId: 'personal_99',
      destinatarioNome: 'Professor Rodrigo',
      motivo: body?['motivo']?.toString() ?? '',
    );
    enviados.insert(0, item);
    return NetworkResponse(true, 201, {'data': item});
  }

  @override
  Future<NetworkResponse> putRequest(String url, dynamic body) async {
    confirmacoes++;
    final id = Uri.parse(url).pathSegments.reversed.skip(1).first;
    final index = recebidos.indexWhere((item) => item['id'] == id);
    if (index < 0) return NetworkResponse(false, 403, null);
    recebidos[index] = {
      ...recebidos[index],
      'status': 'visto',
      'vistoEm': '2026-10-19T09:00:00',
    };
    return NetworkResponse(true, 200, {'data': recebidos[index]});
  }

  @override
  Future<NetworkResponse> deleteRequest(
    String url, {
    Map<String, dynamic>? queryParams,
  }) async {
    final id = Uri.parse(url).pathSegments.last;
    enviados.removeWhere((item) => item['id'] == id);
    return NetworkResponse(true, 204, null);
  }
}
