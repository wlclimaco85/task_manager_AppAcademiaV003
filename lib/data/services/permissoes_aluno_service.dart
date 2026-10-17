import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

/// Estado das permissoes que o aluno concede ao personal que o vinculou.
class PermissoesAluno {
  final bool pendente;
  final Map<String, bool> permissoes;

  const PermissoesAluno({required this.pendente, required this.permissoes});
}

/// Le e responde as permissoes do aluno logado no backend (vale em todos os aparelhos).
class PermissoesAlunoService {
  PermissoesAlunoService._();

  /// Areas que o aluno libera ao personal. "treino" e sempre liberado e nao aparece como escolha.
  static const List<String> areasOpcionais = ['dieta', 'suplementacao', 'avaliacoes', 'metas'];

  /// Devolve null quando a rede falha ou o aluno nao tem vinculo: o popup nao aparece.
  static Future<PermissoesAluno?> meu() async {
    try {
      final resposta = await NetworkCaller().getRequest(ApiLinks.permissoesMeu);
      if (!resposta.isSuccess) return null;
      final body = resposta.body;
      final data = body?['data'];
      if (data is! Map) return null;
      final brutas = data['permissoes'];
      final Map<dynamic, dynamic> mapaBruto = brutas is Map ? brutas : const {};
      final permissoes = <String, bool>{'treino': true};
      for (final area in areasOpcionais) {
        final valor = mapaBruto[area];
        permissoes[area] = valor == true;
      }
      return PermissoesAluno(
        pendente: data['pendente'] == true,
        permissoes: permissoes,
      );
    } catch (e) {
      AppLogger.i.warn('[PermissoesAluno] Falha ao consultar permissoes: $e');
      return null;
    }
  }

  /// Permissoes de um aluno vinculado, lidas pelo personal. Em falha ou sem resposta
  /// devolve o padrao restritivo (so treino): na duvida, bloqueia.
  static Future<Map<String, bool>> doAluno(String alunoId) async {
    final padrao = <String, bool>{'treino': true, for (final a in areasOpcionais) a: false};
    try {
      final resposta = await NetworkCaller().getRequest(ApiLinks.permissoesDoAluno(alunoId));
      if (!resposta.isSuccess) return padrao;
      final data = resposta.body?['data'];
      final brutas = data is Map ? data['permissoes'] : null;
      if (brutas is! Map) return padrao;
      return <String, bool>{
        'treino': true,
        for (final area in areasOpcionais) area: brutas[area] == true,
      };
    } catch (e) {
      AppLogger.i.warn('[PermissoesAluno] Falha ao ler permissoes do aluno $alunoId: $e');
      return padrao;
    }
  }

  /// Grava a escolha do aluno. Devolve true somente com resposta de sucesso.
  static Future<bool> responder(Map<String, bool> escolhas) async {
    try {
      final corpo = {for (final area in areasOpcionais) area: escolhas[area] == true};
      final resposta = await NetworkCaller().putRequest(ApiLinks.permissoesMeu, corpo);
      if (!resposta.isSuccess) {
        AppLogger.i.warn('[PermissoesAluno] Resposta recusada (status ${resposta.statusCode}).');
      }
      return resposta.isSuccess;
    } catch (e) {
      AppLogger.i.warn('[PermissoesAluno] Erro ao gravar permissoes: $e');
      return false;
    }
  }
}
