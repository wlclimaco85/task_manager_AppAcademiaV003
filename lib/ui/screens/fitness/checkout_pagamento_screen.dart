import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/fitness/profissional_vitrine_model.dart';
import 'dart:math';

/// Tela de Checkout Simulado para Contratação de Personal
class CheckoutPagamentoScreen extends StatefulWidget {
  final PacoteContratacaoModel pacote;
  final ProfissionalVitrineModel profissional;

  const CheckoutPagamentoScreen({
    super.key,
    required this.pacote,
    required this.profissional,
  });

  @override
  State<CheckoutPagamentoScreen> createState() => _CheckoutPagamentoScreenState();
}

class _CheckoutPagamentoScreenState extends State<CheckoutPagamentoScreen> {
  int _metodoPagamento = 0; // 0 = Pix, 1 = Cartão
  bool _processando = false;
  final String _pixCode = "00020126360014BR.GOV.BCB.PIX0114+5534999999999520400005303986540550.005802BR5916APP ACADEMIA LTDA6007UBERABA62070503***6304E85C";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        backgroundColor: GridColors.card,
        title: const Text('Checkout Seguro'),
        elevation: 0,
      ),
      body: _processando
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: CustomColors.primaryGreen),
                  const SizedBox(height: 20),
                  Text('Processando pagamento...',
                      style: TextStyle(color: GridColors.textPrimary.withOpacity(0.8))),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resumo do Pedido
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GridColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: GridColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Resumo da Contratação',
                            style: TextStyle(
                                color: CustomColors.primaryGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text(widget.profissional.nome,
                            style: TextStyle(
                                color: GridColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text('Personal Trainer',
                            style: TextStyle(
                                color: GridColors.textPrimary.withOpacity(0.6), fontSize: 13)),
                        Divider(color: GridColors.divider, height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Plano: ${widget.pacote.titulo}',
                                style: TextStyle(color: GridColors.textPrimary)),
                            Text('R\$ ${widget.pacote.precoMensal.toStringAsFixed(2)}',
                                style: TextStyle(
                                    color: GridColors.textPrimary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Taxa de Serviço',
                                style: TextStyle(color: GridColors.textSecondary)),
                            Text('Grátis',
                                style: TextStyle(color: CustomColors.primaryGreen)),
                          ],
                        ),
                        Divider(color: GridColors.divider, height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total a Pagar',
                                style: TextStyle(
                                    color: GridColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            Text('R\$ ${widget.pacote.precoMensal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: CustomColors.primaryGreen,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  Text('Método de Pagamento',
                      style: TextStyle(
                          color: GridColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Seletor Pix
                  GestureDetector(
                    onTap: () => setState(() => _metodoPagamento = 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _metodoPagamento == 0
                            ? CustomColors.primaryGreen.withOpacity(0.1)
                            : GridColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _metodoPagamento == 0
                                ? CustomColors.primaryGreen
                                : GridColors.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.pix,
                              color: _metodoPagamento == 0
                                  ? CustomColors.primaryGreen
                                  : GridColors.textMuted),
                          const SizedBox(width: 12),
                          Text('Pix Copia e Cola',
                              style: TextStyle(color: GridColors.textPrimary, fontSize: 16)),
                          const Spacer(),
                          if (_metodoPagamento == 0)
                            const Icon(Icons.check_circle,
                                color: CustomColors.primaryGreen),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Seletor Cartão
                  GestureDetector(
                    onTap: () => setState(() => _metodoPagamento = 1),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _metodoPagamento == 1
                            ? CustomColors.primaryGreen.withOpacity(0.1)
                            : GridColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _metodoPagamento == 1
                                ? CustomColors.primaryGreen
                                : GridColors.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.credit_card,
                              color: _metodoPagamento == 1
                                  ? CustomColors.primaryGreen
                                  : GridColors.textMuted),
                          const SizedBox(width: 12),
                          Text('Cartão de Crédito',
                              style: TextStyle(color: GridColors.textPrimary, fontSize: 16)),
                          const Spacer(),
                          if (_metodoPagamento == 1)
                            const Icon(Icons.check_circle,
                                color: CustomColors.primaryGreen),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  if (_metodoPagamento == 0)
                    _buildPixDetails()
                  else
                    _buildCreditCardDetails(),
                ],
              ),
            ),
    );
  }

  Widget _buildPixDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pague com Pix para liberação imediata',
            style: TextStyle(color: GridColors.textSecondary)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: GridColors.textPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.qr_code_2, size: 150, color: Colors.black),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _pixCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Código Pix copiado!'),
                    backgroundColor: CustomColors.primaryGreen),
              );
              _simulatePayment();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CustomColors.primaryGreen,
              foregroundColor: GridColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.copy),
            label: const Text('Copiar Código Pix',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditCardDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          style: TextStyle(color: GridColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Número do Cartão',
            labelStyle: TextStyle(color: GridColors.textSecondary),
            filled: true,
            fillColor: GridColors.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                style: TextStyle(color: GridColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Validade (MM/AA)',
                  labelStyle: TextStyle(color: GridColors.textSecondary),
                  filled: true,
                  fillColor: GridColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                style: TextStyle(color: GridColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'CVV',
                  labelStyle: TextStyle(color: GridColors.textSecondary),
                  filled: true,
                  fillColor: GridColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          style: TextStyle(color: GridColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Nome no Cartão',
            labelStyle: TextStyle(color: GridColors.textSecondary),
            filled: true,
            fillColor: GridColors.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _simulatePayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: CustomColors.primaryGreen,
              foregroundColor: GridColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Pagar e Contratar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  void _simulatePayment() {
    setState(() => _processando = true);
    
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _processando = false);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: GridColors.card,
          title: const Icon(Icons.check_circle, color: CustomColors.primaryGreen, size: 60),
          content: Text(
            'Pagamento Aprovado!\n\nVocê contratou o personal ${widget.profissional.nome} com sucesso. Os dados de contato e ficha estarão disponíveis em instantes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: GridColors.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // fecha dialog
                Navigator.pop(context); // fecha tela de checkout
                Navigator.pop(context); // fecha tela do personal
              },
              child: const Text('Voltar ao Início', style: TextStyle(color: CustomColors.primaryGreen)),
            ),
          ],
        ),
      );
    });
  }
}
