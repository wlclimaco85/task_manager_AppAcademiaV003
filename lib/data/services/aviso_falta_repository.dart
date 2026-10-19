import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/aviso_falta_model.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/fitness_conta_sync.dart';
import 'package:task_manager_flutter/data/services/fitness_push_notification_service.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/fitness_access.dart';

class AvisoFaltaCaixa {
  final bool vinculado;
  final List<AvisoFaltaModel> recebidos;
  final List<AvisoFaltaModel> enviados;

  const AvisoFaltaCaixa({
    required this.vinculado,
    required this.recebidos,
    required this.enviados,
  });
}

/// Repositório servidor-first. O cache permite leitura offline, mas nunca
/// simula que um aviso foi entregue à outra conta.
class AvisoFaltaRepository {
  static const _cacheKeyBase = 'appacademia_avisos_falta_caixa_v2';
  static const _vinculoKeyBase = 'appacademia_avisos_falta_vinculo_v2';

  final NetworkCaller _network;
  final FitnessPushNotificationService _notif;

  AvisoFaltaRepository({
    NetworkCaller? network,
    FitnessPushNotificationService? notificacoes,
  })  : _network = network ?? NetworkCaller(),
        _notif = notificacoes ?? FitnessPushNotificationService();

  bool get _souPersonal => podeGerenciarAlunos();
  String get _cacheKey => FitnessContaSync.chave(_cacheKeyBase);
  String get _vinculoKey => FitnessContaSync.chave(_vinculoKeyBase);

  Future<AvisoFaltaCaixa> carregar({bool aceitarCache = true}) async {
    final response =
        await _network.getRequest(ApiLinks.avisosFaltaMeus(_souPersonal));
    if (response.isSuccess) {
      final data = response.body?['data'];
      if (data is Map) {
        final caixa = AvisoFaltaCaixa(
          vinculado: data['vinculado'] == true,
          recebidos: _lista(data['recebidos']),
          enviados: _lista(data['enviados']),
        );
        await _notificarNovosRecebidos(caixa.recebidos);
        await _salvarCache(caixa);
        return caixa;
      }
    }
    if (aceitarCache) return _lerCache();
    throw StateError(
        _mensagemErro(response, 'Não foi possível consultar os avisos.'));
  }

  Future<bool> temVinculo() async {
    try {
      return (await carregar()).vinculado;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_vinculoKey) ?? false;
    }
  }

  Future<List<AvisoFaltaModel>> getEnviados() async =>
      (await carregar()).enviados;

  Future<List<AvisoFaltaModel>> getRecebidos() async =>
      (await carregar()).recebidos;

  Future<int> countNaoVistos() async =>
      (await getRecebidos()).where((item) => !item.foiVisto).length;

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
    final response = await _network.postRequest(
      _souPersonal ? ApiLinks.avisosFaltaPersonal : ApiLinks.avisosFaltaAluno,
      {'dataAula': dataAula, 'horario': horario, 'motivo': motivo},
    );
    if (!response.isSuccess) {
      throw StateError(
          _mensagemErro(response, 'Não foi possível enviar o aviso.'));
    }
    final data = response.body?['data'];
    final criados = data is List
        ? _lista(data)
        : data is Map
            ? [AvisoFaltaModel.fromMap(Map<String, dynamic>.from(data))]
            : <AvisoFaltaModel>[];
    if (criados.isEmpty) {
      throw StateError('O servidor não confirmou o envio.');
    }
    await carregar(aceitarCache: false);
    return criados.first;
  }

  Future<void> marcarComoVisto(String avisoId) async {
    final response = await _network.putRequest(
      ApiLinks.avisoFaltaVisto(_souPersonal, avisoId),
      const <String, dynamic>{},
    );
    if (!response.isSuccess) {
      throw StateError(
          _mensagemErro(response, 'Não foi possível confirmar a leitura.'));
    }
    await carregar(aceitarCache: false);
  }

  Future<void> removerEnviado(String avisoId) async {
    final response = await _network.deleteRequest(
      ApiLinks.avisoFaltaRemover(_souPersonal, avisoId),
    );
    if (!response.isSuccess) {
      throw StateError(
          _mensagemErro(response, 'Não foi possível remover o aviso.'));
    }
    await carregar(aceitarCache: false);
  }

  List<AvisoFaltaModel> _lista(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => AvisoFaltaModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> _notificarNovosRecebidos(List<AvisoFaltaModel> atuais) async {
    final anterior = await _lerCache();
    final idsAnteriores = anterior.recebidos.map((item) => item.id).toSet();
    for (final aviso in atuais
        .where((item) => !item.foiVisto && !idsAnteriores.contains(item.id))) {
      final alunoAvisou = aviso.remetenteTipo == 'aluno';
      await _notif.agendarNotificacao(FitnessNotificationItem(
        id: 'aviso_falta_${aviso.id}',
        titulo: alunoAvisou
            ? '${aviso.remetenteNome} avisou que vai faltar'
            : '${aviso.remetenteNome} cancelou uma aula',
        corpo:
            '${_formatarData(aviso.dataAula)}${aviso.horario == null ? '' : ' às ${aviso.horario}'}${aviso.motivo.isEmpty ? '' : ' • ${aviso.motivo}'}',
        dataHora: aviso.enviadoEm,
        tipo: alunoAvisou ? 'falta_aluno' : 'falta_personal',
        payload: aviso.toMap(),
      ));
    }
  }

  Future<void> _salvarCache(AvisoFaltaCaixa caixa) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vinculoKey, caixa.vinculado);
    await prefs.setString(
        _cacheKey,
        jsonEncode({
          'vinculado': caixa.vinculado,
          'recebidos': caixa.recebidos.map((item) => item.toMap()).toList(),
          'enviados': caixa.enviados.map((item) => item.toMap()).toList(),
        }));
  }

  Future<AvisoFaltaCaixa> _lerCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) {
      return AvisoFaltaCaixa(
        vinculado: prefs.getBool(_vinculoKey) ?? _souPersonal,
        recebidos: const [],
        enviados: const [],
      );
    }
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return AvisoFaltaCaixa(
        vinculado: data['vinculado'] == true,
        recebidos: _lista(data['recebidos']),
        enviados: _lista(data['enviados']),
      );
    } catch (_) {
      return const AvisoFaltaCaixa(
          vinculado: false, recebidos: [], enviados: []);
    }
  }

  String _mensagemErro(NetworkResponse response, String padrao) {
    final mensagem = response.body?['message'] ?? response.body?['error'];
    return mensagem is String && mensagem.trim().isNotEmpty ? mensagem : padrao;
  }

  static String _formatarData(String iso) {
    final data = DateTime.tryParse(iso);
    if (data == null) return iso;
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}
