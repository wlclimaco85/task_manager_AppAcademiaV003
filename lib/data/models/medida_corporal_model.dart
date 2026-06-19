/// Modelo de medida corporal (percentuais + circunferencias) retornado por
/// GET/POST /api/fitness/medidas.
///
/// O endpoint NAO e envelopado pelo backend (retorna o objeto/array direto).
/// O fromJson abaixo e defensivo: aceita o Map com as chaves diretas OU
/// dentro de uma chave 'data', trata null e converte num.
library;

class MedidaCorporal {
  final int? id;
  final DateTime data;
  final double? percentualGordura;
  final double? percentualMassaMuscular;
  final double? percentualAgua;
  final Map<String, double> circunferencias;

  const MedidaCorporal({
    this.id,
    required this.data,
    this.percentualGordura,
    this.percentualMassaMuscular,
    this.percentualAgua,
    this.circunferencias = const {},
  });

  factory MedidaCorporal.fromJson(Map<String, dynamic> json) {
    final map = _unwrap(json);

    final circunferenciasRaw = map['circunferencias'];
    final circunferencias = <String, double>{};
    if (circunferenciasRaw is Map) {
      circunferenciasRaw.forEach((key, value) {
        final parsed = _toDouble(value);
        if (parsed != null) circunferencias[key.toString()] = parsed;
      });
    }

    return MedidaCorporal(
      id: _toInt(map['id']),
      data: _toDate(map['data']),
      percentualGordura: _toDouble(map['percentualGordura']),
      percentualMassaMuscular: _toDouble(map['percentualMassaMuscular']),
      percentualAgua: _toDouble(map['percentualAgua']),
      circunferencias: circunferencias,
    );
  }

  /// Monta o body do POST (sem 'id', que e gerado pelo backend).
  Map<String, dynamic> toJson() {
    return {
      'data': _formatarData(data),
      'percentualGordura': percentualGordura,
      'percentualMassaMuscular': percentualMassaMuscular,
      'percentualAgua': percentualAgua,
      'circunferencias': circunferencias,
    };
  }

  static String _formatarData(DateTime d) {
    final mes = d.month.toString().padLeft(2, '0');
    final dia = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mes-$dia';
  }

  /// Desembrulha o envelope opcional: se o campo 'data' for um Map com as
  /// chaves esperadas (envelope), usa-o; senao usa o proprio json.
  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final inner = json['data'];
    if (inner is Map &&
        (inner.containsKey('percentualGordura') ||
            inner.containsKey('circunferencias'))) {
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
