import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

/// Catalogo de metas sugeridas (titulos) cadastrado no servidor.
class MetaCatalogoService {
  MetaCatalogoService._();

  /// Titulos das metas do catalogo. Lista vazia se a rede falhar (o campo de texto continua disponivel).
  static Future<List<String>> listarTitulos() async {
    try {
      final resposta = await NetworkCaller().getRequest(ApiLinks.fitnessMetasCatalogo);
      if (!resposta.isSuccess) {
        AppLogger.i.warn('[MetaCatalogo] Leitura falhou: HTTP ${resposta.statusCode}');
        return const [];
      }
      final data = resposta.body?['data'];
      if (data is! List) return const [];
      return [for (final t in data) if (t is String && t.trim().isNotEmpty) t];
    } catch (e, stack) {
      AppLogger.i.error('[MetaCatalogo] Falha ao listar metas: $e', stack);
      return const [];
    }
  }
}
