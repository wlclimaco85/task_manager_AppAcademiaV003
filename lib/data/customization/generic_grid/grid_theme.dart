// lib/data/customization/generic_grid/grid_theme.dart
// -----------------------------------------------------------------------------
// 🎨 Tema e Cores padrão do Grid
// -----------------------------------------------------------------------------
import 'package:flutter/material.dart';

class GridColors {
  static const Color primary = Color(0xFF93070A);
  static const Color primaryDark = Color(0xFF6A0507);
  static const Color secondary = Color(0xFF005826);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF000000);
  static const Color background = Color(0xFF005826);
  static const Color card = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA000);
  static const Color success = Color(0xFF2E7D32);
  static const Color divider = Color(0xFFBDBDBD);
}

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
