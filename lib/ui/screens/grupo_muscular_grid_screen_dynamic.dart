import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/customization/dynamic_grid_dynamic_screen.dart';

class GrupoMuscularScreenDynamic extends StatelessWidget {
  const GrupoMuscularScreenDynamic({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      telaNome: 'grupo_muscular',
      hasPermission: (permission) => true,
    );
  }
}
