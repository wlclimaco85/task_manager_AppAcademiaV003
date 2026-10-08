import 'dart:convert';

/// Categoria do Exame
enum CategoriaExame {
  sangue,
  hormonal,
  imagem,
  cardiaco,
  bioimpedancia,
  outro,
}

/// Modelo de Exame Laboratorial / Clínico do Aluno
class ExameRegistroModel {
  final String id;
  final String alunoId;
  final String alunoNome;
  final String titulo; // ex: "Hemograma Completo + Perfil Lipídico", "Painel Hormonal Total & Livre"
  final CategoriaExame categoria;
  final String dataExame; // YYYY-MM-DD
  final String laboratório; // ex: "Laboratório Sabin Uberaba", "Laboratório Carlos Chagas"
  final String? medicoSolicitante; // ex: "Dr. Roberto Endocrinologista"
  final String? urlPdf; // Link / caminho do arquivo PDF do laudo
  final String? nomeArquivoPdf; // ex: "laudo_hormonal_outubro_2026.pdf"
  final int? tamanhoBytesPdf;
  final String? observacoesResultados; // ex: "Testosterona Total: 850 ng/dL, E2: 28 pg/mL, HDL: 55 mg/dL"
  final bool alteracaoRelevante; // Alerta se houve marcador fora da referência
  final bool visualizadoPeloMedico;

  const ExameRegistroModel({
    required this.id,
    required this.alunoId,
    required this.alunoNome,
    required this.titulo,
    this.categoria = CategoriaExame.sangue,
    required this.dataExame,
    this.laboratório = 'Laboratório Sabin Uberaba',
    this.medicoSolicitante,
    this.urlPdf,
    this.nomeArquivoPdf,
    this.tamanhoBytesPdf,
    this.observacoesResultados,
    this.alteracaoRelevante = false,
    this.visualizadoPeloMedico = true,
  });

  ExameRegistroModel copyWith({
    String? id,
    String? alunoId,
    String? alunoNome,
    String? titulo,
    CategoriaExame? categoria,
    String? dataExame,
    String? laboratório,
    String? medicoSolicitante,
    String? urlPdf,
    String? nomeArquivoPdf,
    int? tamanhoBytesPdf,
    String? observacoesResultados,
    bool? alteracaoRelevante,
    bool? visualizadoPeloMedico,
  }) {
    return ExameRegistroModel(
      id: id ?? this.id,
      alunoId: alunoId ?? this.alunoId,
      alunoNome: alunoNome ?? this.alunoNome,
      titulo: titulo ?? this.titulo,
      categoria: categoria ?? this.categoria,
      dataExame: dataExame ?? this.dataExame,
      laboratório: laboratório ?? this.laboratório,
      medicoSolicitante: medicoSolicitante ?? this.medicoSolicitante,
      urlPdf: urlPdf ?? this.urlPdf,
      nomeArquivoPdf: nomeArquivoPdf ?? this.nomeArquivoPdf,
      tamanhoBytesPdf: tamanhoBytesPdf ?? this.tamanhoBytesPdf,
      observacoesResultados:
          observacoesResultados ?? this.observacoesResultados,
      alteracaoRelevante: alteracaoRelevante ?? this.alteracaoRelevante,
      visualizadoPeloMedico:
          visualizadoPeloMedico ?? this.visualizadoPeloMedico,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'alunoId': alunoId,
      'alunoNome': alunoNome,
      'titulo': titulo,
      'categoria': categoria.name,
      'dataExame': dataExame,
      'laboratório': laboratório,
      'medicoSolicitante': medicoSolicitante,
      'urlPdf': urlPdf,
      'nomeArquivoPdf': nomeArquivoPdf,
      'tamanhoBytesPdf': tamanhoBytesPdf,
      'observacoesResultados': observacoesResultados,
      'alteracaoRelevante': alteracaoRelevante,
      'visualizadoPeloMedico': visualizadoPeloMedico,
    };
  }

  factory ExameRegistroModel.fromMap(Map<String, dynamic> map) {
    return ExameRegistroModel(
      id: map['id']?.toString() ?? '',
      alunoId: map['alunoId']?.toString() ?? '',
      alunoNome: map['alunoNome']?.toString() ?? '',
      titulo: map['titulo']?.toString() ?? 'Exame Laboratorial',
      categoria: CategoriaExame.values.firstWhere(
        (c) => c.name == map['categoria'],
        orElse: () => CategoriaExame.sangue,
      ),
      dataExame: map['dataExame']?.toString() ??
          DateTime.now().toIso8601String().substring(0, 10),
      laboratório:
          map['laboratório']?.toString() ?? 'Laboratório Sabin Uberaba',
      medicoSolicitante: map['medicoSolicitante']?.toString(),
      urlPdf: map['urlPdf']?.toString(),
      nomeArquivoPdf: map['nomeArquivoPdf']?.toString(),
      tamanhoBytesPdf: (map['tamanhoBytesPdf'] as num?)?.toInt(),
      observacoesResultados: map['observacoesResultados']?.toString(),
      alteracaoRelevante: map['alteracaoRelevante'] == true,
      visualizadoPeloMedico: map['visualizadoPeloMedico'] != false,
    );
  }
}
