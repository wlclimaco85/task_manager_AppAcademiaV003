import 'package:flutter/material.dart';

class ConfigurarColunasDialog extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const ConfigurarColunasDialog({
    Key? key,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  static void show(BuildContext context, {required VoidCallback onSave, required VoidCallback onCancel}) {
    showDialog(
      context: context,
      builder: (context) => ConfigurarColunasDialog(onSave: onSave, onCancel: onCancel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurar Colunas'),
      content: const Text('Personalize as colunas exibidas na visão Kanban.'),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onSave();
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}