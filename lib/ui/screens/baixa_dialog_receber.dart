import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/baixa_dialog_base.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/conta_receber_model.dart';
import 'package:task_manager_flutter/data/models/forma_pagamento_model.dart';
import 'package:task_manager_flutter/data/services/conta_bancaria_caller.dart';

// use os helpers
// import 'baixa_dialog_base.dart';

class BaixaDialogReceber extends StatefulWidget {
  final ContaReceber conta;

  const BaixaDialogReceber({super.key, required this.conta});

  static Future<void> show(BuildContext context, ContaReceber conta) {
    return BaixaDialogBase.showDialogWithTransition(
      context: context,
      barrierLabel: "Baixar Conta a Receber",
      child: BaixaDialogReceber(conta: conta),
    );
  }

  @override
  State<BaixaDialogReceber> createState() => _BaixaDialogReceberState();
}

class _BaixaDialogReceberState extends State<BaixaDialogReceber> {
  final _formKey = GlobalKey<FormState>();
  final _valorBaixaController = TextEditingController();
  final _valorMultaController = TextEditingController();
  final _valorJurosController = TextEditingController();
  final _valorDescontoController = TextEditingController();

  DateTime _dataBaixa = DateTime.now();
  int? _contaId;
  int? _formaPagamentoId;

  bool _isLoading = true;
  final CustomColors colors = CustomColors();

  List<Map<String, dynamic>> _contas = [];
  List<FormaPagamento> _formasPagamento = [];

  @override
  void initState() {
    super.initState();
    _valorBaixaController.text = widget.conta.valor.toString();
    _valorMultaController.text = widget.conta.valorMulta?.toString() ?? '0';
    _valorJurosController.text = widget.conta.valorJuros?.toString() ?? '0';
    _valorDescontoController.text =
        widget.conta.valorDesconto?.toString() ?? '0';
    _loadData();
  }

  Future<void> _loadData() async {
    final contas = await ContaBancariaCaller.loadContas();
    final formasMap = await FormaPagamento.loadFormasPagamento();
    setState(() {
      _contas = contas;
      _formasPagamento = formasMap
          .map((m) => FormaPagamento(
                id: m['value'],
                nome: m['label'],
                descricao: '',
                status: 'Ativo',
                audit: null,
              ))
          .toList();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 12,
        shadowColor: Colors.black26,
        title: Text(
          'Baixar Conta a Receber',
          style: TextStyle(
              color: colors.getDarkGreenBorder(), fontWeight: FontWeight.bold),
        ),
        content: _isLoading
            ? const SizedBox(
                height: 120, child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      BaixaDialogBase.buildTextField(
                        controller: _valorBaixaController,
                        label: 'Valor da Baixa',
                        icon: Icons.monetization_on,
                        validatorMsg: 'Informe o valor',
                        colors: colors,
                      ),
                      const SizedBox(height: BaixaDialogBase.kFieldGap),
                      Row(
                        children: [
                          Expanded(
                            child: BaixaDialogBase.buildTextField(
                              controller: _valorMultaController,
                              label: 'Multa',
                              icon: Icons.percent,
                              colors: colors,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: BaixaDialogBase.buildTextField(
                              controller: _valorJurosController,
                              label: 'Juros',
                              icon: Icons.trending_up,
                              colors: colors,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: BaixaDialogBase.kFieldGap),
                      BaixaDialogBase.buildTextField(
                        controller: _valorDescontoController,
                        label: 'Desconto',
                        icon: Icons.sell_outlined,
                        colors: colors,
                      ),
                      const SizedBox(height: BaixaDialogBase.kFieldGap),
                      BaixaDialogBase.buildDropdown<int>(
                        label: 'Forma de Pagamento',
                        icon: Icons.payment,
                        value: _formaPagamentoId,
                        items: _formasPagamento
                            .map((f) => DropdownMenuItem<int>(
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
                            .map<DropdownMenuItem<int>>(
                              (c) => DropdownMenuItem<int>(
                                value: c['value'] as int,
                                child: Text(c['label'],
                                    overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _contaId = v),
                        validatorMsg: 'Selecione a conta',
                        colors: colors,
                      ),
                      const SizedBox(height: BaixaDialogBase.kFieldGap),
                      BaixaDialogBase.buildDateRow(
                        date: _dataBaixa,
                        onPick: () => _pickDate(context),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.getConfirmButtonColor(),
              foregroundColor: colors.getButtonTextColor(),
            ),
            onPressed: _baixar,
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext c) async {
    final d = await showDatePicker(
      context: c,
      initialDate: _dataBaixa,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _dataBaixa = d);
  }

  void _baixar() {
    if (_formKey.currentState!.validate()) {
      // aqui você faz seu POST de baixa de receber
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Baixa registrada com sucesso!'),
          backgroundColor: colors.getShowSnackBarSuccess(),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _valorBaixaController.dispose();
    _valorMultaController.dispose();
    _valorJurosController.dispose();
    _valorDescontoController.dispose();
    super.dispose();
  }
}
