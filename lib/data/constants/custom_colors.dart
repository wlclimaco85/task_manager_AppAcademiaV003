import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/services/preferencia_tema_service.dart';

/// Design System: Paleta de Cores AppAcademia (Padrão MFIT Personal)
/// Tonalidade: Cyber Emerald & Slate Obsidian (Atlética, moderna e de alta legibilidade)
/// Suporta dinamicamente os 3 temas: Padrão (Emerald Pro), Branco (Clean) e Preto (OLED Black).
class GridColors {
  // Marca / Ações principais (Emerald Pro)
  // Padrao e Preto: Emerald. Branco: roxo (blusa do desenho) como cor principal.
  static Color get primary => switch (PreferenciaTema.tema.value) {
        TemaApp.barby => const Color(0xFFC2185B),
        TemaApp.branco => const Color(0xFF7828A8), // Roxo da blusa do desenho
        _ => const Color(0xFF047857), // Emerald 700 (contraste >= 4.5:1 sobre branco)
      };
  static Color get primaryDark => switch (PreferenciaTema.tema.value) {
        TemaApp.barby => const Color(0xFF880E4F),
        TemaApp.branco => const Color(0xFF581C87),
        _ => const Color(0xFF065F46), // Emerald 800
      };
  static Color get primaryLight => switch (PreferenciaTema.tema.value) {
        TemaApp.barby => const Color(0xFFEC407A),
        TemaApp.branco => const Color(0xFF9333EA),
        _ => const Color(0xFF10B981), // Emerald 500
      };

  static Color get primarySubtle => switch (PreferenciaTema.tema.value) {
        TemaApp.preto => const Color(0xFF064E3B), // Emerald 900 escuro para contraste no preto
        TemaApp.barby => const Color(0xFFFCE4EC),
        TemaApp.branco => const Color(0xFFF3E8FF), // Roxo claro
        _ => const Color(0xFFECFDF5), // Emerald 50
      };

  // Acentos e Metas. Branco: laranja do fundo do desenho.
  static Color get secondary => switch (PreferenciaTema.tema.value) {
        TemaApp.barby => const Color(0xFF7B1FA2),
        TemaApp.branco => const Color(0xFFE87848), // Laranja do desenho
        _ => const Color(0xFFF59E0B), // Amber 500 (metas, conquistas)
      };
  static Color get secondaryLight => switch (PreferenciaTema.tema.value) {
        TemaApp.barby => const Color(0xFFF3E5F5),
        TemaApp.branco => const Color(0xFFFBD3BD),
        _ => const Color(0xFFFDE68A),
      };
  static Color get secondaryDark => switch (PreferenciaTema.tema.value) {
        TemaApp.barby => const Color(0xFF4A148C),
        TemaApp.branco => const Color(0xFFC2562A),
        _ => const Color(0xFFD97706),
      };

  // Superfícies e Fundos (Adaptativos aos 3 temas)
  static Color get background => switch (PreferenciaTema.tema.value) {
        TemaApp.preto => Colors.black,
        TemaApp.barby => const Color(0xFFFFF0F6),
        TemaApp.branco => Colors.white,
        TemaApp.padrao => const Color(0xFFF8FAFC), // Slate 50
      };

  static Color get card => switch (PreferenciaTema.tema.value) {
        TemaApp.preto => const Color(0xFF111827), // Slate 900 escuro
        TemaApp.barby => const Color(0xFFFFFFFF),
        TemaApp.branco => Colors.white,
        TemaApp.padrao => const Color(0xFFFFFFFF),
      };

  static Color get filterBackground => switch (PreferenciaTema.tema.value) {
        TemaApp.preto => const Color(0xFF1E293B),
        TemaApp.barby => const Color(0xFFFFE4EF),
        TemaApp.branco => const Color(0xFFF8FAFC),
        TemaApp.padrao => const Color(0xFFF1F5F9),
      };

  static Color get dialogBackground => switch (PreferenciaTema.tema.value) {
        TemaApp.preto => const Color(0xFF111827),
        TemaApp.barby => const Color(0xFFFFFFFF),
        TemaApp.branco => Colors.white,
        TemaApp.padrao => const Color(0xFFFFFFFF),
      };

  // Tipografia (Alto contraste WCAG AAA para cada tema)
  static Color get textPrimary => switch (PreferenciaTema.tema.value) {
        TemaApp.preto => const Color(0xFFF8FAFC), // Slate 50 (quase branco)
        TemaApp.barby => const Color(0xFF3B0A24),
        TemaApp.branco => const Color(0xFF0F172A),
        TemaApp.padrao => const Color(0xFF0F172A), // Slate 900
      };

  static Color get textSecondary => switch (PreferenciaTema.tema.value) {
        TemaApp.preto => const Color(0xFF94A3B8), // Slate 400
        TemaApp.barby => const Color(0xFF5A233F),
        TemaApp.branco => const Color(0xFF475569), // Slate 600
        TemaApp.padrao => const Color(0xFF475569), // Slate 600
      };

  static Color get textMuted => switch (PreferenciaTema.tema.value) {
        TemaApp.preto => const Color(0xFFA1A1AA), // Zinc 400
        TemaApp.barby => const Color(0xFF683046),
        TemaApp.branco => const Color(0xFF475569), // Slate 600
        TemaApp.padrao => const Color(0xFF475569), // Slate 600
      };

