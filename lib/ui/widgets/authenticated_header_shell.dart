import 'package:task_manager_flutter/data/services/perfil_conta_service.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/utils/fitness_access.dart';
import 'package:task_manager_flutter/data/services/permissoes_aluno_service.dart';
import 'package:task_manager_flutter/ui/widgets/permissoes_personal_dialog.dart';
import 'package:task_manager_flutter/ui/widgets/perfil_fitness_header.dart';

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
    }
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
    if (!mounted || estado == null || !estado.pendente) return;
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
                color: GridColors.background,
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
