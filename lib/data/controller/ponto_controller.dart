import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import '../../data/models/ponto_model.dart';
import '../../data/services/ponto_service.dart';

/// ====== STATE ======

class PontoState {
  final bool loading;
  final bool registering;
  final List<PontoModel> registros;
  final double? bancoHoras;
  final String? error;
  final List<PontoModel> pontosHoje;

  const PontoState({
    this.loading = false,
    this.registering = false,
    this.registros = const [],
    this.bancoHoras,
    this.error,
    this.pontosHoje = const [],
  });

  PontoState copyWith({
    bool? loading,
    bool? registering,
    List<PontoModel>? registros,
    double? bancoHoras,
    String? error,
    List<PontoModel>? pontosHoje,
  }) {
    return PontoState(
      loading: loading ?? this.loading,
      registering: registering ?? this.registering,
      registros: registros ?? this.registros,
      bancoHoras: bancoHoras ?? this.bancoHoras,
      error: error,
      pontosHoje: pontosHoje ?? this.pontosHoje,
    );
  }
}

/// ====== PROVIDERS ======

final pontoCallerProvider = Provider<PontoCaller>((ref) {
  return PontoCaller();
});

final pontoControllerProvider =
    StateNotifierProvider.family<PontoController, PontoState, int>(
  (ref, parceiroId) {
    final caller = ref.watch(pontoCallerProvider);
    return PontoController(
      caller: caller,
      parceiroId: parceiroId,
    )..carregarDiaAtual();
  },
);

/// ====== CONTROLLER ======

class PontoController extends StateNotifier<PontoState> {
  final PontoCaller caller;
  final int parceiroId;

  PontoController({
    required this.caller,
    required this.parceiroId,
  }) : super(const PontoState());

  DateTime get _hoje => DateTime.now();

  /// 🔥 CARREGAR REGISTROS DO DIA
  Future<void> carregarDiaAtual() async {
    try {
      state = state.copyWith(loading: true, error: null);

      final registros = await caller.listarPorDia(
        data: _hoje,
      );

      registros.sort((a, b) =>
          (a.dataHora ?? DateTime(0)).compareTo(b.dataHora ?? DateTime(0)));

      state = state.copyWith(
        loading: false,
        registros: registros,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Erro ao carregar marcações: $e',
      );
    }
  }

  /// 🔥 DEFINIR AUTOMATICAMENTE ENTRADA/SAÍDA
  TipoRegistro _proximoTipo() {
    if (state.registros.isEmpty) {
      return TipoRegistro.entrada;
    }

    final ultimo = state.registros.last;

    if (ultimo.tipo == TipoRegistro.entrada) {
      return TipoRegistro.saida;
    } else {
      return TipoRegistro.entrada;
    }
  }

  Future<bool> registrarPontoAutomatico(BuildContext context) async {
    final login = AuthUtility.userInfo?.login;
    if (login == null || login.id == null) {
      state = state.copyWith(error: 'Login não encontrado na sessão');
      return false;
    }

    final empresaId = login.empresa?.id;
    if (empresaId == null) {
      state = state.copyWith(error: 'Empresa não encontrada na sessão');
      return false;
    }

    final parceiroId = login.parceiro?.id;

    final tipo = _decidirProximoTipo();

    state = state.copyWith(registering: true, error: null);

    try {
      final ponto = await caller.registrarPonto(
        context,
        tipo: tipo,
      );

      if (ponto == null) {
        state = state.copyWith(
          registering: false,
          error: 'Falha ao registrar ponto',
        );
        return false;
      }

      // -----------------------------------------
      // 🔥 AQUI É O PULO DO GATO:
      // Após registrar o ponto, recarregar TUDO:
      // -----------------------------------------

      await carregarDiaAtual(); // 🔄 Recarrega pontos
      _recalcularTudo(); // 🔢 horas + intervalo
      await carregarBancoHorasMesAtual(); // 📊 banco horas (opcional, se quiser)

      state = state.copyWith(registering: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        registering: false,
        error: 'Erro ao registrar ponto: $e',
      );
      return false;
    }
  }

