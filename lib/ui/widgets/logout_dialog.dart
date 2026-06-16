import 'package:flutter/material.dart';

class LogoutDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const LogoutDialog({
    Key? key,
    required this.onConfirm,
  }) : super(key: key);

  static void show(BuildContext context, {required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (context) => LogoutDialog(onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sair da conta'),
      content: const Text('Tem certeza que deseja sair da sua conta?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('Sair'),
        ),
      ],
    );
  }
}