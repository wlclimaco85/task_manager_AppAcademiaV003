import 'package:task_manager_flutter/data/services/perfil_conta_service.dart';
import 'package:flutter/material.dart';
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
import 'package:task_manager_flutter/ui/screens/fitness/cadastro_inicial_screen.dart';
import 'package:task_manager_flutter/ui/widgets/fitness_notificacoes_sheet.dart';

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
  @override
  void initState() {
    super.initState();
    AuthUtility.session.addListener(_atualizar);
    _atualizar();
  }

  void _atualizar() {
    final s = AuthUtility.userInfo;
    final chave = '${s.login?.id ?? s.data?.id ?? 'usuario'}:${s.token ?? ''}';
    if (_sessaoCarregada == chave) return;
    _sessaoCarregada = chave;
    PushRegistrationService().sincronizar();
    PerfilContaService()
        .carregar()
        .catchError((Object _) => <String, dynamic>{});
    _verificarPermissoesAluno();
    _carregarIndicadores(chave);
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
    final notificacoes =
        await FitnessPushNotificationService().getNotificacoes();
    if (!mounted || _sessaoCarregada != chaveSessao) return;
    setState(() {
      _cadastroIncompleto = incompleto;
      _notificacoesNaoLidas = notificacoes.where((item) => !item.lida).length;
    });
  }

  Future<void> _abrirCadastroInicial() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CadastroInicialScreen()),
    );
    final chave = _sessaoCarregada;
    if (chave != null) await _carregarIndicadores(chave);
  }

  Future<void> _avisarAvaliacaoInicialPendente() async {
    await mostrarDialogoAvaliacaoInicialPendente(
      context,
      onFazerAgora: _abrirCadastroInicial,
    );
  }

  Future<void> _abrirNotificacoes() async {
    final chave = _sessaoCarregada;
    await mostrarCentralNotificacoes(
      context,
      onAtualizarIndicadores: () {
        if (chave != null) _carregarIndicadores(chave);
      },
      onAbrirAvaliacaoInicial: _abrirCadastroInicial,
    );
  }

  String? _permissoesVerificadasPara;

  /// Aluno vinculado por um personal que ainda nao respondeu as permissoes: mostra o popup.
  /// Personal nao ve este popup; cada login e verificado uma vez por sessao.
  Future<void> _verificarPermissoesAluno() async {
    final sessao = AuthUtility.userInfo;
    if (podeGerenciarAlunos(sessao)) return;
    final chave = '${sessao.login?.id}';
    if (_permissoesVerificadasPara == chave) return;
    _permissoesVerificadasPara = chave;

    final estado = await PermissoesAlunoService.meu();
    // A conta pode ter trocado enquanto a consulta estava em voo: nao mostra nem grava
    // permissoes de outra conta.
    final contaAtual = '${AuthUtility.userInfo.login?.id}';
    if (!mounted || contaAtual != chave) return;
    if (estado == null || !estado.pendente) return;
    await showDialog<Map<String, bool>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PermissoesPersonalDialog(
        nomePersonal: 'seu personal',
        inicial: estado.permissoes,
      ),
    );
  }

  @override
  void dispose() {
    AuthUtility.session.removeListener(_atualizar);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<LoginModel>(
        valueListenable: AuthUtility.session,
        builder: (context, sessao, _) {
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
                            nome: sessao.perfilConta?['nome'] as String? ??
                                sessao.login?.nome ??
                                sessao.data?.codDadosPessoal?.nome ??
                                [
                                  sessao.data?.firstName,
                                  sessao.data?.lastName,
                                ].whereType<String>().join(' '),
                            foto: sessao.perfilConta?['foto'] as String? ??
                                sessao.login?.foto ??
                                sessao.data?.codDadosPessoal?.photo ??
                                sessao.data?.photo,
                            perfil: podeGerenciarAlunos(sessao)
                                ? 'Personal'
                                : sessao.login?.tipoLogin ==
                                        LoginEnum.APP_ALUNO
                                    ? 'Aluno'
                                    : 'Minha conta',
                            cadastroIncompleto: _cadastroIncompleto,
                            notificacoesNaoLidas: _notificacoesNaoLidas,
                            onEditar: widget.onEditar,
                            onCadastroIncompleto: _avisarAvaliacaoInicialPendente,
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
