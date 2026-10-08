import 'dart:convert';

/// Registro individual de uma série realizada pelo aluno
class SerieRegistroModel {
  final int numero;
  final double cargaRealKg;
  final int repeticoesRealizadas;
  final bool concluida;
  final int? descansoUtilizadoSegundos;

  const SerieRegistroModel({
    required this.numero,
    required this.cargaRealKg,
    required this.repeticoesRealizadas,
    this.concluida = true,
    this.descansoUtilizadoSegundos,
  });

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'cargaRealKg': cargaRealKg,
      'repeticoesRealizadas': repeticoesRealizadas,
      'concluida': concluida,
      'descansoUtilizadoSegundos': descansoUtilizadoSegundos,
    };
  }

  factory SerieRegistroModel.fromMap(Map<String, dynamic> map) {
    return SerieRegistroModel(
      numero: (map['numero'] as num?)?.toInt() ?? 1,
      cargaRealKg: (map['cargaRealKg'] as num?)?.toDouble() ?? 0.0,
      repeticoesRealizadas:
          (map['repeticoesRealizadas'] as num?)?.toInt() ?? 10,
      concluida: map['concluida'] == true,
      descansoUtilizadoSegundos:
          (map['descansoUtilizadoSegundos'] as num?)?.toInt(),
    );
  }
}

/// Registro de exercício executado na sessão ao vivo
class ExercicioExecutadoRegistroModel {
  final String exercicioId;
  final String exercicioNome;
  final String grupoMuscular;
  final List<SerieRegistroModel> series;
  final String? observacaoAluno;

  const ExercicioExecutadoRegistroModel({
    required this.exercicioId,
    required this.exercicioNome,
    required this.grupoMuscular,
    required this.series,
    this.observacaoAluno,
  });

  Map<String, dynamic> toMap() {
    return {
      'exercicioId': exercicioId,
      'exercicioNome': exercicioNome,
      'grupoMuscular': grupoMuscular,
      'series': series.map((s) => s.toMap()).toList(),
      'observacaoAluno': observacaoAluno,
    };
  }

  factory ExercicioExecutadoRegistroModel.fromMap(Map<String, dynamic> map) {
    return ExercicioExecutadoRegistroModel(
      exercicioId: map['exercicioId']?.toString() ?? '',
      exercicioNome: map['exercicioNome']?.toString() ?? '',
      grupoMuscular: map['grupoMuscular']?.toString() ?? '',
      series: (map['series'] as List<dynamic>?)
              ?.map(
                  (s) => SerieRegistroModel.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      observacaoAluno: map['observacaoAluno']?.toString(),
    );
  }
}

/// Registro completo de uma sessão de treino concluída
class SessaoTreinoRegistroModel {
  final String id;
  final String treinoId;
  final String divisaoLetra;
  final String divisaoNome;
  final String alunoId;
  final String dataHoraInicio;
  final String dataHoraFim;
  final int duracaoSegundos;
  final List<ExercicioExecutadoRegistroModel> exerciciosExecutados;
  final int rpe; // Esforço percebido (1 a 10)
  final String? feedbackAluno;
  final bool sincronizado;

  const SessaoTreinoRegistroModel({
    required this.id,
    required this.treinoId,
    required this.divisaoLetra,
    required this.divisaoNome,
    required this.alunoId,
    required this.dataHoraInicio,
    required this.dataHoraFim,
    required this.duracaoSegundos,
    required this.exerciciosExecutados,
    this.rpe = 7,
    this.feedbackAluno,
    this.sincronizado = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'treinoId': treinoId,
      'divisaoLetra': divisaoLetra,
      'divisaoNome': divisaoNome,
      'alunoId': alunoId,
      'dataHoraInicio': dataHoraInicio,
      'dataHoraFim': dataHoraFim,
      'duracaoSegundos': duracaoSegundos,
      'exerciciosExecutados': exerciciosExecutados.map((e) => e.toMap()).toList(),
      'rpe': rpe,
      'feedbackAluno': feedbackAluno,
      'sincronizado': sincronizado,
    };
  }

  factory SessaoTreinoRegistroModel.fromMap(Map<String, dynamic> map) {
    return SessaoTreinoRegistroModel(
      id: map['id']?.toString() ?? '',
      treinoId: map['treinoId']?.toString() ?? '',
      divisaoLetra: map['divisaoLetra']?.toString() ?? 'A',
      divisaoNome: map['divisaoNome']?.toString() ?? '',
      alunoId: map['alunoId']?.toString() ?? '',
      dataHoraInicio: map['dataHoraInicio']?.toString() ?? '',
      dataHoraFim: map['dataHoraFim']?.toString() ?? '',
      duracaoSegundos: (map['duracaoSegundos'] as num?)?.toInt() ?? 0,
      exerciciosExecutados: (map['exerciciosExecutados'] as List<dynamic>?)
              ?.map((e) => ExercicioExecutadoRegistroModel.fromMap(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
      rpe: (map['rpe'] as num?)?.toInt() ?? 7,
      feedbackAluno: map['feedbackAluno']?.toString(),
      sincronizado: map['sincronizado'] == true,
    );
  }

  String toJson() => json.encode(toMap());

  factory SessaoTreinoRegistroModel.fromJson(String source) =>
      SessaoTreinoRegistroModel.fromMap(
          json.decode(source) as Map<String, dynamic>);
}
