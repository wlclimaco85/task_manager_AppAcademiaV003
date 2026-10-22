import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/models/fitness/profissional_vitrine_model.dart';

void main() {
  test('mantém academia do horário e detalhes do plano recebidos da vitrine', () {
    final horario = HorarioAtendimentoProfissional.fromMap({
      'academiaId': 12,
      'diaSemana': 'Segunda',
      'horarioInicio': '06:00',
      'horarioFim': '08:00',
      'horariosDisponiveis': '["06:00", "07:00"]',
    });
    final plano = PacoteContratacaoModel.fromMap({
      'id': 3,
      'titulo': 'Mensal 3x',
      'descricao': 'Acompanhamento presencial',
      'precoMensal': 300.0,
      'aulasPorSemana': 3,
      'modalidade': 'academia',
      'academiaId': 12,
    });

    expect(horario.academiaId, '12');
    expect(horario.horariosDisponiveis, ['06:00', '07:00']);
    expect(plano.modalidade, 'academia');
    expect(plano.academiaId, '12');
    expect(plano.aulasPorSemana, 3);
  });
}
