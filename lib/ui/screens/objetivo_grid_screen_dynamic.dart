import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/customization/dynamic_grid_dynamic_screen.dart';

class ObjetivoScreenDynamic extends StatelessWidget {
  const ObjetivoScreenDynamic({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      telaNome: 'objetivo',
      hasPermission: (permission) => true,
    );
  }
}
