/// Modelos da Home Saúde (contrato REST real do backend).
///
/// Os endpoints novos NÃO são envelopados pelo backend (retornam o objeto/array
/// direto). Mesmo assim, os fromJson abaixo são defensivos: aceitam o Map com as
/// chaves diretas OU dentro de uma chave 'data', tratam null e convertem num.
library;

/// Resumo diário de saúde retornado por GET/PUT /api/fitness/resumo.
class ResumoSaudeDiaria {
  final DateTime data;
  final int passos;
  final int treinoMinutos;
  final int? batimentos;
  final int sonoMinutos;
  final double? pesoKg;
  final double? pesoMetaKg;
  final int? alturaCm;
  final List<DiaResumoSaude> historicoSemanal;

  const ResumoSaudeDiaria({
    required this.data,
    required this.passos,
    required this.treinoMinutos,
    required this.batimentos,
    required this.sonoMinutos,
    required this.pesoKg,
    required this.pesoMetaKg,
    this.alturaCm,
    required this.historicoSemanal,
  });

  ResumoSaudeDiaria copyWith({
    int? passos,
    int? treinoMinutos,
    int? alturaCm,
  }) {
    return ResumoSaudeDiaria(
      data: data,
      passos: passos ?? this.passos,
      treinoMinutos: treinoMinutos ?? this.treinoMinutos,
      batimentos: batimentos,
      sonoMinutos: sonoMinutos,
      pesoKg: pesoKg,
      pesoMetaKg: pesoMetaKg,
      alturaCm: alturaCm ?? this.alturaCm,
      historicoSemanal: historicoSemanal,
    );
  }

  factory ResumoSaudeDiaria.fromJson(Map<String, dynamic> json) {
    // Aceita payload direto ou aninhado em 'data' (envelope opcional).
    final Map<String, dynamic> map = _unwrap(json);

    final historicoRaw = map['historicoSemanal'];
    final historico = <DiaResumoSaude>[];
    if (historicoRaw is List) {
      for (final item in historicoRaw) {
        if (item is Map) {
          historico.add(
            DiaResumoSaude.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return ResumoSaudeDiaria(
      data: _toDate(map['data']),
      passos: _toInt(map['passos']) ?? 0,
      treinoMinutos: _toInt(map['treinoMinutos']) ?? 0,
      batimentos: _toInt(map['batimentos']),
      sonoMinutos: _toInt(map['sonoMinutos']) ?? 0,
      pesoKg: _toDouble(map['pesoKg']),
      pesoMetaKg: _toDouble(map['pesoMetaKg']),
      alturaCm: _toInt(map['alturaCm']),
      historicoSemanal: historico,
    );
  }

  /// Desembrulha o envelope opcional: se o campo 'data' for um Map com as chaves
  /// esperadas (envelope), usa-o; senão usa o próprio json (chaves diretas).
  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final inner = json['data'];
    if (inner is Map && inner.containsKey('passos')) {
      return Map<String, dynamic>.from(inner);
    }
    return json;
  }
}

/// Item do histórico semanal retornado por GET /api/fitness/historico.
class DiaResumoSaude {
  final DateTime data;
  final int passos;
  final int treinoMinutos;
  final int sonoMinutos;
  final double? pesoKg;
  final int? alturaCm;

  const DiaResumoSaude({
    required this.data,
    required this.passos,
    required this.treinoMinutos,
    required this.sonoMinutos,
    this.pesoKg,
    this.alturaCm,
  });

  factory DiaResumoSaude.fromJson(Map<String, dynamic> json) {
    return DiaResumoSaude(
      data: _toDate(json['data']),
      passos: _toInt(json['passos']) ?? 0,
      treinoMinutos: _toInt(json['treinoMinutos']) ?? 0,
      sonoMinutos: _toInt(json['sonoMinutos']) ?? 0,
      pesoKg: _toDouble(json['pesoKg']),
      alturaCm: _toInt(json['alturaCm']),
    );
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
