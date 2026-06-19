/// Modelo do mural/comunidade (GET/POST /api/fitness/mural/posts).
///
/// O endpoint NÃO é envelopado pelo backend (retorna o objeto/array direto).
/// Mesmo assim, o fromJson é defensivo: aceita o Map com as chaves diretas OU
/// dentro de uma chave 'data', trata null e converte num/bool/string,
/// seguindo o padrão de saude_diaria_model.dart.
library;

/// Post do mural retornado por GET/POST /api/fitness/mural/posts.
class MuralPost {
  final int id;
  final int usuarioId;
  final String conteudo;
  final DateTime criadoEm;
  final bool voce;

  const MuralPost({
    required this.id,
    required this.usuarioId,
    required this.conteudo,
    required this.criadoEm,
    required this.voce,
  });

  factory MuralPost.fromJson(Map<String, dynamic> json) {
    final map = _unwrap(json);
    return MuralPost(
      id: _toInt(map['id']) ?? 0,
      usuarioId: _toInt(map['usuarioId']) ?? 0,
      conteudo: _toStr(map['conteudo']) ?? '',
      criadoEm: _toDate(map['criadoEm']),
      voce: _toBool(map['voce']) ?? false,
    );
  }

  /// Desembrulha o envelope opcional: se o campo 'data' for um Map com as
  /// chaves esperadas (envelope), usa-o; senão usa o próprio json (chaves
  /// diretas).
  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final inner = json['data'];
    if (inner is Map && inner.containsKey('conteudo')) {
      return Map<String, dynamic>.from(inner);
    }
    return json;
  }
}

bool? _toBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true') return true;
    if (lower == 'false') return false;
  }
  if (value is num) return value != 0;
  return null;
}

String? _toStr(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  }
  return null;
}

DateTime _toDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return DateTime.now();
}
