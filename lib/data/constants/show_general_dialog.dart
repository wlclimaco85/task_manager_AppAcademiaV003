import 'package:flutter/material.dart';
import 'dart:ui';

Future<T?> showM3Dialog<T>({
  required BuildContext context,
  required Widget child,
  String barrierLabel = 'Dialog',
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierLabel: barrierLabel,
    barrierDismissible: true,
    barrierColor: Colors.black38,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => Center(
      child: Material(color: Colors.transparent, child: child),
    ),
    transitionBuilder: (_, anim, __, dialogChild) {
      final offsetAnim = Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: FadeTransition(
          opacity: anim,
          child: SlideTransition(position: offsetAnim, child: dialogChild),
        ),
      );
    },
  );
}
