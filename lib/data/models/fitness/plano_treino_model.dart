import 'dart:convert';

/// Item de exercício dentro de uma divisão de treino prescrita
class ItemTreinoModel {
  final String id;
  final String exercicioId;
  final String exercicioNome;
  final String grupoMuscular;
  final String? videoUrl;
  final int series;
  final String repeticoes; // Ex: "10-12", "Falha", "15"
  final double cargaSugeridaKg;
  final int descansoSegundos;
  final String tecnica; // Normal, Bi-set, Drop-set, Rest-pause, Pirâmide
  final String? observacoes;

  const ItemTreinoModel({
    required this.id,
    required this.exercicioId,
    required this.exercicioNome,
    required this.grupoMuscular,
    this.videoUrl,
    this.series = 3,
    this.repeticoes = '10 a 12',
    this.cargaSugeridaKg = 0,
    this.descansoSegundos = 60,
    this.tecnica = 'Normal',
    this.observacoes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercicioId': exercicioId,
      'exercicioNome': exercicioNome,
      'grupoMuscular': grupoMuscular,
      'videoUrl': videoUrl,
      'series': series,
      'repeticoes': repeticoes,
      'cargaSugeridaKg': cargaSugeridaKg,
      'descansoSegundos': descansoSegundos,
      'tecnica': tecnica,
      'observacoes': observacoes,
    };
  }

  factory ItemTreinoModel.fromMap(Map<String, dynamic> map) {
    return ItemTreinoModel(
      id: map['id']?.toString() ?? '',
      exercicioId: map['exercicioId']?.toString() ?? '',
      exercicioNome: map['exercicioNome']?.toString() ?? '',
      grupoMuscular: map['grupoMuscular']?.toString() ?? '',
      videoUrl: map['videoUrl']?.toString(),
      series: (map['series'] as num?)?.toInt() ?? 3,
      repeticoes: map['repeticoes']?.toString() ?? '10 a 12',
      cargaSugeridaKg: (map['cargaSugeridaKg'] as num?)?.toDouble() ?? 0.0,
      descansoSegundos: (map['descansoSegundos'] as num?)?.toInt() ?? 60,
      tecnica: map['tecnica']?.toString() ?? 'Normal',
      observacoes: map['observacoes']?.toString(),
    );
  }
}

/// Divisão de Treino (Treino A, Treino B, Treino C, etc.)
class DivisaoTreinoModel {
  final String id;
  final String letra; // A, B, C, D, E...
  final String nome; // Ex: "Peito e Tríceps", "Quadríceps e Panturrilha"
  final List<ItemTreinoModel> exercicios;

  const DivisaoTreinoModel({
    required this.id,
    required this.letra,
    required this.nome,
    required this.exercicios,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'letra': letra,
      'nome': nome,
      'exercicios': exercicios.map((e) => e.toMap()).toList(),
    };
  }

  factory DivisaoTreinoModel.fromMap(Map<String, dynamic> map) {
    return DivisaoTreinoModel(
      id: map['id']?.toString() ?? '',
      letra: map['letra']?.toString() ?? 'A',
      nome: map['nome']?.toString() ?? 'Treino Geral',
      exercicios: (map['exercicios'] as List<dynamic>?)
              ?.map((e) => ItemTreinoModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Plano de Treino Completo Prescrito pelo Personal Trainer
class PlanoTreinoModel {
  final String id;
  final String alunoId;
  final String alunoNome;
  final String personalId;
  final String titulo; // Ex: "Hipertrofia ABC - Fase 1"
  final String objetivo; // Hipertrofia, Emagrecimento, Força, Condicionamento
  final String dataInicio;
  final String? dataValidade;
  final List<DivisaoTreinoModel> divisoes;
  final bool ativo;
  final bool isTemplate; // Se é um modelo reutilizável

  const PlanoTreinoModel({
    required this.id,
    required this.alunoId,
    required this.alunoNome,
    required this.personalId,
    required this.titulo,
    this.objetivo = 'Hipertrofia',
    required this.dataInicio,
    this.dataValidade,
    required this.divisoes,
    this.ativo = true,
    this.isTemplate = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'alunoId': alunoId,
      'alunoNome': alunoNome,
      'personalId': personalId,
      'titulo': titulo,
      'objetivo': objetivo,
      'dataInicio': dataInicio,
      'dataValidade': dataValidade,
      'divisoes': divisoes.map((d) => d.toMap()).toList(),
      'ativo': ativo,
      'isTemplate': isTemplate,
    };
  }

  factory PlanoTreinoModel.fromMap(Map<String, dynamic> map) {
    return PlanoTreinoModel(
      id: map['id']?.toString() ?? '',
      alunoId: map['alunoId']?.toString() ?? '',
      alunoNome: map['alunoNome']?.toString() ?? '',
      personalId: map['personalId']?.toString() ?? '',
      titulo: map['titulo']?.toString() ?? 'Plano de Treino',
      objetivo: map['objetivo']?.toString() ?? 'Hipertrofia',
      dataInicio: map['dataInicio']?.toString() ?? '',
      dataValidade: map['dataValidade']?.toString(),
      divisoes: (map['divisoes'] as List<dynamic>?)
              ?.map((d) => DivisaoTreinoModel.fromMap(d as Map<String, dynamic>))
              .toList() ??
          [],
      ativo: map['ativo'] == true,
      isTemplate: map['isTemplate'] == true,
    );
  }

  String toJson() => json.encode(toMap());

  factory PlanoTreinoModel.fromJson(String source) =>
      PlanoTreinoModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
