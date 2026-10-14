import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/exercicio_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('remada baixa recebe video inclusive em catalogo antigo sem link', () async {
    SharedPreferences.setMockInitialValues({
      'appacademia_exercicios_v1': json.encode([
        const ExercicioModel(id: 'ex_remada_baixa', nome: 'Remada',
            grupoMuscular: 'Costas').toMap(),
      ]),
    });
    final remada = (await FitnessOfflineRepository().getExercicios())
        .singleWhere((e) => e.id == 'ex_remada_baixa');
    expect(remada.videoUrl, 'https://youtu.be/2YebbYuuBJQ');
    expect(remada.midiaUrl, remada.videoUrl);
  });

  test('catalogo padrao traz mais de 100 exercicios com passo a passo e imagem', () async {
    final lista = await FitnessOfflineRepository().getExercicios();

    expect(lista.length, greaterThanOrEqualTo(100));
    expect(lista.map((e) => e.id).toSet().length, lista.length, reason: 'ids unicos');
    for (final e in lista) {
      expect(e.descricao, startsWith('1. '), reason: e.id);
      expect(e.thumbnailUrl, contains('free-exercise-db'), reason: e.id);
      expect(e.nivel, inInclusiveRange(1, 3), reason: e.id);
    }
  });

  test('catalogo cobre as 16 categorias', () async {
    final grupos = (await FitnessOfflineRepository().getExercicios())
        .map((e) => e.grupoMuscular)
        .toSet();

    expect(grupos, containsAll([
      'Peitoral', 'Costas', 'Lombar', 'Ombros', 'Bíceps', 'Tríceps', 'Antebraço',
      'Quadríceps', 'Posterior', 'Glúteo', 'Adutores e Abdutores', 'Panturrilha',
      'Abdômen', 'Cárdio', 'Funcional', 'Mobilidade',
    ]));
  });

  test('mantem os ids antigos usados pelas fichas de treino', () async {
    final ids = (await FitnessOfflineRepository().getExercicios()).map((e) => e.id).toSet();

    expect(ids, containsAll([
      'ex_supino_reto', 'ex_supino_inclinado', 'ex_crucifixo_polia', 'ex_puxada_frente',
      'ex_remada_curvada', 'ex_remada_baixa', 'ex_agachamento_livre', 'ex_leg_press',
      'ex_cadeira_extensora', 'ex_mesa_flexora', 'ex_stiff', 'ex_elevacao_pelvica',
      'ex_desenvolvimento_halteres', 'ex_elevacao_lateral', 'ex_rosca_direta',
      'ex_triceps_corda', 'ex_prancha', 'ex_esteira_hiit',
    ]));
  });

  test('aparelho com catalogo antigo recebe novos exercicios sem perder dados', () async {
    const antigoComGifQuebrado = ExercicioModel(
      id: 'ex_supino_reto',
      nome: 'Supino Reto com Barra',
      grupoMuscular: 'Peitoral',
      videoUrl:
          'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/00251301-Barbell-Bench-Press_Chest.gif',
    );
    const antigoComVideoDoPersonal = ExercicioModel(
      id: 'ex_leg_press',
      nome: 'Leg Press 45°',
      grupoMuscular: 'Quadríceps',
      videoUrl: 'https://www.youtube.com/watch?v=abc123',
    );
    const personalizado = ExercicioModel(
      id: 'ex_custom_1',
      nome: 'Meu exercício',
      grupoMuscular: 'Funcional',
      descricao: 'Texto do personal',
      isCustom: true,
    );
    SharedPreferences.setMockInitialValues({
      'appacademia_exercicios_v1': json.encode([
        antigoComGifQuebrado.toMap(),
        antigoComVideoDoPersonal.toMap(),
        personalizado.toMap(),
      ]),
    });

    final lista = await FitnessOfflineRepository().getExercicios();
    ExercicioModel porId(String id) => lista.firstWhere((e) => e.id == id);

    expect(lista.length, greaterThanOrEqualTo(100));
    expect(porId('ex_supino_reto').descricao, startsWith('1. '));
    expect(porId('ex_supino_reto').videoUrl, 'https://youtu.be/pCPyqW60Wuk', reason: 'GIF 404 substituido pelo video real');
    expect(porId('ex_supino_reto').midiaUrl, porId('ex_supino_reto').videoUrl);
    expect(porId('ex_leg_press').videoUrl, 'https://www.youtube.com/watch?v=abc123');
    expect(porId('ex_custom_1').descricao, 'Texto do personal');
    expect(lista.any((e) => e.id == 'ex_kettlebell_swing'), isTrue);
  });
}
