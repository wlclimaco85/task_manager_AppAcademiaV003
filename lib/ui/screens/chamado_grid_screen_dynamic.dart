import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/customization/dynamic_grid_dynamic_screen.dart';

class ChamadosScreenDinamic extends StatelessWidget {
  const ChamadosScreenDinamic({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      telaNome: 'chamados',
      hasPermission: (permission) => true,
    );
  }
}
