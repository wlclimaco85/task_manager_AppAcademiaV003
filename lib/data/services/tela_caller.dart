import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import '../models/telas_model.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

class TelaService {
  final NetworkCaller networkCaller;
  late Future<SharedPreferences> _prefs;

  TelaService({required this.networkCaller}) {
    _prefs = SharedPreferences.getInstance();
  }

  // ðŸ” Busca tela por nome diretamente da API
  Future<TelaConfig?> getTelaByNome(String nome, {int? empId, int? clienteId}) async {
    try {
      // Chama /api/telas/{nome} com filtros opcionais
      final url = ApiLinks.getTelaByNome(nome, empId: empId, clienteId: clienteId);
      AppLogger.i
          .info('ðŸŒ [TelaService] Chamando API para obter tela "$nome" â†’ $url');

      final response = await networkCaller.getRequest(url);

      AppLogger.i.info('ðŸ“¡ [TelaService] Resposta recebida: '
          'status=${response.statusCode}, sucesso=${response.isSuccess}');
      AppLogger.i.info('ðŸ§  [TelaService] Corpo bruto: ${response.body}');

      if (response.statusCode == -1) {
        AppLogger.i.info('âš ï¸ [TelaService] NetworkCaller retornou status -1 â†’ '
            'provÃ¡vel erro de conexÃ£o, timeout ou URL invÃ¡lida.');
      }

      if (response.isSuccess && response.body != null) {
        final body = response.body!;
        // O endpoint /{nome} retorna o objeto Tela diretamente
        if (body is Map<String, dynamic>) {
          AppLogger.i.info('âœ… [TelaService] Objeto Tela recebido diretamente.');
          return TelaConfig.fromJson(body);
        }
      } else {
        AppLogger.i.info(
            'âŒ [TelaService] RequisiÃ§Ã£o falhou: status=${response.statusCode}');
      }

      return null;
    } catch (e, stack) {
      AppLogger.i.info('ðŸ’¥ [TelaService] Erro ao buscar tela "$nome": $e');
      AppLogger.i.info('ðŸ“„ StackTrace: $stack');
      return null;
    }
  }

  // ðŸ”§ Buscar preferÃªncias de campos
  Future<List<UserFieldPreference>> getUserPreferences(
      int telaId, int userId) async {
    try {
      final response = await networkCaller.getRequest(
        ApiLinks.getAllpreferencias(telaId.toString(), userId.toString()),
      );

      AppLogger.i.info(
          'âš™ï¸ [TelaService] getUserPreferences resposta: ${response.statusCode}');

      if (response.isSuccess && response.body != null) {
        return (response.body! as List)
            .map((pref) => UserFieldPreference.fromJson(pref))
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.i.info('ðŸ’¥ [TelaService] Erro ao buscar preferÃªncias: $e');
      return [];
    }
  }

  // ðŸ’¾ Salvar preferÃªncias do usuÃ¡rio
  Future<bool> saveUserPreferences(
      int telaId, int userId, Map<String, bool> fieldVisibility) async {
    try {
      final response = await networkCaller.postRequest(
        ApiLinks.getAllpreferencias(telaId.toString(), userId.toString()),
        fieldVisibility,
      );

      AppLogger.i.info(
          'ðŸ’¾ [TelaService] Salvando preferÃªncias â†’ ${response.statusCode}');
      return response.isSuccess;
    } catch (e) {
      AppLogger.i.info('ðŸ’¥ [TelaService] Erro ao salvar preferÃªncias: $e');
      return false;
    }
  }

  // ðŸ§± Salvar tela em cache local
  Future<void> saveTelaToCache(String nome, TelaConfig tela) async {
    final prefs = await _prefs;
    final jsonData = tela.toJson();

    AppLogger.i.info('ðŸ’¾ [TelaService] Salvando tela "$nome" no cache...');
    AppLogger.i.info('ðŸ“¦ JSON salvo: $jsonData');

    await prefs.setString('tela_$nome', json.encode(jsonData));
  }

  // Busca tela atualizada da API; usa cache apenas como fallback offline.
  Future<TelaConfig?> getTelaFromCache(String nome, {int? empId, int? clienteId}) async {
    final fresh = await _getFromApiWithRetry(nome, empId: empId, clienteId: clienteId);
    if (fresh != null) {
      return fresh;
    }

    try {
      final prefs = await _prefs;
      final cached = prefs.getString('tela_$nome');
      if (cached == null || cached.isEmpty) {
        AppLogger.i.info('[TelaService] Nenhum cache encontrado para "$nome".');
        return null;
      }

      AppLogger.i.info('[TelaService] Usando cache como fallback para "$nome".');
      final decoded = json.decode(cached);
      if (decoded is! Map<String, dynamic>) {
        AppLogger.i.info('[TelaService] Cache invalido para "$nome": $decoded');
        return null;
      }

      if (_isCacheValid(decoded)) {
        return TelaConfig.fromJson(decoded);
      }
      return null;
    } catch (e) {
      AppLogger.i.info('[TelaService] Erro ao acessar cache: $e');
      return null;
    }
  }

  bool _isCacheValid(Map<String, dynamic> decoded) {
    return decoded['id'] != null &&
        decoded['id'] > 0 &&
        decoded['nome'] != null &&
        decoded['nome'].toString().isNotEmpty;
  }

  // ðŸ” Tenta buscar a tela atÃ© 3 vezes da API
  Future<TelaConfig?> _getFromApiWithRetry(String nome, {int? empId, int? clienteId}) async {
    const maxTentativas = 3;
    for (int tentativa = 1; tentativa <= maxTentativas; tentativa++) {
      AppLogger.i.info(
          'ðŸ”„ [TelaService] Tentativa $tentativa/$maxTentativas para buscar "$nome"...');

      try {
        final freshTela = await getTelaByNome(nome, empId: empId, clienteId: clienteId);

        if (freshTela != null) {
          AppLogger.i.info(
              'âœ… [TelaService] Tela encontrada na tentativa $tentativa: ${freshTela.nome}');
          await saveTelaToCache(nome, freshTela);
          return freshTela;
        } else {
          AppLogger.i.info(
              'âš ï¸ [TelaService] Tentativa $tentativa falhou (retornou null).');
          if (tentativa < maxTentativas) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      } catch (e) {
        AppLogger.i.info('ðŸ’¥ [TelaService] Erro na tentativa $tentativa: $e');
        if (tentativa < maxTentativas) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    AppLogger.i
        .info('ðŸ’€ [TelaService] Todas as tentativas falharam para "$nome".');
    return null;
  }
}
