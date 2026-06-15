// lib/data/utils/security_matrix.dart
//
// Matriz de segurança do sistema contabilidade_damiao.
//
// Hierarquia de acesso:
//   tipoLogin  →  MASTER | APP_CONTABILIDADE  (vem no login)
//   aplicativo →  contabilidade_damiao         (vem no login)
//   perfil     →  gerente | financeiro | faturista | ponto | system
//                 (mapeado a partir das roles do usuário)
//
// Uso:
//   final matrix = SecurityMatrix.of(AuthUtility.userInfo);
//   if (matrix.canView(AppScreen.contasPagar)) { ... }
//   if (matrix.canInsert(AppScreen.contasPagar)) { ... }

import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. Identificadores de telas / recursos
// ─────────────────────────────────────────────────────────────────────────────

enum AppScreen {
  fitness,
  academias,
  personais,
  dieta,
  medicamentos,
  suplementos,
  exames,
  treinos,
  exercicios,
  atividades,
  sono,
  batimentos,
  corpo,
  metas,
  alimentos,
  objetivos,
  avaliacaoFisica,
  grupoMuscular,
  modalidades,

  // ── Bottom Nav ──────────────────────────────────────────────────────────────
  calendario,
  chat,
  comunicados,
  chamados,
  ged,

  // ── Menu "Mais" ─────────────────────────────────────────────────────────────
  contasPagar,
  contasReceber,
  parceiros,
  dashboard,
  contasBancarias,
  ponto,

