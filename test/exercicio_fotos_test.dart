import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/models/fitness/exercicio_model.dart';

void main() {
  test('fotos do exercicio sobrevivem a ida e volta do mapa', () {
    const foto = 'data:image/jpeg;base64,/9j/4AAQSkZJRg==';
    const ex = ExercicioModel(id: 'ex_1', nome: 'Supino', grupoMuscular: 'Peito', fotos: [foto, foto]);

    final volta = ExercicioModel.fromMap(ex.toMap());

    expect(volta.fotos, [foto, foto]);
  });

  test('exercicio sem fotos le lista vazia e ignora entradas invalidas', () {
    final semFotos = ExercicioModel.fromMap({'id': 'ex_2', 'nome': 'Remada', 'grupoMuscular': 'Costas'});
    expect(semFotos.fotos, isEmpty);

    final comLixo = ExercicioModel.fromMap({
      'id': 'ex_3',
      'nome': 'Remada',
      'grupoMuscular': 'Costas',
      'fotos': ['data:image/png;base64,iVBORw0KGgo=', '', 42, null],
    });
    expect(comLixo.fotos, ['data:image/png;base64,iVBORw0KGgo=']);
  });
}
