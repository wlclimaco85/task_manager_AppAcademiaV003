import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/services/avaliacao_agendada_service.dart';

void main() {
  final hoje = DateTime(2026, 10, 16, 15, 30);

  group('situacao da avaliacao agendada', () {
    test('data anterior a hoje esta vencida', () {
      expect(AvaliacaoAgendadaService.situacao(DateTime(2026, 10, 15), hoje),
          SituacaoAvaliacao.vencida);
    });

    test('hoje ja conta como proxima, mesmo com horario diferente', () {
      expect(AvaliacaoAgendadaService.situacao(DateTime(2026, 10, 16, 8), hoje),
          SituacaoAvaliacao.proxima);
    });

    test('dentro do prazo de aviso (7 dias) vira proxima', () {
      expect(AvaliacaoAgendadaService.situacao(DateTime(2026, 10, 23), hoje),
          SituacaoAvaliacao.proxima);
    });

    test('depois do prazo de aviso fica distante', () {
      expect(AvaliacaoAgendadaService.situacao(DateTime(2026, 10, 24), hoje),
          SituacaoAvaliacao.distante);
    });
  });

  group('armazenamento', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('agendar e listar devolve a mesma data por aluno', () async {
      await AvaliacaoAgendadaService.agendar('aluno_1', DateTime(2026, 11, 3, 10));

      final lista = await AvaliacaoAgendadaService.listar();

      expect(lista['aluno_1'], DateTime(2026, 11, 3));
    });

    test('cancelar remove a avaliacao do aluno', () async {
      await AvaliacaoAgendadaService.agendar('aluno_1', DateTime(2026, 11, 3));
      await AvaliacaoAgendadaService.agendar('aluno_2', DateTime(2026, 11, 4));

      await AvaliacaoAgendadaService.cancelar('aluno_1');

      final lista = await AvaliacaoAgendadaService.listar();
      expect(lista.containsKey('aluno_1'), isFalse);
      expect(lista['aluno_2'], DateTime(2026, 11, 4));
    });

    test('dado corrompido no aparelho nao derruba a leitura', () async {
      SharedPreferences.setMockInitialValues({'avaliacoes_agendadas_v1': '{não é json'});

      expect(await AvaliacaoAgendadaService.listar(), isEmpty);
    });
  });
}
