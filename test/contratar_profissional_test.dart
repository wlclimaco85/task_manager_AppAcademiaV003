import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/profissional_vitrine_model.dart';
import 'package:task_manager_flutter/data/services/profissionais_vitrine_repository.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Suite de Vitrine e Contratação de Profissionais (Personal & Nutricionista)', () {
    test('1. Listar e filtrar profissionais por categoria', () async {
      final repo = ProfissionaisVitrineRepository();

      // Buscar todos
      final todos = await repo.getProfissionais();
      expect(todos.length, greaterThanOrEqualTo(3));

      // Filtrar apenas Personais
      final personais = await repo.getProfissionais(
        categoria: CategoriaProfissional.personal,
      );
      expect(personais.every((p) => p.categoria == CategoriaProfissional.personal), isTrue);

      // Filtrar apenas Nutricionistas
      final nutris = await repo.getProfissionais(
        categoria: CategoriaProfissional.nutricionista,
      );
      expect(nutris.every((p) => p.categoria == CategoriaProfissional.nutricionista), isTrue);
    });

    test('2. Filtrar por Academia atendida e busca por texto', () async {
      final repo = ProfissionaisVitrineRepository();

      // Filtrar por Ironberg
      final ironbergProfs = await repo.getProfissionais(
        academiaFiltro: 'Ironberg',
      );
      expect(ironbergProfs.isNotEmpty, isTrue);
      expect(ironbergProfs.any((p) => p.nome.contains('Rodrigo')), isTrue);

      // Busca por texto "Biomecânica"
      final busca = await repo.getProfissionais(buscaTexto: 'Biomecânica');
      expect(busca.length, equals(1));
      expect(busca.first.nome, contains('Rodrigo'));
    });

    test('3. Grade de Horários Livres e Pacotes com WhatsApp', () async {
      final repo = ProfissionaisVitrineRepository();
      final prof = await repo.getProfissionalPorId('prof-1');

      expect(prof, isNotNull);
      expect(prof!.totalHorariosLivres, greaterThan(0));
      expect(prof.whatsapp, contains('98111-2233'));
      expect(prof.pacotes.isNotEmpty, isTrue);

      final pacoteDestaque = prof.pacotes.firstWhere((p) => p.destaque);
      expect(pacoteDestaque.precoMensal, equals(650.0));
      expect(pacoteDestaque.aulasPorSemana, equals(3));
    });
  });
}
