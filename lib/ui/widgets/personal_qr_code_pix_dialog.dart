import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr/qr.dart' as qr;
import '../../data/constants/custom_colors.dart';
import '../../data/models/fitness/personal_pix_cobranca_model.dart';

/// Modal para exibição do QR Code Pix e Copia e Cola do Personal Trainer
class PersonalQrCodePixDialog extends StatelessWidget {
  final PersonalPixCobrancaModel pixConfig;
  final double? valorCobrado;
  final String? alunoNome;

  const PersonalQrCodePixDialog({
    super.key,
    required this.pixConfig,
    this.valorCobrado,
    this.alunoNome,
  });

  static Future<void> show(
    BuildContext context, {
    required PersonalPixCobrancaModel pixConfig,
    double? valorCobrado,
    String? alunoNome,
  }) {
    return showDialog(
      context: context,
      builder: (_) => PersonalQrCodePixDialog(
        pixConfig: pixConfig,
        valorCobrado: valorCobrado,
        alunoNome: alunoNome,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final valorFinal = valorCobrado ?? pixConfig.valorMensalidadePadrao;
    final codigoPix = pixConfig.obterCodigoPixParaValor(valor: valorFinal);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: GridColors.card,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CustomColors.primaryGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.qr_code_scanner,
                          color: CustomColors.primaryGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cobrança Pix',
                            style: TextStyle(
                              color: GridColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            alunoNome != null
                                ? 'Aluno: $alunoNome'
                                : 'Mensalidade Personal',
                            style: TextStyle(
                              color: GridColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: GridColors.textSecondary),
                    tooltip: 'Fechar',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Valor em destaque
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: CustomColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CustomColors.primaryGreen.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Valor da Mensalidade:',
                      style: TextStyle(
                        color: GridColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'R\$ ${valorFinal.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: CustomColors.primaryGreen,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // QR Code Visual
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildQrCode(codigoPix),
                ),
              ),
              const SizedBox(height: 16),

              // Dados do Titular / Chave
              if (pixConfig.nomeTitular.isNotEmpty || pixConfig.chavePix.isNotEmpty) ...[
                Center(
                  child: Column(
                    children: [
                      if (pixConfig.nomeTitular.isNotEmpty)
                        Text(
                          pixConfig.nomeTitular,
                          style: TextStyle(
                            color: GridColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      if (pixConfig.chavePix.isNotEmpty)
                        Text(
                          '${pixConfig.tipoChavePix}: ${pixConfig.chavePix}',
                          style: TextStyle(
                            color: GridColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Pix Copia e Cola
              Text(
                'Pix Copia e Cola:',
                style: TextStyle(
                  color: GridColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black26
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: GridColors.divider),
                ),
                child: SelectableText(
                  codigoPix.isNotEmpty
                      ? codigoPix
                      : 'Nenhum código Pix configurado ainda.',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: GridColors.textSecondary,
                  ),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 16),

              // Botão Copiar
              FilledButton.icon(
                onPressed: codigoPix.isEmpty
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: codigoPix));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Código Pix Copia e Cola copiado com sucesso!'),
                            backgroundColor: CustomColors.primaryGreen,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: CustomColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.copy, size: 20),
                label: const Text(
                  'Copiar Código Pix',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrCode(String codigo) {
    if (codigo.trim().isEmpty) {
      return Container(
        width: 200,
        height: 200,
        color: Colors.white,
        child: const Center(
          child: Text(
            'Configure a Chave Pix ou o código Copia e Cola no cadastro.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ),
      );
    }

    try {
      final qrCode = qr.QrCode.fromData(
        data: codigo,
        errorCorrectLevel: qr.QrErrorCorrectLevel.M,
      );
      final qrImage = qr.QrImage(qrCode);

      return CustomPaint(
        size: const Size.square(200),
        painter: _QrCodePainter(qrImage),
      );
    } catch (e) {
      return Container(
        width: 200,
        height: 200,
        color: Colors.white,
        child: Center(
          child: Text(
            'Código Pix longo ou formato especial.\nUse o botão "Copiar Código Pix".',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
        ),
      );
    }
  }
}

class _QrCodePainter extends CustomPainter {
  final qr.QrImage imagem;
  _QrCodePainter(this.imagem);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final modulo = size.shortestSide / (imagem.moduleCount + 4);
    final tinta = Paint()
      ..color = Colors.black
      ..isAntiAlias = false;

    for (var linha = 0; linha < imagem.moduleCount; linha++) {
      for (var coluna = 0; coluna < imagem.moduleCount; coluna++) {
        if (imagem.isDark(linha, coluna)) {
          canvas.drawRect(
            Rect.fromLTWH(
              (coluna + 2) * modulo,
              (linha + 2) * modulo,
              modulo,
              modulo,
            ),
            tinta,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrCodePainter oldDelegate) =>
      oldDelegate.imagem != imagem;
}
