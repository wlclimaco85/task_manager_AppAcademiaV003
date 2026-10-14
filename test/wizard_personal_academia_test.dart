import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/wizard_personal_screen.dart';

void main() {
  group('exigeSelecaoAcademia', () {
    test('obrigatoria quando existem academias para escolher', () {
      expect(
          exigeSelecaoAcademia(quantidadeAcademias: 3, falhaAoCarregar: false),
          isTrue);
    });

    test('opcional quando nenhuma academia cadastrada', () {
      expect(
          exigeSelecaoAcademia(quantidadeAcademias: 0, falhaAoCarregar: false),
          isFalse);
    });

    test('continua obrigatoria se a lista falhou ao carregar', () {
      expect(
          exigeSelecaoAcademia(quantidadeAcademias: 0, falhaAoCarregar: true),
          isTrue);
    });
  });
}
