import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/profissional_vitrine_model.dart';
import 'package:task_manager_flutter/data/services/profissionais_vitrine_repository.dart';

/// Profissional de teste criado pelo proprio teste. A vitrine nao traz mais dados
/// de demonstracao: cada cenario prepara o que precisa antes de executar.
ProfissionalVitrineModel _personalDeTeste() => ProfissionalVitrineModel(
      id: 'prof-1',
      nome: 'Rodrigo Medeiros',
      categoria: CategoriaProfissional.personal,
      registroProfissional: '123456-G/MG',
      especialidade: 'Hipertrofia',
      bioResumo: 'Personal de teste',
      whatsapp: '(34) 99999-0000',
      precoMinimoMensal: 250,
      academiasAtendidas: const [
        AcademiaAtendimentoModel(
          id: 'smartfit-uba',
          nome: 'SmartFit Shopping Uberaba',
          endereco: 'Av. Leopoldino de Oliveira, 4000',
          bairroCidade: 'Uberaba - MG',
        ),
      ],
      gradeHorarios: const [
        HorarioAtendimentoProfissional(
          diaSemana: 'Segunda-feira',
          horarioInicio: '06:00',
          horarioFim: '21:00',
          horariosDisponiveis: ['07:00', '08:00'],
        ),
      ],
      pacotes: const [],
    );

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Suite de Vitrine & Academias de Uberaba - MG', () {
    test('1. Listar e filtrar profissionais com foco em Uberaba - MG', () async {
      final repo = ProfissionaisVitrineRepository();
      await repo.salvarProfissional(_personalDeTeste());

      // Buscar todos os profissionais
      final todos = await repo.getProfissionais();
      expect(todos.isNotEmpty, isTrue);

      // Personal atendendo a SmartFit de Uberaba
      final rodrigo = todos.firstWhere((p) => p.id == 'prof-1');
      expect(rodrigo.registroProfissional, contains('/MG'));
      expect(rodrigo.academiasAtendidas.any((a) => a.nome.contains('Shopping Uberaba')), isTrue);
    });

    test('2. Personal cadastrar nova academia em Uberaba', () async {
      final repo = ProfissionaisVitrineRepository();
      await repo.salvarProfissional(_personalDeTeste());

      final novaAcademia = const AcademiaAtendimentoModel(
        id: 'ura-ct-custom',
        nome: 'Centro de Treinamento Alpha Uberaba',
        endereco: 'Av. Nenê Sabino, 1400',
        bairroCidade: 'Olinda, Uberaba - MG',
      );

      await repo.cadastrarNovaAcademia(novaAcademia);

      final listaAcademias = await repo.getAcademiasCadastradas();
      expect(listaAcademias.any((a) => a.nome == 'Centro de Treinamento Alpha Uberaba'), isTrue);

      // Vincular academia ao personal
      await repo.vincularAcademiaAoPersonal(
        personalId: 'prof-1',
        academia: novaAcademia,
      );

      final profAtualizado = await repo.getProfissionalPorId('prof-1');
      expect(profAtualizado!.academiasAtendidas.any((a) => a.nome == 'Centro de Treinamento Alpha Uberaba'), isTrue);
    });

    test('3. Gestão e Visualização da Disponibilidade de Horários Livres', () async {
      final repo = ProfissionaisVitrineRepository();
      await repo.salvarProfissional(_personalDeTeste());

      final prof = await repo.getProfissionalPorId('prof-1');
      expect(prof!.totalHorariosLivres, greaterThan(0));

      // Atualizar disponibilidade: marcar 14:00 como livre na segunda-feira
      await repo.atualizarDisponibilidadeHorario(
        personalId: 'prof-1',
        diaSemana: 'Segunda-feira',
        horario: '14:00',
        marcarComoLivre: true,
      );

      final profPosAjuste = await repo.getProfissionalPorId('prof-1');
      final gradeSegunda = profPosAjuste!.gradeHorarios.firstWhere((g) => g.diaSemana == 'Segunda-feira');
      expect(gradeSegunda.horariosDisponiveis.contains('14:00'), isTrue);
    });
  });
}
