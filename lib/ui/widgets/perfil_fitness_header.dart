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
  final String? nomePersonal;
  final bool? personalOnline;
  final bool? minhaConexaoOnline;
  final String? ultimoTreino;
  final DateTime? dataUltimoTreino;
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
    this.nomePersonal,
    this.personalOnline,
    this.minhaConexaoOnline,
    this.ultimoTreino,
    this.dataUltimoTreino,
    this.onEditar,
    this.onCadastroIncompleto,
    this.onNotificacoes,
  });

  String get _nomeExibido => nome.trim().isEmpty ? 'Minha conta' : nome.trim();
  bool get _temPersonal => nomePersonal?.trim().isNotEmpty ?? false;
  bool get _temUltimoTreino => ultimoTreino?.trim().isNotEmpty ?? false;

  String _dataFormatada(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';

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
    final textoSecundario = context.appTextSecondary;
    final mostrarResumo = _temPersonal || _temUltimoTreino;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? context.appSurfaceAlt
            : GridColors.primarySubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GridColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // 1. Avatar com foto e badge de alerta desacoplados
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Semantics(
                    label: 'Foto de $_nomeExibido',
                    image: true,
                    button: onEditar != null,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onEditar,
                        customBorder: const CircleBorder(),
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
                    ),
                  ),
                  if (cadastroIncompleto)
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: Semantics(
                        label:
                            'Avaliação inicial pendente: faltam foto ou medidas',
                        button: true,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: const Key('cadastro_incompleto_header'),
                            onTap: onCadastroIncompleto,
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: GridColors.secondary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: context.appSurface, width: 2),
                              ),
                              child: const Center(
                                child: Icon(Icons.priority_high,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // 2. Textos (Nome e Perfil) clicáveis para Editar Perfil
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onEditar,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
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
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Badge(
                isLabelVisible: notificacoesNaoLidas > 0,
                label: Text(notificacoesNaoLidas > 99
                    ? '99+'
                    : '$notificacoesNaoLidas'),
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
          if (mostrarResumo) ...[
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: context.appSurface.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _temPersonal
                        ? Icons.support_agent_outlined
                        : Icons.fitness_center_outlined,
                    color: GridColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_temPersonal)
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Personal: ${nomePersonal!.trim()}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: context.appText),
                                ),
                              ),
                            ],
                          ),
                        if (minhaConexaoOnline != null) ...[
                          if (_temPersonal) const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: minhaConexaoOnline!
                                      ? GridColors.primary
                                      : textoSecundario,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                  minhaConexaoOnline!
                                      ? 'Você: Online'
                                      : 'Você: Offline',
                                  style: TextStyle(
                                      fontSize: 11, color: textoSecundario)),
                            ],
                          ),
                        ],
                        if (_temUltimoTreino) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Último treino: ${ultimoTreino!.trim()}${dataUltimoTreino == null ? '' : ' · ${_dataFormatada(dataUltimoTreino!)}'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(fontSize: 11, color: textoSecundario),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
