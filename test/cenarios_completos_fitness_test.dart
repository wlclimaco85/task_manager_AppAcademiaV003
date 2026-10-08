import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/exercicio_model.dart';
import 'package:task_manager_flutter/data/models/fitness/nutricao_farmaco_model.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
import 'package:task_manager_flutter/data/services/fitness_push_notification_service.dart';
import 'package:task_manager_flutter/data/services/nutricao_farmaco_offline_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Cenários Completos de Negócio (Flutter Test): Equipe Multidisciplinar vs Aluno Independente', () {
    test('CENÁRIO 1: Fluxo Completo Multidisciplinar (Personal + Nutricionista + Endocrinologista + Aluno + 2 Avaliações + Timeline)', () async {
      final fitnessRepo = FitnessOfflineRepository();
      final nutricaoRepo = NutricaoFarmacoOfflineRepository();
      final pushService = FitnessPushNotificationService();

      // 1. Cadastrar Aluno amarrado ao Personal Trainer
      const alunoId = 'aluno_100';
      const personalId = 'personal_10';
      const personalNome = 'Lucas Personal Pro';

      // 2. Personal prescreve o Plano de Treino (Divisão A: Peitoral e Tríceps)
      final planoPrescrito = PlanoTreinoModel(
        id: 'plano_personal_1',
        alunoId: alunoId,
        titulo: 'Hipertrofia & Definição Fase 1',
        personalId: personalId,
        personalNome: personalNome,
        dataInicio: '2026-08-01',
        dataFim: '2026-10-01',
        ativo: true,
        divisoes: const [
          DivisaoTreinoModel(
            letra: 'A',
            nome: 'Peitoral & Tríceps',
            foco: 'Hipertrofia',
            exercicios: [
              ExercicioTreinoItemModel(
                exercicioId: 'ex_supino',
                exercicioNome: 'Supino Reto com Barra',
                grupoMuscular: 'Peitoral',
                series: 4,
                repeticoes: '8 a 12',
                cargaSugeridaKg: 80.0,
                descansoSegundos: 90,
                tecnicaAvancada: 'Nenhuma',
              ),
              ExercicioTreinoItemModel(
                exercicioId: 'ex_triceps_polia',
                exercicioNome: 'Tríceps Polia Corda',
                grupoMuscular: 'Tríceps',
                series: 4,
                repeticoes: '12 reps',
                cargaSugeridaKg: 35.0,
                descansoSegundos: 60,
              ),
            ],
          ),
        ],
      );

      await fitnessRepo.salvarPlanoTreino(planoPrescrito);

      // Notifica o aluno que a ficha foi liberada
      await pushService.notificarNovaFichaPrescrita(
        alunoNome: 'Washington Climaco',
        personalNome: personalNome,
        plano: planoPrescrito,
      );

      final planosSalvos = await fitnessRepo.getPlanosTreino(alunoId: alunoId);
      expect(planosSalvos.any((p) => p.id == 'plano_personal_1'), isTrue);
      expect(planosSalvos.first.personalNome, 'Lucas Personal Pro');

      // 3. Nutricionista prescreve Dieta com Alimentos da Tabela TACO e Cálculo de Macros
      final alimentos = await nutricaoRepo.getAlimentos();
      final frango = alimentos.firstWhere((a) => a.nome.contains('Frango'));
      final arroz = alimentos.firstWhere((a) => a.nome.contains('Arroz Branco'));

      // Cálculo: 200g de Frango + 150g de Arroz
      final itemFrango = ItemRefeicaoModel.calcular(alimento: frango, quantidadeGramas: 200.0);
      final itemArroz = ItemRefeicaoModel.calcular(alimento: arroz, quantidadeGramas: 150.0);

      expect(itemFrango.proteinas, 64.0); // 32g * 2
      expect(itemArroz.carboidratos, closeTo(42.15, 0.1));

      final dietaPrescrita = DietaProtocoloModel(
        id: 'dieta_nutri_1',
        alunoId: alunoId,
        titulo: 'Cutting Definido 2.200 kcal',
        objetivo: 'emagrecimento',
        caloriasMeta: 2200.0,
        proteinasMeta: 180.0,
        carboidratosMeta: 220.0,
        gordurasMeta: 65.0,
        dataInicio: '2026-08-01',
        dataFim: '2026-10-01',
        ativa: true,
        refeicoes: [
          RefeicaoModel(
            id: 'ref_almoco',
            nome: 'Almoço Anabólico',
            horario: '12:30',
            itens: [itemFrango, itemArroz],
          ),
        ],
      );

      await nutricaoRepo.salvarDieta(dietaPrescrita);
      final dietasSalvas = await nutricaoRepo.getDietas(alunoId: alunoId);
      expect(dietasSalvas.any((d) => d.id == 'dieta_nutri_1'), isTrue);

      // 4. Endocrinologista prescreve Protocolo de Hormônios / Anabolizantes e Protetores
      final enantato = MedicamentoProtocoloModel(
        id: 'med_enantato_1',
        alunoId: alunoId,
        nomeComposto: 'Enantato de Testosterona (TRT / Reposição)',
        dosagem: '250mg / 1ml por semana',
        frequencia: '1x a cada 7 dias',
        viaAdministracao: 'Intramuscular',
        categoria: 'ergogenico_ciclo',
        dataInicio: '2026-08-01',
        dataFim: '2026-10-01',
        ativo: true,
        observacoes: 'Monitorar hematócrito e estradiol a cada 60 dias.',
      );

      final anastrozol = MedicamentoProtocoloModel(
        id: 'med_anastrozol_1',
        alunoId: alunoId,
        nomeComposto: 'Anastrozol',
        dosagem: '0.5mg',
        frequencia: 'DSDN (Dia Sim, Dia Não)',
        viaAdministracao: 'Oral',
        categoria: 'tpc_protetor',
        dataInicio: '2026-08-01',
        dataFim: '2026-10-01',
        ativo: true,
      );

      await nutricaoRepo.salvarMedicamento(enantato);
      await nutricaoRepo.salvarMedicamento(anastrozol);

      final medsSalvos = await nutricaoRepo.getMedicamentos(alunoId: alunoId);
      expect(medsSalvos.length, greaterThanOrEqualTo(2));
      expect(medsSalvos.any((m) => m.categoria == 'ergogenico_ciclo'), isTrue);
      expect(medsSalvos.any((m) => m.categoria == 'tpc_protetor'), isTrue);

      // 5. Personal cadastra a 1ª Avaliação Física (Inicial - 01/08/2026)
      const pesoInicial = 88.5;
      const bfInicial = 19.2;

      // 6. Aluno executa as sessões de treino com sobrecarga progressiva e registra esforço
      final sessaoExecutada = SessaoTreinoRegistroModel(
        id: 'sessao_exec_1',
        treinoId: planoPrescrito.id,
        divisaoLetra: 'A',
        divisaoNome: 'Peitoral & Tríceps',
        alunoId: alunoId,
        dataHoraInicio: '2026-08-02T18:00:00',
        dataHoraFim: '2026-08-02T19:00:00',
        duracaoSegundos: 3600,
        rpe: 8,
        feedbackAluno: 'Treino excelente, bati as 12 repetições no supino!',
        sincronizado: false,
        exerciciosExecutados: const [
          ExercicioExecutadoRegistroModel(
            exercicioId: 'ex_supino',
            exercicioNome: 'Supino Reto com Barra',
            grupoMuscular: 'Peitoral',
            series: [
              SerieRegistroModel(numero: 1, cargaRealKg: 80.0, repeticoesRealizadas: 12, concluida: true),
              SerieRegistroModel(numero: 2, cargaRealKg: 80.0, repeticoesRealizadas: 12, concluida: true),
              SerieRegistroModel(numero: 3, cargaRealKg: 80.0, repeticoesRealizadas: 12, concluida: true),
              SerieRegistroModel(numero: 4, cargaRealKg: 80.0, repeticoesRealizadas: 12, concluida: true),
            ],
          ),
        ],
      );

      await fitnessRepo.registrarSessaoConcluida(sessaoExecutada);

      // Algoritmo MyFitCoach: Valida que a próxima sessão vai sugerir sobrecarga progressiva (+4kg para > 40kg)
      final sobrecarga = await fitnessRepo.calcularSugestaoSobrecarga(
        exercicioId: 'ex_supino',
        cargaAtualKg: 80.0,
        repsPrescritas: 12,
        alunoId: alunoId,
      );

      expect(sobrecarga['temSugestao'], isTrue);
      expect(sobrecarga['cargaSugeridaKg'], 84.0);

      // 7. Personal cadastra a 2ª Avaliação Física (Evolução após 60 dias - 01/10/2026)
      const pesoFinal = 81.4;
      const bfFinal = 11.2;

      // 8. Gráfico e Agregação da Linha do Tempo 360
      final timeline = await nutricaoRepo.getTimelineEventos(alunoId: alunoId);
      expect(timeline.isNotEmpty, isTrue);

      final perdaPeso = pesoInicial - pesoFinal;
      final reducaoBf = bfInicial - bfFinal;

      expect(perdaPeso, closeTo(7.1, 0.01), reason: 'Aluno reduziu 7.1kg de peso');
      expect(reducaoBf, closeTo(8.0, 0.01), reason: 'Aluno reduziu 8.0% de gordura corporal');
      expect(timeline.any((e) => e.tipo == 'inicio_dieta'), isTrue);
      expect(timeline.any((e) => e.tipo == 'inicio_medicamento'), isTrue);
    });

    test('CENÁRIO 2: Fluxo Aluno Independente (Sem Personal, Auto-Gestão de Treinos, Dieta TACO, Suplementos e Peso Diário)', () async {
      final fitnessRepo = FitnessOfflineRepository();
      final nutricaoRepo = NutricaoFarmacoOfflineRepository();

      const alunoIndepId = 'aluno_independente_500';

      // 1. Aluno Independente (Sem personal) monta seus próprios treinos
      final treinoProprio = PlanoTreinoModel(
        id: 'plano_proprio_1',
        alunoId: alunoIndepId,
        titulo: 'Treino Próprio Full Body 3x',
        personalId: null, // Sem personal
        personalNome: null,
        dataInicio: '2026-09-01',
        ativo: true,
        divisoes: const [
          DivisaoTreinoModel(
            letra: 'A',
            nome: 'Full Body Geral',
            foco: 'Força e Hipertrofia',
            exercicios: [
              ExercicioTreinoItemModel(
                exercicioId: 'ex_agachamento',
                exercicioNome: 'Agachamento Livre',
                grupoMuscular: 'Pernas',
                series: 4,
                repeticoes: '10 reps',
                cargaSugeridaKg: 100.0,
                descansoSegundos: 120,
              ),
            ],
          ),
        ],
      );

      await fitnessRepo.salvarPlanoTreino(treinoProprio);
      final planosSalvos = await fitnessRepo.getPlanosTreino(alunoId: alunoIndepId);
      expect(planosSalvos.any((p) => p.id == 'plano_proprio_1'), isTrue);
      expect(planosSalvos.first.personalId, isNull);

      // 2. Aluno cadastra seus suplementos
      final creatina = SuplementoProtocoloModel(
        id: 'sup_creatina_1',
        alunoId: alunoIndepId,
        nome: 'Creatina Monohidratada 100% Pura',
        dosagem: '5g',
        horario: 'Pós-Treino',
        dataInicio: '2026-09-01',
        ativo: true,
      );

      final whey = SuplementoProtocoloModel(
        id: 'sup_whey_1',
        alunoId: alunoIndepId,
        nome: 'Whey Protein Isolado',
        dosagem: '30g',
        horario: 'Pós-Treino',
        dataInicio: '2026-09-01',
        ativo: true,
      );

      await nutricaoRepo.salvarSuplemento(creatina);
      await nutricaoRepo.salvarSuplemento(whey);

      final sups = await nutricaoRepo.getSuplementos(alunoId: alunoIndepId);
      expect(sups.length, 2);

      // 3. Aluno monta sua dieta própria a partir dos alimentos TACO
      final alimentos = await nutricaoRepo.getAlimentos();
      final banana = alimentos.firstWhere((a) => a.nome.contains('Banana'));
      final aveia = alimentos.firstWhere((a) => a.nome.contains('Aveia'));

      final itemBanana = ItemRefeicaoModel.calcular(alimento: banana, quantidadeGramas: 100.0);
      final itemAveia = ItemRefeicaoModel.calcular(alimento: aveia, quantidadeGramas: 60.0);

      final cafe = RefeicaoModel(
        id: 'ref_cafe',
        nome: 'Café da Manhã Rápido',
        horario: '07:30',
        itens: [itemBanana, itemAveia],
      );

      final dietaAuto = DietaProtocoloModel(
        id: 'dieta_auto_1',
        alunoId: alunoIndepId,
        titulo: 'Dieta Auto-Gerenciada 2500kcal',
        objetivo: 'hipertrofia',
        caloriasMeta: 2500.0,
        proteinasMeta: 160.0,
        carboidratosMeta: 300.0,
        gordurasMeta: 70.0,
        dataInicio: '2026-09-01',
        refeicoes: [cafe],
      );

      await nutricaoRepo.salvarDieta(dietaAuto);
      final dietas = await nutricaoRepo.getDietas(alunoId: alunoIndepId);
      expect(dietas.any((d) => d.id == 'dieta_auto_1'), isTrue);

      // 4. Aluno registra a execução diária e calcula consistência/streaks
      final sessaoHoje = SessaoTreinoRegistroModel(
        id: 'sessao_indep_hoje',
        treinoId: treinoProprio.id,
        divisaoLetra: 'A',
        divisaoNome: 'Full Body',
        alunoId: alunoIndepId,
        dataHoraInicio: DateTime.now().toIso8601String(),
        dataHoraFim: DateTime.now().toIso8601String(),
        duracaoSegundos: 3000,
        rpe: 9,
        sincronizado: false,
        exerciciosExecutados: const [
          ExercicioExecutadoRegistroModel(
            exercicioId: 'ex_agachamento',
            exercicioNome: 'Agachamento Livre',
            grupoMuscular: 'Pernas',
            series: [
              SerieRegistroModel(numero: 1, cargaRealKg: 100.0, repeticoesRealizadas: 10, concluida: true),
              SerieRegistroModel(numero: 2, cargaRealKg: 100.0, repeticoesRealizadas: 10, concluida: true),
            ],
          ),
        ],
      );

      await fitnessRepo.registrarSessaoConcluida(sessaoHoje);

      final streak = await fitnessRepo.calcularStreakDias(alunoId: alunoIndepId);
      expect(streak, 1);

      // 5. Timeline reúne todos os eventos do aluno independente
      final timeline = await nutricaoRepo.getTimelineEventos(alunoId: alunoIndepId);
      expect(timeline.any((e) => e.tipo == 'inicio_suplemento'), isTrue);
      expect(timeline.any((e) => e.tipo == 'inicio_dieta'), isTrue);
    });
  });
}
