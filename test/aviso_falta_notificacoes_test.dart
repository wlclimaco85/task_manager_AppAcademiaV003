import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/services/aviso_falta_repository.dart';
import 'package:task_manager_flutter/data/services/fitness_push_notification_service.dart';
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
    test('Aluno avisa que vai faltar e Personal marca como visto', () async {
      final repo = AvisoFaltaRepository();

      final aviso = await repo.enviar(
        remetenteId: 'aluno_1',
        remetenteNome: 'Carlos Aluno',
        remetenteTipo: 'aluno',
        destinatarioId: 'personal_99',
        destinatarioNome: 'Professor Rodrigo',
        dataAula: '19/10/2026',
        horario: '08:00',
        motivo: 'Consulta médica de rotina',
      );

      expect(aviso.id, isNotEmpty);
      expect(aviso.status, 'aguardando');
      expect(aviso.motivo, 'Consulta médica de rotina');

      // Personal lista avisos recebidos
      final recebidos = await repo.getRecebidos();
      expect(recebidos.length, 1);
      expect(recebidos.first.remetenteNome, 'Carlos Aluno');
      expect(recebidos.first.status, 'aguardando');
      expect(await repo.countNaoVistos(), 1);

      // Personal marca visto
      await repo.marcarComoVisto(aviso.id);

      // Consulta se foi atualizado
      final recebidosAtualizados = await repo.getRecebidos();
      expect(recebidosAtualizados.first.status, 'visto');
      expect(recebidosAtualizados.first.foiVisto, isTrue);
      expect(recebidosAtualizados.first.vistoEm, isNotNull);
      expect(await repo.countNaoVistos(), 0);

      // Aluno consulta enviados e vê que o status foi atualizado
      final enviados = await repo.getEnviados();
      expect(enviados.first.status, 'visto');
    });

    test('Personal avisa que não haverá aula e aluno recebe notificação', () async {
      final repo = AvisoFaltaRepository();

      final aviso = await repo.enviar(
        remetenteId: 'personal_99',
        remetenteNome: 'Professor Rodrigo',
        remetenteTipo: 'personal',
        destinatarioId: 'aluno_1',
        destinatarioNome: 'Carlos Aluno',
        dataAula: '20/10/2026',
        horario: '18:00',
        motivo: 'Imprevisto com transporte',
      );

      expect(aviso.remetenteTipo, 'personal');

      final notificacoes = await FitnessPushNotificationService().getNotificacoes();
      expect(notificacoes.any((n) => n.titulo.contains('Professor Rodrigo')), isTrue);
    });
  });

  group('Notificações Aluno x Personal expandidas', () {
    test('Mensalidade vencida, troca de treino, meta diária e feedbacks são gerados', () async {
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
      expect(notificacoes.any((n) => n.tipo == 'meta_dia_nao_cumprida'), isTrue);
      expect(notificacoes.any((n) => n.tipo == 'aviso_personal'), isTrue);
      expect(notificacoes.any((n) => n.tipo == 'aluno_treino_finalizado'), isTrue);
      expect(notificacoes.any((n) => n.tipo == 'aluno_comentario_treino'), isTrue);
    });
  });

  group('Validação dos 3 Temas Visuais (Padrão, Branco, Preto)', () {
    test('GridColors e CustomColors se adaptam dinamicamente ao tema selecionado', () {
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
