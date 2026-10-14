import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

/// Gera o PDF e abre a tela nativa de impressão/compartilhamento
/// (Android, iOS, Web e Windows). Falhas viram aviso ao usuário e log.
Future<void> imprimirPdf(
  BuildContext context, {
  required String nomeArquivo,
  required Future<Uint8List> Function() gerar,
}) async {
  try {
    final bytes = await gerar();
    await Printing.layoutPdf(name: nomeArquivo, onLayout: (_) async => bytes);
  } catch (e, st) {
    AppLogger.i.error('Falha ao gerar/imprimir PDF $nomeArquivo: $e', st);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível gerar o PDF. Tente novamente.')),
      );
    }
  }
}

/// Nome de arquivo seguro a partir de um título ("Ficha - Hipertrofia ABC.pdf").
String nomeArquivoPdf(String prefixo, String titulo) {
  final limpo = titulo.replaceAll(RegExp(r'[\\/:*?"<>|]'), '').trim();
  return '$prefixo - ${limpo.isEmpty ? 'documento' : limpo}.pdf';
}
