import 'dart:convert' as convert;
import 'dart:typed_data';

import 'package:flutter/material.dart';

enum PerfilBanner { aluno, personal }

class UserBannerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String nomeUsuario;
  final String? screenTitle;
  final String? cargo;
  final String? nomeAluno;
  final String? fotoAlunoBase64;
  final String? nomePersonal;
  final String? fotoPersonalBase64;
  final PerfilBanner perfil;
  final List<Widget>? actions;
  final VoidCallback? onTapped;
  final VoidCallback? onRefresh;
  final bool? isLoading;
  final VoidCallback? onEmpresaTap;
  final VoidCallback? onUserTap;
  final VoidCallback? onFilterToggle;
  final bool showFilterButton;
  final VoidCallback? onExportToExcel;
  final VoidCallback? onConfigurarColunas;
  final bool mostrarConfigurarColunas;

  const UserBannerAppBar({
    super.key,
    this.nomeUsuario = 'Usuario',
    this.screenTitle,
    this.cargo,
    this.nomeAluno,
    this.fotoAlunoBase64,
    this.nomePersonal,
    this.fotoPersonalBase64,
    this.perfil = PerfilBanner.aluno,
    this.actions,
    this.onTapped,
    this.onRefresh,
    this.isLoading,
    this.onEmpresaTap,
    this.onUserTap,
    this.onFilterToggle,
    this.showFilterButton = true,
    this.onExportToExcel,
    this.onConfigurarColunas,
    this.mostrarConfigurarColunas = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(94);

  @override
  Widget build(BuildContext context) {
    final title = (screenTitle?.trim().isNotEmpty ?? false)
        ? screenTitle!.trim()
        : _nomePrincipal;
    final subtitle = _subtitle;

    return Material(
      color: const Color(0xFF6C4FB1),
      elevation: 2,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: preferredSize.height,
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
          child: Row(
            children: [
              _RoundIconButton(
                icon: Icons.arrow_back,
                tooltip: 'Voltar',
                onPressed: Navigator.of(context).canPop()
                    ? () => Navigator.of(context).maybePop()
                    : null,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onUserTap ?? onTapped,
                child: _AvatarUsuario(
                  nome: _nomePrincipal,
                  fotoBase64: _fotoPrincipal,
                  size: 42,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTapped ?? onUserTap,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.12,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (onRefresh != null)
                _RoundIconButton(
                  icon: Icons.refresh,
                  tooltip: 'Atualizar',
                  onPressed: isLoading == true ? null : onRefresh,
                  loading: isLoading == true,
                ),
              if (onExportToExcel != null)
                _RoundIconButton(
                  icon: Icons.table_view,
                  tooltip: 'Exportar',
                  onPressed: onExportToExcel,
                ),
              if (mostrarConfigurarColunas && onConfigurarColunas != null)
                _RoundIconButton(
                  icon: Icons.view_column,
                  tooltip: 'Colunas',
                  onPressed: onConfigurarColunas,
                ),
              if (showFilterButton && onFilterToggle != null)
                _RoundIconButton(
                  icon: Icons.filter_list,
                  tooltip: 'Filtros',
                  onPressed: onFilterToggle,
                ),
              if (onEmpresaTap != null)
                _RoundIconButton(
                  icon: Icons.business,
                  tooltip: 'Empresa',
                  onPressed: onEmpresaTap,
                ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }

  String get _nomePrincipal {
    if (perfil == PerfilBanner.personal &&
        (nomePersonal?.trim().isNotEmpty ?? false)) {
      return nomePersonal!.trim();
    }
    if (nomeAluno?.trim().isNotEmpty ?? false) return nomeAluno!.trim();
    if (nomePersonal?.trim().isNotEmpty ?? false) return nomePersonal!.trim();
    return nomeUsuario.trim().isEmpty ? 'Usuario' : nomeUsuario.trim();
  }

  String? get _fotoPrincipal {
    if (perfil == PerfilBanner.personal &&
        (fotoPersonalBase64?.trim().isNotEmpty ?? false)) {
      return fotoPersonalBase64;
    }
    if (fotoAlunoBase64?.trim().isNotEmpty ?? false) return fotoAlunoBase64;
    return fotoPersonalBase64;
  }

  String get _subtitle {
    if (cargo?.trim().isNotEmpty ?? false) return cargo!.trim();
    if (perfil == PerfilBanner.personal) return 'Personal Trainer';
    if (nomePersonal?.trim().isNotEmpty ?? false) {
      return 'Personal: ${nomePersonal!.trim()}';
    }
    return '';
  }
}

class UserHeaderBanner extends StatelessWidget {
  final Color backgroundColor;
  final EdgeInsets padding;
  final Widget? trailing;

  const UserHeaderBanner({
    super.key,
    this.backgroundColor = const Color(0xFF6C4FB1),
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      color: backgroundColor,
      child: Row(
        children: [
          const _AvatarUsuario(nome: 'Usuario', size: 48),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Usuario',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool loading;

  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          onPressed: onPressed,
          color: Colors.white,
          disabledColor: Colors.white.withValues(alpha: 0.48),
          iconSize: 22,
          visualDensity: VisualDensity.compact,
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon),
        ),
      ),
    );
  }
}

class _AvatarUsuario extends StatelessWidget {
  final String nome;
  final String? fotoBase64;
  final double size;

  const _AvatarUsuario({
    required this.nome,
    this.fotoBase64,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeBase64(fotoBase64);
    final initials = _iniciais(nome);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes == null
          ? Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: const Color(0xFF5D35B1),
                  fontSize: size * 0.34,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : Image.memory(bytes, fit: BoxFit.cover),
    );
  }

  Uint8List? _decodeBase64(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;
    try {
      final normalized = raw.contains(',') ? raw.split(',').last : raw;
      return convert.base64Decode(normalized);
    } catch (_) {
      return null;
    }
  }

  String _iniciais(String value) {
    final parts =
        value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}
