import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/aviso_falta_model.dart';
import 'package:task_manager_flutter/data/services/fitness_conta_sync.dart';
import 'package:task_manager_flutter/data/services/fitness_push_notification_service.dart';

/// Repositório Offline-First para Avisos de Falta (aluno ↔ personal).
///
/// Persiste em SharedPreferences; usa duas chaves separadas:
///   - [_kEnviadosKey] → avisos enviados pelo usuário atual
///   - [_kRecebidosKey] → avisos recebidos pelo usuário atual
class AvisoFaltaRepository {
  static const String _kEnviadosKey = 'appacademia_avisos_falta_enviados_v1';
  static const String _kRecebidosKey = 'appacademia_avisos_falta_recebidos_v1';

  static final AvisoFaltaRepository _instance =
      AvisoFaltaRepository._internal();
  factory AvisoFaltaRepository() => _instance;
  AvisoFaltaRepository._internal();

  final _notif = FitnessPushNotificationService();

  String get _enviadosKey => FitnessContaSync.chave(_kEnviadosKey);
  String get _recebidosKey => FitnessContaSync.chave(_kRecebidosKey);

  // ── Leitura ────────────────────────────────────────────────────

  Future<List<AvisoFaltaModel>> getEnviados() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_enviadosKey));
  }

  Future<List<AvisoFaltaModel>> getRecebidos() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_recebidosKey));
  }

  /// Retorna o total de avisos recebidos ainda não marcados como vistos.
  Future<int> countNaoVistos() async {
    final lista = await getRecebidos();
    return lista.where((a) => !a.foiVisto).length;
  }

  // ── Envio ──────────────────────────────────────────────────────

  /// Envia um aviso de falta.
  /// [remetenteTipo] = 'aluno' ou 'personal'.
  Future<AvisoFaltaModel> enviar({
    required String remetenteTipo,
    required String remetenteId,
    required String remetenteNome,
    required String destinatarioId,
    required String destinatarioNome,
    required String dataAula,
    String? horario,
    String motivo = '',
  }) async {
    final aviso = AvisoFaltaModel(
      id: 'aviso_${DateTime.now().millisecondsSinceEpoch}',
      remetenteTipo: remetenteTipo,
      remetenteId: remetenteId,
      remetenteNome: remetenteNome,
      destinatarioId: destinatarioId,
      destinatarioNome: destinatarioNome,
      dataAula: dataAula,
      horario: horario,
      motivo: motivo,
      enviadoEm: DateTime.now(),
    );

    // Salva na fila "enviados" do remetente
    final enviados = await getEnviados();
    enviados.insert(0, aviso);
    await _salvarEnviados(enviados);

    // Simula entrega ao destinatário (persiste em recebidos do mesmo device
    // quando o mesmo app serve os dois perfis; em produção, o backend distribui).
    final recebidos = await getRecebidos();
    recebidos.insert(0, aviso);
    await _salvarRecebidos(recebidos);

    // Gera notificação local
    final isAlunoAvisando = remetenteTipo == 'aluno';
    await _notif.agendarNotificacao(
      FitnessNotificationItem(
        id: aviso.id,
        titulo: isAlunoAvisando
            ? '🔔 $remetenteNome avisou que não vai treinar'
            : '😔 Personal $remetenteNome não poderá atender hoje',
        corpo: isAlunoAvisando
            ? '$remetenteNome avisou falta para ${_formatarData(dataAula)}${horario != null ? " às $horario" : ""}.'
                '${motivo.isNotEmpty ? " Motivo: $motivo" : ""}'
            : '$remetenteNome avisou que não terá aula em ${_formatarData(dataAula)}${horario != null ? " às $horario" : ""}.'
                '${motivo.isNotEmpty ? " Motivo: $motivo" : ""}',
        dataHora: DateTime.now(),
        tipo: isAlunoAvisando ? 'falta_aluno' : 'falta_personal',
        payload: aviso.toMap(),
      ),
    );

    return aviso;
  }

  // ── Confirmação de leitura ─────────────────────────────────────

  /// Marca um aviso recebido como visto e gera notificação de confirmação
  /// para o remetente.
  Future<void> marcarComoVisto(String avisoId) async {
    final recebidos = await getRecebidos();
    final idx = recebidos.indexWhere((a) => a.id == avisoId);
    if (idx < 0) return;

    final atualizado = recebidos[idx].copyWith(
      status: 'visto',
      vistoEm: DateTime.now(),
    );
    recebidos[idx] = atualizado;
    await _salvarRecebidos(recebidos);

    // Atualiza na fila de enviados (se o mesmo device)
    final enviados = await getEnviados();
    final eIdx = enviados.indexWhere((a) => a.id == avisoId);
    if (eIdx >= 0) {
      enviados[eIdx] = atualizado;
      await _salvarEnviados(enviados);
    }

    // Notificação de confirmação para o remetente
    await _notif.agendarNotificacao(
      FitnessNotificationItem(
        id: 'visto_${avisoId}',
        titulo: '✅ ${atualizado.destinatarioNome} viu seu aviso de falta',
        corpo:
            'O aviso para ${_formatarData(atualizado.dataAula)} foi confirmado como visto.',
        dataHora: DateTime.now(),
        tipo: 'aviso_falta_lido',
        payload: atualizado.toMap(),
      ),
    );
  }

  // ── Deleção ────────────────────────────────────────────────────

  Future<void> removerEnviado(String avisoId) async {
    final lista = await getEnviados();
    lista.removeWhere((a) => a.id == avisoId);
    await _salvarEnviados(lista);
  }

  // ── Privados ───────────────────────────────────────────────────

  List<AvisoFaltaModel> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => AvisoFaltaModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _salvarEnviados(List<AvisoFaltaModel> lista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _enviadosKey, jsonEncode(lista.map((a) => a.toMap()).toList()));
  }

  Future<void> _salvarRecebidos(List<AvisoFaltaModel> lista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _recebidosKey, jsonEncode(lista.map((a) => a.toMap()).toList()));
  }

  static String _formatarData(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
