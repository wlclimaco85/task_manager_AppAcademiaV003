import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/fitness/exercicio_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';
import 'package:task_manager_flutter/data/utils/tenant_context.dart';

/// Personalizações de exercícios por conta.
///
/// Ordem de prevalência, da mais geral para a mais específica: catálogo geral,
/// edição do personal vinculado, edição da própria conta. Exercícios criados
/// pelo personal aparecem para ele e para os alunos vinculados; exercícios criados
/// por quem não tem personal aparecem só para essa conta.
class ExercicioContaSync {
  static bool _ehPersonalizado(Map<String, dynamic> item) =>
      (item['dados'] as Map)['isCustom'] == true || item['origem'] == 'CUSTOM';

  /// Substituiveis em teste (cliente HTTP e estado de login).
  @visibleForTesting
  static http.Client cliente = http.Client();
  @visibleForTesting
  static bool? autenticadoForcado;

  static bool get autenticado =>
      autenticadoForcado ??
      (AuthUtility.userInfo.login?.id != null &&
          (AuthUtility.userInfo.token?.isNotEmpty ?? false));

  /// Envia uma personalização ao servidor. A cópia local já foi gravada pelo
  /// repositório; falhas viram aviso no log e não interrompem a tela.
  static Future<bool> salvar(Map<String, dynamic> exercicio, String origem) async {
    if (!autenticado) return false;
    final id = exercicio['id'].toString();
    final corpo = {...exercicio, 'id': id, 'origem': origem};
    try {
      final headers = {...TenantContext.headers, 'Content-Type': 'application/json'};
      final resposta = await cliente
          .put(Uri.parse('${ApiLinks.exerciciosUsuario}/$id'), headers: headers, body: jsonEncode(corpo))
          .timeout(const Duration(seconds: 10));
      if (resposta.statusCode == 200) return true;
      AppLogger.i.warn('Exercício não sincronizado: HTTP ${resposta.statusCode}');
    } catch (e, stack) {
      AppLogger.i.error('Exercício salvo só neste aparelho: $e', stack);
    }
    return false;
  }

  /// Remove a personalizacao da conta no servidor (volta ao cadastro geral).
  static Future<bool> excluir(String id) async {
    if (!autenticado) return false;
    try {
      final headers = Map<String, String>.from(TenantContext.headers);
      final resposta = await cliente
          .delete(Uri.parse('${ApiLinks.exerciciosUsuario}/$id'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (resposta.statusCode == 200) return true;
      AppLogger.i.warn('Exercício não restaurado no servidor: HTTP ${resposta.statusCode}');
    } catch (e, stack) {
      AppLogger.i.error('Restauração do exercício sem confirmação do servidor: $e', stack);
    }
    return false;
  }

  /// Personalizações do servidor: `meus` (da conta) e `doPersonal` (do personal
  /// vinculado). Retorna null quando o servidor não responde.
  static Future<Map<String, List<Map<String, dynamic>>>?> carregar() async {
    if (!autenticado) return null;
    try {
      final resposta = await cliente
          .get(Uri.parse(ApiLinks.exerciciosUsuario), headers: TenantContext.headers)
          .timeout(const Duration(seconds: 10));
      if (resposta.statusCode != 200) {
        AppLogger.i.warn('Leitura de exercícios personalizados falhou: HTTP ${resposta.statusCode}');
        return null;
      }
      final corpo = jsonDecode(resposta.body) as Map<String, dynamic>;
      List<Map<String, dynamic>> lista(String chave) => (corpo[chave] as List? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      return {'meus': lista('meus'), 'doPersonal': lista('doPersonal')};
    } catch (e, stack) {
      AppLogger.i.error('Exercícios personalizados indisponíveis; usando cópia local.', stack);
      return null;
    }
  }

  /// Aplica as personalizações em ordem sobre o catálogo. Cada item tem
  /// `exercicioId`, `origem` (BASE ou CUSTOM) e `dados` (exercício completo).
  static List<ExercicioModel> aplicar(
    List<ExercicioModel> catalogo,
    List<Map<String, dynamic>> personalizacoes,
  ) {
    var lista = List<ExercicioModel>.from(catalogo);
    for (final item in personalizacoes) {
      final id = item['exercicioId']?.toString() ?? '';
      if (id.isEmpty || item['dados'] is! Map) continue;
      final dados = Map<String, dynamic>.from(item['dados'] as Map)
        ..['id'] = id
        ..['isCustom'] = _ehPersonalizado(item);
      final exercicio = ExercicioModel.fromMap(dados);
      final indice = lista.indexWhere((e) => e.id == id);
      if (indice >= 0) {
        lista[indice] = exercicio;
      } else {
        lista.insert(0, exercicio);
      }
    }
    return lista;
  }
}
