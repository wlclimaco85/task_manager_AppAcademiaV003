import 'package:task_manager_flutter/data/services/perfil_conta_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/utils/fitness_access.dart';
import 'package:task_manager_flutter/data/services/permissoes_aluno_service.dart';
import 'package:task_manager_flutter/ui/widgets/permissoes_personal_dialog.dart';
import 'package:task_manager_flutter/ui/widgets/perfil_fitness_header.dart';
import 'package:task_manager_flutter/data/services/cadastro_inicial_service.dart';
import 'package:task_manager_flutter/data/services/fitness_push_notification_service.dart';
import 'package:task_manager_flutter/data/services/push_registration_service.dart';
import 'package:task_manager_flutter/app.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';
import 'package:task_manager_flutter/ui/screens/fitness/cadastro_inicial_screen.dart';
import 'package:task_manager_flutter/ui/widgets/fitness_notificacoes_sheet.dart';

/// Só falha de transporte (sem rede, timeout) conta como offline. Resposta de erro do
/// servidor (401, 403, 500) significa que o servidor foi alcançado, então está online.
bool ehFalhaDeConexao(Object erro) =>
    erro is http.ClientException || erro is TimeoutException;

/// Acima do Navigator para permanecer visível também nas telas abertas por push.
class AuthenticatedHeaderShell extends StatefulWidget {
  final Widget child;
  final VoidCallback onSair;
  final VoidCallback? onEditar;
  const AuthenticatedHeaderShell({
    super.key,
    required this.child,
    required this.onSair,
    this.onEditar,
  });

  @override
  State<AuthenticatedHeaderShell> createState() =>
      _AuthenticatedHeaderShellState();
}

class _AuthenticatedHeaderShellState extends State<AuthenticatedHeaderShell> {
  String? _sessaoCarregada;
  bool _cadastroIncompleto = false;
  int _notificacoesNaoLidas = 0;
  Timer? _atualizadorConta;
  bool _dialogPermissoesAberto = false;
  bool? _conexaoOnline;

  void _definirConexao(bool online) {
    if (!mounted || _conexaoOnline == online) return;
    setState(() => _conexaoOnline = online);
  }

  String? _textoPerfil(Map<String, dynamic>? perfil, List<String> chaves) {
    if (perfil == null) return null;
    for (final chave in chaves) {
      final valor = perfil[chave]?.toString().trim();
      if (valor != null && valor.isNotEmpty) return valor;
    }
    return null;
  }

  bool? _boolPerfil(Map<String, dynamic>? perfil, List<String> chaves) {
    if (perfil == null) return null;
    for (final chave in chaves) {
      final valor = perfil[chave];
      if (valor is bool) return valor;
      if (valor is num) return valor != 0;
      if (valor is String) {
        final normalizado = valor.trim().toLowerCase();
        if (normalizado == 'true' ||
            normalizado == 'online' ||
            normalizado == '1') return true;
        if (normalizado == 'false' ||
            normalizado == 'offline' ||
            normalizado == '0') return false;
      }
    }
    return null;
  }

  DateTime? _dataPerfil(Map<String, dynamic>? perfil, List<String> chaves) {
    final texto = _textoPerfil(perfil, chaves);
    return texto == null ? null : DateTime.tryParse(texto);
  }

  @override
  void initState() {
    super.initState();
    AuthUtility.session.addListener(_atualizar);
    FitnessPushNotificationService().mudancas.addListener(_atualizarContador);
    _atualizar();
    _atualizadorConta = Timer.periodic(const Duration(seconds: 15), (_) async {
      // Enquanto offline, tenta de novo: uma falha isolada não pode prender o status.
      if (_conexaoOnline != true) _atualizarConexao();
      await FitnessPushNotificationService().sincronizarRemotas();
      await _atualizarContador();
      await _verificarPermissoesAluno(forcar: true);
    });
  }

  Future<void> _atualizarContador() async {
    final notificacoes =
        await FitnessPushNotificationService().getNotificacoes();
    if (!mounted) return;
    setState(() => _notificacoesNaoLidas =
        notificacoes.where((item) => !item.lida).length);
  }