  static const Color textOnPrimary = Color(0xFFFFFFFF); // Texto em botões coloridos

  // Inputs e Controles
  static Color get inputBackground => switch (PreferenciaTema.tema.value) {
        TemaApp.preto => const Color(0xFF18212F),
        TemaApp.barby => const Color(0xFFFFF7FB),
        TemaApp.branco => const Color(0xFFF8FAFC),
        TemaApp.padrao => const Color(0xFFF8FAFC),
      };

  static Color get inputBorder => switch (PreferenciaTema.tema.value) {
        TemaApp.preto => const Color(0xFF334155),
        TemaApp.barby => const Color(0xFFF1B6CC),
        TemaApp.branco => const Color(0xFFE2E8F0),
        TemaApp.padrao => const Color(0xFFE2E8F0),
      };

  static const Color inputBorderFocus = Color(0xFF059669);
  static const Color buttonBackground = Color(0xFF059669);
  static const Color buttonText = Color(0xFFFFFFFF);

  // Estados
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color info = Color(0xFF3B82F6); // Blue 500

  // Estrutura
  static Color get divider => switch (PreferenciaTema.tema.value) {
        TemaApp.preto => const Color(0xFF334155),
        TemaApp.barby => const Color(0xFFF1B6CC),
        TemaApp.branco => const Color(0xFFE2E8F0),
        TemaApp.padrao => const Color(0xFFE2E8F0),
      };

  static Color get hover => switch (PreferenciaTema.tema.value) {
        TemaApp.preto => const Color(0x1AFFFFFF),
        TemaApp.barby => const Color(0x14000000),
        _ => const Color(0x0A000000),
      };

  static Color get selectedRow => switch (PreferenciaTema.tema.value) {
        TemaApp.preto => const Color(0xFF064E3B),
        TemaApp.barby => const Color(0xFFFCE4EC),
        _ => const Color(0xFFECFDF5),
      };

  static Color get shadow => switch (PreferenciaTema.tema.value) {
        TemaApp.preto => const Color(0x40000000),
        TemaApp.barby => const Color(0x1A9D174D),
        _ => const Color(0x0D000000),
      };

  // Links
  static const Color link = Color(0xFF059669);
}

/// Cores semanticas que acompanham os temas Padrao, Branco e Preto.
/// Use estas propriedades em widgets novos ou em telas que precisam reagir
/// ao tema; [GridColors] continua sendo a paleta de marca.
extension AppThemeColors on BuildContext {
  Color get appBackground => Theme.of(this).scaffoldBackgroundColor;
  Color get appSurface => Theme.of(this).colorScheme.surface;
  Color get appSurfaceAlt => Theme.of(this).colorScheme.surfaceContainerLow;
  Color get appText => Theme.of(this).colorScheme.onSurface;
  Color get appTextSecondary => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get appBorder => Theme.of(this).colorScheme.outlineVariant;
}

class CustomColors {
  static Color get primaryGreen => GridColors.primary;
  static Color get darkGreen => GridColors.primaryDark;
  static Color get lightGreen => GridColors.primaryLight;
  static Color get card => GridColors.card;
  static Color get background => GridColors.background;
  static Color get textPrimary => GridColors.textPrimary;
  static Color get textSecondary => GridColors.textSecondary;
  static const Color error = GridColors.error;
  static const Color success = GridColors.success;
  static const Color warning = GridColors.warning;
  static const Color info = GridColors.info;

  Color get _lightGreenBackground => GridColors.card;
  Color get _darkGreenBorder => GridColors.primary;
  Color get _buttonBackground => GridColors.buttonBackground;
  Color get _textColorDesc => GridColors.textSecondary;
  Color get _borderInput => GridColors.inputBorder;
  Color get _textColor => GridColors.textPrimary;
  Color get _negotiationCardBackground => GridColors.card;
  Color get _confirmButtonColor => GridColors.success;
  Color get _cancelButtonColor => GridColors.error;
  Color get _buttonTextColor => GridColors.buttonText;
  Color get _darkBlue => GridColors.textPrimary;
  Color get _headerTable => GridColors.filterBackground;
  Color get _showSnackBarError => GridColors.error;
  Color get _showSnackBarSuccess => GridColors.success;
  Color get _showSnackBarWarning => GridColors.warning;
  Color get _showSnackBarInfo => GridColors.info;
  Color get _showSnackBarText => GridColors.textOnPrimary;

  Color getShowSnackBarText() => _showSnackBarText;
  Color getShowSnackBarInfo() => _showSnackBarInfo;
  Color getShowSnackBarWarning() => _showSnackBarWarning;
  Color getShowSnackBarSuccess() => _showSnackBarSuccess;
  Color getShowSnackBarError() => _showSnackBarError;
  Color getBorderInput() => _borderInput;
  Color getLightGreenBackground() => _lightGreenBackground;
  Color getDarkBlue() => _darkBlue;
  Color getDarkGreenBorder() => _darkGreenBorder;
  Color getButtonBackground() => _buttonBackground;
  Color getTextColorDesc() => _textColorDesc;
  Color getTextColor() => _textColor;
  Color getNegotiationCardBackground() => _negotiationCardBackground;
  Color getConfirmButtonColor() => _confirmButtonColor;
  Color getCancelButtonColor() => _cancelButtonColor;
  Color getButtonTextColor() => _buttonTextColor;
  Color getHeaderTable() => _headerTable;
}
