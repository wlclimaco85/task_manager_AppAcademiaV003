import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

/// Layout escolhido pelo usuario para os dashboards (aluno, personal e academia).
enum DashboardLayout {
  novo('Layout novo'),
  classico('Layout clássico');

  const DashboardLayout(this.rotulo);
  final String rotulo;
}

/// Guarda a escolha no aparelho. Falha de leitura/gravacao cai no layout novo, sem quebrar a tela.
class DashboardLayoutPreferencia {
  DashboardLayoutPreferencia._();

  static const _chave = 'dashboard_layout_v1';

  static Future<DashboardLayout> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_chave) == DashboardLayout.classico.name
          ? DashboardLayout.classico
          : DashboardLayout.novo;
    } catch (e, stack) {
      AppLogger.i.error('[DashboardLayout] Falha ao ler preferencia: $e', stack);
      return DashboardLayout.novo;
    }
  }

  static Future<void> salvar(DashboardLayout layout) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chave, layout.name);
    } catch (e, stack) {
      AppLogger.i.error('[DashboardLayout] Falha ao salvar preferencia: $e', stack);
    }
  }
}
