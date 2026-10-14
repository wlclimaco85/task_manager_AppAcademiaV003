import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/services/fitness_conta_sync.dart';
import 'package:task_manager_flutter/data/services/fitness_360_local_store.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/tenant_context.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';
import 'sessao_treino_registro_model.dart';

class PontoFitness {
  final DateTime data;
  final double valor;
  const PontoFitness(this.data, this.valor);
}

class SerieFitness {
  final String titulo, unidade;
  final List<PontoFitness> pontos;
  const SerieFitness(this.titulo, this.unidade, this.pontos);
}

class GraficosFitnessDados {
  final List<SessaoTreinoRegistroModel> sessoes;
  final List<Fitness360Record> registros;
  final List<Map<String, dynamic>> diario;
  const GraficosFitnessDados(
      {required this.sessoes, required this.registros, this.diario = const []});

  static Future<GraficosFitnessDados> carregar() async {
    final resultados = await Future.wait<dynamic>([
      FitnessOfflineRepository().getSessoesConcluidas(),
      Fitness360LocalStore.records(),
      _carregarDiario(),
    ]);
    return GraficosFitnessDados(
        sessoes: resultados[0],
        registros: resultados[1],
        diario: resultados[2]);
  }

  static Future<List<Map<String, dynamic>>> _carregarDiario() async {
    final prefs = await SharedPreferences.getInstance();
    final key = FitnessContaSync.chave('fitness_graficos_diario');
    try {
      if (FitnessContaSync.autenticado) {
        final hoje = DateTime.now();
        String dia(DateTime d) => d.toIso8601String().split('T').first;
        final url = Uri.parse(
                ApiLinks.fitnessResumo.replaceFirst('/resumo', '/historico'))
            .replace(queryParameters: {
          'inicio': dia(hoje.subtract(const Duration(days: 89))),
          'fim': dia(hoje)
        });
        final resposta = await http
            .get(url, headers: TenantContext.headers)
            .timeout(const Duration(seconds: 10));
        if (resposta.statusCode == 200 && jsonDecode(resposta.body) is List) {
          await prefs.setString(key, resposta.body);
        } else {
          AppLogger.i.warn(
              'Gráficos: histórico diário indisponível; usando cache real.');
        }
      }
      return (jsonDecode(prefs.getString(key) ?? '[]') as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (error, stack) {
      AppLogger.i.error('Gráficos: falha ao carregar histórico diário.', stack);
      try {
        return (jsonDecode(prefs.getString(key) ?? '[]') as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } catch (_) {
        return [];
      }
    }
  }

  Map<String, String> get exercicios => {
        for (final s in sessoes)
          for (final e in s.exerciciosExecutados) e.exercicioId: e.exercicioNome
      };
  Set<String> get medidas => {
        'Peso',
        for (final r in registros.where((r) => r.type == 'corpo')) r.title
      };

  List<SerieFitness> series(
      {required int dias,
      required DateTime agora,
      String medida = 'Peso',
      String? exercicioId}) {
    final inicio = DateTime(agora.year, agora.month, agora.day)
        .subtract(Duration(days: dias - 1));
    bool noPeriodo(DateTime d) => !d.isBefore(inicio) && !d.isAfter(agora);
    DateTime dia(DateTime d) => DateTime(d.year, d.month, d.day);
    double? numero(dynamic v) => v is num
        ? v.toDouble()
        : double.tryParse(v?.toString().replaceAll(',', '.') ?? '');
    final treinos = {
      for (final s in sessoes)
        if (s.id.isNotEmpty) s.id: s
    }.values.where((s) {
      final d = DateTime.tryParse(s.dataHoraInicio);
      return d != null && noPeriodo(d);
    }).toList()
      ..sort((a, b) => a.dataHoraInicio.compareTo(b.dataHoraInicio));
    final porDia = <DateTime, PontoFitness>{};
    if (medida == 'Peso') {
      for (final r in diario) {
        final d = DateTime.tryParse(r['data']?.toString() ?? '');
        final v = numero(r['pesoKg']);
        if (d != null && noPeriodo(d) && v != null && v.isFinite && v > 0)
          porDia[dia(d)] = PontoFitness(d, v);
      }
    }
    String unidade = medida == 'Peso' ? 'kg' : '';
    for (final r in registros.where((r) =>
        r.type == 'corpo' && r.title == medida && noPeriodo(r.createdAt))) {
      final match =
          RegExp(r'^\s*(\d+(?:[.,]\d+)?)\s*(.*)$').firstMatch(r.value);
      if (match == null) continue;
      final v = numero(match.group(1));
      if (v == null || !v.isFinite) continue;
      final anterior = porDia[dia(r.createdAt)];
      if (anterior == null || !r.createdAt.isBefore(anterior.data)) {
        porDia[dia(r.createdAt)] = PontoFitness(r.createdAt, v);
        unidade = match.group(2)!.trim();
      }
    }
    List<PontoFitness> pontos(
            double Function(SessaoTreinoRegistroModel) valor) =>
        [
          for (final s in treinos)
            PontoFitness(DateTime.parse(s.dataHoraInicio), valor(s))
        ];
    final contagens = <DateTime, double>{};
    for (final s in treinos) {
      final d = dia(DateTime.parse(s.dataHoraInicio));
      contagens[d] = (contagens[d] ?? 0) + 1;
    }
    final peso = porDia.values.toList()
      ..sort((a, b) => a.data.compareTo(b.data));
    final quantidade = [
      for (var i = 0; i < dias; i++)
        PontoFitness(inicio.add(Duration(days: i)),
            contagens[inicio.add(Duration(days: i))] ?? 0)
    ];
    List<PontoFitness> registrosDaUnidade(String tipo, RegExp formato) {
      final pontos = <PontoFitness>[];
      for (final r
          in registros.where((r) => r.type == tipo && noPeriodo(r.createdAt))) {
        final m = formato.firstMatch(r.value);
        if (m == null) continue;
        final v = numero(m.group(1));
        if (v != null && v.isFinite) pontos.add(PontoFitness(r.createdAt, v));
      }
      return pontos..sort((a, b) => a.data.compareTo(b.data));
    }

    final sono = <DateTime, PontoFitness>{};
    final passos = <PontoFitness>[];
    for (final r in diario) {
      final d = DateTime.tryParse(r['data']?.toString() ?? '');
      if (d == null || !noPeriodo(d)) continue;
      final s = numero(r['sonoMinutos']);
      if (s != null && s > 0) sono[dia(d)] = PontoFitness(d, s);
      final p = numero(r['passos']);
      if (p != null && p > 0) passos.add(PontoFitness(d, p));
    }
    for (final r
        in registros.where((r) => r.type == 'sono' && noPeriodo(r.createdAt))) {
      final horas = RegExp(r'(\d+(?:[.,]\d+)?)\s*h').firstMatch(r.value);
      final minutos = RegExp(r'(\d+)\s*m').firstMatch(r.value);
      if (horas != null || minutos != null)
        sono[dia(r.createdAt)] = PontoFitness(
            r.createdAt,
            (numero(horas?.group(1)) ?? 0) * 60 +
                (numero(minutos?.group(1)) ?? 0));
    }
    final sonoOrdenado = sono.values.toList()
      ..sort((a, b) => a.data.compareTo(b.data));
    passos.sort((a, b) => a.data.compareTo(b.data));
    return [
      SerieFitness('Evolução de $medida', unidade, peso),
      SerieFitness('Quantidade de treinos', 'treinos',
          treinos.isEmpty ? [] : quantidade),
      SerieFitness(
          'Volume realizado',
          'kg × repetições',
          pontos((s) => s.exerciciosExecutados
              .expand((e) => e.series)
              .where((s) => s.concluida)
              .fold<double>(
                  0, (v, s) => v + s.cargaRealKg * s.repeticoesRealizadas))),
      SerieFitness(
          'Duração dos treinos', 'min', pontos((s) => s.duracaoSegundos / 60)),
      SerieFitness(
          'Séries concluídas',
          'séries',
          pontos((s) => s.exerciciosExecutados
              .expand((e) => e.series)
              .where((s) => s.concluida)
              .length
              .toDouble())),
      SerieFitness(
          'Repetições realizadas',
          'repetições',
          pontos((s) => s.exerciciosExecutados
              .expand((e) => e.series)
              .where((s) => s.concluida)
              .fold<double>(0, (v, s) => v + s.repeticoesRealizadas))),
      SerieFitness(
          'Esforço registrado', 'RPE', pontos((s) => s.rpe.toDouble())),
      SerieFitness('Atividade registrada', 'km',
          registrosDaUnidade('atividade', RegExp(r'(\d+(?:[.,]\d+)?)\s*km'))),
      SerieFitness('Sono registrado', 'min', sonoOrdenado),
      SerieFitness('Passos registrados', 'passos', passos),
      SerieFitness('Batimentos registrados', 'bpm',
          registrosDaUnidade('batimento', RegExp(r'(\d+(?:[.,]\d+)?)\s*bpm'))),
      if (exercicioId != null)
        SerieFitness('Carga do exercício', 'kg', [
          for (final s in treinos)
            if (s.exerciciosExecutados.any((e) =>
                e.exercicioId == exercicioId &&
                e.series.any((s) => s.concluida)))
              PontoFitness(
                  DateTime.parse(s.dataHoraInicio),
                  s.exerciciosExecutados
                      .where((e) => e.exercicioId == exercicioId)
                      .expand((e) => e.series)
                      .where((s) => s.concluida)
                      .map((s) => s.cargaRealKg)
                      .reduce((a, b) => a > b ? a : b))
        ]),
    ];
  }
}
