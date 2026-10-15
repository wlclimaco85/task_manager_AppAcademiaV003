import 'package:flutter/painting.dart';
import 'dart:ui';

/// Logo "Eu Atleta": letra A (o atleta) com uma barra de halteres como
/// travessa. Verde esmeralda e branco, as cores do app (GridColors).
class LogoEuAtleta {
  static const Color verdeClaro = Color(0xFF10B981);
  static const Color verdeEscuro = Color(0xFF047857);
  static const Color branco = Color(0xFFFFFFFF);

  /// [raio] é a fração do lado usada nos cantos (0 = quadrado, iOS/maskable).
  /// [escala] reduz o desenho central (maskable precisa de margem de segurança).
  static void desenhar(Canvas canvas, double lado,
      {double raio = 0.22, double escala = 1.0}) {
    final fundo = Rect.fromLTWH(0, 0, lado, lado);
    final paintFundo = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [verdeClaro, verdeEscuro],
      ).createShader(fundo);
    canvas.drawRRect(
        RRect.fromRectAndRadius(fundo, Radius.circular(lado * raio)), paintFundo);

    canvas.save();
    canvas.translate(lado / 2, lado / 2);
    canvas.scale(lado * escala);
    canvas.translate(-0.5, -0.5);

    final traco = Paint()
      ..color = branco
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final letra = Path()
      ..moveTo(0.27, 0.76)
      ..lineTo(0.5, 0.22)
      ..lineTo(0.73, 0.76);
    canvas.drawPath(letra, traco);

    // Barra de halteres atravessando o A.
    final barra = Paint()
      ..color = branco
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.04
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0.16, 0.56), const Offset(0.84, 0.56), barra);

    final disco = Paint()..color = branco;
    void discos(double x, double sinal) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(x, 0.56), width: 0.06, height: 0.24),
              const Radius.circular(0.02)),
          disco);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(x + sinal * 0.075, 0.56), width: 0.05, height: 0.16),
              const Radius.circular(0.02)),
          disco);
    }

    discos(0.2, -1);
    discos(0.8, 1);
    canvas.restore();
  }
}
