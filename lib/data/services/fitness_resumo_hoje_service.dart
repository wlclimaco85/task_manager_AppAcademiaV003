import 'dart:math' as math;

import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';
import 'package:task_manager_flutter/data/services/fitness_360_local_store.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
import 'package:task_manager_flutter/data/utils/calorias_treino_forca.dart';

class FitnessResumoHojeService {
  FitnessResumoHojeService._();

  static Future<Fitness360Summary> carregar({Fitness360Summary? remoto}) async {
    final resultados = await Future.wait<dynamic>([
      Fitness360LocalStore.records(),
      FitnessOfflineRepository().getSessoesConcluidas(),
      if (remoto == null) Fitness360LocalStore.summary(),
    ]);
    final registros = resultados[0] as List<Fitness360Record>;
    final sessoes = resultados[1] as List<SessaoTreinoRegistroModel>;
    final base = remoto ?? resultados[2] as Fitness360Summary;
    final agora = DateTime.now();
    bool hoje(DateTime data) => data.year == agora.year &&
        data.month == agora.month && data.day == agora.day;

    final atividadesHoje = registros
        .where((r) => r.type == 'atividade' && hoje(r.createdAt))
        .toList();
    final pesoLocal = _pesoMaisRecente(registros);
    final pesoAtual = base.weightKg ?? pesoLocal;
    final sessoesHoje = {
      for (final sessao in sessoes)
        if (sessao.id.isNotEmpty) sessao.id: sessao,
    }.values.where((sessao) {
      final data = DateTime.tryParse(sessao.dataHoraFim) ??
          DateTime.tryParse(sessao.dataHoraInicio);
      return data != null && hoje(data);
    }).toList();

    final minutosAtividade = _somarInteiro(atividadesHoje, 'min');
    final caloriasAtividade = _somarInteiro(atividadesHoje, 'kcal');
    final distanciaAtividade = _somarDecimal(atividadesHoje, 'km');
    final minutosForca = sessoesHoje.fold<int>(0, (total, sessao) =>
        total + sessao.duracaoSegundos ~/ 60);
    final caloriasForca = sessoesHoje.fold<int>(0, (total, sessao) =>
        total + (calcularCaloriasTreinoForca(
          minutos: sessao.duracaoSegundos ~/ 60,
          rpe: sessao.rpe,
          pesoKg: pesoAtual,
        ) ?? 0));
    final possuiRegistroHoje = atividadesHoje.isNotEmpty || sessoesHoje.isNotEmpty;

    return Fitness360Summary(
      steps: base.steps,
      trainingMinutes:
          math.max(base.trainingMinutes, minutosAtividade) + minutosForca,
      heartRate: base.heartRate,
      sleepMinutes: base.sleepMinutes,
      weightKg: pesoAtual,
      habitsDone: math.max(base.habitsDone, possuiRegistroHoje ? 1 : 0),
      activeCalories:
          math.max(base.activeCalories, caloriasAtividade) + caloriasForca,
      distanceKm: math.max(base.distanceKm, distanciaAtividade),
      activeDaysWeek:
          math.max(base.activeDaysWeek, possuiRegistroHoje ? 1 : 0),
      weightGoalKg: base.weightGoalKg,
      lastSyncAt: base.lastSyncAt,
      syncSource: base.syncSource,
      heightCm: base.heightCm,
      strengthTrainingMinutes: minutosForca,
      strengthCalories: caloriasForca,
    );
  }

  static int _somarInteiro(List<Fitness360Record> registros, String unidade) {
    var total = 0;
    final regex = RegExp('(\\d+)\\s*$unidade', caseSensitive: false);
    for (final registro in registros) {
      total += int.tryParse(regex.firstMatch(registro.value)?.group(1) ?? '') ?? 0;
    }
    return total;
  }

  static double _somarDecimal(
      List<Fitness360Record> registros, String unidade) {
    var total = 0.0;
    final regex = RegExp('(\\d+(?:[.,]\\d+)?)\\s*$unidade',
        caseSensitive: false);
    for (final registro in registros) {
      total += double.tryParse((regex.firstMatch(registro.value)?.group(1) ?? '')
              .replaceAll(',', '.')) ??
          0;
    }
    return double.parse(total.toStringAsFixed(1));
  }

  static double? _pesoMaisRecente(List<Fitness360Record> registros) {
    for (final registro in registros) {
      if (registro.type != 'corpo' || registro.title.toLowerCase() != 'peso') {
        continue;
      }
      final match = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(registro.value);
      final peso = double.tryParse((match?.group(1) ?? '').replaceAll(',', '.'));
      if (peso != null && peso > 0) return peso;
    }
    return null;
  }
}
