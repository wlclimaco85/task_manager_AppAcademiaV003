import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/services/preferencia_tema_service.dart';

/// Luminancia relativa WCAG 2.x.
double _luminancia(Color c) {
  double canal(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * canal(c.r) + 0.7152 * canal(c.g) + 0.0722 * canal(c.b);
}

double _razao(Color a, Color b) {
  final la = _luminancia(a);
  final lb = _luminancia(b);
  final claro = math.max(la, lb);
  final escuro = math.min(la, lb);
  return (claro + 0.05) / (escuro + 0.05);
}

void main() {
  for (final tema in TemaApp.values) {
    group('tema ${tema.name}', () {
      setUp(() => PreferenciaTema.tema.value = tema);
      tearDown(() => PreferenciaTema.tema.value = TemaApp.padrao);

      test('texto principal legivel sobre o fundo (>= 4.5:1)', () {
        expect(_razao(GridColors.textPrimary, GridColors.background), greaterThanOrEqualTo(4.5));
      });

      test('texto secundario legivel sobre o card (>= 4.5:1)', () {
        expect(_razao(GridColors.textSecondary, GridColors.card), greaterThanOrEqualTo(4.5));
      });

      test('texto mutado nunca fica invisivel sobre o card (>= 4.5:1)', () {
        expect(_razao(GridColors.textMuted, GridColors.card), greaterThanOrEqualTo(4.5));
      });

      test('texto sobre cor de marca legivel (>= 4.5:1)', () {
        expect(_razao(GridColors.textOnPrimary, GridColors.primary), greaterThanOrEqualTo(4.5));
      });
    });
  }

  test('Padrao e Branco tem fundos diferentes', () {
    PreferenciaTema.tema.value = TemaApp.padrao;
    final padrao = GridColors.background;
    PreferenciaTema.tema.value = TemaApp.branco;
    final branco = GridColors.background;
    PreferenciaTema.tema.value = TemaApp.padrao;
    expect(padrao, isNot(equals(branco)));
  });
}
