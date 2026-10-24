// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:js';

import 'package:task_manager_flutter/data/utils/app_logger.dart';

/// Sintetiza o bip no navegador sem depender do som do sistema operacional.
class AlertaSonoroDescanso {
  static JsObject? _contexto;
  static bool _falhaRegistrada = false;

  static void proximo() => _tocar(frequencia: 660, duracao: .16);

  static void urgente() => _tocar(frequencia: 880, duracao: .2);

  static void finalizado() => _tocar(frequencia: 1040, duracao: .36);

  static void _tocar({required double frequencia, required double duracao}) {
    try {
      final contexto = _contexto ??= _criarContexto();
      if (contexto == null) return;
      contexto.callMethod('resume');
      final oscilador = contexto.callMethod('createOscillator') as JsObject;
      final ganho = contexto.callMethod('createGain') as JsObject;
      final agora = (contexto['currentTime'] as num).toDouble();
      final frequenciaOscilador = oscilador['frequency'] as JsObject;
      final volume = ganho['gain'] as JsObject;

      frequenciaOscilador.callMethod('setValueAtTime', [frequencia, agora]);
      volume
        ..callMethod('setValueAtTime', [.22, agora])
        ..callMethod('exponentialRampToValueAtTime', [.001, agora + duracao]);
      oscilador
        ..callMethod('connect', [ganho])
        ..callMethod('start', [agora])
        ..callMethod('stop', [agora + duracao]);
      ganho.callMethod('connect', [contexto['destination']]);
    } catch (_) {
      // Alguns navegadores bloqueiam áudio até a primeira interação do usuário.
      if (!_falhaRegistrada) {
        _falhaRegistrada = true;
        AppLogger.i.warn('O navegador bloqueou o alerta sonoro do descanso.');
      }
    }
  }

  static JsObject? _criarContexto() {
    final fabrica = context['AudioContext'] ?? context['webkitAudioContext'];
    return fabrica is JsFunction ? JsObject(fabrica, const []) : null;
  }
}
