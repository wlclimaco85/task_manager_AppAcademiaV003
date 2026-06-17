import 'package:task_manager_flutter/data/models/auth_utility.dart';

class TenantContext {
  static dynamic get login {
    final info = AuthUtility.userInfo;
    return info.login ?? info.data?.login;
  }

  static int? get empresaId => login?.empresa?.id;
  static int? get parceiroId => login?.parceiro?.id;
  static int? get aplicativoId => login?.aplicativo?.id;
  static int? get userLogadoId => login?.id ?? AuthUtility.userInfo.data?.id;

  static Map<String, String> get headers {
    final token = AuthUtility.userInfo.token;
    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (empresaId != null) 'X-Tenant-ID': empresaId.toString(),
      'Accept-Encoding': 'gzip',
    };
  }

  static Map<String, String> get jsonHeaders => {
        ...headers,
        'Content-Type': 'application/json;charset=UTF-8',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Credentials': 'true',
        'Access-Control-Allow-Methods':
            'GET, POST, PUT, PATCH, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
      };

  static String applyToUrl(String url) {
    final uri = Uri.parse(url);
    final query = Map<String, String>.from(uri.queryParameters);

    void putIfAbsentValue(String key, int? value) {
      if (value != null && !query.containsKey(key)) {
        query[key] = value.toString();
      }
    }

    putIfAbsentValue('empresa', empresaId);
    putIfAbsentValue('parceiro', parceiroId);
    putIfAbsentValue('aplicativo', aplicativoId);
    putIfAbsentValue('empresaId', empresaId);
    putIfAbsentValue('parceiroId', parceiroId);
    putIfAbsentValue('appId', aplicativoId);
    putIfAbsentValue('userLogadoId', userLogadoId);
    putIfAbsentValue('audit.empresaId', empresaId);
    putIfAbsentValue('audit.parceiroId', parceiroId);
    putIfAbsentValue('audit.appId', aplicativoId);
    putIfAbsentValue('audit.userLogadoId', userLogadoId);

    return uri.replace(queryParameters: query).toString();
  }

  static Map<String, dynamic> applyToBody(Map<String, dynamic>? body) {
    final result = Map<String, dynamic>.from(body ?? const {});

    if (empresaId != null) {
      result.putIfAbsent('empresa', () => <String, dynamic>{});
      if (result['empresa'] is Map) {
        result['empresa']['id'] ??= empresaId;
      }
    }

    if (aplicativoId != null) {
      result.putIfAbsent('aplicativo', () => <String, dynamic>{});
      if (result['aplicativo'] is Map) {
        result['aplicativo']['id'] ??= aplicativoId;
      }
    }

    if (parceiroId != null) {
      result.putIfAbsent('parceiro', () => <String, dynamic>{});
      if (result['parceiro'] is Map) {
        result['parceiro']['id'] ??= parceiroId;
      }
    }

    result.putIfAbsent('audit', () => <String, dynamic>{});
    if (result['audit'] is Map) {
      result['audit']['empresaId'] ??= empresaId;
      result['audit']['parceiroId'] ??= parceiroId;
      result['audit']['appId'] ??= aplicativoId;
      result['audit']['userLogadoId'] ??= userLogadoId;
    }

    return result;
  }
}
