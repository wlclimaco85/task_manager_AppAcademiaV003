import 'package:task_manager_flutter/data/utils/app_logger.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Mantem a tela ligada enquanto o aluno esta nos exercicios (sem bloqueio automatico).
/// Falha de plataforma nao pode derrubar a tela: so registra no log.
class TelaAtivaService {
  TelaAtivaService._();

  static Future<void> manterLigada() async {
    try {
      await WakelockPlus.enable();
    } catch (e) {
      AppLogger.i.warn('[TelaAtiva] Nao foi possivel manter a tela ligada: $e');
    }
  }

  static Future<void> liberar() async {
    try {
      await WakelockPlus.disable();
    } catch (e) {
      AppLogger.i.warn('[TelaAtiva] Nao foi possivel liberar a tela: $e');
    }
  }
}
