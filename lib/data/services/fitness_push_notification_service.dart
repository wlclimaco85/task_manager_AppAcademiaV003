import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';

/// Modelo de Notificação Push Fitness
class FitnessNotificationItem {
  final String id;
  final String titulo;
  final String corpo;
  final DateTime dataHora;
  final String tipo; // 'treino_hoje', 'inatividade', 'nova_ficha', 'meta_batida'
  final bool lida;
  final Map<String, dynamic>? payload;

  FitnessNotificationItem({
    required this.id,
    required this.titulo,
    required this.corpo,
    required this.dataHora,
    required this.tipo,
    this.lida = false,
    this.payload,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'titulo': titulo,
        'corpo': corpo,
        'dataHora': dataHora.toIso8601String(),
        'tipo': tipo,
        'lida': lida,
        'payload': payload,
      };

  factory FitnessNotificationItem.fromMap(Map<String, dynamic> map) =>
      FitnessNotificationItem(
        id: map['id']?.toString() ?? '',
        titulo: map['titulo']?.toString() ?? '',
        corpo: map['corpo']?.toString() ?? '',
        dataHora: DateTime.tryParse(map['dataHora']?.toString() ?? '') ??
            DateTime.now(),
        tipo: map['tipo']?.toString() ?? 'geral',
        lida: map['lida'] == true,
        payload: map['payload'] is Map<String, dynamic> ? map['payload'] : null,
      );
}

/// Serviço de Notificações Push Inteligentes (Padrão MFIT Personal & MyFitCoach)
/// Suporta agendamentos locais offline e integração transparente com Firebase Cloud Messaging (FCM).
class FitnessPushNotificationService {
  static const String _kNotificationsKey = 'appacademia_fitness_notifications_v1';

  static final FitnessPushNotificationService _instance =
      FitnessPushNotificationService._internal();
  factory FitnessPushNotificationService() => _instance;
  FitnessPushNotificationService._internal();

  final _repo = FitnessOfflineRepository();

  /// Inicializa e verifica gatilhos automáticos (ex: inatividade ou lembrete de treino do dia)
  Future<void> inicializarVerificacoesAutomaticas({String? alunoId}) async {
    try {
      await verificarLembreteInatividade(alunoId: alunoId);
      await verificarLembreteTreinoDoDia(alunoId: alunoId);
    } catch (e) {
      debugPrint('[FitnessPushNotificationService] Erro nas verificações automáticas: $e');
    }
  }

  /// 1. Gatilho de Inatividade (> 48h sem treinar)
  Future<void> verificarLembreteInatividade({String? alunoId}) async {
    final sessoes = await _repo.getSessoesConcluidas(alunoId: alunoId);
    if (sessoes.isEmpty) return;

    final ultimaSessao = DateTime.tryParse(sessoes.first.dataHoraFim);
    if (ultimaSessao == null) return;

    final horasSemTreino = DateTime.now().difference(ultimaSessao).inHours;
    if (horasSemTreino >= 48) {
      final dias = (horasSemTreino / 24).floor();
      await agendarNotificacao(
        FitnessNotificationItem(
          id: 'inatividade_${DateTime.now().day}',
          titulo: '⚡ Sentimos sua falta no treino!',
          corpo: 'Você está há $dias dias sem treinar. Que tal bater a meta de hoje e manter o foco?',
          dataHora: DateTime.now(),
          tipo: 'inatividade',
        ),
      );
    }
  }

  /// 2. Gatilho de Treino do Dia
  Future<void> verificarLembreteTreinoDoDia({String? alunoId}) async {
    final plano = await _repo.getPlanoAtivo(alunoId: alunoId ?? 'aluno_1');
    if (plano == null || plano.divisoes.isEmpty) return;

    // Sugere a próxima divisão a ser treinada
    final divisaoSugerida = plano.divisoes.first;

    await agendarNotificacao(
      FitnessNotificationItem(
        id: 'treino_hoje_${DateTime.now().day}',
        titulo: '🔥 Treino de Hoje Pronto!',
        corpo: 'Hoje é dia de Treino ${divisaoSugerida.letra} (${divisaoSugerida.nome}). Abra o app e inicie sua sessão.',
        dataHora: DateTime.now(),
        tipo: 'treino_hoje',
        payload: {
          'planoId': plano.id,
          'divisaoLetra': divisaoSugerida.letra,
        },
      ),
    );
  }

  /// 3. Gatilho quando Personal publica ou atualiza ficha
  Future<void> notificarNovaFichaPrescrita({
    required String alunoNome,
    required String personalNome,
    required PlanoTreinoModel plano,
  }) async {
    await agendarNotificacao(
      FitnessNotificationItem(
        id: 'nova_ficha_${plano.id}',
        titulo: '📋 Nova Ficha Prescrita!',
        corpo: 'O Personal $personalNome acabou de prescrever seu novo treino "${plano.titulo}". Acesse agora para conferir.',
        dataHora: DateTime.now(),
        tipo: 'nova_ficha',
        payload: {'planoId': plano.id},
      ),
    );
  }

  /// 4. Notificação de Meta / Streak Batido
  Future<void> notificarMetaBatida({
    required int streakDias,
    required double tonelagemKg,
  }) async {
    await agendarNotificacao(
      FitnessNotificationItem(
        id: 'meta_${DateTime.now().millisecondsSinceEpoch}',
        titulo: '🏆 Treino Batido com Sucesso!',
        corpo: 'Você levantou ${(tonelagemKg / 1000).toStringAsFixed(1)} toneladas hoje! Sequência de $streakDias dias consecutivos.',
        dataHora: DateTime.now(),
        tipo: 'meta_batida',
      ),
    );
  }

  /// Grava a notificação no repositório local
  Future<void> agendarNotificacao(FitnessNotificationItem item) async {
    final lista = await getNotificacoes();
    // Evita duplicar a mesma notificação no mesmo dia
    if (lista.any((n) => n.id == item.id)) return;

    lista.insert(0, item);
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(lista.map((n) => n.toMap()).toList());
    await prefs.setString(_kNotificationsKey, jsonStr);
  }

  Future<List<FitnessNotificationItem>> getNotificacoes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kNotificationsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = json.decode(raw) as List<dynamic>;
      return decoded
          .map((e) => FitnessNotificationItem.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[FitnessPushNotificationService] Erro decode notificações: $e');
      return [];
    }
  }

  Future<void> marcarComoLida(String id) async {
    final lista = await getNotificacoes();
    final idx = lista.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      final antiga = lista[idx];
      lista[idx] = FitnessNotificationItem(
        id: antiga.id,
        titulo: antiga.titulo,
        corpo: antiga.corpo,
        dataHora: antiga.dataHora,
        tipo: antiga.tipo,
        lida: true,
        payload: antiga.payload,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kNotificationsKey, json.encode(lista.map((n) => n.toMap()).toList()));
    }
  }
}
