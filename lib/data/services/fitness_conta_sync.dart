import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/tenant_context.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

class FitnessContaSync {
  static final Set<String> _emAndamento = {};
  static bool get autenticado => AuthUtility.userInfo.login?.id != null &&
      (AuthUtility.userInfo.token?.isNotEmpty ?? false);
  static String chave(String base) => autenticado
      ? '${base}_conta_${AuthUtility.userInfo.login!.id}' : base;
  static String get _url => ApiLinks.fitnessResumo.replaceFirst('/resumo', '/documentos');

  static Future<void> salvar(String tipo, Map<String, dynamic> documento) async {
    if (!autenticado) return;
    final prefs = await SharedPreferences.getInstance();
    final chaveFila = chave('fitness_pendentes_$tipo');
    final fila = Map<String, dynamic>.from(jsonDecode(prefs.getString(chaveFila) ?? '{}'));
    fila[documento['id']] = documento;
    await prefs.setString(chaveFila, jsonEncode(fila));
    await carregar(tipo);
  }

  static Future<List<Map<String, dynamic>>?> carregar(String tipo) async {
    if (!autenticado) return null;
    final contaId = AuthUtility.userInfo.login!.id;
    final prefs = await SharedPreferences.getInstance();
    final chaveFila = chave('fitness_pendentes_$tipo');
    if (_emAndamento.contains(chaveFila)) return null;
    final headers = Map<String, String>.from(TenantContext.headers);
    final fila = Map<String, dynamic>.from(jsonDecode(prefs.getString(chaveFila) ?? '{}'));
    final enviados = Map<String, dynamic>.from(fila);
    _emAndamento.add(chaveFila);
    try {
      for (final id in fila.keys.toList()) {
        final response = await http.put(Uri.parse('$_url/$tipo/$id'),
          headers: {...headers, 'Content-Type': 'application/json'}, body: jsonEncode(fila[id]))
          .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) { fila.remove(id); }
        else AppLogger.i.warn('Gravação fitness pendente: $tipo HTTP ${response.statusCode}');
      }
      final atuais = Map<String, dynamic>.from(jsonDecode(prefs.getString(chaveFila) ?? '{}'));
      for (final id in enviados.keys) {
        if (!fila.containsKey(id) && jsonEncode(atuais[id]) == jsonEncode(enviados[id])) {
          atuais.remove(id);
        }
      }
      fila..clear()..addAll(atuais);
      await prefs.setString(chaveFila, jsonEncode(fila));
      final response = await http.get(Uri.parse('$_url/$tipo'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        AppLogger.i.warn('Leitura fitness falhou: $tipo HTTP ${response.statusCode}');
        return null;
      }
      final remotos = (jsonDecode(response.body)['data'] as List)
          .map((e) => Map<String, dynamic>.from(e)).toList();
      final porId = {for (final e in remotos) e['id']: e};
      for (final e in fila.values) { porId[e['id']] = Map<String, dynamic>.from(e); }
      if (tipo == 'sessoes') {
        for (final e in porId.values) { e['sincronizado'] = !fila.containsKey(e['id']); }
      }
      if (AuthUtility.userInfo.login?.id != contaId) return null;
      return porId.values.toList();
    } catch (error, stack) {
      AppLogger.i.error('Dados fitness permanecem locais; sincronização indisponível.', stack);
      return null;
    } finally {
      _emAndamento.remove(chaveFila);
    }
  }
}
