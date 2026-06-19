import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/saude_diaria_model.dart';
import 'package:task_manager_flutter/data/services/saude_diaria_caller.dart';

class Fitness360Summary {
  const Fitness360Summary({
    required this.steps,
    required this.trainingMinutes,
    required this.heartRate,
    required this.sleepMinutes,
    required this.weightKg,
    required this.habitsDone,
    required this.habitsTotal,
    required this.weeklyProgress,
    required this.points,
    required this.sleepScore,
    required this.cardioScore,
    required this.bodyScore,
    required this.activeCalories,
    required this.distanceKm,
    required this.spo2,
    required this.stress,
    required this.readiness,
    required this.weightGoalKg,
    required this.lastSyncAt,
    required this.syncSource,
  });

  final int steps;
  final int trainingMinutes;
  final int heartRate;
  final int sleepMinutes;
  final double weightKg;
  final int habitsDone;
  final int habitsTotal;
  final double weeklyProgress;
  final int points;
  final int sleepScore;
  final int cardioScore;
  final int bodyScore;
  final int activeCalories;
  final double distanceKm;
  final int spo2;
  final int stress;
  final int readiness;
  final double weightGoalKg;
  final DateTime lastSyncAt;
  final String syncSource;

  String get sleepLabel {
    final hours = sleepMinutes ~/ 60;
    final minutes = sleepMinutes % 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  /// Converte um [ResumoSaudeDiaria] da API REAL em [Fitness360Summary],
  /// reaproveitando as MESMAS fórmulas derivadas do store local.
  ///
  /// - steps/trainingMinutes/heartRate/sleepMinutes/weightKg vêm da API
  ///   (com fallback para os campos opcionais que podem vir null).
  /// - spo2, stress, habits, points, weeklyProgress, scores e syncSource seguem
  ///   a mesma lógica/fallback de [Fitness360LocalStore.summary]. O tamanho do
  ///   histórico semanal substitui a "quantidade de registros" como base das
  ///   derivações que dependiam dela.
  factory Fitness360Summary.fromApi(ResumoSaudeDiaria r) {
    final dias = r.historicoSemanal.length;
    return Fitness360Summary(
      steps: r.passos,
      trainingMinutes: r.treinoMinutos,
      heartRate: r.batimentos ?? 72,
      sleepMinutes: r.sonoMinutos,
      weightKg: r.pesoKg ?? 76.4,
      habitsDone: 0,
      habitsTotal: 6,
      weeklyProgress: (dias / 7).clamp(0.0, 1.0),
      points: 120 + (dias * 20),
      sleepScore: (74 + dias * 3).clamp(0, 100),
      cardioScore: (68 + dias * 2).clamp(0, 100),
      bodyScore: (72 + dias * 2).clamp(0, 100),
      activeCalories: 286 + dias * 42,
      distanceKm: 5.6 + dias * 0.4,
      spo2: 97,
      stress: 31,
      readiness: 70,
      weightGoalKg: r.pesoMetaKg ?? 74,
      lastSyncAt: DateTime.now(),
      syncSource: 'API',
    );
  }
}

class Fitness360Record {
  const Fitness360Record({
    required this.id,
    required this.type,
    required this.title,
    required this.value,
    required this.note,
    required this.createdAt,
  });

  final int id;
  final String type;
  final String title;
  final String value;
  final String note;
  final DateTime createdAt;

  factory Fitness360Record.fromJson(Map<String, dynamic> json) {
    return Fitness360Record(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? 'atividade',
      title: json['title'] as String? ?? '',
      value: json['value'] as String? ?? '',
      note: json['note'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'value': value,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };
}

class Fitness360LocalStore {
  Fitness360LocalStore._();

  static const _recordsKey = 'fitness360.records.v1';
  static const _cardOrderKey = 'fitness360.home.card_order.v1';
  static const _hiddenCardsKey = 'fitness360.home.hidden_cards.v1';
  static const _syncAtKey = 'fitness360.last_sync_at.v1';
  static const _syncSourceKey = 'fitness360.sync_source.v1';
  static const _integrationConsentKey = 'fitness360.integration_consent.v1';
  static const _communityOptInKey = 'fitness360.community_opt_in.v1';

  static const defaultHomeCards = [
    'steps',
    'sleep',
    'workout',
    'heart',
    'body',
    'goals',
    'community',
  ];

  static Future<List<Fitness360Record>> records({String? type}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recordsKey);
    final parsed = _decodeRecords(raw);
    final list = parsed
        .map((item) => Fitness360Record.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (type == null) return list;
    return list.where((item) => item.type == type).toList();
  }

  static List<dynamic> _decodeRecords(String? raw) {
    if (raw == null || raw.isEmpty) return _seed;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List<dynamic>) return decoded;
    } catch (_) {
      return _seed;
    }
    return _seed;
  }