  void _atualizar() {
    final s = AuthUtility.userInfo;
    final chave = '${s.login?.id ?? s.data?.id ?? 'usuario'}:${s.token ?? ''}';
    if (_sessaoCarregada == chave) return;
    _sessaoCarregada = chave;
    PushRegistrationService().sincronizar();
    _atualizarConexao();
    _verificarPermissoesAluno();
    _carregarIndicadores(chave);
  }

  void _atualizarConexao() {
    PerfilContaService().carregar().then((_) {
      _definirConexao(true);
    }).catchError((Object erro) {
      _definirConexao(!ehFalhaDeConexao(erro));
    });
  }

  Future<void> _carregarIndicadores(String chaveSessao) async {
    final ehAluno = !podeGerenciarAlunos(AuthUtility.userInfo);
    var incompleto = false;
    if (ehAluno) {
      // 1. Carrega dados locais imediatamente (offline-first)
      var dados = await CadastroInicialService.carregar();
      var pendencias = CadastroInicialService.pendencias(dados);
      incompleto = pendencias.isNotEmpty;
      if (mounted && _sessaoCarregada == chaveSessao) {
        setState(() => _cadastroIncompleto = incompleto);
      }

      // 2. Tenta atualizar remotamente em segundo plano sem bloquear a UI
      try {
        await CadastroInicialService.buscarRemoto()
            .timeout(const Duration(seconds: 3));
        dados = await CadastroInicialService.carregar();
        pendencias = CadastroInicialService.pendencias(dados);
        incompleto = pendencias.isNotEmpty;
      } catch (_) {}

      if (incompleto) {
        await FitnessPushNotificationService().agendarNotificacao(
          FitnessNotificationItem(
            id: 'cadastro_inicial_${AuthUtility.userInfo.login?.id ?? 'aluno'}',
            titulo: 'Complete seu cadastro inicial',
            corpo:
                'Inclua sua foto e medidas para acompanhar sua evolução completa.',
            dataHora: DateTime.now(),
            tipo: 'cadastro_inicial',
          ),
        );
      }
    }
    await FitnessPushNotificationService().sincronizarRemotas();
    final notificacoes =
        await FitnessPushNotificationService().getNotificacoes();
    if (!mounted || _sessaoCarregada != chaveSessao) return;
    setState(() {
      _cadastroIncompleto = incompleto;
      _notificacoesNaoLidas = notificacoes.where((item) => !item.lida).length;
    });
  }

  BuildContext get _navContext =>
      TaskManagerApp.globalKey.currentContext ?? context;

