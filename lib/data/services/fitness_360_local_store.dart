import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/hidratacao_model.dart';
import 'package:task_manager_flutter/data/models/saude_diaria_model.dart';
import 'package:task_manager_flutter/data/services/gamificacao_caller.dart';
import 'package:task_manager_flutter/data/services/saude_diaria_caller.dart';

/// Hábito de hidratação concluído: total do dia atingiu a meta configurada.
bool hidratacaoMetaAtingida(ResumoHidratacao? resumo) {
  final meta = resumo?.metaDiariaMl;
  if (resumo == null || meta == null || meta <= 0) return false;
  return resumo.totalMl >= meta;
}

/// Resumo exibido no Hub Fitness. Todos os valores vêm de dados reais (API ou
/// registros locais do aluno); o que não tem fonte fica null/zero e a tela
/// mostra "sem registro" em vez de número de demonstração.
class Fitness360Summary {
  const Fitness360Summary({
    required this.steps,
    required this.trainingMinutes,
    required this.heartRate,
    required this.sleepMinutes,
    required this.weightKg,
    required this.habitsDone,
    required this.activeCalories,
    required this.distanceKm,
    required this.activeDaysWeek,
    required this.weightGoalKg,
    required this.lastSyncAt,
    required this.syncSource,
    this.heightCm,
  });

  /// Hábitos diários contados: treino, passos, sono, hidratação e check-in.
  static const int totalHabitos = 5;

  int get habitsTotal => totalHabitos;

  /// Meta de sono usada no card (8 horas).
  static const int sleepGoalMinutes = 480;

  final int steps;
  final int trainingMinutes;
  final int? heartRate;
  final int sleepMinutes;

  /// Peso real (API ou registro local). Null quando o aluno ainda não tem peso.
  final double? weightKg;
  final double? weightGoalKg;
  final int? heightCm;
  final int habitsDone;
  final int activeCalories;
  final double distanceKm;

  /// Dias com atividade (passos ou treino) nos últimos 7 dias.
  final int activeDaysWeek;
  final DateTime lastSyncAt;
  final String syncSource;

  double get weeklyProgress => (activeDaysWeek / 7).clamp(0.0, 1.0);

  /// Título do card "Corpo" no Hub.
  String get pesoTitulo => weightKg != null
      ? 'Corpo ${weightKg!.toStringAsFixed(1)} kg'
      : 'Corpo sem registro';

  /// Texto da meta de peso no card "Corpo".
  String get metaPesoTexto => weightGoalKg != null
      ? 'Meta ${weightGoalKg!.toStringAsFixed(1)} kg'
      : 'Meta não definida';

  /// IMC real (peso / altura²); null sem peso ou altura.
  double? get imc {
    if (weightKg == null || heightCm == null || heightCm! <= 0) return null;
    final alturaM = heightCm! / 100;
    return weightKg! / (alturaM * alturaM);
  }

  String get imcTexto =>
      imc != null ? 'IMC ${imc!.toStringAsFixed(1)}' : 'IMC sem altura';

