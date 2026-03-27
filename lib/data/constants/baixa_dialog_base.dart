import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';

/// Helpers e estilo compartilhado para os diálogos de Baixa
class BaixaDialogBase {
  static const double kFieldGap = 16;
  static const EdgeInsets kDialogContentPadding =
      EdgeInsets.symmetric(horizontal: 4, vertical: 8);

  static Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? validatorMsg,
    TextInputType keyboardType = TextInputType.number,
    required CustomColors colors,
  }) {
    return Padding(
      padding: kDialogContentPadding,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: GridColors.inputBorder),
          filled: true,
          fillColor: GridColors.inputBackground,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.getBorderInput(), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.getBorderInput(), width: 1.6),
          ),
        ),
        keyboardType: keyboardType,
        validator: (v) => (validatorMsg != null && (v == null || v.isEmpty))
            ? validatorMsg
            : null,
      ),
    );
  }

  static Widget buildDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required String validatorMsg,
    required CustomColors colors,
  }) {
    return Padding(
      padding: kDialogContentPadding,
      child: DropdownButtonFormField<T>(
        isExpanded: true,
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: GridColors.inputBorder),
          filled: true,
          fillColor: GridColors.inputBackground,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.getBorderInput(), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.getBorderInput(), width: 1.6),
          ),
        ),
        items: items,
        onChanged: onChanged,
        validator: (v) => (v == null) ? validatorMsg : null,
      ),
    );
  }

  static Widget buildDateRow({
    required DateTime date,
    required VoidCallback onPick,
  }) {
    return Padding(
      padding: kDialogContentPadding,
      child: Row(
        children: [
          const Icon(Icons.calendar_today,
              size: 20, color: GridColors.inputBorder),
          const SizedBox(width: 8),
          const Text('Data da Baixa:'),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onPick,
            child: Text(
              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: GridColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// Transição padronizada: blur + fade + slide
  static Future<void> showDialogWithTransition({
    required BuildContext context,
    required String barrierLabel,
    required Widget child,
  }) {
    return showGeneralDialog(
      context: context,
      barrierLabel: barrierLabel,
      barrierDismissible: true,
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) =>
          Center(child: Material(color: Colors.transparent, child: child)),
      transitionBuilder: (_, anim, __, theChild) {
        final offsetAnim = Tween<Offset>(
                begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: FadeTransition(
              opacity: anim,
              child: SlideTransition(position: offsetAnim, child: theChild)),
        );
      },
    );
  }
}
