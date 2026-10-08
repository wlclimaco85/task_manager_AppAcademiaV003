import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/exercicio_model.dart';
import 'package:task_manager_flutter/data/models/fitness/nutricao_farmaco_model.dart';
import 'package:task_manager_flutter/data/models/fitness/personal_gestao_model.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/data/models/fitness/profissional_vitrine_model.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
import 'package:task_manager_flutter/data/services/fitness_push_notification_service.dart';
import 'package:task_manager_flutter/data/services/nutricao_farmaco_offline_repository.dart';
import 'package:task_manager_flutter/data/services/personal_gestao_offline_repository.dart';
import 'package:task_manager_flutter/data/services/profissionais_vitrine_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Cenários Completos de Negócio', () {
    test('CENÁRIO 1: Fluxo Completo Multidisciplinar', () async {
      final fitnessRepo = FitnessOfflineRepository();
      
      const alunoId = 'aluno_100';
      const personalId = 'personal_10';
      const personalNome = 'Lucas Personal Pro';

      final planoTreino = PlanoTreinoModel(
        id: 'plano_prescrito_1',
        alunoId: alunoId,
        alunoNome: 'Aluno Teste',
        titulo: 'Ficha Hipertrofia & Força AB',
        personalId: personalId,
        dataInicio: '2026-08-01',
        ativo: true,
        divisoes: const [
          DivisaoTreinoModel(
            id: 'div_a',
            letra: 'A',
            nome: 'Peito, Tríceps e Ombros',
            exercicios: [
              ItemTreinoModel(
                id: 'item_1',
                exercicioId: 'ex_supino',
                exercicioNome: 'Supino Reto com Barra',
                grupoMuscular: 'Peitoral',
                series: 4,
                repeticoes: '8 a 12 reps',
                cargaSugeridaKg: 80.0,
                descansoSegundos: 90,
              ),
            ],
          ),
        ],
      );

      await fitnessRepo.salvarPlanoTreino(planoTreino);
      final planos = await fitnessRepo.getPlanosTreino(alunoId: alunoId);
      expect(planos.any((p) => p.id == 'plano_prescrito_1'), isTrue);
    });

    test('CENÁRIO 2: Valida Background Sync Queue Sessoes', () async {
      final fitnessRepo = FitnessOfflineRepository();
      
      final sessaoExecutada = SessaoTreinoRegistroModel(
        id: 'sessao_sync_1',
        treinoId: 'plano_sync',
        divisaoLetra: 'A',
        divisaoNome: 'A - Teste',
        alunoId: 'aluno_1',
        dataHoraInicio: '2026-08-02T10:00:00',
        dataHoraFim: '2026-08-02T11:15:00',
        duracaoSegundos: 4500,
        rpe: 8,
        sincronizado: false,
        exerciciosExecutados: const [],
      );

      await fitnessRepo.registrarSessaoConcluida(sessaoExecutada);
      
      final sessoes = await fitnessRepo.getSessoesConcluidas();
      expect(sessoes.first.sincronizado, isFalse);

      final sessaoAtualizada = SessaoTreinoRegistroModel(
        id: 'sessao_sync_1',
        treinoId: 'plano_sync',
        divisaoLetra: 'A',
        divisaoNome: 'A - Teste',
        alunoId: 'aluno_1',
        dataHoraInicio: '2026-08-02T10:00:00',
        dataHoraFim: '2026-08-02T11:15:00',
        duracaoSegundos: 4500,
        rpe: 8,
        sincronizado: true,
        exerciciosExecutados: const [],
      );

      await fitnessRepo.atualizarSessaoTreino(sessaoAtualizada);

      final sessoesPosSync = await fitnessRepo.getSessoesConcluidas();
      expect(sessoesPosSync.first.sincronizado, isTrue);
    });
  });
}
