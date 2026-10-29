import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/agenda_evento_model.dart';
import 'package:task_manager_flutter/data/services/fitness_conta_sync.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

class AgendaRepository {
  static const _cacheKeyBase = 'appacademia_agenda_eventos_v2';

  final NetworkCaller _network;
  AgendaRepository({NetworkCaller? network})
      : _network = network ?? NetworkCaller();

  String get _cacheKey => FitnessContaSync.chave(_cacheKeyBase);

  Future<List<AgendaEventoModel>> listar(DateTime inicio, DateTime fim) async {
    try {
      final uri = Uri.parse(ApiLinks.fitnessAgenda).replace(queryParameters: {
        'inicio': _semFuso(inicio),
        'fim': _semFuso(fim),
      });
      final response = await _network.getRequest(uri.toString());
      if (response.isSuccess) {
        final raw = response.body?['data'];
        if (raw is List) {
          final eventos = raw
              .whereType<Map>()
              .map((item) =>
                  AgendaEventoModel.fromMap(Map<String, dynamic>.from(item)))
              .toList();
          await _mesclarCache(eventos);
          return _filtrarPorPeriodo(await _lerCache(), inicio, fim);
        }
      }
    } catch (_) {
      // Segue para fallback do cache offline
    }

    final emCache = await _lerCache();
    return _filtrarPorPeriodo(emCache, inicio, fim);
  }

  Future<List<AgendaEventoModel>> criar(Map<String, dynamic> dados) async {
    try {
      final response = await _network.postRequest(ApiLinks.fitnessAgenda, dados);
      if (response.isSuccess) {
        final raw = response.body?['data'];
        if (raw is List) {
          final eventos = raw
              .whereType<Map>()
              .map((item) =>
                  AgendaEventoModel.fromMap(Map<String, dynamic>.from(item)))
              .toList();
          await _mesclarCache(eventos);
          return eventos;
        }
      }
    } catch (_) {
      // Segue para fallback local
    }

    // Fallback offline: gera evento local garantindo que o usuário não perca seu compromisso
    final novoId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final inicioDt = DateTime.tryParse(dados['inicio']?.toString() ?? '') ?? DateTime.now();
    final fimDt = DateTime.tryParse(dados['fim']?.toString() ?? '') ?? inicioDt.add(const Duration(hours: 1));
    final eventoLocal = AgendaEventoModel(
      id: novoId,
      titulo: dados['titulo']?.toString() ?? 'Novo Evento',
      tipo: dados['tipo']?.toString() ?? 'OUTRO',
      inicio: inicioDt,
      fim: fimDt,
      local: dados['local']?.toString() ?? '',
      observacao: dados['observacao']?.toString() ?? '',
      lembreteMinutos: (dados['lembreteMinutos'] as num?)?.toInt() ?? 60,
      alunoId: dados['alunoId']?.toString(),
      podeEditar: true,
      compartilhado: dados['alunoId'] != null,
    );

    final lista = await _lerCache();
    lista.add(eventoLocal);
    await _salvarCache(lista);
    return [eventoLocal];
  }

