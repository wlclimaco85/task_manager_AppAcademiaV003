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
import 'package:task_manager_flutter/ui/screens/fitness/cadastro_inicial_screen.dart';

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
    final chave = s.token == null || s.token!.isEmpty
        ? null
        : '${s.login?.id}:${s.token}';
    if (_sessaoCarregada == chave) return;
    _sessaoCarregada = chave;
    if (chave != null && s.login?.id != null) {
      PerfilContaService().carregar().catchError(
            (Object _) => <String, dynamic>{},
          );
      _verificarPermissoesAluno();
      _carregarIndicadores(chave);
    }
  }

  Future<void> _carregarIndicadores(String chaveSessao) async {
    final ehAluno = !podeGerenciarAlunos(AuthUtility.userInfo);
    var incompleto = false;
    if (ehAluno) {
      await CadastroInicialService.buscarRemoto();
      final dados = await CadastroInicialService.carregar();
      final pendencias = CadastroInicialService.pendencias(dados);
      incompleto = pendencias.isNotEmpty;
      if (incompleto) {
        await FitnessPushNotificationService().agendarNotificacao(
          FitnessNotificationItem(
            id: 'cadastro_inicial_${AuthUtility.userInfo.login?.id ?? 'aluno'}',
            titulo: 'Complete seu cadastro inicial',
            corpo: 'Inclua sua foto e medidas para acompanhar sua evolução completa.',
            dataHora: DateTime.now(),
            tipo: 'cadastro_inicial',
          ),
        );
      }
    }
    final notificacoes = await FitnessPushNotificationService().getNotificacoes();
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

  Future<void> _abrirNotificacoes() async {
    var itens = await FitnessPushNotificationService().getNotificacoes();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .72),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text('Notificações', style: Theme.of(context).textTheme.titleLarge),
                ),
                Flexible(
                  child: itens.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('Nenhuma notificação por enquanto.')),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: itens.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = itens[index];
                            return ListTile(
                              key: ValueKey('notificacao_${item.id}'),
                              leading: Icon(
                                item.tipo == 'cadastro_inicial'
                                    ? Icons.person_outline
                                    : Icons.notifications_outlined,
                                color: item.lida ? context.appTextSecondary : GridColors.primary,
                              ),
                              title: Text(item.titulo,
                                  style: TextStyle(fontWeight: item.lida ? FontWeight.w500 : FontWeight.w700)),
                              subtitle: Text(item.corpo),
                              trailing: item.lida
                                  ? null
                                  : const Icon(Icons.circle, size: 10, color: GridColors.primary),
                              onTap: () async {
                                await FitnessPushNotificationService().marcarComoLida(item.id);
                                itens = await FitnessPushNotificationService().getNotificacoes();
                                setSheetState(() {});
                                if (item.tipo == 'cadastro_inicial' && sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                  await _abrirCadastroInicial();
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final chave = _sessaoCarregada;
    if (chave != null) await _carregarIndicadores(chave);
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
          if (sessao.token == null || sessao.token!.isEmpty)
            return widget.child;
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
                          child: InkWell(
                            onTap: widget.onEditar,
                            borderRadius: BorderRadius.circular(16),
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
                              onCadastroIncompleto: _abrirCadastroInicial,
                              onNotificacoes: _abrirNotificacoes,
                            ),
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
