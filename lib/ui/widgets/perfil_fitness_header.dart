import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

/// Identifica a conta ativa sem ocupar o espaço das ações do cabeçalho.
class PerfilFitnessHeader extends StatelessWidget {
  final String nome;
  final String perfil;
  final String? foto;

  const PerfilFitnessHeader({
    super.key,
    required this.nome,
    required this.perfil,
    this.foto,
  });

  String get _nomeExibido => nome.trim().isEmpty ? 'Minha conta' : nome.trim();

  Widget _iniciais() {
    final partes = _nomeExibido.split(RegExp(r'\s+'));
    final iniciais = partes.first.characters.first +
        (partes.length > 1 ? partes.last.characters.first : '');
    return Center(
      child: Text(
        iniciais.toUpperCase(),
        style: const TextStyle(
          color: GridColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _foto() {
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
        color: GridColors.primarySubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GridColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
      children: [
        Semantics(
          label: 'Foto de $_nomeExibido',
          image: true,
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: GridColors.primarySubtle,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: _foto(),
          ),
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: GridColors.textPrimary,
                ),
              ),
              Text(
                perfil,
                style: const TextStyle(
                  fontSize: 12,
                  color: GridColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }
}
