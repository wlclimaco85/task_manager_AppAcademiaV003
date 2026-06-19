/// Modelos de gamificação (conquistas, ranking, opt-ins de comunidade).
///
/// Os endpoints novos de fitness NÃO são envelopados pelo backend (retornam
/// o objeto/array direto). Mesmo assim, os fromJson abaixo são defensivos:
/// aceitam o Map com as chaves diretas OU dentro de uma chave 'data', tratam
/// null e convertem num/bool/string, seguindo o padrão de saude_diaria_model.dart.
library;

/// Perfil de gamificação retornado por GET/PUT /api/fitness/gamificacao/perfil.
class GamificacaoPerfil {
  final bool rankingOptIn;
  final bool comunidadeOptIn;

  const GamificacaoPerfil({
    required this.rankingOptIn,
    required this.comunidadeOptIn,
  });

  GamificacaoPerfil copyWith({
    bool? rankingOptIn,
    bool? comunidadeOptIn,
  }) {
    return GamificacaoPerfil(
      rankingOptIn: rankingOptIn ?? this.rankingOptIn,
      comunidadeOptIn: comunidadeOptIn ?? this.comunidadeOptIn,
    );
  }

  factory GamificacaoPerfil.fromJson(Map<String, dynamic> json) {
    final map = _unwrap(json);
    return GamificacaoPerfil(
      rankingOptIn: _toBool(map['rankingOptIn']) ?? false,
      comunidadeOptIn: _toBool(map['comunidadeOptIn']) ?? false,
    );
  }

  /// Desembrulha o envelope opcional: se o campo 'data' for um Map com as
  /// chaves esperadas (envelope), usa-o; senão usa o próprio json (chaves
  /// diretas).
  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final inner = json['data'];
    if (inner is Map &&
        (inner.containsKey('rankingOptIn') ||
            inner.containsKey('comunidadeOptIn'))) {
      return Map<String, dynamic>.from(inner);
    }
    return json;
  }
}

/// Item de conquista retornado por GET /api/fitness/gamificacao/conquistas.
class ConquistaItem {
  final String codigo;
  final String nome;
  final String descricao;
  final bool obtida;
  final DateTime? obtidaEm;

  const ConquistaItem({
    required this.codigo,
    required this.nome,
    required this.descricao,
    required this.obtida,
    this.obtidaEm,
  });

  factory ConquistaItem.fromJson(Map<String, dynamic> json) {
    return ConquistaItem(
      codigo: _toStr(json['codigo']) ?? '',
      nome: _toStr(json['nome']) ?? '',
      descricao: _toStr(json['descricao']) ?? '',
      obtida: _toBool(json['obtida']) ?? false,
      obtidaEm: _toDateOrNull(json['obtidaEm']),
    );
  }
}

/// Item de ranking retornado por GET /api/fitness/gamificacao/ranking.
class RankingItem {
  final int posicao;
  final int usuarioId;
  final int pontuacao;
  final bool voce;

  const RankingItem({
    required this.posicao,
    required this.usuarioId,
    required this.pontuacao,
    required this.voce,
  });

  factory RankingItem.fromJson(Map<String, dynamic> json) {
    return RankingItem(
      posicao: _toInt(json['posicao']) ?? 0,
      usuarioId: _toInt(json['usuarioId']) ?? 0,
      pontuacao: _toInt(json['pontuacao']) ?? 0,
      voce: _toBool(json['voce']) ?? false,
    );
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

DateTime? _toDateOrNull(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