  static Future<void> addRecord({
    required String type,
    required String title,
    required String value,
    String note = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await records();
    final nextId = current.isEmpty
        ? 1
        : current.map((item) => item.id).reduce((a, b) => a > b ? a : b) + 1;
    final updated = [
      Fitness360Record(
        id: nextId,
        type: type,
        title: title,
        value: value,
        note: note,
        createdAt: DateTime.now(),
      ),
      ...current,
    ];
    await prefs.setString(
      _recordsKey,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );

    if (type == 'atividade') {
      await _sincronizarAtividadeComBackend(value);
    }
  }

  /// Extrai "<numero> passos" ou "<numero> min" do texto livre do registro de
  /// atividade e soma ao resumo diario real no backend (passos/treinoMinutos).
  /// Falha silenciosa: o registro local ja foi salvo, o backend e um reforco.
  static final _valorAtividadePattern =
      RegExp(r'(\d+)\s*(passos?|min(?:utos?)?)', caseSensitive: false);

  static Future<void> _sincronizarAtividadeComBackend(String value) async {
    final match = _valorAtividadePattern.firstMatch(value);
    if (match == null) return;
    final quantidade = int.tryParse(match.group(1) ?? '');
    if (quantidade == null) return;
    final unidade = match.group(2)!.toLowerCase();

    final caller = SaudeDiariaCaller();
    final atual = await caller.fetchResumo() ??
        ResumoSaudeDiaria(
          data: DateTime.now(),
          passos: 0,
          treinoMinutos: 0,
          batimentos: null,
          sonoMinutos: 0,
          pesoKg: null,
          pesoMetaKg: null,
          historicoSemanal: const [],
        );

    final atualizado = unidade.startsWith('passo')
        ? atual.copyWith(passos: atual.passos + quantidade)
        : atual.copyWith(treinoMinutos: atual.treinoMinutos + quantidade);

    await caller.salvarResumo(atualizado);
  }

  static Future<List<String>> homeCardOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_cardOrderKey) ?? defaultHomeCards;
    final sanitized = [
      ...saved.where(defaultHomeCards.contains),
      ...defaultHomeCards.where((item) => !saved.contains(item)),
    ];
    return sanitized;
  }

