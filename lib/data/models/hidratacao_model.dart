/// Modelo de hidratacao retornado por GET /api/hidratacao/resumo e
/// POST /api/hidratacao/registros.
///
/// Campos e paths confirmados em HidratacaoDtos.java e HidratacaoController.java
/// (backend modulo Hidratacao, ja existente em produdcao). O endpoint NAO e
/// envelopado pelo backend (retorna o objeto direto). O fromJson abaixo e
/// defensivo: aceita o Map com as chaves diretas OU dentro de uma chave
/// 'data', trata null e converte num.
library;

class ResumoHidratacao {
  final DateTime? data;
  final int totalMl;
  final int? metaDiariaMl;
  final int? volumeCopoMl;
  final double? percentual;

  const ResumoHidratacao({
    this.data,
    required this.totalMl,
    this.metaDiariaMl,
    this.volumeCopoMl,
    this.percentual,
  });

  factory ResumoHidratacao.fromJson(Map<String, dynamic> json) {
    final map = _unwrap(json);

    return ResumoHidratacao(
      data: _toDate(map['data']),
      totalMl: _toInt(map['totalMl']) ?? 0,
      metaDiariaMl: _toInt(map['metaDiariaMl']),
      volumeCopoMl: _toInt(map['volumeCopoMl']),
      percentual: _toDouble(map['percentual']),
    );
  }

  /// Desembrulha o envelope opcional: se o campo 'data' for um Map com as
  /// chaves esperadas (envelope), usa-o; senao usa o proprio json.
  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final inner = json['data'];
    if (inner is Map &&
        (inner.containsKey('totalMl') || inner.containsKey('metaDiariaMl'))) {
      return Map<String, dynamic>.from(inner);
    }
    return json;
  }
}

DateTime? _toDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
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

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', '.'));
  return null;
}
