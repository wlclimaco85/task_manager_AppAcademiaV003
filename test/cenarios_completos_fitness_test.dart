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

  group('Cenários Completos de Negócio (Flutter Test): Equipe Multidisciplinar, Contratação & Execução', () {
    test('CENÁRIO 1: Fluxo Completo Multidisciplinar (Personal + Nutricionista + Endocrinologista + Aluno + 2 Avaliações + Timeline)', () async {
      final fitnessRepo = FitnessOfflineRepository();
      final nutricaoRepo = NutricaoFarmacoOfflineRepository();
      final pushService = FitnessPushNotificationService();

      // 1. Cadastrar Aluno amarrado ao Personal Trainer
      const alunoId = 'aluno_100';
      const personalId = 'personal_10';
      const personalNome = 'Lucas Personal Pro';

      // 2. Personal prescreve o Treino (Divisão A e B com sobrecarga)
      final planoTreino = PlanoTreinoModel(
        id: 'plano_prescrito_1',
        alunoId: alunoId,
        titulo: 'Ficha Hipertrofia & Força AB',
        personalId: personalId,
        personalNome: personalNome,
        dataInicio: '2026-08-01',
        ativo: true,
        divisoes: const [
          DivisaoTreinoModel(
            letra: 'A',
            nome: 'Peito, Tríceps e Ombros',
            foco: 'Hipertrofia Superior',
            exercicios: [
              ExercicioTreinoItemModel(
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

      // 3. Nutricionista prescreve Dieta baseada na tabela TACO
      final refeicaoAlmoco = RefeicaoModel(
        id: 'ref_almoco',
        titulo: 'Almoço Anabólico',
        horario: '12:30',
        itens: [
          ItemRefeicaoModel(
            alimento: const AlimentoModel(
              id: 'ali_frango',
              nome: 'Peito de Frango Grelhado',
              grupo: 'Proteínas',
              categoria: 'proteinas',
              calorias: 159.0,
              proteinas: 32.0,
              carboidratos: 0.0,
              gorduras: 3.2,
            ),
            quantidadeGramas: 200, // 64g proteína
          ),
        ],
      );

      final dietaPrescrita = DietaProtocoloModel(
        id: 'dieta_cutting_1',
        alunoId: alunoId,
        titulo: 'Dieta Cutting 2200kcal',
        objetivo: 'cutting',
        caloriasMeta: 2200.0,
        proteinasMeta: 180.0,
        carboidratosMeta: 220.0,
        gordurasMeta: 50.0,
        dataInicio: '2026-08-01',
        dataFim: '2026-10-30',
        refeicoes: [refeicaoAlmoco],
      );

      await nutricaoRepo.salvarDieta(dietaPrescrita);
      expect(dietaPrescrita.totalProteinas, 64.0);

      // 4. Endocrinologista prescreve Protocolo Hormonal / Farmacológico
      final medicamento = MedicamentoProtocoloModel(
        id: 'med_cipionato',
        alunoId: alunoId,
        nome: 'Cipionato de Testosterona (Deposteron)',
        categoria: 'hormonio',
        dosagem: '100mg/semana',
        frequencia: 'Semanal (Segundas)',
        viaAdministracao: 'Intramuscular',
        dataInicio: '2026-08-01',
        dataFim: '2026-11-01',
        medicoPrescritor: 'Dr. Roberto Endocrinologista',
      );

      await nutricaoRepo.salvarMedicamento(medicamento);
      final meds = await nutricaoRepo.getMedicamentos(alunoId: alunoId);
      expect(meds.any((m) => m.id == 'med_cipionato'), isTrue);

      // 5. Personal cadastra a 1ª Avaliação Física
      const pesoInicial = 88.5;
      const bfInicial = 19.2;

      // 6. Aluno lança execuções diárias de treino no Player
      final sessaoExecutada = SessaoTreinoRegistroModel(
        id: 'sessao_exec_1',
        treinoId: planoTreino.id,
        divisaoLetra: 'A',
        divisaoNome: 'Peito, Tríceps e Ombros',
        alunoId: alunoId,
        dataHoraInicio: '2026-08-02T10:00:00',
        dataHoraFim: '2026-08-02T11:15:00',
        duracaoSegundos: 4500,
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

      // 7. Personal cadastra a 2ª Avaliação Física (Evolução após 60 dias)
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

      // 1. Aluno Independente monta seus próprios treinos
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
      final planos = await fitnessRepo.getPlanosTreino(alunoId: alunoIndepId);
      expect(planos.any((p) => p.id == 'plano_proprio_1'), isTrue);

      // 2. Aluno cadastra sua suplementação
      final creatina = SuplementoProtocoloModel(
        id: 'sup_creatina',
        alunoId: alunoIndepId,
        nome: 'Creatina 100% Pura Creapure',
        dosagem: '5g ao dia',
        horario: '10:00',
        dataInicio: '2026-09-01',
      );

      await nutricaoRepo.salvarSuplemento(creatina);

      // 3. Aluno cadastra sua Dieta TACO
      final cafe = RefeicaoModel(
        id: 'ref_cafe',
        titulo: 'Café da Manhã',
        horario: '07:30',
        itens: [
          ItemRefeicaoModel(
            alimento: const AlimentoModel(
              id: 'ali_ovos',
              nome: 'Ovo de Galinha Cozido',
              grupo: 'Proteínas',
              categoria: 'proteinas',
              calorias: 146.0,
              proteinas: 13.3,
              carboidratos: 0.6,
              gorduras: 9.5,
            ),
            quantidadeGramas: 150,
          ),
        ],
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

    test('CENÁRIO 3: Aluno Busca e Contrata Personal em Uberaba (Academias, Horários e WhatsApp)', () async {
      final vitrineRepo = ProfissionaisVitrineRepository();

      // 1. Aluno filtra personais atuantes na SmartFit - Shopping Uberaba
      final profsUberaba = await vitrineRepo.getProfissionais(
        categoria: CategoriaProfissional.personal,
        academiaFiltro: 'SmartFit - Shopping Uberaba',
      );

      expect(profsUberaba.isNotEmpty, isTrue);
      final personalEscolhido = profsUberaba.first;
      expect(personalEscolhido.nome, contains('Rodrigo Medeiros'));

      // 2. Aluno consulta a grade e disponibilidade de horários livres
      expect(personalEscolhido.totalHorariosLivres, greaterThan(0));
      final gradeSegunda = personalEscolhido.gradeHorarios.firstWhere((g) => g.diaSemana == 'Segunda-feira');
      expect(gradeSegunda.horariosDisponiveis.contains('07:00'), isTrue);

      // 3. Aluno escolhe o pacote de acompanhamento presencial 3x/semana
      final pacotePresencial = personalEscolhido.pacotes.firstWhere((p) => p.destaque);
      expect(pacotePresencial.precoMensal, equals(600.0));
      expect(pacotePresencial.aulasPorSemana, equals(3));
      expect(personalEscolhido.whatsapp, contains('(34) 99876-1122'));
    });

    test('CENÁRIO 4: Personal Prescreve Ficha Completa, Aluno Segue no Player e Devolve Feedback RPE', () async {
      final personalRepo = PersonalGestaoOfflineRepository();
      final fitnessRepo = FitnessOfflineRepository();

      const alunoId = 'aluno_gestao_1';
      const alunoNome = 'Lucas Mendonça';

      // 1. Personal prescreve nova ficha ABCD com vigência de 45 dias
      await personalRepo.definirValidadeTreino(
        alunoId: alunoId,
        validadeDias: 45,
        treinoNome: 'Hipertrofia Metabólica ABCD',
      );

      final alunos = await personalRepo.getAlunos();
      final alunoAtual = alunos.firstWhere((a) => a.id == alunoId);
      expect(alunoAtual.treinoAtualNome, equals('Hipertrofia Metabólica ABCD'));
      expect(alunoAtual.validadeTreinoDias, equals(45));

      // 2. Aluno executa o treino da ficha no Player ao Vivo
      final sessaoExecutada = SessaoTreinoRegistroModel(
        id: 'sessao_abcd_1',
        treinoId: 'treino_abcd',
        divisaoLetra: 'A',
        divisaoNome: 'Treino A - Peito e Tríceps',
        alunoId: alunoId,
        dataHoraInicio: DateTime.now().subtract(const Duration(minutes: 60)).toIso8601String(),
        dataHoraFim: DateTime.now().toIso8601String(),
        duracaoSegundos: 3600,
        rpe: 9, // RPE 9/10
        feedbackAluno: 'Supino com 90kg foi até a falha na 4ª série!',
        sincronizado: false,
        exerciciosExecutados: const [
          ExercicioExecutadoRegistroModel(
            exercicioId: 'ex_supino',
            exercicioNome: 'Supino Reto com Barra',
            grupoMuscular: 'Peitoral',
            series: [
              SerieRegistroModel(numero: 1, cargaRealKg: 90.0, repeticoesRealizadas: 10, concluida: true),
              SerieRegistroModel(numero: 2, cargaRealKg: 90.0, repeticoesRealizadas: 10, concluida: true),
            ],
          ),
        ],
      );

      await fitnessRepo.registrarSessaoConcluida(sessaoExecutada);

      // 3. O feedback é registrado na visão do Personal Trainer
      final feedback = PersonalAlunoFeedbackModel(
        id: 'fb_novo_1',
        treinoId: sessaoExecutada.treinoId,
        divisaoNome: sessaoExecutada.divisaoNome,
        data: DateTime.now().toIso8601String().substring(0, 10),
        rpe: sessaoExecutada.rpe,
        comentario: sessaoExecutada.feedbackAluno ?? '',
        exercicioDestaque: 'Supino Reto com Barra',
      );

      await personalRepo.adicionarFeedbackTreino(
        alunoId: alunoId,
        feedback: feedback,
      );

      // 4. Personal visualiza o feedback atualizado do aluno
      final alunosPosFeedback = await personalRepo.getAlunos();
      final alunoComFeedback = alunosPosFeedback.firstWhere((a) => a.id == alunoId);

      expect(alunoComFeedback.feedbacks.isNotEmpty, isTrue);
      expect(alunoComFeedback.feedbacks.first.rpe, equals(9));
      expect(alunoComFeedback.feedbacks.first.comentario, contains('Supino com 90kg'));
    });
  });
}
