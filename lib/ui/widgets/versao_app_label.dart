import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/app_version.dart';

/// Versao do app (nome, build e commit), mostrada no rodape do app e do web.
class VersaoAppLabel extends StatelessWidget {
  const VersaoAppLabel({super.key, this.cor});

  final Color? cor;

  @override
  Widget build(BuildContext context) {
    return Text(
      kAppVersaoTexto,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11,
        color: cor ?? Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