  // ── Dashboard – gráficos ────────────────────────────────────────────────────
  dashKpis,
  dashFinanceCards,
  dashFluxoDiario,
  dashTendenciaFinanceira,
  dashDistribuicaoClientes,
  dashComparativoTrimestral,
  dashAlertas,
  dashChamadosCards,
  dashChamadosPie,
  dashTendenciaChamados,
  dashChatsLinha,
  dashChatsDiario,
  dashSaldoContas,
  dashEvolucaoSaldos,
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Ações possíveis
// ─────────────────────────────────────────────────────────────────────────────

enum AppAction { view, insert, update, delete }

// ─────────────────────────────────────────────────────────────────────────────
// 3. Perfis internos do sistema
// ─────────────────────────────────────────────────────────────────────────────

enum UserProfile {
  system, // MASTER / acesso total
  gerente, // vê tudo, pode tudo exceto excluir dados financeiros
  financeiro, // contas pagar/receber/bancárias + dashboard financeiro
  academia, // AppAcademia: foco em treino, saude e atendimento
  faturista, // parceiros + chamados + comunicados + GED
  ponto, // apenas bater ponto + calendário
  semAcesso, // fallback
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Mapeamento role.key → UserProfile
// ─────────────────────────────────────────────────────────────────────────────

const Map<String, UserProfile> _roleKeyToProfile = {
  'ROLE_SYSTEM': UserProfile.system,
  'ROLE_GERENTE': UserProfile.gerente,
  'ROLE_ACADEMIA': UserProfile.academia,
  'ROLE_ALUNO': UserProfile.academia,
  'ROLE_PERSONAL': UserProfile.academia,
  'ROLE_NUTRICIONISTA': UserProfile.academia,
  'ROLE_FINANCEIRO': UserProfile.financeiro,
  'ROLE_FATURISTA': UserProfile.faturista,
  'ROLE_PONTO': UserProfile.ponto,
};

// ─────────────────────────────────────────────────────────────────────────────
// 5. Definição da matriz por perfil
//    Estrutura: Map<AppScreen, Set<AppAction>>
// ─────────────────────────────────────────────────────────────────────────────

const _allActions = {
  AppAction.view,
  AppAction.insert,
  AppAction.update,
  AppAction.delete
};
const _readOnly = {AppAction.view};
const _noInsertDelete = {AppAction.view, AppAction.update};
const _fitnessScreens = {
  AppScreen.fitness,
  AppScreen.academias,
  AppScreen.personais,
  AppScreen.dieta,
  AppScreen.medicamentos,
  AppScreen.suplementos,
  AppScreen.exames,
  AppScreen.treinos,
  AppScreen.exercicios,
  AppScreen.atividades,
  AppScreen.sono,
  AppScreen.batimentos,
  AppScreen.corpo,
  AppScreen.metas,
  AppScreen.alimentos,
  AppScreen.objetivos,
  AppScreen.avaliacaoFisica,
  AppScreen.grupoMuscular,
  AppScreen.modalidades,
};

final Map<UserProfile, Map<AppScreen, Set<AppAction>>> _matrix = {
  // ── SYSTEM: acesso total ───────────────────────────────────────────────────
  UserProfile.system: {
    for (final s in AppScreen.values) s: _allActions,
  },

  // ── GERENTE: vê tudo, CRUD completo exceto delete financeiro ──────────────
  UserProfile.gerente: {
    AppScreen.fitness: _readOnly,
    AppScreen.academias: _allActions,
    AppScreen.personais: _allActions,
    AppScreen.dieta: _allActions,
    AppScreen.medicamentos: _allActions,
    AppScreen.suplementos: _allActions,
    AppScreen.exames: _allActions,
    AppScreen.treinos: _allActions,
    AppScreen.exercicios: _allActions,
    AppScreen.atividades: _readOnly,
    AppScreen.sono: _readOnly,
    AppScreen.batimentos: _readOnly,
    AppScreen.corpo: _readOnly,
    AppScreen.metas: _allActions,
    AppScreen.alimentos: _allActions,
    AppScreen.objetivos: _allActions,
    AppScreen.avaliacaoFisica: _allActions,
    AppScreen.grupoMuscular: _allActions,
    AppScreen.modalidades: _allActions,
    AppScreen.calendario: _allActions,
    AppScreen.chat: _readOnly,
    AppScreen.comunicados: _allActions,
    AppScreen.chamados: _allActions,
    AppScreen.ged: _allActions,
    AppScreen.contasPagar: _noInsertDelete,
    AppScreen.contasReceber: _noInsertDelete,
    AppScreen.parceiros: _allActions,
    AppScreen.dashboard: _readOnly,
    AppScreen.contasBancarias: _noInsertDelete,
    AppScreen.ponto: _readOnly,
    // dashboard widgets
    AppScreen.dashKpis: _readOnly,
    AppScreen.dashFinanceCards: _readOnly,
    AppScreen.dashFluxoDiario: _readOnly,
    AppScreen.dashTendenciaFinanceira: _readOnly,
    AppScreen.dashDistribuicaoClientes: _readOnly,
    AppScreen.dashComparativoTrimestral: _readOnly,
    AppScreen.dashAlertas: _readOnly,
    AppScreen.dashChamadosCards: _readOnly,
    AppScreen.dashChamadosPie: _readOnly,
    AppScreen.dashTendenciaChamados: _readOnly,
    AppScreen.dashChatsLinha: _readOnly,
    AppScreen.dashChatsDiario: _readOnly,
    AppScreen.dashSaldoContas: _readOnly,
    AppScreen.dashEvolucaoSaldos: _readOnly,
  },

  // ── FINANCEIRO: foco em contas + dashboard financeiro ─────────────────────
  UserProfile.academia: {
    AppScreen.fitness: _readOnly,
    AppScreen.academias: _allActions,
    AppScreen.personais: _allActions,
    AppScreen.dieta: _allActions,
    AppScreen.medicamentos: _allActions,
    AppScreen.suplementos: _allActions,
    AppScreen.exames: _allActions,
    AppScreen.treinos: _allActions,
    AppScreen.exercicios: _allActions,
    AppScreen.atividades: _readOnly,
    AppScreen.sono: _readOnly,
    AppScreen.batimentos: _readOnly,
    AppScreen.corpo: _readOnly,
    AppScreen.metas: _allActions,
    AppScreen.alimentos: _allActions,
    AppScreen.objetivos: _allActions,
    AppScreen.avaliacaoFisica: _allActions,
    AppScreen.grupoMuscular: _allActions,
    AppScreen.modalidades: _allActions,
  },

  UserProfile.financeiro: {
    AppScreen.calendario: _readOnly,
    AppScreen.chat: _readOnly,
    AppScreen.comunicados: _readOnly,
    AppScreen.chamados: _readOnly,
    AppScreen.ged: _readOnly,
    AppScreen.contasPagar: _allActions,
    AppScreen.contasReceber: _allActions,
    AppScreen.parceiros: _readOnly,
    AppScreen.dashboard: _readOnly,
    AppScreen.contasBancarias: _allActions,
    AppScreen.ponto: {AppAction.view, AppAction.insert},
    // dashboard widgets — apenas financeiros
    AppScreen.dashKpis: _readOnly,
    AppScreen.dashFinanceCards: _readOnly,
    AppScreen.dashFluxoDiario: _readOnly,
    AppScreen.dashTendenciaFinanceira: _readOnly,
    AppScreen.dashDistribuicaoClientes: _readOnly,
    AppScreen.dashComparativoTrimestral: _readOnly,
    AppScreen.dashAlertas: _readOnly,
    AppScreen.dashSaldoContas: _readOnly,
    AppScreen.dashEvolucaoSaldos: _readOnly,
    // sem acesso a gráficos de chamados/chats
  },

  // ── FATURISTA: parceiros, chamados, comunicados, GED ──────────────────────
  UserProfile.faturista: {
    AppScreen.calendario: _readOnly,
    AppScreen.chat: _allActions,
    AppScreen.comunicados: _allActions,
    AppScreen.chamados: _allActions,
    AppScreen.ged: _allActions,
    AppScreen.parceiros: _allActions,
    AppScreen.contasPagar: _readOnly,
    AppScreen.contasReceber: _readOnly,
    AppScreen.dashboard: _readOnly,
    AppScreen.contasBancarias: _readOnly,
    AppScreen.ponto: {AppAction.view, AppAction.insert},
    // dashboard widgets — apenas chamados/chats
    AppScreen.dashChamadosCards: _readOnly,
    AppScreen.dashChamadosPie: _readOnly,
    AppScreen.dashTendenciaChamados: _readOnly,
    AppScreen.dashChatsLinha: _readOnly,
    AppScreen.dashChatsDiario: _readOnly,
  },

  // ── PONTO: apenas bater ponto e ver calendário ────────────────────────────
  UserProfile.ponto: {
    AppScreen.calendario: _readOnly,
    AppScreen.ponto: {AppAction.view, AppAction.insert},
    AppScreen.chat: _readOnly,
    AppScreen.comunicados: _readOnly,
  },

  // ── SEM ACESSO ─────────────────────────────────────────────────────────────
  UserProfile.semAcesso: {},
};

// ─────────────────────────────────────────────────────────────────────────────
// 6. Classe principal
// ─────────────────────────────────────────────────────────────────────────────

class SecurityMatrix {
  final UserProfile profile;
  final LoginEnum? tipoLogin;
  final String? aplicativoNome;

