import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/personal_gestao_model.dart';
import 'package:task_manager_flutter/data/services/personal_gestao_offline_repository.dart';

/// Alunos e agenda de teste, criados pelo proprio teste. A gestao nao traz mais
/// dados de demonstracao: cada cenario prepara os registros que usa.
PersonalAlunoGestaoModel _alunoLucas() => PersonalAlunoGestaoModel(
      id: 'aluno-1',
      nome: 'Lucas Mendonça',
      email: 'lucas@example.invalid',
      telefone: '(34) 99999-0001',
      treinoAtualNome: 'Treino ABC',
      dataVencimentoTreino: DateTime.now().add(const Duration(days: 5)).toIso8601String(),
      feedbacks: const [
        PersonalAlunoFeedbackModel(
          id: 'fb-1',
          treinoId: 'treino-1',
          divisaoNome: 'Peito',
          data: '2026-10-08',
          rpe: 9,
          comentario: 'Pesado demais na ultima serie',
        ),
      ],
    );

PersonalAlunoGestaoModel _alunaCamila() => PersonalAlunoGestaoModel(
      id: 'aluno-2',
      nome: 'Camila Rodrigues',
      email: 'camila@example.invalid',
      telefone: '(34) 99999-0002',
      treinoAtualNome: 'Treino Full Body',
      dataVencimentoTreino: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      diasSemTreinar: 4,
      statusMensalidade: StatusMensalidadeAluno.atrasado,
    );

PersonalAlunoGestaoModel _alunoTerceiro() => PersonalAlunoGestaoModel(
      id: 'aluno-3',
      nome: 'Pedro Almeida',
      email: 'pedro@example.invalid',
      telefone: '(34) 99999-0003',
      treinoAtualNome: 'Treino Superior',
      dataVencimentoTreino: DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    );

PersonalAgendamentoAulaModel _aulaAgendada() => const PersonalAgendamentoAulaModel(
      id: 'agenda-1',
      alunoId: 'aluno-1',
      alunoNome: 'Lucas Mendonça',
      academiaNome: 'Ironberg Alphaville',
      data: '2026-10-08',
      horarioInicio: '10:00',
      horarioFim: '11:00',
    );

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Suite de Gestão do Personal Trainer (MFIT Pro Standard)', () {
    test('1. Alunos do Personal: seed e cálculo de alertas de vigência de ficha', () async {
      final repo = PersonalGestaoOfflineRepository();
      await repo.salvarAluno(_alunoLucas());
      await repo.salvarAluno(_alunaCamila());
      await repo.salvarAluno(_alunoTerceiro());
      final alunos = await repo.getAlunos();

      expect(alunos.isNotEmpty, isTrue);
      expect(alunos.length, greaterThanOrEqualTo(3));

      // Aluno 1: ficha prestes a vencer (5 dias)
      final lucas = alunos.firstWhere((a) => a.id == 'aluno-1');
      expect(lucas.nome, equals('Lucas Mendonça'));
      expect(lucas.alertaTreinoVencendo, isTrue);
      expect(lucas.feedbacks.isNotEmpty, isTrue);
      expect(lucas.feedbacks.first.rpe, equals(9));

      // Aluno 2: ficha vencida e inadimplente
      final camila = alunos.firstWhere((a) => a.id == 'aluno-2');
      expect(camila.treinoVencido, isTrue);
      expect(camila.alertaInadimplente, isTrue);
      expect(camila.diasSemTreinar, equals(4));
    });

    test('2. Definir Vigência de Treino e Atualização do Alerta de Troca', () async {
      final repo = PersonalGestaoOfflineRepository();
      await repo.salvarAluno(_alunoLucas());
      await repo.definirValidadeTreino(
        alunoId: 'aluno-1',
        validadeDias: 60,
        treinoNome: 'Novo Treino Periodizado ABCD',
      );

      final alunos = await repo.getAlunos();
      final lucas = alunos.firstWhere((a) => a.id == 'aluno-1');
      expect(lucas.treinoAtualNome, equals('Novo Treino Periodizado ABCD'));
      expect(lucas.validadeTreinoDias, equals(60));
      expect(lucas.alertaTreinoVencendo, isFalse);
    });

    test('3. Controle Financeiro Simples: Dar Baixa / Receber Mensalidade', () async {
      final repo = PersonalGestaoOfflineRepository();
      await repo.salvarAluno(_alunaCamila());

      // Camila está atrasada inicialmente
      var alunos = await repo.getAlunos();
      var camila = alunos.firstWhere((a) => a.id == 'aluno-2');
      expect(camila.statusMensalidade, equals(StatusMensalidadeAluno.atrasado));

      // Registrar recebimento
      await repo.registrarRecebimentoMensalidade(
        alunoId: 'aluno-2',
        mesReferencia: '10/2026',
      );

      alunos = await repo.getAlunos();
      camila = alunos.firstWhere((a) => a.id == 'aluno-2');
      expect(camila.statusMensalidade, equals(StatusMensalidadeAluno.pago));
      expect(camila.alertaInadimplente, isFalse);
      expect(camila.dataUltimoPagamento, isNotNull);
    });

    test('4. Agenda de Aulas por Academia e Remarcação com Motivo', () async {
      final repo = PersonalGestaoOfflineRepository();
      await repo.agendarAula(_aulaAgendada());
      final agendas = await repo.getAgendamentos();

      expect(agendas.isNotEmpty, isTrue);
      final aula1 = agendas.firstWhere((a) => a.id == 'agenda-1');
      expect(aula1.academiaNome, equals('Ironberg Alphaville'));
      expect(aula1.status, equals(StatusAgendamentoAula.agendada));

      // Remarcar aula
      await repo.remarcarAula(
        aulaId: 'agenda-1',
        novaData: '2026-10-09',
        novoHorarioInicio: '11:00',
        novoHorarioFim: '12:00',
        novaAcademia: 'SmartFit Paulista',
        motivo: 'Choque de horário com avaliação física',
      );

      final agendasAtualizadas = await repo.getAgendamentos();
      final aulaRemarcada =
          agendasAtualizadas.firstWhere((a) => a.id == 'agenda-1');
      expect(aulaRemarcada.status, equals(StatusAgendamentoAula.remarcada));
      expect(aulaRemarcada.horarioInicio, equals('11:00'));
      expect(aulaRemarcada.academiaNome, equals('SmartFit Paulista'));
      expect(aulaRemarcada.motivoRemarcacao, contains('Choque de horário'));
    });
  });
}
