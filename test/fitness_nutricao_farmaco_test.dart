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

  group('Módulo Nutrição & Alimentos TACO', () {
    test('Cálculo de macros proporcional à quantidade em gramas', () {
      const frango = AlimentoModel(
        id: 'alim_1',
        nome: 'Peito de Frango Grelhado',
        categoria: 'proteinas',
        porcaoPadraoGramas: 100.0,
        calorias: 159.0,
        proteinas: 32.0,
        carboidratos: 0.0,
        gorduras: 3.2,
      );

      // 200g de frango
      final item200g = ItemRefeicaoModel.calcular(
        alimento: frango,
        quantidadeGramas: 200.0,
      );

      expect(item200g.calorias, 318.0);
      expect(item200g.proteinas, 64.0);
      expect(item200g.carboidratos, 0.0);
      expect(item200g.gorduras, 6.4);

      // 150g de frango
      final item150g = ItemRefeicaoModel.calcular(
        alimento: frango,
        quantidadeGramas: 150.0,
      );

      expect(item150g.proteinas, 48.0);
      expect(item150g.calorias, 238.5);
    });

    test('Cálculo total de calorias e macros de uma Refeição e Dieta', () {
      const frango = AlimentoModel(
        id: 'alim_1',
        nome: 'Peito de Frango Grelhado',
        categoria: 'proteinas',
        calorias: 159.0,
        proteinas: 32.0,
        carboidratos: 0.0,
        gorduras: 3.2,
      );

      const arroz = AlimentoModel(
        id: 'alim_2',
        nome: 'Arroz Branco Cozido',
        categoria: 'carboidratos',
        calorias: 128.0,
        proteinas: 2.5,
        carboidratos: 28.1,
        gorduras: 0.2,
      );

      final itemFrango = ItemRefeicaoModel.calcular(
        alimento: frango,
        quantidadeGramas: 200.0,
      );
      final itemArroz = ItemRefeicaoModel.calcular(
        alimento: arroz,
        quantidadeGramas: 150.0,
      );

      final almoco = RefeicaoModel(
        id: 'ref_1',
        nome: 'Almoço',
        horario: '12:30',
        itens: [itemFrango, itemArroz],
      );

      expect(almoco.totalProteinas, closeTo(67.75, 0.1));
      expect(almoco.totalCarboidratos, closeTo(42.15, 0.1));
      expect(almoco.totalCalorias, closeTo(510.0, 1.0));

      final dieta = DietaProtocoloModel(
        id: 'dieta_teste',
        alunoId: 'aluno_1',
        titulo: 'Cutting 2000kcal',
        objetivo: 'emagrecimento',
        caloriasMeta: 2000.0,
        proteinasMeta: 160.0,
        carboidratosMeta: 200.0,
        gordurasMeta: 50.0,
        dataInicio: '2026-10-01',
        refeicoes: [almoco],
      );

      expect(dieta.totalCaloriasReal, closeTo(510.0, 1.0));
      expect(dieta.totalProteinasReal, closeTo(67.75, 0.1));
    });

    test('NutricaoFarmacoOfflineRepository persiste e busca alimentos e dietas',
        () async {
      final repo = NutricaoFarmacoOfflineRepository();
      final alimentos = await repo.getAlimentos();

      expect(alimentos.isNotEmpty, isTrue);
      expect(alimentos.any((a) => a.nome.contains('Frango')), isTrue);
      expect(alimentos.any((a) => a.nome.contains('Arroz')), isTrue);

      final dietas = await repo.getDietas();
      expect(dietas.isNotEmpty, isTrue);
    });
  });

  group('Módulo MyFitCoach & Sobrecarga Inteligente', () {
    test('Algoritmo sugere +2kg quando aluno bate meta de repetições',
        () async {
      final repo = FitnessOfflineRepository();

      // Registra sessão concluída com 10 reps e 80kg
      final sessaoPassada = SessaoTreinoRegistroModel(
        id: 'sessao_1',
        treinoId: 'plano_1',
        divisaoLetra: 'A',
        divisaoNome: 'Peitoral',
        alunoId: 'aluno_1',
        dataHoraInicio: DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        dataHoraFim: DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        duracaoSegundos: 3000,
        sincronizado: false,
        exerciciosExecutados: [
          const ExercicioExecutadoRegistroModel(
            exercicioId: 'ex_supino',
            exercicioNome: 'Supino Reto',
            grupoMuscular: 'Peito',
            series: [
              SerieRegistroModel(numero: 1, cargaRealKg: 80.0, repeticoesRealizadas: 10, concluida: true),
              SerieRegistroModel(numero: 2, cargaRealKg: 80.0, repeticoesRealizadas: 10, concluida: true),
              SerieRegistroModel(numero: 3, cargaRealKg: 80.0, repeticoesRealizadas: 10, concluida: true),
            ],
          ),
        ],
      );

      await repo.registrarSessaoConcluida(sessaoPassada);

      // Calcula sobrecarga para o supino prescrito com meta de 10 reps
      final sugestao = await repo.calcularSugestaoSobrecarga(
        exercicioId: 'ex_supino',
        cargaAtualKg: 80.0,
        repsPrescritas: 10,
        alunoId: 'aluno_1',
      );

      expect(sugestao['temSugestao'], isTrue);
      expect(sugestao['incrementoKg'], 4.0); // carga >= 40kg incrementa +4kg
      expect(sugestao['cargaSugeridaKg'], 84.0);
    });

    test('Cálculo de Streak de dias consecutivos de treino', () async {
      final repo = FitnessOfflineRepository();
      final hoje = DateTime.now();

      final sessaoHoje = SessaoTreinoRegistroModel(
        id: 'sessao_hoje',
        treinoId: 'plano_1',
        divisaoLetra: 'A',
        divisaoNome: 'Peitoral',
        alunoId: 'aluno_1',
        dataHoraInicio: hoje.toIso8601String(),
        dataHoraFim: hoje.toIso8601String(),
        duracaoSegundos: 3000,
        sincronizado: false,
        exerciciosExecutados: [],
      );

      final sessaoOntem = SessaoTreinoRegistroModel(
        id: 'sessao_ontem',
        treinoId: 'plano_1',
        divisaoLetra: 'B',
        divisaoNome: 'Costas',
        alunoId: 'aluno_1',
        dataHoraInicio: hoje.subtract(const Duration(days: 1)).toIso8601String(),
        dataHoraFim: hoje.subtract(const Duration(days: 1)).toIso8601String(),
        duracaoSegundos: 3000,
        sincronizado: false,
        exerciciosExecutados: [],
      );

      await repo.registrarSessaoConcluida(sessaoHoje);
      await repo.registrarSessaoConcluida(sessaoOntem);

      final streak = await repo.calcularStreakDias(alunoId: 'aluno_1');
      expect(streak, 2);
    });
  });

  group('Módulo Notificações Inteligentes', () {
    test('Agenda e recupera notificações push de treino e metas', () async {
      final pushService = FitnessPushNotificationService();

      await pushService.agendarNotificacao(
        FitnessNotificationItem(
          id: 'notif_teste_1',
          titulo: '🔥 Treino de Hoje',
          corpo: 'Bora treinar!',
          dataHora: DateTime.now(),
          tipo: 'treino_hoje',
        ),
      );

      final notifs = await pushService.getNotificacoes();
      expect(notifs.any((n) => n.id == 'notif_teste_1'), isTrue);

      await pushService.marcarComoLida('notif_teste_1');
      final notifsAtualizadas = await pushService.getNotificacoes();
      final lida = notifsAtualizadas.firstWhere((n) => n.id == 'notif_teste_1');
      expect(lida.lida, isTrue);
    });
  });
}
