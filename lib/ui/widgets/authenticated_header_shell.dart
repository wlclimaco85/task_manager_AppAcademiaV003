import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/utils/fitness_access.dart';
import 'package:task_manager_flutter/ui/widgets/perfil_fitness_header.dart';

/// Acima do Navigator para permanecer visível também nas telas abertas por push.
class AuthenticatedHeaderShell extends StatelessWidget {
  final Widget child;
  final VoidCallback onSair;
  const AuthenticatedHeaderShell({super.key, required this.child, required this.onSair});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<LoginModel>(
    valueListenable: AuthUtility.session,
    builder: (context, sessao, _) {
      if (sessao.token == null || sessao.token!.isEmpty) return child;
      return Column(children: [
        Material(color: GridColors.background, child: SafeArea(bottom: false,
          child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
            Expanded(child: PerfilFitnessHeader(
              nome: sessao.login?.nome ?? sessao.data?.codDadosPessoal?.nome ??
                [sessao.data?.firstName, sessao.data?.lastName].whereType<String>().join(' '),
              foto: sessao.data?.codDadosPessoal?.photo ?? sessao.data?.photo,
              perfil: podeGerenciarAlunos(sessao) ? 'Personal' :
                sessao.login?.tipoLogin == LoginEnum.APP_ALUNO ? 'Aluno' : 'Minha conta',
            )),
            const SizedBox(width: 8),
            TextButton.icon(onPressed: onSair, icon: const Icon(Icons.logout),
              label: const Text('Sair')),
          ])),
        )),
        Expanded(child: child),
      ]);
    },
  );
}
