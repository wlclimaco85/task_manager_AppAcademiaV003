import 'package:flutter/material.dart';

/// Design System: Paleta de Cores AppAcademia (Padrão MFIT Personal)
/// Tonalidade: Cyber Emerald & Slate Obsidian (Atlética, moderna e de alta legibilidade)
class GridColors {
  // Marca / Ações principais (Substituindo o coral do MFIT por Emerald Pro)
  static const Color primary = Color(0xFF059669); // Emerald 600
  static const Color primaryDark = Color(0xFF047857); // Emerald 700
  static const Color primaryLight = Color(0xFF10B981); // Emerald 500
  static const Color primarySubtle = Color(0xFFECFDF5); // Emerald 50

  // Acentos e Metas
  static const Color secondary = Color(0xFFF59E0B); // Amber 500 (metas, conquistas)
  static const Color secondaryLight = Color(0xFFFDE68A);
  static const Color secondaryDark = Color(0xFFD97706);

  // Superfícies e Fundos (Clean e moderno estilo MFIT)
  static const Color background = Color(0xFFF8FAFC); // Slate 50 (Fundo geral do app)
  static const Color card = Color(0xFFFFFFFF); // Branco para cartões
  static const Color filterBackground = Color(0xFFF1F5F9); // Slate 100
  static const Color dialogBackground = Color(0xFFFFFFFF);

  // Tipografia (Alto contraste WCAG AAA)
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900 (Títulos e destaque)
  static const Color textSecondary = Color(0xFF64748B); // Slate 500 (Subtítulos e labels)
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color textOnPrimary = Color(0xFFFFFFFF); // Texto em botões coloridos

  // Inputs e Controles
  static const Color inputBackground = Color(0xFFF8FAFC);
  static const Color inputBorder = Color(0xFFE2E8F0); // Slate 200
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
  static const Color divider = Color(0xFFE2E8F0); // Slate 200
  static const Color hover = Color(0x0A000000);
  static const Color selectedRow = Color(0xFFECFDF5);
  static const Color shadow = Color(0x0D000000); // Sombra suave moderna

  // Links
  static const Color link = Color(0xFF059669);
}

class CustomColors {
  static const Color primaryGreen = GridColors.primary;
  static const Color darkGreen = GridColors.primaryDark;
  static const Color lightGreen = GridColors.primaryLight;
  static const Color card = GridColors.card;
  static const Color background = GridColors.background;
  static const Color textPrimary = GridColors.textPrimary;
  static const Color textSecondary = GridColors.textSecondary;
  static const Color error = GridColors.error;
  static const Color success = GridColors.success;
  static const Color warning = GridColors.warning;
  static const Color info = GridColors.info;

  final Color _lightGreenBackground = GridColors.card;
  final Color _darkGreenBorder = GridColors.primary;
  final Color _buttonBackground = GridColors.buttonBackground;
  final Color _textColorDesc = GridColors.textSecondary;
  final Color _borderInput = GridColors.inputBorder;
  final Color _textColor = GridColors.textPrimary;
  final Color _negotiationCardBackground = GridColors.card;
  final Color _confirmButtonColor = GridColors.success;
  final Color _cancelButtonColor = GridColors.error;
  final Color _buttonTextColor = GridColors.buttonText;
  final Color _darkBlue = GridColors.textPrimary;
  final Color _headerTable = GridColors.filterBackground;
  final Color _showSnackBarError = GridColors.error;
  final Color _showSnackBarSuccess = GridColors.success;
  final Color _showSnackBarWarning = GridColors.warning;
  final Color _showSnackBarInfo = GridColors.info;
  final Color _showSnackBarText = GridColors.textOnPrimary;

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
