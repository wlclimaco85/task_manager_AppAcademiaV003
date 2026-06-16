import 'package:flutter/material.dart';

class ConfirmarLogoutDialog extends StatelessWidget {
  const ConfirmarLogoutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sair'),
      content: const Text('Deseja realmente sair do aplicativo?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sair'),
        ),
      ],
    );
  }
}
