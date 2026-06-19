/// Modelo de lembrete (medicamento/suplemento/habito/outro) retornado por
/// GET/POST /api/fitness/lembretes.
///
/// O endpoint NAO e envelopado pelo backend (retorna o objeto/array direto).
/// O fromJson abaixo e defensivo: aceita o Map com as chaves diretas OU
/// dentro de uma chave 'data', trata null e converte num.
library;

class Lembrete {
  final int? id;
  final String tipo;
  final String nome;
  final String? horario;
  final String? frequencia;
  final bool ativo;
  final bool concluidoHoje;

  const Lembrete({
    this.id,
    required this.tipo,
    required this.nome,
    this.horario,
    this.frequencia,
    this.ativo = true,
    this.concluidoHoje = false,
  });

  factory Lembrete.fromJson(Map<String, dynamic> json) {
    final map = _unwrap(json);

    return Lembrete(
      id: _toInt(map['id']),
      tipo: (map['tipo'] as String?) ?? 'OUTRO',
      nome: (map['nome'] as String?) ?? '',
      horario: map['horario'] as String?,
      frequencia: map['frequencia'] as String?,
      ativo: map['ativo'] as bool? ?? true,
      concluidoHoje: map['concluidoHoje'] as bool? ?? false,
    );
  }

  /// Monta o body do POST (sem 'id', que e gerado pelo backend).
  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'nome': nome,
      'horario': horario,
      'frequencia': frequencia,
    };
  }

  /// Desembrulha o envelope opcional: se o campo 'data' for um Map com as
  /// chaves esperadas (envelope), usa-o; senao usa o proprio json.
  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final inner = json['data'];
    if (inner is Map &&
        (inner.containsKey('tipo') || inner.containsKey('nome'))) {
      return Map<String, dynamic>.from(inner);
    }
    return json;
  }
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
