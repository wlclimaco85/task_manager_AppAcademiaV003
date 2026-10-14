// lib/data/customization/generic_grid/grid_theme.dart
// -----------------------------------------------------------------------------
// 🎨 Tema e Cores padrão do Grid
// -----------------------------------------------------------------------------
import 'package:flutter/material.dart';

import 'package:task_manager_flutter/data/utils/grid_colors.dart';
export 'package:task_manager_flutter/data/utils/grid_colors.dart';

// -----------------------------------------------------------------------------
// 🎛️ Estilos de texto (opcional para centralizar padrões de texto do grid)
// -----------------------------------------------------------------------------
class GridTextStyles {
  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Colors.black54,
  );

  static const TextStyle value = TextStyle(
    fontSize: 13,
    color: Colors.black87,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: GridColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: GridColors.primary,
  );
}
