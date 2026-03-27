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

  // 🔍 Busca tela por nome diretamente da API
  Future<TelaConfig?> getTelaByNome(String nome, {int? empId, int? clienteId}) async {
    try {
      // Chama /api/telas/{nome} com filtros opcionais
      final url = ApiLinks.getTelaByNome(nome, empId: empId, clienteId: clienteId);
      AppLogger.i
          .info('🌐 [TelaService] Chamando API para obter tela "$nome" → $url');

      final response = await networkCaller.getRequest(url);

      AppLogger.i.info('📡 [TelaService] Resposta recebida: '
          'status=${response.statusCode}, sucesso=${response.isSuccess}');
      AppLogger.i.info('🧠 [TelaService] Corpo bruto: ${response.body}');

      if (response.statusCode == -1) {
        AppLogger.i.info('⚠️ [TelaService] NetworkCaller retornou status -1 → '
            'provável erro de conexão, timeout ou URL inválida.');
      }

      if (response.isSuccess && response.body != null) {
        final body = response.body!;
        // O endpoint /{nome} retorna o objeto Tela diretamente
        if (body is Map<String, dynamic>) {
          AppLogger.i.info('✅ [TelaService] Objeto Tela recebido diretamente.');
          return TelaConfig.fromJson(body);
        }
      } else {
        AppLogger.i.info(
            '❌ [TelaService] Requisição falhou: status=${response.statusCode}');
      }

      return null;
    } catch (e, stack) {
      AppLogger.i.info('💥 [TelaService] Erro ao buscar tela "$nome": $e');
      AppLogger.i.info('📄 StackTrace: $stack');
      return null;
    }
  }

  // 🔧 Buscar preferências de campos
  Future<List<UserFieldPreference>> getUserPreferences(
      int telaId, int userId) async {
    try {
      final response = await networkCaller.getRequest(
        ApiLinks.getAllpreferencias(telaId.toString(), userId.toString()),
      );

      AppLogger.i.info(
          '⚙️ [TelaService] getUserPreferences resposta: ${response.statusCode}');

      if (response.isSuccess && response.body != null) {
        return (response.body! as List)
            .map((pref) => UserFieldPreference.fromJson(pref))
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.i.info('💥 [TelaService] Erro ao buscar preferências: $e');
      return [];
    }
  }

  // 💾 Salvar preferências do usuário
  Future<bool> saveUserPreferences(
      int telaId, int userId, Map<String, bool> fieldVisibility) async {
    try {
      final response = await networkCaller.postRequest(
        ApiLinks.getAllpreferencias(telaId.toString(), userId.toString()),
        fieldVisibility,
      );

      AppLogger.i.info(
          '💾 [TelaService] Salvando preferências → ${response.statusCode}');
      return response.isSuccess;
    } catch (e) {
      AppLogger.i.info('💥 [TelaService] Erro ao salvar preferências: $e');
      return false;
    }
  }

  // 🧱 Salvar tela em cache local
  Future<void> saveTelaToCache(String nome, TelaConfig tela) async {
    final prefs = await _prefs;
    final jsonData = tela.toJson();

    AppLogger.i.info('💾 [TelaService] Salvando tela "$nome" no cache...');
    AppLogger.i.info('📦 JSON salvo: $jsonData');

    await prefs.setString('tela_$nome', json.encode(jsonData));
  }

  // 🔍 Buscar tela do cache ou API se necessário
  Future<TelaConfig?> getTelaFromCache(String nome, {int? empId, int? clienteId}) async {
    try {
      final prefs = await _prefs;
      final cached = prefs.getString('tela_$nome');

      if (cached == null || cached.isEmpty) {
        AppLogger.i.info(
            '❌ [TelaService] Nenhum cache encontrado para "$nome". Indo para API.');
        return await _getFromApiWithRetry(nome, empId: empId, clienteId: clienteId);
      }

      AppLogger.i.info('✅ [TelaService] Cache encontrado para "$nome".');
      final decoded = json.decode(cached);

      if (decoded is! Map<String, dynamic>) {
        AppLogger.i
            .info('⚠️ [TelaService] Cache inválido (não é Map): $decoded');
        return await _getFromApiWithRetry(nome, empId: empId, clienteId: clienteId);
      }

      if (_isCacheValid(decoded)) {
        AppLogger.i
            .info('🧩 [TelaService] Cache válido. Reconstruindo TelaConfig...');
        final tela = TelaConfig.fromJson(decoded);
        AppLogger.i.info(
            '✅ [TelaService] Tela reconstruída: ID=${tela.id}, Nome=${tela.nome}');
        return tela;
      } else {
        AppLogger.i.info(
            '⚠️ [TelaService] Cache inválido (ID ou Nome nulos). Atualizando...');
        return await _getFromApiWithRetry(nome, empId: empId, clienteId: clienteId);
      }
    } catch (e) {
      AppLogger.i.info('💥 [TelaService] Erro ao acessar cache: $e');
      return await _getFromApiWithRetry(nome, empId: empId, clienteId: clienteId);
    }
  }

  bool _isCacheValid(Map<String, dynamic> decoded) {
    return decoded['id'] != null &&
        decoded['id'] > 0 &&
        decoded['nome'] != null &&
        decoded['nome'].toString().isNotEmpty;
  }

  // 🔁 Tenta buscar a tela até 3 vezes da API
  Future<TelaConfig?> _getFromApiWithRetry(String nome, {int? empId, int? clienteId}) async {
    const maxTentativas = 3;
    for (int tentativa = 1; tentativa <= maxTentativas; tentativa++) {
      AppLogger.i.info(
          '🔄 [TelaService] Tentativa $tentativa/$maxTentativas para buscar "$nome"...');

      try {
        final freshTela = await getTelaByNome(nome, empId: empId, clienteId: clienteId);

        if (freshTela != null) {
          AppLogger.i.info(
              '✅ [TelaService] Tela encontrada na tentativa $tentativa: ${freshTela.nome}');
          await saveTelaToCache(nome, freshTela);
          return freshTela;
        } else {
          AppLogger.i.info(
              '⚠️ [TelaService] Tentativa $tentativa falhou (retornou null).');
          if (tentativa < maxTentativas) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      } catch (e) {
        AppLogger.i.info('💥 [TelaService] Erro na tentativa $tentativa: $e');
        if (tentativa < maxTentativas) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    AppLogger.i
        .info('💀 [TelaService] Todas as tentativas falharam para "$nome".');
    return null;
  }
}
