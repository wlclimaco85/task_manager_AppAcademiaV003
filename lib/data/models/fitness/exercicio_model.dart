import 'dart:convert';

/// Modelo de Exercício Físico (Catálogo Padrão MFIT Personal)
class ExercicioModel {
  final String id;
  final String nome;
  final String grupoMuscular; // Peito, Costas, Quadríceps, Posterior, Ombros, Bíceps, Tríceps, Abdômen, Cárdio
  final String? equipamento; // Barra, Halteres, Polia, Máquina, Peso Corporal
  final String? videoUrl; // Link demonstrativo (loop/animação)
  final String? thumbnailUrl;
  final String instrucoes;
  final String? errosComuns;
  final bool isCustom; // Criado pelo personal

  const ExercicioModel({
    required this.id,
    required this.nome,
    required this.grupoMuscular,
    this.equipamento,
    this.videoUrl,
    this.thumbnailUrl,
    this.instrucoes = '',
    this.errosComuns,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'grupoMuscular': grupoMuscular,
      'equipamento': equipamento,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'instrucoes': instrucoes,
      'errosComuns': errosComuns,
      'isCustom': isCustom,
    };
  }

  factory ExercicioModel.fromMap(Map<String, dynamic> map) {
    return ExercicioModel(
      id: map['id']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      grupoMuscular: map['grupoMuscular']?.toString() ?? 'Geral',
      equipamento: map['equipamento']?.toString(),
      videoUrl: map['videoUrl']?.toString(),
      thumbnailUrl: map['thumbnailUrl']?.toString(),
      instrucoes: map['instrucoes']?.toString() ?? '',
      errosComuns: map['errosComuns']?.toString(),
      isCustom: map['isCustom'] == true,
    );
  }

  String toJson() => json.encode(toMap());

  factory ExercicioModel.fromJson(String source) =>
      ExercicioModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
