import 'package:flutter/material.dart';

class NotificacoesDrawer extends StatelessWidget {
  final VoidCallback onMarkAllAsRead;
  final VoidCallback onSettings;

  const NotificacoesDrawer({
    Key? key,
    required this.onMarkAllAsRead,
    required this.onSettings,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    VoidCallback? onMarkAllAsRead,
    VoidCallback? onSettings,
  }) {
    Scaffold.of(context).openDrawer();
    // Aqui seria implementado um drawer real ou um modal
    // Por enquanto, usando um SnackBar como placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notificações - Em desenvolvimento'),
        action: SnackBarAction(
          label: 'Configurações',
          onPressed: onSettings ?? () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