  /// Permissões vindas do banco (quando disponíveis).
  /// Chave: telaNome, Valor: conjunto de ações permitidas.
  final Map<String, Set<AppAction>> _backendPerms;

  const SecurityMatrix._({
    required this.profile,
    this.tipoLogin,
    this.aplicativoNome,
    Map<String, Set<AppAction>> backendPerms = const {},
  }) : _backendPerms = backendPerms;

  /// Constrói a matriz a partir do usuário logado.
  factory SecurityMatrix.of(LoginModel? userInfo) {
    if (userInfo == null) {
      return const SecurityMatrix._(profile: UserProfile.semAcesso);
    }

    final login = userInfo.login;
    final tipoLogin = login?.tipoLogin;
    final aplicativoNome = login?.aplicativo?.nome;

    // MASTER sempre tem acesso total
    if (tipoLogin == LoginEnum.MASTER) {
      return SecurityMatrix._(
        profile: UserProfile.system,
        tipoLogin: tipoLogin,
        aplicativoNome: aplicativoNome,
        backendPerms: {},
      );
    }

    // Verifica se é o aplicativo correto
    final appName = aplicativoNome?.toLowerCase() ?? '';
    final isSupportedApp = switch (tipoLogin) {
      LoginEnum.APP_ACADEMIA ||
      LoginEnum.APP_PERSONAL ||
      LoginEnum.APP_NUTRICIONISTA ||
      LoginEnum.APP_ALUNO ||
      LoginEnum.APP_CONTABILIDADE =>
        true,
      _ => appName.contains('academia') ||
          appName.contains('fitness') ||
          appName.contains('personal') ||
          appName.contains('nutricionista') ||
          appName.contains('aluno') ||
          appName.contains('forafit') ||
          appName.contains('contabilidade'),
    };

    if (!isSupportedApp) {
      return SecurityMatrix._(
        profile: UserProfile.semAcesso,
        tipoLogin: tipoLogin,
        aplicativoNome: aplicativoNome,
        backendPerms: {},
      );
    }

    // Resolve perfil pelas roles (para fallback)
    final roles = login?.roles ?? [];
    UserProfile resolved = UserProfile.semAcesso;

    const priority = [
      UserProfile.system,
      UserProfile.gerente,
      UserProfile.academia,
      UserProfile.financeiro,
      UserProfile.faturista,
      UserProfile.ponto,
    ];

    for (final p in priority) {
      final key = _roleKeyToProfile.entries
          .firstWhere((e) => e.value == p,
              orElse: () => const MapEntry('', UserProfile.semAcesso))
          .key;
      if (roles.any((r) => r.key == key)) {
        resolved = p;
        break;
      }
    }

    // Constrói mapa de permissões do banco (OR entre roles — tela liberada se
    // qualquer role do usuário tiver acesso)
    if (resolved == UserProfile.semAcesso &&
        (tipoLogin == LoginEnum.APP_ACADEMIA ||
            tipoLogin == LoginEnum.APP_PERSONAL ||
            tipoLogin == LoginEnum.APP_NUTRICIONISTA ||
            tipoLogin == LoginEnum.APP_ALUNO ||
            appName.contains('academia') ||
            appName.contains('fitness') ||
            appName.contains('forafit'))) {
      resolved = UserProfile.academia;
    }

    final backendPerms = <String, Set<AppAction>>{};
    if (userInfo.permissoes != null && userInfo.permissoes!.isNotEmpty) {
      for (final p in userInfo.permissoes!) {
        final existing = backendPerms[p.telaNome] ?? <AppAction>{};
        if (p.podeVer) existing.add(AppAction.view);
        if (p.podeInserir) existing.add(AppAction.insert);
        if (p.podeEditar) existing.add(AppAction.update);
        if (p.podeDeletar) existing.add(AppAction.delete);
        backendPerms[p.telaNome] = existing;
      }
    }

    return SecurityMatrix._(
      profile: resolved,
      tipoLogin: tipoLogin,
      aplicativoNome: aplicativoNome,
      backendPerms: backendPerms,
    );
  }

