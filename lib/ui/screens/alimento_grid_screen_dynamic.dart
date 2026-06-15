import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/customization/dynamic_grid_dynamic_screen.dart';

class AlimentoScreenDynamic extends StatelessWidget {
  const AlimentoScreenDynamic({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      telaNome: 'alimento',
      hasPermission: (permission) => true,
    );
  }
}
