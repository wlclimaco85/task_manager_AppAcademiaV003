import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço responsável por criar a fila de sincronização em Background.
/// Drena requisições pendentes (Offline-First) quando a conectividade é restaurada.
class BackgroundSyncService {
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  Timer? _syncTimer;
  bool _isSyncing = false;
  final NetworkCaller _networkCaller = NetworkCaller();
  final FitnessOfflineRepository _offlineRepository = FitnessOfflineRepository();

  /// Inicializa o worker em background. (Em produção, usaria WorkManager).
  void initialize() {
    // Tenta sincronizar imediatamente na abertura do app
    syncPendingData();

    // Inicia um polling a cada 3 minutos como substituto do WorkManager na web/mobile
    _syncTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      syncPendingData();
    });
  }

  void stop() {
    _syncTimer?.cancel();
  }

  /// Drena a fila local (Treinos concluídos, check-ins, etc.)
  Future<void> syncPendingData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      debugPrint('🔄 [BackgroundSyncService] Verificando dados offline pendentes...');
      await _syncSessoesTreino();
      await _syncGenericQueue();
    } catch (e) {
      debugPrint('⚠️ [BackgroundSyncService] Erro ao sincronizar: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncSessoesTreino() async {
    final sessoes = await _offlineRepository.getSessoesConcluidas();
    final pendentes = sessoes.where((s) => !s.sincronizado).toList();

    if (pendentes.isEmpty) return;
    debugPrint('📤 [BackgroundSyncService] Sincronizando ${pendentes.length} treinos pendentes com o servidor.');

    // Simulação do envio das sessões pendentes para o Backend
    for (var sessao in pendentes) {
      // Exemplo: final response = await _networkCaller.postRequest(ApiLinks.registrarTreino, sessao.toMap());
      // Vamos simular sucesso para atualizar o banco local
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Atualiza o status localmente (sincronizado: true)
      final atualizada = SessaoTreinoRegistroModel(
        id: sessao.id,
        treinoId: sessao.treinoId,
        divisaoLetra: sessao.divisaoLetra,
        divisaoNome: sessao.divisaoNome,
        alunoId: sessao.alunoId,
        dataHoraInicio: sessao.dataHoraInicio,
        dataHoraFim: sessao.dataHoraFim,
        duracaoSegundos: sessao.duracaoSegundos,
        rpe: sessao.rpe,
        feedbackAluno: sessao.feedbackAluno,
        exerciciosExecutados: sessao.exerciciosExecutados,
        sincronizado: true, // AGORA ESTÁ SINCRONIZADO
      );
      
      await _offlineRepository.atualizarSessaoTreino(atualizada);
    }
    
    debugPrint('✅ [BackgroundSyncService] Sincronização de treinos finalizada.');
  }

  // Fila genérica para outras requisições (POST/PUT/DELETE) que falharam por falta de internet
  static const String _kGenericQueueKey = 'appacademia_generic_sync_queue';

  Future<void> enqueueRequest(String method, String url, dynamic body) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kGenericQueueKey) ?? '[]';
    final List<dynamic> queue = json.decode(raw);
    
    queue.add({
      'method': method,
      'url': url,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    await prefs.setString(_kGenericQueueKey, json.encode(queue));
    debugPrint('📥 [BackgroundSyncService] Requisição ($method $url) adicionada à fila offline.');
  }

  Future<void> _syncGenericQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kGenericQueueKey) ?? '[]';
    final List<dynamic> queue = json.decode(raw);
    
    if (queue.isEmpty) return;

    List<dynamic> remainingQueue = [];
    
    for (var req in queue) {
      final method = req['method'];
      final url = req['url'];
      final body = req['body'];
      
      try {
        bool success = false;
        if (method == 'POST') {
          final res = await _networkCaller.postRequest(url, body);
          success = res.isSuccess;
        } else if (method == 'PUT') {
          final res = await _networkCaller.putRequest(url, body);
          success = res.isSuccess;
        } else if (method == 'PATCH') {
          final res = await _networkCaller.patchRequest(url, body);
          success = res.isSuccess;
        } else if (method == 'DELETE') {
          final res = await _networkCaller.deleteRequest(url, queryParams: body);
          success = res.isSuccess;
        }

        if (!success) {
          remainingQueue.add(req);
        } else {
          debugPrint('✅ [BackgroundSyncService] Requisição da fila sincronizada: $method $url');
        }
      } catch (e) {
        remainingQueue.add(req);
      }
    }
    
    await prefs.setString(_kGenericQueueKey, json.encode(remainingQueue));
  }
}
