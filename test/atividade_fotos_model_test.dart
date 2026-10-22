import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/services/fitness_360_local_store.dart';

void main() {
  test('preserva até três fotos no registro de atividade', () {
    final registro = Fitness360Record.fromJson({
      'id': 21,
      'type': 'atividade',
      'title': 'Caminhada',
      'value': '4.0 km',
      'note': 'Parque',
      'createdAt': '2026-10-22T10:00:00.000',
      'fotosBase64': ['foto-1', 'foto-2', 'foto-3', 'foto-extra'],
    });

    expect(registro.fotosBase64, ['foto-1', 'foto-2', 'foto-3']);
    expect(registro.toJson()['fotosBase64'], ['foto-1', 'foto-2', 'foto-3']);
  });
}
