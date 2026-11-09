import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

/// Cadastro da academia feito pelo dono. Erros do servidor viram [Exception] com a mensagem do backend.
class AcademiaCadastroService {
  AcademiaCadastroService._();

  static Future<Map<String, dynamic>> obter() async {
    final dados = await _leitura(ApiLinks.fitnessAcademiaCadastro, 'carregar o cadastro');
    return dados is Map ? Map<String, dynamic>.from(dados) : <String, dynamic>{'cadastrada': false};
  }

  static Future<void> salvarDados(Map<String, dynamic> dados) async {
    final r = await NetworkCaller().putRequest(ApiLinks.fitnessAcademiaCadastroDados, dados);
    _verificar(r, 'salvar os dados da academia');
  }

  static Future<void> salvarHorarios(List<Map<String, dynamic>> horarios) async {
    final r = await NetworkCaller().putRequest(ApiLinks.fitnessAcademiaCadastroHorarios, {'horarios': horarios});
    _verificar(r, 'salvar os horários');
  }

  static Future<void> criarPlano(Map<String, dynamic> plano) async {
    final r = await NetworkCaller().postRequest(ApiLinks.fitnessAcademiaCadastroPlanos, plano);
    _verificar(r, 'criar o plano');
  }

  static Future<void> atualizarPlano(int id, Map<String, dynamic> plano) async {
    final r = await NetworkCaller().putRequest(ApiLinks.fitnessAcademiaCadastroPlano(id), plano);
    _verificar(r, 'atualizar o plano');
  }

  static Future<void> excluirPlano(int id) async {
    final r = await NetworkCaller().deleteRequest(ApiLinks.fitnessAcademiaCadastroPlano(id));
    _verificar(r, 'excluir o plano');
  }

  static Future<List<Map<String, dynamic>>> buscarPersonais(String termo) async {
    final dados = await _leitura(
      '${ApiLinks.fitnessAcademiaCadastroPersonaisBusca}?q=${Uri.encodeQueryComponent(termo)}',
      'buscar personais',
    );
    return _lista(dados);
  }

  static Future<void> vincularPersonal(int personalId) async {
    final r = await NetworkCaller().postRequest(ApiLinks.fitnessAcademiaCadastroPersonal(personalId), null);
    _verificar(r, 'vincular o personal');
  }

  static Future<void> desvincularPersonal(int personalId) async {
    final r = await NetworkCaller().deleteRequest(ApiLinks.fitnessAcademiaCadastroPersonal(personalId));
    _verificar(r, 'remover o personal');
  }

  static Future<dynamic> _leitura(String url, String acao) async {
    try {
      final r = await NetworkCaller().getRequest(url);
      _verificar(r, acao);
      return r.body?['data'];
    } catch (e, stack) {
      AppLogger.i.error('[AcademiaCadastro] Falha ao $acao: $e', stack);
      rethrow;
    }
  }

  static void _verificar(NetworkResponse r, String acao) {
    if (r.isSuccess) return;
    final mensagem = r.body?['message']?.toString();
    AppLogger.i.warn('[AcademiaCadastro] Falha ao $acao: HTTP ${r.statusCode}');
    throw Exception(mensagem ?? 'Não foi possível $acao (HTTP ${r.statusCode}).');
  }

  static List<Map<String, dynamic>> _lista(dynamic dados) {
    if (dados is! List) return const [];
    return [for (final item in dados) if (item is Map) Map<String, dynamic>.from(item)];
  }
}
