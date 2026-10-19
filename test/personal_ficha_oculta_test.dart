import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/models/fitness/personal_gestao_model.dart';

void main() {
  const base = PersonalAlunoGestaoModel(
    id: '1',
    nome: 'Aluno',
    email: 'aluno@teste.com',
    telefone: '',
  );

  test('ficha visivel por padrao', () {
    expect(base.fichaOcultaParaAluno, isFalse);
  });

  test('flag sobrevive ao ida e volta em toMap/fromMap', () {
    final oculta = base.copyWith(fichaOcultaParaAluno: true);
    final lido = PersonalAlunoGestaoModel.fromMap(oculta.toMap());
    expect(lido.fichaOcultaParaAluno, isTrue);
  });

  test('registro antigo sem o campo volta como ficha visivel', () {
    final lido = PersonalAlunoGestaoModel.fromMap(base.toMap()..remove('fichaOcultaParaAluno'));
    expect(lido.fichaOcultaParaAluno, isFalse);
  });
}