  Future<AgendaEventoModel> atualizar(
      String id, Map<String, dynamic> dados) async {
    try {
      final response =
          await _network.putRequest('${ApiLinks.fitnessAgenda}/$id', dados);
      if (response.isSuccess) {
        final evento = AgendaEventoModel.fromMap(
            Map<String, dynamic>.from(response.body?['data'] as Map));
        final lista = await _lerCache();
        final idx = lista.indexWhere((e) => e.id == id);
        if (idx >= 0) {
          lista[idx] = evento;
        } else {
          lista.add(evento);
        }
        await _salvarCache(lista);
        return evento;
      }
    } catch (_) {
      // Segue para fallback local
    }

    final lista = await _lerCache();
    final idx = lista.indexWhere((e) => e.id == id);
    final existente = idx >= 0 ? lista[idx] : null;

    final inicioDt = dados['inicio'] != null
        ? DateTime.tryParse(dados['inicio'].toString()) ?? (existente?.inicio ?? DateTime.now())
        : (existente?.inicio ?? DateTime.now());
    final fimDt = dados['fim'] != null
        ? DateTime.tryParse(dados['fim'].toString()) ?? (existente?.fim ?? inicioDt.add(const Duration(hours: 1)))
        : (existente?.fim ?? inicioDt.add(const Duration(hours: 1)));

    final atualizado = AgendaEventoModel(
      id: id,
      titulo: dados['titulo']?.toString() ?? existente?.titulo ?? '',
      tipo: dados['tipo']?.toString() ?? existente?.tipo ?? 'OUTRO',
      inicio: inicioDt,
      fim: fimDt,
      local: dados['local']?.toString() ?? existente?.local ?? '',
      observacao: dados['observacao']?.toString() ?? existente?.observacao ?? '',
      lembreteMinutos: (dados['lembreteMinutos'] as num?)?.toInt() ?? existente?.lembreteMinutos ?? 60,
      alunoId: dados['alunoId']?.toString() ?? existente?.alunoId,
      podeEditar: true,
      compartilhado: existente?.compartilhado ?? false,
    );

    if (idx >= 0) {
      lista[idx] = atualizado;
    } else {
      lista.add(atualizado);
    }
    await _salvarCache(lista);
    return atualizado;
  }

  /// Cancela com justificativa obrigatoria. Devolve false quando nao houve conexao e o
  /// cancelamento ficou so no aparelho. Rejeicao do servidor (ex.: 403) vira erro visivel.
  Future<bool> cancelar(String id,
      {required String motivo, String quem = 'aluno'}) async {
    final justificativa = motivo.trim();
    var sincronizado = false;
    final resposta = await _network.deleteRequest(
      '${ApiLinks.fitnessAgenda}/$id',
      queryParams: {'motivo': justificativa},
    );
    if (resposta.isSuccess) {
      sincronizado = true;
    } else if (resposta.statusCode > 0) {
      throw StateError('Não foi possível cancelar agora. Tente novamente.');
    }

    final lista = await _lerCache();
    final idx = lista.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      final item = lista[idx];
      lista[idx] = AgendaEventoModel(
        id: item.id,
        serieId: item.serieId,
        titulo: item.titulo,
        tipo: item.tipo,
        inicio: item.inicio,
        fim: item.fim,
        local: item.local,
        observacao: justificativa.isNotEmpty
            ? 'Cancelado pelo $quem: $justificativa'
            : item.observacao,
        status: 'CANCELADO',
        compartilhado: item.compartilhado,
        lembreteMinutos: item.lembreteMinutos,
        alunoId: item.alunoId,
        alunoNome: item.alunoNome,
        personalNome: item.personalNome,
        podeEditar: item.podeEditar,
      );
      await _salvarCache(lista);
    }
    return sincronizado;
  }

  List<AgendaEventoModel> _filtrarPorPeriodo(
      List<AgendaEventoModel> eventos, DateTime inicio, DateTime fim) {
    return eventos
        .where((e) => !e.inicio.isBefore(inicio) && !e.inicio.isAfter(fim))
        .toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
  }

  Future<List<AgendaEventoModel>> _lerCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bruto = prefs.getString(_cacheKey);
      if (bruto == null || bruto.isEmpty) return [];
      final lista = jsonDecode(bruto) as List<dynamic>;
      return lista
          .whereType<Map>()
          .map((m) => AgendaEventoModel.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _salvarCache(List<AgendaEventoModel> eventos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapList = eventos.map((e) => e.toMap()).toList();
      await prefs.setString(_cacheKey, jsonEncode(mapList));
    } catch (_) {}
  }

  Future<void> _mesclarCache(List<AgendaEventoModel> remotos) async {
    final locais = await _lerCache();
    final mapa = <String, AgendaEventoModel>{};
    for (final l in locais) {
      mapa[l.id] = l;
    }
    for (final r in remotos) {
      mapa[r.id] = r;
    }
    await _salvarCache(mapa.values.toList());
  }

  static String _semFuso(DateTime value) =>
      value.toIso8601String().split('.').first;
}

