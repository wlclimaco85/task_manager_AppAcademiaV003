import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/tenant_context.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';
import 'package:task_manager_flutter/data/services/fitness_conta_sync.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/personal_gestao_model.dart';
import 'package:task_manager_flutter/data/models/fitness/personal_conta_pagar_model.dart';
import 'package:task_manager_flutter/data/models/fitness/personal_pix_cobranca_model.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';

/// Repositório Offline-First para a Gestão do Personal Trainer (AppAcademia V003)
/// Gerencia alunos, vigência e alertas de treinos, frequência, feedbacks, agenda de aulas e financeiro simples.
class PersonalGestaoOfflineRepository {
  static const String _kAlunosKey = 'appacademia_personal_alunos_v1';
  static const String _kAgendasKey = 'appacademia_personal_agendas_v1';
  static const String _kContasPagarKey = 'appacademia_personal_contas_pagar_v1';
  static const String _kPixCobrancaKey = 'appacademia_personal_pix_cobranca_v1';

  static final PersonalGestaoOfflineRepository _instance =
      PersonalGestaoOfflineRepository._internal();
  factory PersonalGestaoOfflineRepository() => _instance;
  PersonalGestaoOfflineRepository._internal();

  String get _url =>
      ApiLinks.fitnessResumo.replaceFirst('/resumo', '/personal');
  String get _filaKey => FitnessContaSync.chave('personal_pendentes_v1');
  bool _sincronizando = false;
  Map<String, dynamic> _fila(SharedPreferences p) =>
      Map<String, dynamic>.from(jsonDecode(p.getString(_filaKey) ?? '{}'));

  Future<void> _enfileirar(String caminho, Map<String, dynamic> dados) async {
    final p = await SharedPreferences.getInstance();
    final fila = _fila(p)..[caminho] = dados;
    await p.setString(_filaKey, jsonEncode(fila));
    await sincronizarPendencias();
  }

