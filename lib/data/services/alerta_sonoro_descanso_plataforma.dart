import 'package:flutter/services.dart';

/// Alerta nativo usado fora do navegador, acompanhado pelo háptico da tela.
class AlertaSonoroDescanso {
  static void proximo() => SystemSound.play(SystemSoundType.alert);

  static void urgente() => SystemSound.play(SystemSoundType.alert);

  static void finalizado() => SystemSound.play(SystemSoundType.alert);
}
