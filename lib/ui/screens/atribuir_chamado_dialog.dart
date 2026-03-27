import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:intl/intl.dart';

class HistoricoChamadoDialog {
  static Future<Object?> show(BuildContext context, int chamadoId) async {
    final colors = CustomColors();
    bool isLoading = true;
    List<Map<String, dynamic>> historico = [];
    String? erro;

    // 🔹 Chama o backend
    try {
      final response = await NetworkCaller()
          .getRequest(ApiLinks.getAllChamados(chamadoId.toString()));

      if (response.isSuccess && response.body != null) {
        final data = response.body!['data']['dados'] ?? [];
        historico = List<Map<String, dynamic>>.from(data);
      } else {
        erro = 'Não foi possível carregar o histórico';
      }
    } catch (e) {
      erro = 'Erro ao consultar o histórico: $e';
    }

    isLoading = false;

    return showGeneralDialog(
      context: context,
      barrierLabel: "Histórico do Chamado",
      barrierDismissible: true,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (_, anim, __, child) {
        final offset =
            Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        );

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: offset,
              child: AlertDialog(
                backgroundColor: GridColors.dialogBackground.withOpacity(0.97),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                insetPadding: const EdgeInsets.all(16),
                title: Row(
                  children: [
                    const Icon(Icons.history_rounded,
                        color: GridColors.secondary),
                    const SizedBox(width: 8),
                    Text(
                      "Histórico do Chamado #$chamadoId",
                      style: const TextStyle(
                        color: GridColors.secondaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : erro != null
                          ? Center(
                              child: Text(
                                erro,
                                style: const TextStyle(color: GridColors.error),
                              ),
                            )
                          : historico.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Nenhum registro encontrado',
                                    style: TextStyle(
                                      color: GridColors.secondaryDark,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: historico.length,
                                  separatorBuilder: (_, __) => const Divider(),
                                  itemBuilder: (ctx, i) {
                                    final item = historico[i];
                                    final usuario =
                                        item['usuario']?['nome'] ?? '---';
                                    final dataHora =
                                        item['dataHora'] ?? item['data'] ?? '';
                                    final status = item['status'] ?? '';
                                    final obs = item['observacao'] ?? '';

                                    final dataFmt = dataHora.isNotEmpty
                                        ? DateFormat('dd/MM/yyyy HH:mm')
                                            .format(DateTime.parse(dataHora))
                                        : '';

                                    return ListTile(
                                      leading: const Icon(Icons.timeline,
                                          color: GridColors.primary),
                                      title: Text(
                                        status.isEmpty
                                            ? 'Alteração registrada'
                                            : status,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (obs.isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Text(
                                                obs,
                                                style: const TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Por $usuario em $dataFmt',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                ),
                actionsAlignment: MainAxisAlignment.spaceBetween,
                actionsPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                actions: [
                  // 🔹 Botões compactos e roláveis
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Exportar'),
                          onPressed: () {
                            // TODO: exportar PDF/CSV
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Exportação do histórico #$chamadoId em desenvolvimento'),
                                backgroundColor:
                                    colors.getShowSnackBarSuccess(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Recarregar'),
                          onPressed: () {
                            Navigator.pop(context);
                            HistoricoChamadoDialog.show(context, chamadoId);
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Fechar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.getCancelButtonColor(),
                            foregroundColor: colors.getButtonTextColor(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
