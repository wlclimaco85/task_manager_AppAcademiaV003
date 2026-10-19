import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/constants/custom_colors.dart';
import '../../data/services/fitness_push_notification_service.dart';
import '../../app.dart';

/// Exibe o diálogo autoexplicativo avisando que falta fazer a avaliação inicial
Future<void> mostrarDialogoAvaliacaoInicialPendente(
  BuildContext context, {
  required VoidCallback onFazerAgora,
}) async {
  final targetContext = Navigator.maybeOf(context) != null
      ? context
      : (TaskManagerApp.globalKey.currentContext ?? context);

  await showDialog<void>(
    context: targetContext,
    useRootNavigator: true,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: GridColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: GridColors.secondary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.priority_high, color: GridColors.secondary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Avaliação Inicial Pendente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: GridColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Falta você fazer a sua avaliação inicial!',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: GridColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Cadastrar sua foto e suas medidas corporais é essencial para que seu treino seja personalizado, calcular cargas ideais e acompanhar sua evolução física ao longo do tempo.',
            style: TextStyle(
              fontSize: 14,
              color: GridColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(
            'Lembrar mais tarde',
            style: TextStyle(color: GridColors.textSecondary),
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: GridColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: () {
            Navigator.pop(dialogContext);
            onFazerAgora();
          },
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: const Text('Fazer Avaliação Agora'),
        ),
      ],
    ),
  );
}

/// Central de Notificações com exibição detalhada de cada notificação
Future<void> mostrarCentralNotificacoes(
  BuildContext context, {
  required VoidCallback onAtualizarIndicadores,
  required VoidCallback onAbrirAvaliacaoInicial,
}) async {
  final targetContext = Navigator.maybeOf(context) != null
      ? context
      : (TaskManagerApp.globalKey.currentContext ?? context);

  final notifService = FitnessPushNotificationService();
  var itens = await notifService.getNotificacoes();

  if (!targetContext.mounted) return;

  await showModalBottomSheet<void>(
    context: targetContext,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: GridColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) {
        final naoLidas = itens.where((n) => !n.lida).length;

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.80,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabeçalho da Central de Notificações
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: GridColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.notifications_active, color: GridColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notificações',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: GridColors.textPrimary,
                              ),
                            ),
                            Text(
                              naoLidas > 0
                                  ? '$naoLidas notificação(ões) não lida(s)'
                                  : 'Todas as notificações em dia',
                              style: TextStyle(
                                fontSize: 12,
                                color: GridColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (naoLidas > 0)
                        TextButton(
                          onPressed: () async {
                            for (final item in itens) {
                              if (!item.lida) await notifService.marcarComoLida(item.id);
                            }
                            itens = await notifService.getNotificacoes();
                            setSheetState(() {});
                            onAtualizarIndicadores();
                          },
                          child: const Text('Ler todas', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Lista de Notificações
                Flexible(
                  child: itens.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(36),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_off_outlined,
                                  size: 48, color: GridColors.textSecondary.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                'Nenhuma notificação por enquanto',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: GridColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: itens.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = itens[index];
                            final iconInfo = _obterIconeNotificacao(item.tipo);

                            return InkWell(
                              key: ValueKey('notificacao_${item.id}'),
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                if (!item.lida) {
                                  await notifService.marcarComoLida(item.id);
                                  itens = await notifService.getNotificacoes();
                                  setSheetState(() {});
                                  onAtualizarIndicadores();
                                }
                                if (item.tipo == 'cadastro_inicial' && sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                  onAbrirAvaliacaoInicial();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: item.lida
                                      ? GridColors.filterBackground.withValues(alpha: 0.4)
                                      : GridColors.primarySubtle.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: item.lida
                                        ? GridColors.divider
                                        : GridColors.primary.withValues(alpha: 0.35),
                                    width: item.lida ? 1 : 1.5,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Ícone com fundo suave
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: iconInfo.cor.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(iconInfo.icone, color: iconInfo.cor, size: 22),
                                    ),
                                    const SizedBox(width: 12),

                                    // Conteúdo completo da notificação
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.titulo,
                                                  style: TextStyle(
                                                    fontWeight: item.lida ? FontWeight.w600 : FontWeight.w800,
                                                    fontSize: 14,
                                                    color: GridColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              if (!item.lida)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  margin: const EdgeInsets.only(left: 6),
                                                  decoration: BoxDecoration(
                                                    color: GridColors.primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.corpo,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: GridColors.textSecondary,
                                              height: 1.3,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _formatarDataHora(item.dataHora),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: GridColors.textSecondary.withValues(alpha: 0.75),
                                                ),
                                              ),
                                              if (item.tipo == 'cadastro_inicial')
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: GridColors.primary,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Text(
                                                    'Fazer Avaliação →',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  onAtualizarIndicadores();
}

String _formatarDataHora(DateTime dataHora) {
  final hoje = DateTime.now();
  if (dataHora.year == hoje.year && dataHora.month == hoje.month && dataHora.day == hoje.day) {
    return 'Hoje às ${DateFormat('HH:mm').format(dataHora)}';
  }
  return DateFormat('dd/MM às HH:mm').format(dataHora);
}

class _NotifIconInfo {
  final IconData icone;
  final Color cor;
  _NotifIconInfo(this.icone, this.cor);
}

_NotifIconInfo _obterIconeNotificacao(String tipo) {
  switch (tipo) {
    case 'cadastro_inicial':
      return _NotifIconInfo(Icons.priority_high, GridColors.secondary);
    case 'falta_aluno':
    case 'falta_personal':
      return _NotifIconInfo(Icons.event_busy, Colors.orange);
    case 'treino_atualizado':
    case 'treino_hoje':
      return _NotifIconInfo(Icons.fitness_center, GridColors.primary);
    case 'mensalidade_vencendo':
      return _NotifIconInfo(Icons.payment, Colors.blue);
    case 'meta_dia_nao_cumprida':
      return _NotifIconInfo(Icons.bedtime_outlined, Colors.purple);
    case 'aluno_treino_finalizado':
      return _NotifIconInfo(Icons.emoji_events_outlined, Colors.amber);
    case 'aluno_comentario_treino':
    case 'aviso_personal':
      return _NotifIconInfo(Icons.chat_bubble_outline, GridColors.primary);
    default:
      return _NotifIconInfo(Icons.notifications_outlined, GridColors.primary);
  }
}