  Future<void> sincronizarPendencias() async {
    if (!FitnessContaSync.autenticado || _sincronizando) return;
    _sincronizando = true;
    final p = await SharedPreferences.getInstance();
    final key = _filaKey;
    final enviados = _fila(p);
    final headers = {
      ...TenantContext.headers,
      'Content-Type': 'application/json'
    };
    try {
      for (final e in enviados.entries) {
        final response = await http
            .put(Uri.parse('$_url${e.key}'),
                headers: headers, body: jsonEncode(e.value))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final atual =
              Map<String, dynamic>.from(jsonDecode(p.getString(key) ?? '{}'));
          if (jsonEncode(atual[e.key]) == jsonEncode(e.value)) {
            atual.remove(e.key);
            await p.setString(key, jsonEncode(atual));
          }
        } else {
          AppLogger.i
              .warn('Gestão do personal pendente: HTTP ${response.statusCode}');
        }
      }
    } catch (e, stack) {
      AppLogger.i
          .error('Gestão preservada offline; sincronização pendente.', stack);
    } finally {
      _sincronizando = false;
    }
  }

  Future<List<Map<String, dynamic>>?> _lerRemoto(String caminho) async {
    if (!FitnessContaSync.autenticado) return null;
    final conta = _filaKey;
    try {
      final response = await http
          .get(Uri.parse('$_url$caminho'), headers: TenantContext.headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 || conta != _filaKey) return null;
      return (jsonDecode(response.body)['data'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e, stack) {
      AppLogger.i
          .error('Leitura personal indisponível; usando cache real.', stack);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> buscarAlunos(String busca) async {
    final resultado = await _lerRemoto(
        '/buscar-alunos?q=${Uri.encodeQueryComponent(busca.trim())}');
    if (resultado == null)
      throw Exception('Não foi possível buscar alunos. Verifique sua conexão.');
    return resultado;
  }

  Future<PersonalAlunoGestaoModel> vincularAluno(
    String alunoId, {
    required Map<String, dynamic> contrato,
  }) async {
    final r = await http
        .post(Uri.parse('$_url/alunos/vincular'),
            headers: {
              ...TenantContext.headers,
              'Content-Type': 'application/json'
            },
            body: jsonEncode({'alunoId': alunoId, 'contrato': contrato}))
        .timeout(const Duration(seconds: 10));
    if (r.statusCode != 200)
      throw Exception(
          'Não foi possível vincular o aluno. Verifique se ele já possui outro personal.');
    final json = jsonDecode(r.body);
    return PersonalAlunoGestaoModel.fromMap(
        Map<String, dynamic>.from(json['data'] ?? json));
  }

  Future<List<Map<String, dynamic>>> getPlanosCobranca() async {
    final p = await SharedPreferences.getInstance();
    final key = FitnessContaSync.chave('personal_planos_cobranca');
    final remoto = await _lerRemoto('/planos');
    if (remoto != null) await p.setString(key, jsonEncode(remoto));
    return (jsonDecode(p.getString(key) ?? '[]') as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<SessaoTreinoRegistroModel>> getHistoricoAluno(
      String alunoId) async {
    final p = await SharedPreferences.getInstance();
    final key = FitnessContaSync.chave('personal_sessoes_$alunoId');
    final remoto = await _lerRemoto('/alunos/$alunoId/sessoes');
    if (remoto != null) await p.setString(key, jsonEncode(remoto));
    return (jsonDecode(p.getString(key) ?? '[]') as List)
        .map((e) =>
            SessaoTreinoRegistroModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> getDesempenhoAluno(String alunoId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = FitnessContaSync.chave('personal_desempenho_$alunoId');
    try {
      final response = await http
          .get(Uri.parse('$_url/alunos/$alunoId/desempenho'),
              headers: TenantContext.headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body is Map ? body['data'] : null;
        if (data is Map) {
          final resultado = Map<String, dynamic>.from(data);
          await prefs.setString(key, jsonEncode(resultado));
          return resultado;
        }
      }
    } catch (e, stack) {
      AppLogger.i.error(
          'Desempenho do aluno indisponível; usando o último cache.', stack);
    }
    return Map<String, dynamic>.from(
        jsonDecode(prefs.getString(key) ?? '{}') as Map);
  }

  Future<bool> publicarTreino(String alunoId, PlanoTreinoModel plano) async {
    final caminho = '/alunos/$alunoId/planos/${plano.id}';
    await _enfileirar(caminho, plano.toMap());
    return !_fila(await SharedPreferences.getInstance()).containsKey(caminho);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. Gestão de Alunos do Personal
  // ─────────────────────────────────────────────────────────────────────────────

  Future<List<PersonalAlunoGestaoModel>> getAlunos() async {
    final prefs = await SharedPreferences.getInstance();
    // Migra cadastros locais reais já existentes antes da primeira leitura remota.
    final migrado = FitnessContaSync.chave('personal_gestao_backend_v1');
    final localKey = FitnessContaSync.chave(_kAlunosKey + '_real');
    if (prefs.getBool(migrado) != true && FitnessContaSync.autenticado) {
      final locais = jsonDecode(prefs.getString(localKey) ?? '[]') as List;
      final fila = _fila(prefs);
      for (final aluno in locais) {
        final documento = Map<String, dynamic>.from(aluno);
        // O formulário anterior gravava este e-mail fixo sem perguntar ao usuário.
        if (documento['email'] == 'aluno@email.com') documento['email'] = '';
        fila.putIfAbsent('/alunos/${aluno['id']}', () => documento);
      }
      await prefs.setString(_filaKey, jsonEncode(fila));
      await prefs.setBool(migrado, true);
    }
    await sincronizarPendencias();
    final remoto = await _lerRemoto('/alunos');
    if (localKey != FitnessContaSync.chave(_kAlunosKey + '_real')) return [];
    if (remoto != null) {
      final porId = {for (final e in remoto) e['id'].toString(): e};
      for (final e in _fila(prefs).entries.where(
          (e) => e.key.startsWith('/alunos/') && !e.key.contains('/planos/'))) {
        porId[e.value['id'].toString()] = Map<String, dynamic>.from(e.value);
      }
      await prefs.setString(FitnessContaSync.chave(_kAlunosKey + '_real'),
          jsonEncode(porId.values.toList()));
    }
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
    await prefs.setString(
        FitnessContaSync.chave(_kAlunosKey + '_real'), jsonStr);
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
    await _enfileirar('/alunos/${aluno.id}', aluno.toMap());
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
      await _enfileirar('/alunos/${lista[idx].id}', lista[idx].toMap());
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
      await _enfileirar('/alunos/${lista[idx].id}', lista[idx].toMap());
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
      await _enfileirar('/alunos/${lista[idx].id}', lista[idx].toMap());
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
      await _enfileirar('/alunos/${lista[idx].id}', lista[idx].toMap());
    }
  }

  /// Liga/desliga a ocultacao da ficha de treino do aluno (decisao do personal).
  Future<void> definirFichaOculta(
      {required String alunoId, required bool oculta}) async {
    final lista = await getAlunos();
    final idx = lista.indexWhere((a) => a.id == alunoId);
    if (idx >= 0) {
      lista[idx] = lista[idx].copyWith(fichaOcultaParaAluno: oculta);
      await _salvarAlunos(lista);
      await _enfileirar('/alunos/${lista[idx].id}', lista[idx].toMap());
    }
  }

  /// Verifica se o aluno logado tem sua ficha de treino marcada como oculta pelo personal.
  Future<bool> isFichaOcultaParaAlunoAtual() async {
    final login = AuthUtility.userInfo.login;
    final loginId = login?.id?.toString() ?? '';
    final email = (login?.email ?? '').trim().toLowerCase();

    final alunos = await getAlunos();
    for (final a in alunos) {
      final matchId =
          loginId.isNotEmpty && (a.loginId == loginId || a.id == loginId);
      final matchEmail =
          email.isNotEmpty && a.email.trim().toLowerCase() == email;
      if (matchId || matchEmail) {
        return a.fichaOcultaParaAluno;
      }
    }
    return false;
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
            .map((e) =>
                PersonalAgendamentoAulaModel.fromMap(e as Map<String, dynamic>))
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
    await prefs.setString(
        FitnessContaSync.chave(_kAgendasKey + '_real'), jsonStr);
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
  // 4. Gestão de Contas a Pagar do Personal
  // ─────────────────────────────────────────────────────────────────────────────

  Future<List<PersonalContaPagarModel>> getContasPagar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw =
        prefs.getString(FitnessContaSync.chave(_kContasPagarKey + '_real'));

    List<PersonalContaPagarModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = _seedContasPagarIniciais();
      await _salvarContasPagar(lista);
    } else {
      try {
        final decoded = json.decode(raw) as List<dynamic>;
        lista = decoded
            .map((e) =>
                PersonalContaPagarModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint(
            '[PersonalGestaoOfflineRepository] Erro decode contas a pagar: $e');
        lista = [];
      }
    }
    // Ordena por data de vencimento
    lista.sort((a, b) => a.dataVencimento.compareTo(b.dataVencimento));
    return lista;
  }

  Future<void> _salvarContasPagar(List<PersonalContaPagarModel> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(lista.map((e) => e.toMap()).toList());
    await prefs.setString(
        FitnessContaSync.chave(_kContasPagarKey + '_real'), jsonStr);
  }

  Future<void> salvarContaPagar(PersonalContaPagarModel conta) async {
    final lista = await getContasPagar();
    final idx = lista.indexWhere((c) => c.id == conta.id);
    if (idx >= 0) {
      lista[idx] = conta;
    } else {
      lista.add(conta);
    }
    await _salvarContasPagar(lista);
  }

  Future<void> excluirContaPagar(String contaId) async {
    final lista = await getContasPagar();
    lista.removeWhere((c) => c.id == contaId);
    await _salvarContasPagar(lista);
  }

  Future<void> registrarPagamentoConta(String contaId,
      {bool pago = true}) async {
    final lista = await getContasPagar();
    final idx = lista.indexWhere((c) => c.id == contaId);
    if (idx >= 0) {
      final atual = lista[idx];
      lista[idx] = atual.copyWith(
        pago: pago,
        dataPagamento: pago ? DateTime.now() : null,
      );
      await _salvarContasPagar(lista);
    }
  }

  List<PersonalContaPagarModel> _seedContasPagarIniciais() {
    final agora = DateTime.now();
    return [
      PersonalContaPagarModel(
        id: 'pagar_1',
        descricao: 'Aluguel Espaço Academia Smart',
        categoria: CategoriaContaPagar.espacoAcademia,
        valor: 450.00,
        dataVencimento: DateTime(agora.year, agora.month, 10),
        pago: true,
        dataPagamento: DateTime(agora.year, agora.month, 10),
        observacao: 'Repasse fixo para atendimento presencial',
      ),
      PersonalContaPagarModel(
        id: 'pagar_2',
        descricao: 'Anuidade Conselho Regional CREF',
        categoria: CategoriaContaPagar.cref,
        valor: 180.00,
        dataVencimento: DateTime(agora.year, agora.month, 25),
        pago: false,
        observacao: 'Parcela 03/06',
      ),
      PersonalContaPagarModel(
        id: 'pagar_3',
        descricao: 'Anúncios Instagram & Marketing Alunos',
        categoria: CategoriaContaPagar.marketing,
        valor: 120.00,
        dataVencimento: DateTime(agora.year, agora.month, 28),
        pago: false,
        observacao: 'Campanha novos alunos consultoria',
      ),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. Configuração de Cobrança Pix & Mensalidade do Personal
  // ─────────────────────────────────────────────────────────────────────────────

  Future<PersonalPixCobrancaModel> getPixCobranca() async {
    final prefs = await SharedPreferences.getInstance();
    final raw =
        prefs.getString(FitnessContaSync.chave(_kPixCobrancaKey + '_real'));

    if (raw == null || raw.isEmpty) {
      return PersonalPixCobrancaModel();
    }
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return PersonalPixCobrancaModel.fromMap(decoded);
    } catch (e) {
      debugPrint(
          '[PersonalGestaoOfflineRepository] Erro decode pix cobranca: $e');
      return PersonalPixCobrancaModel();
    }
  }

  Future<void> salvarPixCobranca(PersonalPixCobrancaModel pix) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      FitnessContaSync.chave(_kPixCobrancaKey + '_real'),
      pix.toJson(),
    );
  }
}
