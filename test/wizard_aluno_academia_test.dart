import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/wizard_aluno_screen.dart';

void main() {
  group('lerAcademiaIdPersonal', () {
    test('le academiaId inteiro do contrato de personais-disponiveis', () {
      expect(
          lerAcademiaIdPersonal({'id': 464, 'nome': 'P', 'academiaId': 153}),
          153);
    });

    test('aceita academiaId como string numerica', () {
      expect(lerAcademiaIdPersonal({'academiaId': '153'}), 153);
    });

    test('personal sem academia retorna null', () {
      expect(lerAcademiaIdPersonal({'id': 1, 'academiaId': null}), isNull);
      expect(lerAcademiaIdPersonal({'id': 1}), isNull);
    });
  });
}
