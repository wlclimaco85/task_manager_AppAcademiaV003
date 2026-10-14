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

  /// Passo a passo numerado da execução (ex.: "1. Posicione a barra...").
  final String descricao;

  /// 1 = iniciante, 2 = intermediário, 3 = avançado.
  final int? nivel;
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
    this.descricao = '',
    this.nivel,
    this.isCustom = false,
  });

  /// Mídia exibida: vídeo cadastrado ou, sem vídeo, a imagem demonstrativa.
  String? get midiaUrl => (videoUrl != null && videoUrl!.isNotEmpty)
      ? videoUrl
      : ((thumbnailUrl != null && thumbnailUrl!.isNotEmpty) ? thumbnailUrl : null);

  String? get nivelTexto => switch (nivel) {
        1 => 'Iniciante',
        2 => 'Intermediário',
        3 => 'Avançado',
        _ => null,
      };

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
      'descricao': descricao,
      'nivel': nivel,
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
      descricao: map['descricao']?.toString() ?? '',
      nivel: map['nivel'] is int ? map['nivel'] as int : int.tryParse('${map['nivel']}'),
      isCustom: map['isCustom'] == true,
    );
  }

  String toJson() => json.encode(toMap());

  factory ExercicioModel.fromJson(String source) =>
      ExercicioModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