  /// Atalho para o usuário logado atual.
  factory SecurityMatrix.current() => SecurityMatrix.of(AuthUtility.userInfo);

  // ── Verificações ────────────────────────────────────────────────────────────

  bool _can(AppScreen screen, AppAction action) {
    // MASTER/SYSTEM: acesso total
    if (profile == UserProfile.system || tipoLogin == LoginEnum.MASTER) {
      return true;
    }

    // Se backend retornou permissões, usa elas (ignora matrix hardcoded)
    if (_backendPerms.isNotEmpty) {
      final backendActions = _backendPerms[screen.name];
      if (backendActions != null) {
        return backendActions.contains(action);
      }
      if (!_fitnessScreens.contains(screen)) {
        return false;
      }
    }

    // Fallback: matrix hardcoded
    return _matrix[profile]?[screen]?.contains(action) ?? false;
  }

  bool canView(AppScreen screen) => _can(screen, AppAction.view);
  bool canInsert(AppScreen screen) => _can(screen, AppAction.insert);
  bool canUpdate(AppScreen screen) => _can(screen, AppAction.update);
  bool canDelete(AppScreen screen) => _can(screen, AppAction.delete);

  /// Retorna true se o usuário tem pelo menos uma ação na tela.
  bool hasAnyAccess(AppScreen screen) {
    if (profile == UserProfile.system || tipoLogin == LoginEnum.MASTER) {
      return true;
    }
    if (_backendPerms.isNotEmpty) {
      final backendActions = _backendPerms[screen.name];
      if (backendActions != null) return backendActions.isNotEmpty;
      if (!_fitnessScreens.contains(screen)) return false;
    }
    return (_matrix[profile]?[screen]?.isNotEmpty) ?? false;
  }

  /// Lista todas as telas visíveis para o perfil atual.
  List<AppScreen> get visibleScreens =>
      AppScreen.values.where((s) => canView(s)).toList();

  /// Lista todas as telas do menu principal visíveis.
  List<AppScreen> get visibleMenuScreens => [
        AppScreen.fitness,
        AppScreen.academias,
        AppScreen.personais,
        AppScreen.dieta,
        AppScreen.medicamentos,
        AppScreen.suplementos,
        AppScreen.exames,
        AppScreen.exercicios,
        AppScreen.atividades,
        AppScreen.sono,
        AppScreen.batimentos,
        AppScreen.corpo,
        AppScreen.metas,
      ].where((s) => canView(s)).toList();

  /// Lista os widgets do dashboard visíveis para o perfil.
  List<AppScreen> get visibleDashboardWidgets => [
        AppScreen.dashKpis,
        AppScreen.dashFinanceCards,
        AppScreen.dashFluxoDiario,
        AppScreen.dashTendenciaFinanceira,
        AppScreen.dashDistribuicaoClientes,
        AppScreen.dashComparativoTrimestral,
        AppScreen.dashAlertas,
        AppScreen.dashChamadosCards,
        AppScreen.dashChamadosPie,
        AppScreen.dashTendenciaChamados,
        AppScreen.dashChatsLinha,
        AppScreen.dashChatsDiario,
        AppScreen.dashSaldoContas,
        AppScreen.dashEvolucaoSaldos,
      ].where((s) => canView(s)).toList();

  @override
  String toString() =>
      'SecurityMatrix(profile: $profile, tipo: $tipoLogin, app: $aplicativoNome, backendPerms: ${_backendPerms.length} telas)';
}
