import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr/qr.dart' as qr;

/// Aceita apenas um payload Pix com CRC íntegro, informado pelo responsável.
bool codigoPixValido(String codigo) {
  if (codigo.length > 1024 || !codigo.startsWith('000201') ||
      !codigo.toUpperCase().contains('BR.GOV.BCB.PIX') ||
      codigo.length < 12 || codigo.substring(codigo.length - 8, codigo.length - 4) != '6304') {
    return false;
  }
  var crc = 0xFFFF;
  for (final byte in utf8.encode(codigo.substring(0, codigo.length - 4))) {
    crc ^= byte << 8;
    for (var i = 0; i < 8; i++) {
      crc = ((crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1) & 0xFFFF;
    }
  }
  return crc.toRadixString(16).padLeft(4, '0').toUpperCase() ==
      codigo.substring(codigo.length - 4).toUpperCase();
}

class DoacaoPixQr extends StatelessWidget {
  final String codigo;
  const DoacaoPixQr({super.key, required this.codigo});
  @override
  Widget build(BuildContext context) {
    if (!codigoPixValido(codigo)) return const SizedBox.shrink();
    final imagem = qr.QrImage(qr.QrCode.fromData(
        data: codigo, errorCorrectLevel: qr.QrErrorCorrectLevel.M));
    return Semantics(label: 'QR Code Pix para doação voluntária', image: true,
      child: CustomPaint(size: const Size.square(224), painter: _PixPainter(imagem)));
  }
}

class _PixPainter extends CustomPainter {
  final qr.QrImage imagem;
  _PixPainter(this.imagem);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final modulo = size.shortestSide / (imagem.moduleCount + 8);
    final tinta = Paint()..color = Colors.black..isAntiAlias = false;
    for (var linha = 0; linha < imagem.moduleCount; linha++) {
      for (var coluna = 0; coluna < imagem.moduleCount; coluna++) {
        if (imagem.isDark(linha, coluna)) {
          canvas.drawRect(Rect.fromLTWH((coluna + 4) * modulo,
              (linha + 4) * modulo, modulo, modulo), tinta);
        }
      }
    }
  }
  @override
  bool shouldRepaint(covariant _PixPainter oldDelegate) => oldDelegate.imagem != imagem;
}
