/// Modelo de registro de exame retornado por GET/POST /api/fitness/exames.
///
/// O endpoint NAO e envelopado pelo backend (retorna o objeto/array direto).
/// O fromJson abaixo e defensivo: aceita o Map com as chaves diretas OU
/// dentro de uma chave 'data', trata null e converte num.
library;

class ExameRegistro {
  final int? id;
  final DateTime data;
  final String nomeExame;
  final String? observacao;

  const ExameRegistro({
    this.id,
    required this.data,
    required this.nomeExame,
    this.observacao,
  });

  factory ExameRegistro.fromJson(Map<String, dynamic> json) {
    final map = _unwrap(json);
    return ExameRegistro(
      id: _toInt(map['id']),
      data: _toDate(map['data']),
      nomeExame: map['nomeExame']?.toString() ?? '',
      observacao: map['observacao']?.toString(),
    );
  }

  /// Monta o body do POST (sem 'id', que e gerado pelo backend).
  Map<String, dynamic> toJson() {
    return {
      'data': _formatarData(data),
      'nomeExame': nomeExame,
      'observacao': observacao,
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
    if (inner is Map && inner.containsKey('nomeExame')) {
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
