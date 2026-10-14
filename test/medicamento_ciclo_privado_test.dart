import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/models/fitness/nutricao_farmaco_model.dart';

void main() {
  MedicamentoProtocoloModel med({required String categoria, bool privado = false}) =>
      MedicamentoProtocoloModel(
        id: 'med_1',
        alunoId: 'aluno_1',
        nomeComposto: 'Enantato de Testosterona',
        dosagem: '250mg',
        frequencia: '1x por semana',
        categoria: categoria,
        dataInicio: '2026-10-14',
        privado: privado,
      );

  test('so ciclo anabolizante permite a flag privado', () {
    expect(MedicamentoProtocoloModel.permitePrivado('ergogenico_ciclo'), isTrue);
    for (final c in ['tpc_protetor', 'manipulado_farmacia', 'geral']) {
      expect(MedicamentoProtocoloModel.permitePrivado(c), isFalse, reason: c);
    }
  });

  test('ciclo privado fica oculto para o personal', () {
    expect(med(categoria: 'ergogenico_ciclo', privado: true).visivelParaPersonal, isFalse);
    expect(med(categoria: 'ergogenico_ciclo').visivelParaPersonal, isTrue);
  });

  test('flag em categoria que nao e ciclo nao esconde do personal', () {
    expect(med(categoria: 'geral', privado: true).visivelParaPersonal, isTrue);
  });

  test('flag privado sobrevive ao salvar e ler (toMap/fromMap)', () {
    final lido = MedicamentoProtocoloModel.fromMap(
        med(categoria: 'ergogenico_ciclo', privado: true).toMap());
    expect(lido.privado, isTrue);

    final antigo = Map<String, dynamic>.from(med(categoria: 'ergogenico_ciclo').toMap())
      ..remove('privado');
    expect(MedicamentoProtocoloModel.fromMap(antigo).privado, isFalse,
        reason: 'registros antigos continuam visiveis');
  });
}
