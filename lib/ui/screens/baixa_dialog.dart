import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/baixa_dialog_base.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/conta_pagar_model.dart';
import 'package:task_manager_flutter/data/models/forma_pagamento_model.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/conta_bancaria_caller.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
// use os helpers
// import 'baixa_dialog_base.dart';

class BaixaDialog extends StatefulWidget {
  final ContaPagar conta;

  const BaixaDialog({super.key, required this.conta});

  static Future<void> show(BuildContext context, ContaPagar conta) {
    return BaixaDialogBase.showDialogWithTransition(
      context: context,
      barrierLabel: "Registrar Baixa",
      child: BaixaDialog(conta: conta),
    );
  }

  @override
  State<BaixaDialog> createState() => _BaixaDialogState();
}

class _BaixaDialogState extends State<BaixaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  DateTime _dataBaixa = DateTime.now();
  int? _formaPagamentoId;
  int? _contaId;

  bool _isLoading = true;
  final CustomColors colors = CustomColors();

  List<FormaPagamento> _formasPagamento = [];
  List<Map<String, dynamic>> _contas = [];

  @override
  void initState() {
    super.initState();
    _valorController.text = widget.conta.valor.toString();
    _loadData();
  }

  Future<void> _loadData() async {
    final formasMap = await FormaPagamento.loadFormasPagamento();
    final contasMap = await ContaBancariaCaller.loadContas();
    setState(() {
      _formasPagamento = formasMap
          .map((m) => FormaPagamento(
                id: m['value'],
                nome: m['label'],
                descricao: '',
                status: 'Ativo',
                audit: null,
              ))
          .toList();
      _contas = contasMap;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: 1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: AlertDialog(
        backgroundColor: GridColors.dialogBackground.withOpacity(0.95),
        elevation: 12,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Registrar Baixa',
            style: TextStyle(
                color: colors.getDarkGreenBorder(),
                fontWeight: FontWeight.bold)),
        content: _isLoading
            ? const SizedBox(
                height: 120, child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      BaixaDialogBase.buildTextField(
                        controller: _valorController,
                        label: 'Valor da Baixa',
                        icon: Icons.attach_money,
                        validatorMsg: 'Informe o valor',
                        colors: colors,
                      ),
                      const SizedBox(height: BaixaDialogBase.kFieldGap),
                      BaixaDialogBase.buildDropdown<int>(
                        label: 'Forma de Pagamento',
                        icon: Icons.payment,
                        value: _formaPagamentoId,
                        items: _formasPagamento
                            .map((f) => DropdownMenuItem(
                                value: f.id, child: Text(f.nome ?? '')))
                            .toList(),
                        onChanged: (v) => setState(() => _formaPagamentoId = v),
                        validatorMsg: 'Selecione a forma de pagamento',
                        colors: colors,
                      ),
                      const SizedBox(height: BaixaDialogBase.kFieldGap),
                      BaixaDialogBase.buildDropdown<int>(
                        label: 'Conta Bancária',
                        icon: Icons.account_balance,
                        value: _contaId,
                        items: _contas
                            .map((c) => DropdownMenuItem<int>(
                                  value: c['value'] as int,
                                  child: Text(c['label'],
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _contaId = v),
                        validatorMsg: 'Selecione a conta',
                        colors: colors,
                      ),
                      const SizedBox(height: BaixaDialogBase.kFieldGap),
                      BaixaDialogBase.buildDateRow(
                        date: _dataBaixa,
                        onPick: () => _selectDate(context),
                      ),
                    ],
                  ),
                ),
              ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: colors.getCancelButtonColor(),
              foregroundColor: colors.getButtonTextColor(),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.getConfirmButtonColor(),
              foregroundColor: colors.getButtonTextColor(),
            ),
            onPressed: _submitBaixa,
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataBaixa,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dataBaixa = picked);
  }

  Future<void> _submitBaixa() async {
    if (_formKey.currentState!.validate()) {
      final valorBaixa = double.parse(_valorController.text);
      final NetworkResponse res = await NetworkCaller().postRequest(
        ApiLinks.registrarBaixaContaPagar(widget.conta.id.toString()),
        {
          'dataBaixa': _dataBaixa.toIso8601String(),
          'valorBaixa': valorBaixa,
          'formaPagamentoId': _formaPagamentoId,
          'contaId': _contaId,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.isSuccess
              ? 'Baixa registrada com sucesso!'
              : 'Erro: ${res.statusCode}'),
          backgroundColor: res.isSuccess
              ? colors.getShowSnackBarSuccess()
              : colors.getShowSnackBarError(),
        ),
      );
      if (res.isSuccess) Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }
}
