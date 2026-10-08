import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/exame_registro_model.dart';
import 'package:task_manager_flutter/data/services/exames_offline_repository.dart';
import 'package:task_manager_flutter/data/services/nutricao_farmaco_offline_repository.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Suite de Exames Clínicos e Laudos PDF com Dashboards & Timeline 360', () {
    test('1. Listar e filtrar exames laboratoriais e hormonais', () async {
      final repo = ExamesOfflineRepository();
      final exames = await repo.getExames();

      expect(exames.isNotEmpty, isTrue);
      expect(exames.length, greaterThanOrEqualTo(3));

      // Verificar exame hormonal do Lucas
      final hormonal = exames.firstWhere((e) => e.categoria == CategoriaExame.hormonal);
      expect(hormonal.titulo, contains('Painel Hormonal'));
      expect(hormonal.nomeArquivoPdf, contains('.pdf'));
      expect(hormonal.dataExame, isNotEmpty);
      expect(hormonal.laboratório, contains('Sabin'));
    });

    test('2. Cadastrar novo exame com anexo PDF e marcadores clínicos', () async {
      final repo = ExamesOfflineRepository();

      final novoExame = const ExameRegistroModel(
        id: 'exame_custom_1',
        alunoId: 'aluno-1',
        alunoNome: 'Lucas Mendonça',
        titulo: 'Exame de Bioimpedância InBody 770',
        categoria: CategoriaExame.bioimpedancia,
        dataExame: '2026-10-08',
        laboratório: 'Clínica BioNutri Uberaba',
        medicoSolicitante: 'Dr. Roberto Endocrinologista',
        nomeArquivoPdf: 'inbody_770_outubro_2026.pdf',
        urlPdf: 'https://appacademia.com.br/docs/inbody_770.pdf',
        observacoesResultados: 'Massa Magra: 42.5kg, Gordura Corporal: 11.0%, Água Corporal: 58.2L',
      );

      await repo.salvarExame(novoExame);

      final examesAtualizados = await repo.getExames(alunoId: 'aluno-1');
      expect(examesAtualizados.any((e) => e.id == 'exame_custom_1'), isTrue);
    });

    test('3. Exames integrados na Timeline Fitness 360 do Aluno e Profissionais', () async {
      final nutricaoRepo = NutricaoFarmacoOfflineRepository();
      final timeline = await nutricaoRepo.getTimelineEventos(alunoId: 'aluno-1');

      expect(timeline.isNotEmpty, isTrue);
      expect(timeline.any((e) => e.tipo == 'exame_laboratorial'), isTrue);

      final eventoExame = timeline.firstWhere((e) => e.tipo == 'exame_laboratorial');
      expect(eventoExame.titulo, contains('Exame:'));
      expect(eventoExame.descricao, contains('.pdf'));
    });
  });
}
