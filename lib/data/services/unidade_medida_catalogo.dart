import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

/// Unidades de medida do cadastro do backend (tabela unidade_medida).
///
/// Offline-first: busca no backend e guarda o resultado; sem rede, usa o cache.
/// Sem cache nenhum, devolve as unidades de anabolizante para o formulario
/// continuar funcionando.
class UnidadeMedidaCatalogo {
  UnidadeMedidaCatalogo._();

  static const String _chaveCache = 'unidades_medida_cache_v1';
  static const List<String> unidadesPadrao = ['ML', 'UI', 'COMP'];

  static Future<List<String>> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final resposta = await NetworkCaller().getRequest(ApiLinks.unidadesMedida);
      if (resposta.isSuccess) {
        final simbolos = simbolosDaResposta(resposta.body);
        if (simbolos.isNotEmpty) {
          await prefs.setString(_chaveCache, jsonEncode(simbolos));
          return simbolos;
        }
      }
      AppLogger.i.warn(
          '[UnidadeMedida] Resposta sem unidades (status ${resposta.statusCode}); usando cache.');
    } catch (e) {
      AppLogger.i.warn('[UnidadeMedida] Falha ao buscar unidades; usando cache: $e');
    }
    return _lerCache(prefs) ?? unidadesPadrao;
  }

  /// Extrai os simbolos de `{"data": {"dados": [{"simbolo": "ML"}, ...]}}`.
  @visibleForTesting
  static List<String> simbolosDaResposta(dynamic body) {
    final corpo = body is String ? jsonDecode(body) : body;
    final dados = (corpo is Map ? corpo['data'] : null) is Map
        ? (corpo['data'] as Map)['dados']
        : null;
    if (dados is! List) return const [];
    final simbolos = <String>[];
    for (final item in dados) {
      final simbolo = (item is Map ? item['simbolo'] : null)?.toString().trim().toUpperCase();
      if (simbolo != null && simbolo.isNotEmpty && !simbolos.contains(simbolo)) {
        simbolos.add(simbolo);
      }
    }
    return simbolos;
  }

  static List<String>? _lerCache(SharedPreferences prefs) {
    final raw = prefs.getString(_chaveCache);
    if (raw == null) return null;
    try {
      final lista = List<String>.from(jsonDecode(raw) as List);
      return lista.isEmpty ? null : lista;
    } catch (e) {
      AppLogger.i.warn('[UnidadeMedida] Cache de unidades invalido: $e');
      return null;
    }
  }
}