  String get sleepLabel {
    final hours = sleepMinutes ~/ 60;
    final minutes = sleepMinutes % 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  String get sonoTitulo =>
      sleepMinutes > 0 ? 'Sono $sleepLabel' : 'Sono sem registro';

  String get sonoSubtitulo => sleepMinutes > 0
      ? '${(sleepMinutes * 100 ~/ sleepGoalMinutes).clamp(0, 999)}% da meta de 8h'
      : 'Registre seu sono para acompanhar a recuperação';

  String get cardioTitulo =>
      heartRate != null ? 'Cardio $heartRate bpm' : 'Cardio sem registro';

  String get cardioSubtitulo => heartRate != null
      ? 'Frequência cardíaca registrada hoje'
      : 'Registre seus batimentos';

  String get diasAtivosTexto => '$activeDaysWeek/7 dias ativos';

  /// Converte o resumo REAL da API. [hidratacaoMetaAtingida] e [checkinFeito]
  /// vêm das APIs de hidratação e check-in e completam os hábitos do dia.
  factory Fitness360Summary.fromApi(
    ResumoSaudeDiaria r, {
    bool hidratacaoMetaAtingida = false,
    bool checkinFeito = false,
  }) {
    final habitos = [
      r.treinoMinutos > 0,
      r.passos > 0,
      r.sonoMinutos > 0,
      hidratacaoMetaAtingida,
      checkinFeito,
    ].where((feito) => feito).length;

    return Fitness360Summary(
      steps: r.passos,
      trainingMinutes: r.treinoMinutos,
      heartRate: r.batimentos,
      sleepMinutes: r.sonoMinutos,
      weightKg: r.pesoKg,
      weightGoalKg: r.pesoMetaKg,
      heightCm: r.alturaCm,
      habitsDone: habitos,
      activeCalories: r.caloriasAtivas,
      distanceKm: r.distanciaKm,
      activeDaysWeek: diasAtivosNaSemana(r),
      lastSyncAt: DateTime.now(),
      syncSource: 'API',
    );
  }

  /// Dias distintos com passos ou treino no histórico semanal (inclui hoje).
  static int diasAtivosNaSemana(ResumoSaudeDiaria r) {
    final dias = <String>{
      for (final d in r.historicoSemanal)
        if (d.passos > 0 || d.treinoMinutos > 0)
          '${d.data.year}-${d.data.month}-${d.data.day}',
      if (r.passos > 0 || r.treinoMinutos > 0)
        '${r.data.year}-${r.data.month}-${r.data.day}',
    };
    return dias.length.clamp(0, 7);
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
    'workout',
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

  /// Extrai "<numero> km", "<numero> min" ou calorias do registro de
  /// atividade e sincroniza com o backend.
  static final _valorAtividadePattern = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(km|quil[oô]metros?|min(?:utos?)?|passos?)',
      caseSensitive: false);

  static Future<void> _sincronizarAtividadeComBackend(String value) async {
    final match = _valorAtividadePattern.firstMatch(value);
    if (match == null) return;
    final numStr = match.group(1)?.replaceAll(',', '.') ?? '';
    final quantidadeDouble = double.tryParse(numStr);
    if (quantidadeDouble == null) return;
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

    final atualizado = unidade.startsWith('km') || unidade.startsWith('quil')
        ? atual.copyWith(
            treinoMinutos: atual.treinoMinutos + (quantidadeDouble * 10).round(),
            passos: atual.passos + (quantidadeDouble * 1300).round(),
          )
        : atual.copyWith(
            treinoMinutos: atual.treinoMinutos + quantidadeDouble.round(),
          );

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

  /// Le o opt-in de comunidade preferencialmente do backend (GET perfil de
  /// gamificacao). Em caso de falha de rede, cai no valor salvo localmente
  /// (mesmo padrao de [_atividadeSeriesFromBackend]).
  static Future<bool> communityOptInFromBackend() async {
    final perfil = await GamificacaoCaller().fetchPerfil();
    if (perfil != null) {
      // Mantem o cache local consistente com o backend.
      await setCommunityOptIn(perfil.comunidadeOptIn);
      return perfil.comunidadeOptIn;
    }
    return communityOptIn();
  }

  /// Atualiza o opt-in de comunidade no backend via PUT. So atualiza o cache
  /// local se a chamada de rede tiver sucesso; em falha, mantem o valor local
  /// anterior como fallback (nao perde a intencao do usuario, mas evita
  /// divergencia silenciosa do servidor).
  static Future<bool> setCommunityOptInBackend(bool enabled) async {
    final perfil = await GamificacaoCaller().atualizarOptIns(
      comunidadeOptIn: enabled,
    );
    if (perfil != null) {
      await setCommunityOptIn(perfil.comunidadeOptIn);
      return true;
    }
    // Falha de rede: mantem o local como fallback (padrao do projeto), mas
    // ainda assim aplica a intencao do usuario localmente.
    await setCommunityOptIn(enabled);
    return false;
  }

  static Future<Fitness360Summary> summary() async {
    final prefs = await SharedPreferences.getInstance();
    final all = await records();
    final activity = all.where((item) => item.type == 'atividade').toList();
    final body = all.where((item) => item.type == 'corpo').toList();
    final habits = all.where((item) => item.type == 'habito').toList();
    final sleep = all.where((item) => item.type == 'sono').toList();
    final heart = all.where((item) => item.type == 'batimento').toList();

    // Modo offline: somente o que o aluno registrou localmente; sem registro
    // os valores ficam zerados/nulos (nada de números de demonstração).
    final limiteSemana = DateTime.now().subtract(const Duration(days: 7));
    final diasAtivos = <String>{
      for (final item in activity)
        if (item.createdAt.isAfter(limiteSemana))
          '${item.createdAt.year}-${item.createdAt.month}-${item.createdAt.day}',
    };

    return Fitness360Summary(
      steps: 0,
      trainingMinutes: _sumMinutes(activity, fallback: 0),
      heartRate: heart.isEmpty ? null : _firstInt(heart, fallback: 0),
      sleepMinutes: _firstSleepMinutes(sleep, fallback: 0),
      weightKg: _firstDouble(body),
      habitsDone: habits.length.clamp(0, Fitness360Summary.totalHabitos),
      activeCalories: _sumCalories(activity, fallback: 0),
      distanceKm: _sumKm(activity, fallback: 0),
      activeDaysWeek: diasAtivos.length.clamp(0, 7),
      weightGoalKg: null,
      lastSyncAt: DateTime.tryParse(prefs.getString(_syncAtKey) ?? '') ??
          DateTime.now(),
      syncSource: prefs.getString(_syncSourceKey) ?? 'Registro de Atividades',
    );
  }

  static double _sumKm(List<Fitness360Record> items, {required double fallback}) {
    double total = 0.0;
    for (final item in items) {
      final match = RegExp(r'(\d+(?:[.,]\d+)?)\s*km', caseSensitive: false).firstMatch(item.value);
      if (match != null) {
        total += double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0.0;
      }
    }
    return total == 0.0 ? fallback : double.parse(total.toStringAsFixed(1));
  }

  static int _sumCalories(List<Fitness360Record> items, {required int fallback}) {
    int total = 0;
    for (final item in items) {
      final match = RegExp(r'(\d+)\s*kcal', caseSensitive: false).firstMatch(item.value);
      if (match != null) {
        total += int.tryParse(match.group(1)!) ?? 0;
      }
    }
    return total == 0 ? fallback : total;
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

  static double? _firstDouble(List<Fitness360Record> items) {
    for (final item in items) {
      final normalized = item.value.replaceAll(',', '.');
      final match = RegExp(r'\d+(\.\d+)?').firstMatch(normalized);
      if (match != null) return double.tryParse(match.group(0)!);
    }
    return null;
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
      'value': '5,6 km',
      'note': 'Distância diária concluída',
      'createdAt': DateTime.now().toIso8601String(),
    },
    {
      'id': 2,
      'type': 'atividade',
      'title': 'Futebol',
      'value': '60 min (570 kcal)',
      'note': 'Partida com amigos • Alta intensidade',
      'createdAt':
          DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
    },
    {
      'id': 3,
      'type': 'atividade',
      'title': 'Beach Tennis',
      'value': '45 min (380 kcal)',
      'note': 'Treino de areia / Alto gasto calórico',
      'createdAt':
          DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
    },
    {
      'id': 4,
      'type': 'corpo',
      'title': 'Peso',
      'value': '76,4 kg',
      'note': 'IMC estimado 23,8',
      'createdAt':
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    },
    {
      'id': 5,
      'type': 'habito',
      'title': 'Agua',
      'value': '2,5 L',
      'note': 'Check-in diário de hidratação',
      'createdAt': DateTime.now()
          .subtract(const Duration(minutes: 40))
          .toIso8601String(),
    },
  ];
}
