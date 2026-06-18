import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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

  String get sleepLabel {
    final hours = sleepMinutes ~/ 60;
    final minutes = sleepMinutes % 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
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

  static Future<List<Fitness360Record>> records({String? type}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recordsKey);
    final parsed = raw == null ? _seed : jsonDecode(raw) as List<dynamic>;
    final list = parsed
        .map((item) => Fitness360Record.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (type == null) return list;
    return list.where((item) => item.type == type).toList();
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
  }

  static Future<Fitness360Summary> summary() async {
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
    );
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
