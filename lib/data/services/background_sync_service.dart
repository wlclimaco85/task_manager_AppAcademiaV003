import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
import 'package:task_manager_flutter/data/services/fitness_conta_sync.dart';
import 'package:task_manager_flutter/data/services/nutricao_farmaco_offline_repository.dart';
import 'package:task_manager_flutter/data/services/exames_offline_repository.dart';
import 'package:task_manager_flutter/data/services/fitness_360_local_store.dart';
import 'package:task_manager_flutter/data/services/personal_gestao_offline_repository.dart';
import 'package:task_manager_flutter/data/utils/fitness_access.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';

/// Serviço responsável pelo monitoramento contínuo e sincronização automática em background.
/// 100% transparente para o usuário: sincroniza ao iniciar, ao voltar pro app (resumed),
/// a cada 20 segundos em segundo plano, ou quando uma conexão com a internet é detectada.
class BackgroundSyncService with WidgetsBindingObserver {
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  Timer? _syncTimer;
  bool _isSyncing = false;
  bool _initialized = false;

  /// Notificador reativo para que as telas (Hub de Treinos, Nutrição, etc.) atualizem
  /// automaticamente e silenciosamente na interface sempre que novos dados chegarem.
  static final ValueNotifier<int> mudancas = ValueNotifier<int>(0);

  final NetworkCaller _networkCaller = NetworkCaller();
  final FitnessOfflineRepository _offlineRepository = FitnessOfflineRepository();

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addObserver(this);

    // Dispara sincronização imediata
    syncPendingData();

    // Sincroniza imediatamente sempre que a sessão mudar (ex: login/logout)
    AuthUtility.session.addListener(() {
      if (FitnessContaSync.autenticado) {
        syncPendingData();
      }
    });

    // Monitoramento inteligente contínuo a cada 20 segundos
    _syncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (FitnessContaSync.autenticado) {
        syncPendingData();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && FitnessContaSync.autenticado) {
      debugPrint('📱 [BackgroundSyncService] App resumed: sincronizando dados em segundo plano...');
      syncPendingData();
    }
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    _initialized = false;
  }

  /// Drena todas as pendências locais e busca atualizações da nuvem
  Future<void> syncPendingData() async {
    if (_isSyncing || !FitnessContaSync.autenticado) return;
    _isSyncing = true;

    try {
      // 1. Treinos e fichas (Mobile & Web)
      await _syncTreinos();

      // 2. Nutrição, medicamentos e suplementos
      await _syncNutricao();

      // 3. Exames clínicos e registros corporais
      await _syncExamesERegistros();

      // 4. Gestão de Personal (se for perfil personal)
      if (podeGerenciarAlunos()) {
        await PersonalGestaoOfflineRepository().sincronizarPendencias();
      }

      // 5. Fila genérica
      await _syncGenericQueue();

      // Notifica as telas abertas para atualizarem silenciosamente
      mudancas.value++;
    } catch (e) {
      debugPrint('⚠️ [BackgroundSyncService] Erro na sincronização silenciosa: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncTreinos() async {
    await _offlineRepository.getPlanosTreino();
    await _offlineRepository.getSessoesConcluidas();
  }

  Future<void> _syncNutricao() async {
    await NutricaoFarmacoOfflineRepository().getDietas();
    await NutricaoFarmacoOfflineRepository().getMedicamentos();
    await NutricaoFarmacoOfflineRepository().getSuplementos();
  }

  Future<void> _syncExamesERegistros() async {
    await ExamesOfflineRepository().getExames();
    await Fitness360LocalStore.records();
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
