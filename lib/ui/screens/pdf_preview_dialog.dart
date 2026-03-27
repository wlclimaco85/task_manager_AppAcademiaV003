import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfPreviewDialog extends StatelessWidget {
  final Uint8List bytes;

  const PdfPreviewDialog({
    super.key,
    required this.bytes,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Visualizar PDF'),
      content: SizedBox(
        width: 400,
        height: 500,
        child: SfPdfViewer.memory(bytes),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
