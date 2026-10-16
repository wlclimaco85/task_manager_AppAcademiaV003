import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';

PlanoTreinoModel _treinoOriginal() => const PlanoTreinoModel(
      id: 'plano_origem',
      alunoId: 'aluno_ana',
      alunoNome: 'Ana',
      personalId: 'personal_1',
      titulo: 'Hipertrofia ABC',
      objetivo: 'Força',
      dataInicio: '2026-09-01',
      dataValidade: '2026-12-01',
      divisoes: [
        DivisaoTreinoModel(
          id: 'div_a',
          letra: 'A',
          nome: 'Peito',
          exercicios: [
            ItemTreinoModel(
              id: 'item_1',
              exercicioId: 'ex_supino',
              exercicioNome: 'Supino reto',
              grupoMuscular: 'Peito',
              series: 3,
            ),
          ],
        ),
      ],
    );

void main() {
  test('clone vai para o novo aluno com id e datas proprios', () {
    final clone = _treinoOriginal().clonarParaAluno(
      novoId: 'plano_novo',
      alunoId: 'aluno_bia',
      alunoNome: 'Bia',
      dataInicio: '2026-10-16',
    );

    expect(clone.id, 'plano_novo');
    expect(clone.alunoId, 'aluno_bia');
    expect(clone.alunoNome, 'Bia');
    expect(clone.dataInicio, '2026-10-16');
    expect(clone.dataValidade, isNull);
    expect(clone.ativo, isTrue);
    expect(clone.isTemplate, isFalse);
  });

  test('clone mantem titulo, objetivo, personal e exercicios', () {
    final clone = _treinoOriginal().clonarParaAluno(
      novoId: 'plano_novo',
      alunoId: 'aluno_bia',
      alunoNome: 'Bia',
      dataInicio: '2026-10-16',
    );

    expect(clone.titulo, 'Hipertrofia ABC');
    expect(clone.objetivo, 'Força');
    expect(clone.personalId, 'personal_1');
    expect(clone.divisoes.single.exercicios.single.exercicioNome, 'Supino reto');
    expect(clone.divisoes.single.exercicios.single.series, 3);
  });

  test('alterar o clone nao altera o treino original', () {
    final original = _treinoOriginal();
    final clone = original.clonarParaAluno(
      novoId: 'plano_novo',
      alunoId: 'aluno_bia',
      alunoNome: 'Bia',
      dataInicio: '2026-10-16',
    );

    clone.divisoes.clear();

    expect(clone.divisoes, isEmpty);
    expect(original.divisoes.single.exercicios.single.series, 3);
    expect(original.alunoId, 'aluno_ana');
    expect(original.dataValidade, '2026-12-01');
  });
}
