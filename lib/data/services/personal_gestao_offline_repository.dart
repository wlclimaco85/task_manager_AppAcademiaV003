import 'dart:convert';
import 'package:task_manager_flutter/data/services/fitness_conta_sync.dart';
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
    final raw = prefs.getString(FitnessContaSync.chave(_kAlunosKey + '_real'));

    List<PersonalAlunoGestaoModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = [];
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
        lista = [];
      }
    }
    return lista;
  }

  Future<void> _salvarAlunos(List<PersonalAlunoGestaoModel> alunos) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(alunos.map((e) => e.toMap()).toList());
    await prefs.setString(FitnessContaSync.chave(_kAlunosKey + '_real'), jsonStr);
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
    final raw = prefs.getString(FitnessContaSync.chave(_kAgendasKey + '_real'));

    List<PersonalAgendamentoAulaModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = [];
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
        lista = [];
      }
    }
    return lista;
  }

  Future<void> _salvarAgendamentos(
      List<PersonalAgendamentoAulaModel> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(lista.map((e) => e.toMap()).toList());
    await prefs.setString(FitnessContaSync.chave(_kAgendasKey + '_real'), jsonStr);
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




}
