import 'package:flutter/material.dart';

class GridColors {
  static const Color primary = Color(0xFF5937B2);
  static const Color primaryDark = Color(0xFF340A9C);
  static const Color primaryLight = Color(0xFF7859C9);
  static const Color secondary = Color(0xFFFA903A);
  static const Color secondaryLight = Color(0xFFFFB16F);
  static const Color secondaryDark = Color(0xFFC66A1F);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF241B3F);
  static const Color link = Color(0xFFFA903A);
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFF5937B2);
  static const Color buttonBackground = Color(0xFFFA903A);
  static const Color buttonText = Color(0xFFFFFFFF);
  static const Color background = Color(0xFF5937B2);
  static const Color card = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA000);
  static const Color success = Color(0xFF2E7D32);
  static const Color info = Color(0xFF1976D2);
  static const Color divider = Color(0xFFBDBDBD);
  static const Color filterBackground = Color(0xFFF4F0FF);
  static const Color hover = Color(0x1A000000);
  static const Color selectedRow = Color(0xFFF4F0FF);
  static const Color dialogBackground = Color(0xFFFFFFFF);
  static const Color shadow = Color(0x26000000);
}

class CustomColors {
  final Color _lightGreenBackground = GridColors.card;
  final Color _darkGreenBorder = GridColors.primary;
  final Color _buttonBackground = GridColors.buttonBackground;
  final Color _textColorDesc = GridColors.textSecondary;
  final Color _borderInput = GridColors.inputBorder;
  final Color _textColor = GridColors.textSecondary;
  final Color _negotiationCardBackground = GridColors.card;
  final Color _confirmButtonColor = GridColors.success;
  final Color _cancelButtonColor = GridColors.error;
  final Color _buttonTextColor = GridColors.buttonText;
  final Color _darkBlue = GridColors.background;
  final Color _headerTable = GridColors.filterBackground;
  final Color _showSnackBarError = GridColors.error;
  final Color _showSnackBarSuccess = GridColors.success;
  final Color _showSnackBarWarning = GridColors.warning;
  final Color _showSnackBarInfo = GridColors.info;
  final Color _showSnackBarText = GridColors.textPrimary;

  Color getShowSnackBarText() {
    return _showSnackBarText;
  }

  Color getShowSnackBarInfo() {
    return _showSnackBarInfo;
  }

  Color getShowSnackBarWarning() {
    return _showSnackBarWarning;
  }

  Color getShowSnackBarSuccess() {
    return _showSnackBarSuccess;
  }

  Color getShowSnackBarError() {
    return _showSnackBarError;
  }

  getBorderInput() {
    return _borderInput;
  }

  getLightGreenBackground() {
    return _lightGreenBackground;
  }

  getDarkBlue() {
    return _darkBlue;
  }

  getDarkGreenBorder() {
    return _darkGreenBorder;
  }

  getButtonBackground() {
    return _buttonBackground;
  }

  getTextColorDesc() {
    return _textColorDesc;
  }

  getTextColor() {
    return _textColor;
  }

  getNegotiationCardBackground() {
    return _negotiationCardBackground;
  }

  getConfirmButtonColor() {
    return _confirmButtonColor;
  }

  getCancelButtonColor() {
    return _cancelButtonColor;
  }

  getButtonTextColor() {
    return _buttonTextColor;
  }

  getHeaderTable() {
    return _headerTable;
  }
}
