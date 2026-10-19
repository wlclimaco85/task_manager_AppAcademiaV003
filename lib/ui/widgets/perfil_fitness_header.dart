import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

/// Identifica a conta ativa sem ocupar o espaço das ações do cabeçalho.
class PerfilFitnessHeader extends StatelessWidget {
  final String nome;
  final String perfil;
  final String? foto;
  final bool cadastroIncompleto;
  final int notificacoesNaoLidas;
  final VoidCallback? onEditar;
  final VoidCallback? onCadastroIncompleto;
  final VoidCallback? onNotificacoes;

  const PerfilFitnessHeader({
    super.key,
    required this.nome,
    required this.perfil,
    this.foto,
    this.cadastroIncompleto = false,
    this.notificacoesNaoLidas = 0,
    this.onEditar,
    this.onCadastroIncompleto,
    this.onNotificacoes,
  });

  String get _nomeExibido => nome.trim().isEmpty ? 'Minha conta' : nome.trim();

  Widget _iniciais() {
    final partes = _nomeExibido.split(RegExp(r'\s+'));
    final iniciais = partes.first.characters.first +
        (partes.length > 1 ? partes.last.characters.first : '');
    return Center(
      child: Text(
        iniciais.toUpperCase(),
        style: TextStyle(
          color: GridColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _foto(BuildContext context) {
    final valor = foto?.trim() ?? '';
    if (valor.isEmpty) return _iniciais();
    try {
      final uri = Uri.tryParse(valor);
      final ImageProvider imagem;
      if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
        imagem = NetworkImage(valor);
      } else {
        final bytes = valor.startsWith('data:')
            ? Uri.parse(valor).data!.contentAsBytes()
            : base64Decode(valor);
        imagem = MemoryImage(bytes);
      }
      return Image(
        image: imagem,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        errorBuilder: (_, error, stack) {
          AppLogger.i.warn('Foto do perfil indisponível; exibindo iniciais.');
          return _iniciais();
        },
      );
    } catch (error) {
      AppLogger.i.warn('Foto do perfil inválida; exibindo iniciais.');
      return _iniciais();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? context.appSurfaceAlt
            : GridColors.primarySubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GridColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onEditar,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Semantics(
                        label: 'Foto de $_nomeExibido',
                        image: true,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.appSurfaceAlt,
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _foto(context),
                        ),
                      ),
                      if (cadastroIncompleto)
                        Positioned(
                          right: -5,
                          bottom: -5,
                          child: Semantics(
                            label: 'Avaliação inicial pendente: faltam foto ou medidas',
                            button: true,
                            child: InkWell(
                              key: const Key('cadastro_incompleto_header'),
                              onTap: onCadastroIncompleto,
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: GridColors.secondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: context.appSurface, width: 2),
                                ),
                                child: const Center(
                                  child: Icon(Icons.priority_high, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _nomeExibido,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: context.appText,
                          ),
                        ),
                        Text(
                          perfil,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.appTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        Badge(
          isLabelVisible: notificacoesNaoLidas > 0,
          label: Text(notificacoesNaoLidas > 99 ? '99+' : '$notificacoesNaoLidas'),
          child: Semantics(
            label: notificacoesNaoLidas == 0
                ? 'Notificações'
                : 'Notificações, $notificacoesNaoLidas não lidas',
            button: true,
            child: IconButton(
              key: const Key('abrir_notificacoes'),
              onPressed: onNotificacoes,
              icon: const Icon(Icons.notifications_outlined),
              color: context.appText,
            ),
          ),
        ),
      ],
      ),
    );
  }
}
