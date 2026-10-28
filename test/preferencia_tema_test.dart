import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/services/preferencia_tema_service.dart';

void main() {
  group('modoDe', () {
    test('padrao mantem o visual claro atual, sem seguir o aparelho', () {
      expect(PreferenciaTema.modoDe(TemaApp.padrao), ThemeMode.light);
    });

    test('branco e sempre claro', () {
      expect(PreferenciaTema.modoDe(TemaApp.branco), ThemeMode.light);
    });

    test('barby e sempre claro', () {
      expect(PreferenciaTema.modoDe(TemaApp.barby), ThemeMode.light);
    });

    test('preto e sempre escuro', () {
      expect(PreferenciaTema.modoDe(TemaApp.preto), ThemeMode.dark);
    });
  });

  group('lerSalvo', () {
    test('le cada opcao pelo nome salvo', () {
      expect(PreferenciaTema.lerSalvo('branco'), TemaApp.branco);
      expect(PreferenciaTema.lerSalvo('preto'), TemaApp.preto);
      expect(PreferenciaTema.lerSalvo('barby'), TemaApp.barby);
    });

    test('valor ausente ou desconhecido cai no padrao', () {
      expect(PreferenciaTema.lerSalvo(null), TemaApp.padrao);
      expect(PreferenciaTema.lerSalvo('neon'), TemaApp.padrao);
    });
  });
}