  TipoRegistro _decidirProximoTipo() {
    if (state.registros.isEmpty) {
      return TipoRegistro.entrada;
    }

    final ultimo = state.registros.last;

    if (ultimo.tipo == TipoRegistro.entrada) {
      return TipoRegistro.saida;
    } else {
      return TipoRegistro.entrada;
    }
  }

  void _recalcularTudo() {
    state = state.copyWith(
      registros: [...state.registros],
      error: null,
    );
  }

  /// 🔥 CALCULAR BANCO DE HORAS
  Future<double?> carregarBancoHorasMesAtual() async {
    try {
      state = state.copyWith(loading: true, error: null);

      final agora = DateTime.now();

      final valor = await caller.calcularBancoHoras(
        mes: agora,
      );

      state = state.copyWith(
        loading: false,
        bancoHoras: valor,
      );

      return valor;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Erro ao carregar banco de horas: $e',
      );
      return null;
    }
  }

  /// 🔥 GERAR PDF
  Future<Uint8List?> gerarRelatorioPdf() async {
    try {
      final fim = DateTime.now();
      final inicio = fim.subtract(const Duration(days: 30));

      return await caller.gerarPdf(
        inicio: inicio,
        fim: fim,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Erro ao gerar PDF: $e',
      );
      return null;
    }
  }

  // ========================================
  // 🔥 CÁLCULOS DE HORAS TRABALHADAS
  // ========================================

  Duration get horasTrabalhadas {
    final registros = [...state.registros]..sort((a, b) =>
        (a.dataHora ?? DateTime(0)).compareTo(b.dataHora ?? DateTime(0)));

    Duration total = Duration.zero;

    for (int i = 0; i < registros.length - 1; i++) {
      final atual = registros[i];
      final prox = registros[i + 1];

      if (atual.tipo == TipoRegistro.entrada &&
          prox.tipo == TipoRegistro.saida &&
          prox.dataHora != null &&
          atual.dataHora != null) {
        total += prox.dataHora!.difference(atual.dataHora!);
      }
    }

    return total;
  }

  Duration get intervaloTotal {
    final registros = [...state.registros]..sort((a, b) =>
        (a.dataHora ?? DateTime(0)).compareTo(b.dataHora ?? DateTime(0)));

    Duration total = Duration.zero;

    for (int i = 0; i < registros.length - 1; i++) {
      final atual = registros[i];
      final prox = registros[i + 1];

      if (atual.tipo == TipoRegistro.saida &&
          prox.tipo == TipoRegistro.entrada &&
          prox.dataHora != null &&
          atual.dataHora != null) {
        total += prox.dataHora!.difference(atual.dataHora!);
      }
    }

    return total;
  }

  String get horasTrabalhadasFormatada => _formatDuration(horasTrabalhadas);

  String get intervaloFormatado => _formatDuration(intervaloTotal);

  String _formatDuration(Duration d) {
    final horas = d.inHours;
    final min = d.inMinutes.remainder(60);
    return '${horas}h ${min.toString().padLeft(2, '0')}min';
  }

  /// 🔥 GERAR LISTA DE PAR ENTRADA/SAÍDA PARA A TELA
  List<Map<String, String>> get marcacoesAgrupadas {
    final registros = [...state.registros]..sort((a, b) =>
        (a.dataHora ?? DateTime(0)).compareTo(b.dataHora ?? DateTime(0)));

    final List<Map<String, String>> lista = [];

    for (int i = 0; i < registros.length; i++) {
      final r = registros[i];

      if (r.tipo == TipoRegistro.entrada) {
        String entrada = r.horaFormatada;
        String saida = '--:--';

        if (i + 1 < registros.length &&
            registros[i + 1].tipo == TipoRegistro.saida) {
          saida = registros[i + 1].horaFormatada;
        }

        lista.add({
          'entrada': entrada,
          'saida': saida,
        });
      }
    }

    return lista;
  }
}
