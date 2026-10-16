import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/models/fitness/exercicio_model.dart';
import 'package:task_manager_flutter/data/services/exercicio_conta_sync.dart';

ExercicioModel _base(String id, {String? video}) => ExercicioModel.fromMap({
      'id': id,
      'nome': 'Exercicio $id',
      'grupoMuscular': 'Peitoral',
      'videoUrl': video,
      'instrucoes': 'Instrucao',
      'descricao': '1. Passo',
      'isCustom': false,
    });

Map<String, dynamic> _item(String id, String origem, Map<String, dynamic> dados) => {
      'exercicioId': id,
      'origem': origem,
      'dados': {...dados, 'id': id},
    };

void main() {
  final catalogo = [
    _base('ex_supino', video: 'https://youtu.be/geral'),
    _base('ex_remada', video: 'https://youtu.be/remada'),
  ];

  test('sem personalizacao, o catalogo geral aparece igual para todos', () {
    final lista = ExercicioContaSync.aplicar(catalogo, const []);

    expect(lista.map((e) => e.id), ['ex_supino', 'ex_remada']);
    expect(lista.first.videoUrl, 'https://youtu.be/geral');
  });

  test('edicao do personal troca o video so do exercicio editado', () {
    final lista = ExercicioContaSync.aplicar(catalogo, [
      _item('ex_supino', 'BASE', {'nome': 'Exercicio ex_supino', 'videoUrl': 'https://youtu.be/personal'}),
    ]);

    expect(lista.firstWhere((e) => e.id == 'ex_supino').videoUrl, 'https://youtu.be/personal');
    expect(lista.firstWhere((e) => e.id == 'ex_remada').videoUrl, 'https://youtu.be/remada');
  });

  test('a edicao do aluno vale por cima da do personal', () {
    final lista = ExercicioContaSync.aplicar(catalogo, [
      _item('ex_supino', 'BASE', {'nome': 'Exercicio ex_supino', 'videoUrl': 'https://youtu.be/personal'}),
      _item('ex_supino', 'BASE', {'nome': 'Exercicio ex_supino', 'videoUrl': 'https://youtu.be/aluno'}),
    ]);

    expect(lista.firstWhere((e) => e.id == 'ex_supino').videoUrl, 'https://youtu.be/aluno');
  });

  test('exercicio criado pelo personal entra na lista como personalizado', () {
    final lista = ExercicioContaSync.aplicar(catalogo, [
      _item('ex_meu_1', 'CUSTOM', {'nome': 'Meu exercicio', 'grupoMuscular': 'Costas'}),
    ]);

    expect(lista.length, 3);
    final criado = lista.firstWhere((e) => e.id == 'ex_meu_1');
    expect(criado.nome, 'Meu exercicio');
    expect(criado.isCustom, isTrue);
    expect(lista.firstWhere((e) => e.id == 'ex_supino').isCustom, isFalse);
  });

  test('editar um exercicio criado pela conta mantem a marcacao de personalizado', () {
    final lista = ExercicioContaSync.aplicar(catalogo, [
      _item('ex_meu_1', 'CUSTOM', {'nome': 'Meu exercicio', 'isCustom': true}),
      _item('ex_meu_1', 'BASE', {'nome': 'Meu exercicio', 'isCustom': true, 'videoUrl': 'https://youtu.be/x'}),
    ]);

    final editado = lista.firstWhere((e) => e.id == 'ex_meu_1');
    expect(editado.isCustom, isTrue);
    expect(editado.videoUrl, 'https://youtu.be/x');
  });

  test('ignora itens sem id ou sem dados, sem derrubar a lista', () {
    final lista = ExercicioContaSync.aplicar(catalogo, [
      {'exercicioId': '', 'origem': 'BASE', 'dados': {'nome': 'x'}},
      {'exercicioId': 'ex_remada', 'origem': 'BASE', 'dados': 'invalido'},
    ]);

    expect(lista.map((e) => e.id), ['ex_supino', 'ex_remada']);
  });
}
