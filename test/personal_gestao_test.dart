import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/personal_gestao_model.dart';
import 'package:task_manager_flutter/data/services/personal_gestao_offline_repository.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Suite de Gestão do Personal Trainer (MFIT Pro Standard)', () {
    test('1. Alunos do Personal: seed e cálculo de alertas de vigência de ficha', () async {
      final repo = PersonalGestaoOfflineRepository();
      final alunos = await repo.getAlunos();

      expect(alunos.isNotEmpty, isTrue);
      expect(alunos.length, greaterThanOrEqualTo(3));

      // Verificar aluno 1 (Lucas Mendonça - Ficha prestes a vencer em 5 dias)
      final lucas = alunos.firstWhere((a) => a.id == 'aluno-1');
      expect(lucas.nome, equals('Lucas Mendonça'));
      expect(lucas.alertaTreinoVencendo, isTrue);
      expect(lucas.feedbacks.isNotEmpty, isTrue);
      expect(lucas.feedbacks.first.rpe, equals(9));

      // Verificar aluno 2 (Camila Rodrigues - Ficha vencida e inadimplente)
      final camila = alunos.firstWhere((a) => a.id == 'aluno-2');
      expect(camila.treinoVencido, isTrue);
      expect(camila.alertaInadimplente, isTrue);
      expect(camila.diasSemTreinar, equals(4));
    });

    test('2. Definir Vigência de Treino e Atualização do Alerta de Troca', () async {
      final repo = PersonalGestaoOfflineRepository();
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
