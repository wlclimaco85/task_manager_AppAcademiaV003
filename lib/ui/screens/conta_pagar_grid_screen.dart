// conta_pagar_grid_screen.dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/customization/generic_grid_card.dart';
import 'package:task_manager_flutter/data/models/conta_pagar_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/screens/baixa_dialog.dart';
import 'package:task_manager_flutter/ui/screens/desfazer_baixa_dialog.dart';

// ✅ importe o seu caller
import 'package:task_manager_flutter/data/services/contaPagar_boleto_caller.dart';

class ContaPagarGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const ContaPagarGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericMobileGridScreen<ContaPagar>(
      title: "Contas a Pagar",
      fetchEndpoint: ApiLinks.allContasPagar,
      createEndpoint: ApiLinks.createContaPagar,
      updateEndpoint: ApiLinks.updateContaPagar(":id"),
      deleteEndpoint: ApiLinks.deleteContaPagar(":id"),
      fromJson: (json) => ContaPagar.fromJson(json),
      toJson: (obj) => obj.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: ContaPagar.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'audit.createdAt',

      // 🔹 NOVOS PARÂMETROS
      statusFieldName: 'status',
      editableStatus: true,
      enumMaps: {
        'status': StatusConta.map,
      },
      statusEnumMap: StatusConta.values
          .asMap()
          .map((key, value) => MapEntry(value, value.name)),

      customActions: () => [
        // ✅ NOVO BOTÃO
        CustomAction<ContaPagar>(
          icon: Icons.upload_file,
          label: 'Importar Boleto (PDF)',
          onPressed: (context, object) => _importarBoletoPdf(context, object),
          isVisible: (_) => true,
        ),
        CustomAction<ContaPagar>(
          icon: Icons.payment,
          label: 'Baixar',
          onPressed: (context, object) => _showBaixaDialog(context, object),
          isVisible: (object) => object.status == StatusConta.ABERTO,
        ),
        CustomAction<ContaPagar>(
          icon: Icons.undo,
          label: 'Desfazer Baixa',
          isVisible: (obj) => obj.status == StatusConta.BAIXADA,
          onPressed: (context, object) {
            DesfazerBaixaDialog.show(
              context,
              tipo: 'pagar',
              contaId: object.id!,
              dataBaixa: object.dataBaixa!,
              valorBaixa: object.valorBaixa!,
              contaLabel: object.contaBaixa?.descricao ?? 'Conta não informada',
              formaPagamentoLabel:
                  object.formaPagamento?.nome ?? 'Forma não informada',
            );
          },
        ),
      ],
      useUserBannerAppBar: true,
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50],
      ),
      enableSearch: true,
    );
  }

  void _showBaixaDialog(BuildContext context, ContaPagar conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BaixaDialog(conta: conta);
      },
    );
  }

  /// 📄 Importa PDF do boleto e, se sucesso, abre popup com informações retornadas.
  Future<void> _importarBoletoPdf(
      BuildContext context, ContaPagar conta) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );

    if (picked == null ||
        picked.files.isEmpty ||
        picked.files.single.path == null) {
      return; // usuário cancelou
    }

    final File pdfFile = File(picked.files.single.path!);

    _showLoading(context, 'Importando boleto...');

    try {
      // ✅ chama o seu Caller
      final result = await ContaPagarBoletoCaller().importarBoleto(
        pdfFile: pdfFile,
        descricao: conta.descricao ?? "Boleto importado",
        valor: (conta.valor ?? 0).toDouble(),
        dataVencimentoIso: _toIsoDate(conta.dataVencimento) ?? _todayIso(),
        empresaId: conta.empresa?.id ?? 1,
        parceiroNome: conta.parceiro?.nome,
        parceiroDocumento: conta.parceiro?.cpf,
        //   formaPagamentoId: conta.formaPagamento?.id,
        // observacao: conta.observacao,
        // numeroNota: conta.numeroNota,
      );

      Navigator.of(context, rootNavigator: true).pop(); // fecha loading

      if (result != null) {
        _showImportResultPopup(context, result);
      } else {
        _showError(context,
            'Falha ao importar boleto. Verifique o token e o endpoint.');
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop(); // fecha loading
      _showError(context, 'Erro ao importar boleto: $e');
    }
  }

  void _showImportResultPopup(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Boleto importado'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _info('ContaPagar ID', data['contaPagarId']),
              _info('File ID', data['fileId']),
              _info('Parceiro ID', data['parceiroId']),
              const Divider(height: 20),
              _info('Descrição', data['descricao']),
              _info('Valor', data['valor']),
              _info('Vencimento', data['dataVencimento']),
              _info('Parceiro', data['parceiroNome']),
              _info('Documento', data['parceiroDocumento']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, dynamic value) {
    if (value == null) return const SizedBox.shrink();
    final txt = value.toString();
    if (txt.isEmpty || txt == 'null') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label: $txt'),
    );
  }

  void _showLoading(BuildContext context, String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
      ),
    );
  }

  void _showError(BuildContext context, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erro'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  String? _toIsoDate(dynamic date) {
    if (date == null) return null;

    // Se vier como String (ex: "2026-01-31")
    if (date is String) {
      return date.length >= 10 ? date.substring(0, 10) : date;
    }

    // Se for DateTime
    if (date is DateTime) {
      final y = date.year.toString().padLeft(4, '0');
      final m = date.month.toString().padLeft(2, '0');
      final d = date.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }
    return null;
  }

  String _todayIso() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
