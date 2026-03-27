import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/baixa_caller.dart';

class DesfazerBaixaDialog extends StatefulWidget {
  final int contaId;
  final String tipo; // "pagar" ou "receber"
  final DateTime dataBaixa;
  final double valorBaixa;
  final String contaLabel;
  final String formaPagamentoLabel;

  const DesfazerBaixaDialog({
    super.key,
    required this.contaId,
    required this.tipo,
    required this.dataBaixa,
    required this.valorBaixa,
    required this.contaLabel,
    required this.formaPagamentoLabel,
  });

  static Future<void> show(
    BuildContext context, {
    required int contaId,
    required String tipo,
    required DateTime dataBaixa,
    required double valorBaixa,
    required String contaLabel,
    required String formaPagamentoLabel,
  }) {
    return showGeneralDialog(
      context: context,
      barrierLabel: "Desfazer Baixa",
      barrierDismissible: true,
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => Center(
        child: Material(
          color: Colors.transparent,
          child: DesfazerBaixaDialog(
            contaId: contaId,
            tipo: tipo,
            dataBaixa: dataBaixa,
            valorBaixa: valorBaixa,
            contaLabel: contaLabel,
            formaPagamentoLabel: formaPagamentoLabel,
          ),
        ),
      ),
      transitionBuilder: (_, anim, __, child) {
        final offsetAnim = Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: FadeTransition(
              opacity: anim,
              child: SlideTransition(position: offsetAnim, child: child)),
        );
      },
    );
  }

  @override
  State<DesfazerBaixaDialog> createState() => _DesfazerBaixaDialogState();
}

class _DesfazerBaixaDialogState extends State<DesfazerBaixaDialog> {
  bool _isLoading = false;
  final colors = CustomColors();

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: 1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: AlertDialog(
        backgroundColor: GridColors.dialogBackground.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 12,
        shadowColor: Colors.black26,
        title: Row(
          children: [
            const Icon(Icons.undo, color: GridColors.primary),
            const SizedBox(width: 8),
            Text('Desfazer Baixa',
                style: TextStyle(
                    color: colors.getDarkGreenBorder(),
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: _isLoading
            ? const SizedBox(
                height: 100, child: Center(child: CircularProgressIndicator()))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoTile('Data da Baixa', _fmtDate(widget.dataBaixa)),
                  _infoTile('Valor', _fmtCurrency(widget.valorBaixa)),
                  _infoTile('Conta', widget.contaLabel),
                  _infoTile('Forma Pagamento', widget.formaPagamentoLabel),
                  const Divider(height: 24),
                  const Text(
                    'Tem certeza que deseja desfazer esta baixa?\nEsta ação não pode ser desfeita.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: colors.getCancelButtonColor(),
              foregroundColor: colors.getButtonTextColor(),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.undo),
            label: const Text('Desfazer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.getConfirmButtonColor(),
              foregroundColor: colors.getButtonTextColor(),
            ),
            onPressed: _isLoading ? null : _confirmDesfazer,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDesfazer() async {
    setState(() => _isLoading = true);

    final NetworkResponse res = await BaixaCaller.desfazerBaixa(
      tipo: widget.tipo,
      id: widget.contaId,
    );

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res.isSuccess
          ? 'Baixa desfeita com sucesso!'
          : 'Erro ao desfazer baixa'),
      backgroundColor: res.isSuccess
          ? colors.getShowSnackBarSuccess()
          : colors.getShowSnackBarError(),
    ));

    if (res.isSuccess) Navigator.pop(context, true);
  }

  Widget _infoTile(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.right, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _fmtCurrency(double v) => 'R\$ ${v.toStringAsFixed(2)}';
}
