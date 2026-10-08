import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/personal_gestao_model.dart';

/// Repositório Offline-First para a Gestão do Personal Trainer (AppAcademia V003)
/// Gerencia alunos, vigência e alertas de treinos, frequência, feedbacks, agenda de aulas e financeiro simples.
class PersonalGestaoOfflineRepository {
  static const String _kAlunosKey = 'appacademia_personal_alunos_v1';
  static const String _kAgendasKey = 'appacademia_personal_agendas_v1';

  static final PersonalGestaoOfflineRepository _instance =
      PersonalGestaoOfflineRepository._internal();
  factory PersonalGestaoOfflineRepository() => _instance;
  PersonalGestaoOfflineRepository._internal();

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. Gestão de Alunos do Personal
  // ─────────────────────────────────────────────────────────────────────────────

  Future<List<PersonalAlunoGestaoModel>> getAlunos() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAlunosKey);

    List<PersonalAlunoGestaoModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = _seedAlunos();
      await _salvarAlunos(lista);
    } else {
      try {
        final decoded = json.decode(raw) as List<dynamic>;
        lista = decoded
            .map((e) =>
                PersonalAlunoGestaoModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[PersonalGestaoOfflineRepository] Erro decode alunos: $e');
        lista = _seedAlunos();
      }
    }
    return lista;
  }

  Future<void> _salvarAlunos(List<PersonalAlunoGestaoModel> alunos) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(alunos.map((e) => e.toMap()).toList());
    await prefs.setString(_kAlunosKey, jsonStr);
  }

  Future<void> salvarAluno(PersonalAlunoGestaoModel aluno) async {
    final lista = await getAlunos();
    final idx = lista.indexWhere((a) => a.id == aluno.id);
    if (idx >= 0) {
      lista[idx] = aluno;
    } else {
      lista.insert(0, aluno);
    }
    await _salvarAlunos(lista);
  }

  /// Define o período de vigência e alerta de troca do treino do aluno
  Future<void> definirValidadeTreino({
    required String alunoId,
    required int validadeDias,
    required String treinoNome,
  }) async {
    final lista = await getAlunos();
    final idx = lista.indexWhere((a) => a.id == alunoId);
    if (idx >= 0) {
      final hoje = DateTime.now();
      final vencimento = hoje.add(Duration(days: validadeDias));
      final alunoAtualizado = lista[idx].copyWith(
        treinoAtualNome: treinoNome,
        dataInicioTreino: hoje.toIso8601String().substring(0, 10),
        validadeTreinoDias: validadeDias,
        dataVencimentoTreino: vencimento.toIso8601String().substring(0, 10),
      );
      lista[idx] = alunoAtualizado;
      await _salvarAlunos(lista);
    }
  }

  /// Adiciona um feedback / comentário de treino vindo do aluno
  Future<void> adicionarFeedbackTreino({
    required String alunoId,
    required PersonalAlunoFeedbackModel feedback,
  }) async {
    final lista = await getAlunos();
    final idx = lista.indexWhere((a) => a.id == alunoId);
    if (idx >= 0) {
      final aluno = lista[idx];
      final novosFeedbacks = [feedback, ...aluno.feedbacks];
      lista[idx] = aluno.copyWith(
        feedbacks: novosFeedbacks,
        diasSemTreinar: 0,
        totalTreinosConcluidos: aluno.totalTreinosConcluidos + 1,
      );
      await _salvarAlunos(lista);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. Controle Financeiro Simples de Mensalidades
  // ─────────────────────────────────────────────────────────────────────────────

  /// Registra o recebimento do mês de um aluno
  Future<void> registrarRecebimentoMensalidade({
    required String alunoId,
    required String mesReferencia,
  }) async {
    final lista = await getAlunos();
    final idx = lista.indexWhere((a) => a.id == alunoId);
    if (idx >= 0) {
      final hoje = DateTime.now().toIso8601String().substring(0, 10);
      lista[idx] = lista[idx].copyWith(
        statusMensalidade: StatusMensalidadeAluno.pago,
        dataUltimoPagamento: hoje,
        mesReferencia: mesReferencia,
      );
      await _salvarAlunos(lista);
    }
  }

  /// Altera o status financeiro de um aluno (ex: marcar atrasado)
  Future<void> atualizarStatusFinanceiro({
    required String alunoId,
    required StatusMensalidadeAluno status,
  }) async {
    final lista = await getAlunos();
    final idx = lista.indexWhere((a) => a.id == alunoId);
    if (idx >= 0) {
      lista[idx] = lista[idx].copyWith(statusMensalidade: status);
      await _salvarAlunos(lista);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. Agenda de Aulas & Academias com Remarcação
  // ─────────────────────────────────────────────────────────────────────────────

  Future<List<PersonalAgendamentoAulaModel>> getAgendamentos() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAgendasKey);

    List<PersonalAgendamentoAulaModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = _seedAgendamentos();
      await _salvarAgendamentos(lista);
    } else {
      try {
        final decoded = json.decode(raw) as List<dynamic>;
        lista = decoded
            .map((e) => PersonalAgendamentoAulaModel.fromMap(
                e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[PersonalGestaoOfflineRepository] Erro decode agendas: $e');
        lista = _seedAgendamentos();
      }
    }
    return lista;
  }

  Future<void> _salvarAgendamentos(
      List<PersonalAgendamentoAulaModel> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(lista.map((e) => e.toMap()).toList());
    await prefs.setString(_kAgendasKey, jsonStr);
  }

  Future<void> agendarAula(PersonalAgendamentoAulaModel aula) async {
    final lista = await getAgendamentos();
    final idx = lista.indexWhere((a) => a.id == aula.id);
    if (idx >= 0) {
      lista[idx] = aula;
    } else {
      lista.insert(0, aula);
    }
    await _salvarAgendamentos(lista);
  }

  /// Remarcar aula com registro do motivo
  Future<void> remarcarAula({
    required String aulaId,
    required String novaData,
    required String novoHorarioInicio,
    required String novoHorarioFim,
    String? novaAcademia,
    String? motivo,
  }) async {
    final lista = await getAgendamentos();
    final idx = lista.indexWhere((a) => a.id == aulaId);
    if (idx >= 0) {
      final atual = lista[idx];
      lista[idx] = atual.copyWith(
        data: novaData,
        horarioInicio: novoHorarioInicio,
        horarioFim: novoHorarioFim,
        academiaNome: novaAcademia ?? atual.academiaNome,
        status: StatusAgendamentoAula.remarcada,
        motivoRemarcacao: motivo ?? 'Remarcado a pedido do aluno',
      );
      await _salvarAgendamentos(lista);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. Seed de Dados de Demonstração (MFIT Pro Standard)
  // ─────────────────────────────────────────────────────────────────────────────

  List<PersonalAlunoGestaoModel> _seedAlunos() {
    final hoje = DateTime.now();
    return [
      PersonalAlunoGestaoModel(
        id: 'aluno-1',
        nome: 'Lucas Mendonça',
        email: 'lucas.mendonca@email.com',
        telefone: '(11) 98765-4321',
        objetivo: 'Hipertrofia & Ganho de Massa',
        nivel: 'Avançado',
        ativo: true,
        treinoAtualNome: 'ABC Hipertrofia Pesada 4x',
        dataInicioTreino: hoje.subtract(const Duration(days: 40)).toIso8601String().substring(0, 10),
        validadeTreinoDias: 45,
        dataVencimentoTreino: hoje.add(const Duration(days: 5)).toIso8601String().substring(0, 10), // Vence em 5 dias (Alerta)
        diasSemTreinar: 1,
        frequenciaSemanalMedia: 5,
        volumeTotalKg: 48500.0,
        totalTreinosConcluidos: 28,
        valorMensalidade: 350.0,
        diaVencimento: 10,
        statusMensalidade: StatusMensalidadeAluno.pago,
        dataUltimoPagamento: hoje.toIso8601String().substring(0, 10),
        feedbacks: [
          PersonalAlunoFeedbackModel(
            id: 'fb-1',
            treinoId: 'treino-a',
            divisaoNome: 'Treino A - Peito e Tríceps',
            data: hoje.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10),
            rpe: 9,
            comentario: 'Supino Reto com 100kg foi até a falha na 4ª série! Ombro sem dores.',
            exercicioDestaque: 'Supino Reto com Barra',
          ),
          PersonalAlunoFeedbackModel(
            id: 'fb-2',
            treinoId: 'treino-c',
            divisaoNome: 'Treino C - Pernas Completo',
            data: hoje.subtract(const Duration(days: 3)).toIso8601String().substring(0, 10),
            rpe: 10,
            comentario: 'Agachamento livre muito pesado, precisei de 2min de descanso.',
            exercicioDestaque: 'Agachamento Livre com Barra',
          ),
        ],
      ),
      PersonalAlunoGestaoModel(
        id: 'aluno-2',
        nome: 'Camila Rodrigues',
        email: 'camila.rodrigues@email.com',
        telefone: '(11) 91234-5678',
        objetivo: 'Emagrecimento & Definição Glúteos',
        nivel: 'Intermediário',
        ativo: true,
        treinoAtualNome: 'Glúteos & Inferiores 360',
        dataInicioTreino: hoje.subtract(const Duration(days: 65)).toIso8601String().substring(0, 10),
        validadeTreinoDias: 60,
        dataVencimentoTreino: hoje.subtract(const Duration(days: 5)).toIso8601String().substring(0, 10), // Vencido há 5 dias!
        diasSemTreinar: 4, // Alerta assiduidade
        frequenciaSemanalMedia: 3,
        volumeTotalKg: 31200.0,
        totalTreinosConcluidos: 22,
        valorMensalidade: 300.0,
        diaVencimento: 5,
        statusMensalidade: StatusMensalidadeAluno.atrasado, // Em débito
        dataUltimoPagamento: hoje.subtract(const Duration(days: 35)).toIso8601String().substring(0, 10),
        feedbacks: [
          PersonalAlunoFeedbackModel(
            id: 'fb-3',
            treinoId: 'treino-b',
            divisaoNome: 'Treino B - Glúteos & Posterior',
            data: hoje.subtract(const Duration(days: 4)).toIso8601String().substring(0, 10),
            rpe: 8,
            comentario: 'Elevação pélvica rendeu bem com 80kg, sentindo muito o glúteo.',
            exercicioDestaque: 'Elevação Pélvica',
          ),
        ],
      ),
      PersonalAlunoGestaoModel(
        id: 'aluno-3',
        nome: 'Gabriel Santos',
        email: 'gabriel.santos@email.com',
        telefone: '(11) 99887-7665',
        objetivo: 'Condicionamento & Força',
        nivel: 'Iniciante',
        ativo: true,
        treinoAtualNome: 'Full Body Adaptação',
        dataInicioTreino: hoje.subtract(const Duration(days: 10)).toIso8601String().substring(0, 10),
        validadeTreinoDias: 30,
        dataVencimentoTreino: hoje.add(const Duration(days: 20)).toIso8601String().substring(0, 10),
        diasSemTreinar: 0,
        frequenciaSemanalMedia: 3,
        volumeTotalKg: 14500.0,
        totalTreinosConcluidos: 8,
        valorMensalidade: 280.0,
        diaVencimento: 15,
        statusMensalidade: StatusMensalidadeAluno.pendente,
        feedbacks: [
          PersonalAlunoFeedbackModel(
            id: 'fb-4',
            treinoId: 'treino-fb',
            divisaoNome: 'Treino Full Body A',
            data: hoje.toIso8601String().substring(0, 10),
            rpe: 6,
            comentario: 'Treino suave hoje, adaptando bem a postura no leg press.',
            exercicioDestaque: 'Leg Press 45',
          ),
        ],
      ),
    ];
  }

  List<PersonalAgendamentoAulaModel> _seedAgendamentos() {
    final hoje = DateTime.now().toIso8601String().substring(0, 10);
    return [
      PersonalAgendamentoAulaModel(
        id: 'agenda-1',
        alunoId: 'aluno-1',
        alunoNome: 'Lucas Mendonça',
        academiaNome: 'Ironberg Alphaville',
        data: hoje,
        horarioInicio: '07:00',
        horarioFim: '08:00',
        tipoAula: 'Musculação Acompanhada (Peito)',
        status: StatusAgendamentoAula.agendada,
        observacao: 'Foco em progressão de carga no supino e crossover.',
      ),
      PersonalAgendamentoAulaModel(
        id: 'agenda-2',
        alunoId: 'aluno-2',
        alunoNome: 'Camila Rodrigues',
        academiaNome: 'SmartFit Jardins',
        data: hoje,
        horarioInicio: '09:00',
        horarioFim: '10:00',
        tipoAula: 'Avaliação Física & Reavaliação de Ficha',
        status: StatusAgendamentoAula.agendada,
        observacao: 'Levar adipômetro e fita métrica para nova dobra cutânea.',
      ),
      PersonalAgendamentoAulaModel(
        id: 'agenda-3',
        alunoId: 'aluno-3',
        alunoNome: 'Gabriel Santos',
        academiaNome: 'BlueFit Paulista',
        data: hoje,
        horarioInicio: '18:00',
        horarioFim: '19:00',
        tipoAula: 'Musculação Acompanhada',
        status: StatusAgendamentoAula.remarcada,
        motivoRemarcacao: 'Aluno solicitou alteração das 17h para 18h devido a trânsito.',
        observacao: 'Ajuste de postura no agachamento.',
      ),
    ];
  }
}
