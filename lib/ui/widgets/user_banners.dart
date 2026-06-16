import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/configurar_colunas_dialog.dart';
import 'package:task_manager_flutter/ui/widgets/logout_dialog.dart';
import 'package:task_manager_flutter/ui/widgets/notificacoes_drawer.dart';

class UserBannerAppBar extends StatelessWidget {
  final String nomeUsuario;
  final String? cargo;
  final VoidCallback? onConfigurarColunas;
  final bool mostrarConfigurarColunas;

  const UserBannerAppBar({
    super.key,
    required this.nomeUsuario,
    this.cargo,
    this.onConfigurarColunas,
    this.mostrarConfigurarColunas = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _AvatarUsuario(nomeUsuario: nomeUsuario),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomeUsuario,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (cargo != null && cargo!.isNotEmpty)
                  Text(
                    cargo!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.75),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          _NotifBellButton(),
          if (mostrarConfigurarColunas) ...[
            const SizedBox(width: 4),
            _ConfigColunasButton(onPressed: onConfigurarColunas),
          ],
          const SizedBox(width: 4),
          _LogoutButton(isWide: isWide),
        ],
      ),
    );
  }
}

class FilterActionBar extends StatelessWidget {
  final List<Widget> actions;

  const FilterActionBar({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: actions,
      ),
    );
  }
}

class UserListTile extends StatelessWidget {
  final String nome;
  final String? subtitulo;
  final String? cargo;
  final bool ativo;
  final VoidCallback? onTap;
  final VoidCallback? onConfigurarColunas;
  final VoidCallback? onExcluir;

  const UserListTile({
    super.key,
    required this.nome,
    this.subtitulo,
    this.cargo,
    this.ativo = true,
    this.onTap,
    this.onConfigurarColunas,
    this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: _AvatarUsuario(nomeUsuario: nome),
      title: Text(
        nome,
        style: theme.textTheme.bodyLarge,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: _buildSubtitle(theme),
      trailing: _buildTrailing(context),
      onTap: onTap,
      tileColor: ativo
          ? null
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
    );
  }

  Widget? _buildSubtitle(ThemeData theme) {
    final parts = <String>[
      if (cargo != null && cargo!.isNotEmpty) cargo!,
      if (!ativo) 'Inativo',
    ];
    if (parts.isEmpty && (subtitulo == null || subtitulo!.isEmpty)) {
      return null;
    }
    return Text(
      [
        if (subtitulo != null && subtitulo!.isNotEmpty) subtitulo!,
        ...parts,
      ].join(' • '),
      style: theme.textTheme.bodySmall,
    );
  }

  Widget _buildTrailing(BuildContext context) {
    final hasConfig = onConfigurarColunas != null;
    final hasExcluir = onExcluir != null;
    if (!hasConfig && !hasExcluir) {
      return const Icon(Icons.chevron_right);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasConfig)
          _IconAction(
            icon: Icons.view_column_outlined,
            tooltip: 'Configurar colunas',
            onPressed: onConfigurarColunas!,
          ),
        if (hasExcluir)
          _IconAction(
            icon: Icons.delete_outline,
            tooltip: 'Excluir',
            onPressed: onExcluir!,
          ),
      ],
    );
  }
}

class _AvatarUsuario extends StatelessWidget {
  final String nomeUsuario;

  const _AvatarUsuario({required this.nomeUsuario});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iniciais = _iniciaisDe(nomeUsuario);

    return CircleAvatar(
      radius: 20,
      backgroundColor: theme.colorScheme.secondaryContainer,
      child: Text(
        iniciais,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _iniciaisDe(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1))
        .toUpperCase();
  }
}

class _NotifBellButton extends StatelessWidget {
  const _NotifBellButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.notifications_none),
      tooltip: 'Notificações',
      onPressed: () => NotificacoesDrawer.show(context),
    );
  }
}

class _ConfigColunasButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _ConfigColunasButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.view_column_outlined),
      tooltip: 'Configurar colunas',
      onPressed: onPressed,
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final bool isWide;

  const _LogoutButton({required this.isWide});

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return TextButton.icon(
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Sair'),
        onPressed: () => LogoutDialog.show(context),
      );
    }
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Sair',
      onPressed: () => LogoutDialog.show(context),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}
