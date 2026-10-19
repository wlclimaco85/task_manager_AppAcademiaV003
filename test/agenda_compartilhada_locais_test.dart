import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/agenda_evento_model.dart';
import 'package:task_manager_flutter/data/services/agenda_repository.dart';
import 'package:task_manager_flutter/ui/screens/fitness/agenda_compartilhada_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Agenda e Locais: Academias e Residencia por ultimo', () {
    test('tela agenda_compartilhada define lista de locais com academias e residencia por ultimo', () {
      const screen = AgendaCompartilhadaScreen();
      final state = screen.createState() as dynamic;

      // Executa _locaisDisponiveis
      final locais = state.locaisDisponiveisTest();
      expect(locais, isNotEmpty);
      expect(locais.last, 'Residência',
          reason: 'O requisito explicito exige que Residencia seja a ultima opcao da lista');
      
      expect(locais.contains('Smart Fit'), isTrue);
      expect(locais.contains('Bluefit'), isTrue);
      expect(locais.contains('Bodytech'), isTrue);
      
      // Residencia não pode aparecer duplicada no meio
      final indexResidencia = locais.indexOf('Residência');
      expect(indexResidencia, equals(locais.length - 1));
    });

    test('AgendaRepository salva e recupera eventos offline em cache', () async {
      final repo = AgendaRepository();
      final inicio = DateTime(2026, 10, 20, 10, 0);
      final fim = DateTime(2026, 10, 20, 11, 0);

      final criados = await repo.criar({
        'titulo': 'Aula com personal',
        'tipo': 'AULA',
        'inicio': inicio.toIso8601String(),
        'fim': fim.toIso8601String(),
        'local': 'Residência',
        'observacao': 'Treino funcional na sala',
        'lembreteMinutos': 30,
      });

      expect(criados, isNotEmpty);
      expect(criados.first.local, 'Residência');
      expect(criados.first.titulo, 'Aula com personal');

      final listados = await repo.listar(
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 31),
      );

      expect(listados, isNotEmpty);
      expect(listados.any((e) => e.local == 'Residência'), isTrue);
    });

    test('AgendaEventoModel toMap e fromMap mantem consistencia do campo local', () {
      final evento = AgendaEventoModel(
        id: 'ev_123',
        titulo: 'Treino de Musculação',
        tipo: 'TREINO',
        inicio: DateTime(2026, 10, 21, 8, 0),
        fim: DateTime(2026, 10, 21, 9, 0),
        local: 'Smart Fit',
      );

      final map = evento.toMap();
      expect(map['local'], 'Smart Fit');

      final reconstruido = AgendaEventoModel.fromMap(map);
      expect(reconstruido.id, 'ev_123');
      expect(reconstruido.local, 'Smart Fit');
      expect(reconstruido.titulo, 'Treino de Musculação');
    });
  });
}
