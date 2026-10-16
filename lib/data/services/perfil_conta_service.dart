import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_utility.dart';
import '../models/login_model.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class PerfilContaService {
  static String get _url =>
      ApiLinks.fitnessResumo.replaceFirst('/resumo', '/perfil-conta');
  Future<Map<String, dynamic>> carregar() => _requisitar();
  Future<Map<String, dynamic>> salvar(Map<String, dynamic> dados) =>
      _requisitar(dados);
  Future<Map<String, dynamic>> _requisitar([
    Map<String, dynamic>? dados,
  ]) async {
    final sessao = AuthUtility.userInfo;
    final id = sessao.login?.id;
    final token = sessao.token;
    if (id == null || token == null || token.isEmpty)
      throw StateError('Entre novamente para editar seu perfil.');
    final headers = Map<String, String>.from(TenantContext.jsonHeaders);
    final resposta = await (dados == null
            ? http.get(Uri.parse(_url), headers: headers)
            : http.put(
                Uri.parse(_url),
                headers: headers,
                body: jsonEncode(dados),
              ))
        .timeout(const Duration(seconds: 25));
    if (AuthUtility.userInfo.login?.id != id ||
        AuthUtility.userInfo.token != token) {
      throw StateError('A conta mudou. Abra seu perfil novamente.');
    }
    if (resposta.statusCode != 200) {
      throw StateError(
        resposta.statusCode == 401 || resposta.statusCode == 403
            ? 'Sua sessão expirou. Entre novamente.'
            : 'Não foi possível ${dados == null ? "carregar" : "salvar"} seu perfil. Tente novamente.',
      );
    }
    final json =
        jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
    final perfil = Map<String, dynamic>.from(
      json['data'] is Map ? json['data'] : json,
    );
    final esperada = AuthUtility.userInfo;
    final atualizada = LoginModel.fromJson(esperada.toJson());
    atualizada.perfilConta = perfil;
    if (perfil['nome'] is String) atualizada.login?.nome = perfil['nome'];
    await AuthUtility.setUserInfo(atualizada, sessaoEsperada: esperada);
    return perfil;
  }
}
