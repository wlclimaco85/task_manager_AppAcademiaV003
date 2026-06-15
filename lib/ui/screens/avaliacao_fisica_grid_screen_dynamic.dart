import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/customization/dynamic_grid_dynamic_screen.dart';

class AvaliacaoFisicaScreenDynamic extends StatelessWidget {
  const AvaliacaoFisicaScreenDynamic({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      telaNome: 'avaliacao_fisica',
      hasPermission: (permission) => true,
    );
  }
}