  Future<void> _abrirCadastroInicial() async {
    final nav = TaskManagerApp.globalKey.currentState;
    if (nav != null) {
      await nav.push(
        MaterialPageRoute(builder: (_) => const CadastroInicialScreen()),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CadastroInicialScreen()),
      );
    }
    final chave = _sessaoCarregada;
    if (chave != null) await _carregarIndicadores(chave);
  }

  Future<void> _avisarAvaliacaoInicialPendente() async {
    final ctx = _navContext;
    try {
      await mostrarDialogoAvaliacaoInicialPendente(
        ctx,
        onFazerAgora: _abrirCadastroInicial,
      );
    } catch (e, stack) {
      AppLogger.i.error(
          'Erro ao abrir diálogo de avaliação inicial pendente: $e', stack);
    }
  }

  Future<void> _abrirNotificacoes() async {
    final chave = _sessaoCarregada;
    final ctx = _navContext;
    try {
      await FitnessPushNotificationService().sincronizarRemotas();
      if (!mounted || _sessaoCarregada != chave) return;
      await mostrarCentralNotificacoes(
        ctx,
        onAtualizarIndicadores: () {
          if (chave != null) _carregarIndicadores(chave);
        },
        onAbrirAvaliacaoInicial: _abrirCadastroInicial,
      );
    } catch (e, stack) {
      AppLogger.i.error('Erro ao abrir Central de Notificações: $e', stack);
    }
  }

  String? _permissoesVerificadasPara;

  /// Aluno vinculado por um personal que ainda nao respondeu as permissoes: mostra o popup.
  /// Personal nao ve este popup; cada login e verificado uma vez por sessao.
  Future<void> _verificarPermissoesAluno({bool forcar = false}) async {
    final sessao = AuthUtility.userInfo;
    if (podeGerenciarAlunos(sessao)) return;
    final chave = '${sessao.login?.id}';
    if (_dialogPermissoesAberto) return;
    if (!forcar && _permissoesVerificadasPara == chave) return;
    _permissoesVerificadasPara = chave;

    final estado = await PermissoesAlunoService.meu();
    // A conta pode ter trocado enquanto a consulta estava em voo: nao mostra nem grava
    // permissoes de outra conta.
    final contaAtual = '${AuthUtility.userInfo.login?.id}';
    if (!mounted || contaAtual != chave) return;
    if (estado == null || !estado.pendente) return;
    _dialogPermissoesAberto = true;
    try {
      await showDialog<Map<String, bool>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PermissoesPersonalDialog(
          nomePersonal: estado.personalNome,
          inicial: estado.permissoes,
          contrato: estado.contrato,
        ),
      );
    } finally {
      _dialogPermissoesAberto = false;
    }
  }

  @override
  void dispose() {
    _atualizadorConta?.cancel();
    AuthUtility.session.removeListener(_atualizar);
    FitnessPushNotificationService()
        .mudancas
        .removeListener(_atualizarContador);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<LoginModel>(
        valueListenable: AuthUtility.session,
        builder: (context, sessao, _) {
          final perfilConta = sessao.perfilConta;
          final temUsuario = sessao.login != null ||
              sessao.data != null ||
              sessao.perfilConta != null ||
              (sessao.token != null && sessao.token!.isNotEmpty);
          if (!temUsuario) return widget.child;
          return Column(
            children: [
              Material(
                color: context.appBackground,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: PerfilFitnessHeader(
                            nome: perfilConta?['nome'] as String? ??
                                sessao.login?.nome ??
                                sessao.data?.codDadosPessoal?.nome ??
                                [
                                  sessao.data?.firstName,
                                  sessao.data?.lastName,
                                ].whereType<String>().join(' '),
                            foto: perfilConta?['foto'] as String? ??
                                sessao.login?.foto ??
                                sessao.data?.codDadosPessoal?.photo ??
                                sessao.data?.photo,
                            perfil: podeGerenciarAlunos(sessao)
                                ? 'Personal'
                                : sessao.login?.tipoLogin == LoginEnum.APP_ALUNO
                                    ? 'Aluno'
                                    : 'Minha conta',
                            cadastroIncompleto: _cadastroIncompleto,
                            notificacoesNaoLidas: _notificacoesNaoLidas,
                            nomePersonal: _textoPerfil(perfilConta, const [
                              'personalNome',
                              'nomePersonal',
                              'personal_name',
                            ]),
                            minhaConexaoOnline: _conexaoOnline,
                            personalOnline: _boolPerfil(perfilConta, const [
                              'personalOnline',
                              'personalEstaOnline',
                              'personal_online',
                            ]),
                            ultimoTreino: _textoPerfil(perfilConta, const [
                              'ultimoTreino',
                              'ultimoTreinoNome',
                              'lastWorkout',
                            ]),
                            dataUltimoTreino: _dataPerfil(perfilConta, const [
                              'dataUltimoTreino',
                              'ultimoTreinoEm',
                              'lastWorkoutAt',
                            ]),
                            onEditar: widget.onEditar,
                            onCadastroIncompleto:
                                _avisarAvaliacaoInicialPendente,
                            onNotificacoes: _abrirNotificacoes,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: widget.onSair,
                          icon: const Icon(Icons.logout),
                          label: const Text('Sair'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(child: widget.child),
            ],
          );
        },
      );
}
