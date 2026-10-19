import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/services/fitness_push_notification_service.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/tenant_context.dart';

/// Registra este navegador/celular no FCM e mantém o token ligado ao login atual.
///
/// Os valores públicos do Firebase entram por `--dart-define`; nenhuma credencial
/// privada é empacotada no aplicativo.
class PushRegistrationService {
  static final PushRegistrationService _instance =
      PushRegistrationService._internal();
  factory PushRegistrationService() => _instance;
  PushRegistrationService._internal();

  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _senderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const _storageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const _vapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY');

  bool _inicializado = false;
  bool _inicializando = false;
  String? _ultimaContaToken;
  StreamSubscription<String>? _registrationSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;

  bool get configurado =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _senderId.isNotEmpty &&
      _projectId.isNotEmpty;

  bool get _plataformaSuportada =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> inicializar() async {
    if (_inicializado ||
        _inicializando ||
        !configurado ||
        !_plataformaSuportada) {
      return;
    }
    _inicializando = true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: _apiKey,
            appId: _appId,
            messagingSenderId: _senderId,
            projectId: _projectId,
            authDomain: _authDomain.isEmpty ? null : _authDomain,
            storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
          ),
        );
      }
      final messaging = FirebaseMessaging.instance;
      if (!await messaging.isSupported()) return;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      _registrationSubscription ??=
          messaging.onRegistered.listen((token) => _registrar(token));
      _messageSubscription ??=
          FirebaseMessaging.onMessage.listen(_guardarMensagemRecebida);
      _inicializado = true;
    } catch (e) {
      debugPrint('[PushRegistrationService] Firebase indisponível: $e');
    } finally {
      _inicializando = false;
    }
  }

  Future<void> sincronizar() async {
    await inicializar();
    if (!_inicializado) return;
    final sessao = AuthUtility.userInfo;
    final loginId = TenantContext.userLogadoId;
    if (loginId == null || (sessao.token?.isEmpty ?? true)) return;
    try {
      await FirebaseMessaging.instance.register(
        vapidKey: kIsWeb && _vapidKey.isNotEmpty ? _vapidKey : null,
        serviceWorkerScriptPath: kIsWeb ? 'firebase-messaging-sw.js' : null,
      );
    } catch (e) {
      debugPrint('[PushRegistrationService] Token FCM indisponível: $e');
    }
  }

  Future<void> _registrar(String token) async {
    final sessao = AuthUtility.userInfo;
    final loginId = TenantContext.userLogadoId;
    if (loginId == null || (sessao.token?.isEmpty ?? true)) return;
    final chave = '$loginId:$token';
    if (_ultimaContaToken == chave) return;
    try {
      final response = await http.post(
        Uri.parse(TenantContext.applyToUrl(ApiLinks.deviceToken)),
        headers: TenantContext.jsonHeaders,
        body: jsonEncode({'token': token, 'plataforma': _plataforma()}),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _ultimaContaToken = chave;
      } else {
        debugPrint(
            '[PushRegistrationService] Registro recusado: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[PushRegistrationService] Falha ao registrar token: $e');
    }
  }

  Future<void> _guardarMensagemRecebida(RemoteMessage message) async {
    final titulo = message.notification?.title ?? message.data['titulo'];
    final corpo = message.notification?.body ?? message.data['corpo'];
    if (titulo == null || corpo == null) return;
    await FitnessPushNotificationService().agendarNotificacao(
      FitnessNotificationItem(
        id: message.messageId ?? 'fcm_${DateTime.now().microsecondsSinceEpoch}',
        titulo: titulo.toString(),
        corpo: corpo.toString(),
        dataHora: message.sentTime ?? DateTime.now(),
        tipo: message.data['tipo']?.toString() ?? 'agenda',
        payload: Map<String, dynamic>.from(message.data),
      ),
    );
  }

  String _plataforma() {
    if (kIsWeb) return 'WEB';
    return defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID';
  }
}
