import 'package:flutter/material.dart';
import 'grid_colors.dart';

ThemeData appTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: GridColors.primary,
      primary: GridColors.primary,
      secondary: GridColors.secondary,
      error: GridColors.error,
      surface: GridColors.card,
      onPrimary: GridColors.textPrimary,
      onSecondary: GridColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: GridColors.primary,
      foregroundColor: GridColors.textPrimary,
      centerTitle: false,
      elevation: 2,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: GridColors.secondary,
      foregroundColor: GridColors.textPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: GridColors.primary, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      labelStyle: const TextStyle(color: GridColors.secondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: GridColors.primary,
        foregroundColor: GridColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: GridColors.secondary,
        side: const BorderSide(color: GridColors.secondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    ),
    dividerColor: GridColors.divider,
    cardColor: GridColors.card,
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: GridColors.secondary,
      contentTextStyle: TextStyle(color: GridColors.textPrimary),
    ),
  );
}
