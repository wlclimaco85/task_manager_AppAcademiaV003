/// Modelo de check-in diario (humor/observacao) retornado por
/// GET/PUT /api/fitness/checkin.
///
/// O endpoint NAO e envelopado pelo backend (retorna o objeto direto). O
/// fromJson abaixo e defensivo: aceita o Map com as chaves diretas OU dentro
/// de uma chave 'data', trata null e converte num. Se o checkin do dia ainda
/// nao existir, o backend retorna objeto vazio/null-safe (nao 404).
library;

class CheckinDiario {
  final DateTime dataRegistro;
  final String? humor;
  final String? observacao;

  const CheckinDiario({
    required this.dataRegistro,
    this.humor,
    this.observacao,
  });

  factory CheckinDiario.fromJson(Map<String, dynamic> json) {
    final map = _unwrap(json);

    return CheckinDiario(
      dataRegistro: _toDate(map['dataRegistro']),
      humor: map['humor'] as String?,
      observacao: map['observacao'] as String?,
    );
  }

  /// Desembrulha o envelope opcional: se o campo 'data' for um Map com as
  /// chaves esperadas (envelope), usa-o; senao usa o proprio json.
  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final inner = json['data'];
    if (inner is Map &&
        (inner.containsKey('humor') || inner.containsKey('observacao'))) {
      return Map<String, dynamic>.from(inner);
    }
    return json;
  }
}

DateTime _toDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return DateTime.now();
}
