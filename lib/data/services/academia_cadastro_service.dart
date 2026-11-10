import 'package:flutter/foundation.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

/// Cadastro da academia feito pelo dono. Erros do servidor viram [FalhaCadastroAcademia] com a mensagem
/// do backend. Falhas de rede (sem conexao, timeout) sao registradas e viram mensagem em portugues.
class AcademiaCadastroService {
  AcademiaCadastroService._();

  /// Fabrica do cliente HTTP. Trocavel apenas em testes (widget test sem rede).
  @visibleForTesting
  static NetworkCaller Function() fabricaRede = () => NetworkCaller();

  static Future<Map<String, dynamic>> obter() async {
    final r = await _executar(() => fabricaRede().getRequest(ApiLinks.fitnessAcademiaCadastro), 'carregar o cadastro');
    final dados = r.body?['data'];
    return dados is Map ? Map<String, dynamic>.from(dados) : <String, dynamic>{'cadastrada': false};
  }

  static Future<void> salvarDados(Map<String, dynamic> dados) => _executar(
      () => fabricaRede().putRequest(ApiLinks.fitnessAcademiaCadastroDados, dados), 'salvar os dados da academia');

  static Future<void> salvarHorarios(List<Map<String, dynamic>> horarios) => _executar(
      () => fabricaRede().putRequest(ApiLinks.fitnessAcademiaCadastroHorarios, {'horarios': horarios}),
      'salvar os horários');

  static Future<void> criarPlano(Map<String, dynamic> plano) =>
      _executar(() => fabricaRede().postRequest(ApiLinks.fitnessAcademiaCadastroPlanos, plano), 'criar o plano');

  static Future<void> atualizarPlano(int id, Map<String, dynamic> plano) =>
      _executar(() => fabricaRede().putRequest(ApiLinks.fitnessAcademiaCadastroPlano(id), plano), 'atualizar o plano');

  static Future<void> excluirPlano(int id) =>
      _executar(() => fabricaRede().deleteRequest(ApiLinks.fitnessAcademiaCadastroPlano(id)), 'excluir o plano');

  static Future<List<Map<String, dynamic>>> buscarPersonais(String termo) async {
    final r = await _executar(
      () => fabricaRede().getRequest(
          '${ApiLinks.fitnessAcademiaCadastroPersonaisBusca}?q=${Uri.encodeQueryComponent(termo)}'),
      'buscar personais',
    );
    return _lista(r.body?['data']);
  }

  static Future<void> vincularPersonal(int personalId) => _executar(
      () => fabricaRede().postRequest(ApiLinks.fitnessAcademiaCadastroPersonal(personalId), null),
      'vincular o personal');

  static Future<void> desvincularPersonal(int personalId) => _executar(
      () => fabricaRede().deleteRequest(ApiLinks.fitnessAcademiaCadastroPersonal(personalId)),
      'remover o personal');

  /// Executa a chamada, valida a resposta e traduz falhas. Erro do servidor propaga como esta;
  /// excecao de rede vira mensagem em portugues, com o log registrado.
  static Future<NetworkResponse> _executar(Future<NetworkResponse> Function() chamada, String acao) async {
    try {
      final r = await chamada();
      if (r.isSuccess) return r;
      final mensagem = r.body?['message']?.toString();
      AppLogger.i.warn('[AcademiaCadastro] Falha ao $acao: HTTP ${r.statusCode}');
      throw FalhaCadastroAcademia(mensagem ?? 'Não foi possível $acao (HTTP ${r.statusCode}).');
    } on FalhaCadastroAcademia {
      rethrow;
    } catch (e, stack) {
      AppLogger.i.error('[AcademiaCadastro] Falha ao $acao: $e', stack);
      throw FalhaCadastroAcademia('Sem conexão com o servidor. Tente $acao novamente.');
    }
  }

  static List<Map<String, dynamic>> _lista(dynamic dados) {
    if (dados is! List) return const [];
    return [for (final item in dados) if (item is Map) Map<String, dynamic>.from(item)];
  }
}

/// Falha de negocio ou do servidor com mensagem pronta para mostrar ao dono.
class FalhaCadastroAcademia implements Exception {
  const FalhaCadastroAcademia(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}
