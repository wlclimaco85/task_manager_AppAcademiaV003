import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/customization/dynamic_grid_dynamic_screen.dart';

class ModalidadeScreenDynamic extends StatelessWidget {
  const ModalidadeScreenDynamic({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      telaNome: 'modalidade',
      hasPermission: (permission) => true,
    );
  }
}