  static Future<void> saveHomeCardOrder(List<String> order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _cardOrderKey,
      order.where(defaultHomeCards.contains).toList(),
    );
  }

  static Future<Set<String>> hiddenHomeCards() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_hiddenCardsKey) ?? const <String>[]).toSet();
  }

  static Future<void> setHomeCardHidden(String cardId, bool hidden) async {
    final prefs = await SharedPreferences.getInstance();
    final hiddenCards = await hiddenHomeCards();
    if (hidden) {
      hiddenCards.add(cardId);
    } else {
      hiddenCards.remove(cardId);
    }
    await prefs.setStringList(_hiddenCardsKey, hiddenCards.toList());
  }

  static Future<void> markSynced({String source = 'Importacao manual'}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_syncAtKey, DateTime.now().toIso8601String());
    await prefs.setString(_syncSourceKey, source);
  }

  static Future<bool> integrationConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_integrationConsentKey) ?? false;
  }

  static Future<void> setIntegrationConsent(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_integrationConsentKey, enabled);
  }

  static Future<bool> communityOptIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_communityOptInKey) ?? false;
  }

  static Future<void> setCommunityOptIn(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_communityOptInKey, enabled);
  }

  static Future<Fitness360Summary> summary() async {
    final prefs = await SharedPreferences.getInstance();
    final all = await records();
    final activity = all.where((item) => item.type == 'atividade').toList();
    final body = all.where((item) => item.type == 'corpo').toList();
    final habits = all.where((item) => item.type == 'habito').toList();
    final sleep = all.where((item) => item.type == 'sono').toList();
    final heart = all.where((item) => item.type == 'batimento').toList();

    return Fitness360Summary(
      steps: _firstInt(activity, fallback: 7842),
      trainingMinutes: _sumMinutes(activity, fallback: 32),
      heartRate: _firstInt(heart, fallback: 72),
      sleepMinutes: _firstSleepMinutes(sleep, fallback: 438),
      weightKg: _firstDouble(body, fallback: 76.4),
      habitsDone: habits.length.clamp(0, 6),
      habitsTotal: 6,
      weeklyProgress: ((activity.length + habits.length + body.length) / 18)
          .clamp(0.0, 1.0),
      points: 120 + (activity.length * 20) + (habits.length * 10),
      sleepScore: (74 + sleep.length * 3).clamp(0, 100),
      cardioScore: (68 + heart.length * 2).clamp(0, 100),
      bodyScore: (72 + body.length * 2).clamp(0, 100),
      activeCalories: 286 + activity.length * 42,
      distanceKm: 5.6 + activity.length * 0.4,
      spo2: 97,
      stress: 31,
      readiness: (70 + habits.length * 4).clamp(0, 100),
      weightGoalKg: 74,
      lastSyncAt: DateTime.tryParse(prefs.getString(_syncAtKey) ?? '') ??
          DateTime.now().subtract(const Duration(minutes: 28)),
      syncSource: prefs.getString(_syncSourceKey) ?? 'Importacao manual',
    );
  }

  static Future<List<int>> weeklySeries(String type) async {
    if (type == 'atividade') {
      final apiSeries = await _atividadeSeriesFromBackend();
      if (apiSeries != null && apiSeries.any((value) => value > 0)) {
        return apiSeries;
      }
    }
    final all = await records(type: type);
    final seed = switch (type) {
      'sono' => [72, 78, 81, 69, 84, 88, 80],
      'batimento' => [68, 74, 71, 79, 76, 72, 70],
      'corpo' => [78, 77, 77, 76, 76, 75, 76],
      'meta' => [20, 35, 48, 60, 74, 82, 90],
      _ => [4200, 6200, 8000, 5400, 9200, 7600, 8400],
    };
    if (all.isEmpty) return seed;
    return [
      for (var i = 0; i < 7; i++)
        seed[i] +
            all.where((item) => item.createdAt.weekday == i + 1).length * 5
    ];
  }

  /// Serie real de passos dos ultimos 7 dias via GET /api/fitness/resumo
  /// (historicoSemanal). Retorna null em falha de rede para cair no mock.
  static Future<List<int>?> _atividadeSeriesFromBackend() async {
    final resumo = await SaudeDiariaCaller().fetchResumo();
    if (resumo == null) return null;
    final passosPorDia = <String, int>{
      for (final dia in resumo.historicoSemanal) _chaveData(dia.data): dia.passos,
    };
    final hoje = DateTime.now();
    return [
      for (var i = 6; i >= 0; i--)
        passosPorDia[_chaveData(hoje.subtract(Duration(days: i)))] ?? 0,
    ];
  }

  static String _chaveData(DateTime d) => '${d.year}-${d.month}-${d.day}';

  static Future<List<int>> insightSeries(String type, String range) async {
    final weekly = await weeklySeries(type);
    return switch (range) {
      'Dia' => [
          for (var i = 0; i < 6; i++)
            (weekly[i % weekly.length] * (0.72 + i * 0.06)).round()
        ],
      'Mes' => [
          for (var i = 0; i < 4; i++)
            (weekly.skip(i).take(4).fold<int>(0, (sum, value) => sum + value) /
                    4)
                .round()
        ],
      _ => weekly,
    };
  }

  static int _firstInt(List<Fitness360Record> items, {required int fallback}) {
    for (final item in items) {
      final match = RegExp(r'\d+').firstMatch(item.value.replaceAll('.', ''));
      if (match != null) return int.tryParse(match.group(0)!) ?? fallback;
    }
    return fallback;
  }

  static double _firstDouble(
    List<Fitness360Record> items, {
    required double fallback,
  }) {
    for (final item in items) {
      final normalized = item.value.replaceAll(',', '.');
      final match = RegExp(r'\d+(\.\d+)?').firstMatch(normalized);
      if (match != null) return double.tryParse(match.group(0)!) ?? fallback;
    }
    return fallback;
  }

  static int _sumMinutes(
    List<Fitness360Record> items, {
    required int fallback,
  }) {
    var total = 0;
    for (final item in items) {
      if (!item.value.toLowerCase().contains('min')) continue;
      total += _firstInt([item], fallback: 0);
    }
    return total == 0 ? fallback : total;
  }

  static int _firstSleepMinutes(
    List<Fitness360Record> items, {
    required int fallback,
  }) {
    for (final item in items) {
      final hours = RegExp(r'(\d+)h').firstMatch(item.value);
      final minutes = RegExp(r'(\d+)m').firstMatch(item.value);
      if (hours != null || minutes != null) {
        return (int.tryParse(hours?.group(1) ?? '0') ?? 0) * 60 +
            (int.tryParse(minutes?.group(1) ?? '0') ?? 0);
      }
    }
    return fallback;
  }

  static final List<Map<String, dynamic>> _seed = [
    {
      'id': 1,
      'type': 'atividade',
      'title': 'Caminhada',
      'value': '7842 passos',
      'note': 'Meta diaria em 78%',
      'createdAt': DateTime.now().toIso8601String(),
    },
    {
      'id': 2,
      'type': 'atividade',
      'title': 'Treino funcional',
      'value': '32 min',
      'note': 'Forca + cardio',
      'createdAt':
          DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
    },
    {
      'id': 3,
      'type': 'sono',
      'title': 'Sono principal',
      'value': '7h 18m',
      'note': 'Qualidade boa',
      'createdAt':
          DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
    },
    {
      'id': 4,
      'type': 'batimento',
      'title': 'Repouso',
      'value': '72 bpm',
      'note': 'Dentro do esperado',
      'createdAt':
          DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
    },
    {
      'id': 5,
      'type': 'corpo',
      'title': 'Peso',
      'value': '76,4 kg',
      'note': 'IMC estimado 23,8',
      'createdAt':
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    },
    {
      'id': 6,
      'type': 'habito',
      'title': 'Agua',
      'value': '2,1 L',
      'note': 'Check-in diario',
      'createdAt': DateTime.now()
          .subtract(const Duration(minutes: 40))
          .toIso8601String(),
    },
  ];
}
