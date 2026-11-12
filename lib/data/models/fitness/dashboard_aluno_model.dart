/// Indicadores do dashboard do proprio aluno (resposta de /api/fitness/aluno/dashboard).
class DashboardAlunoModel {
  const DashboardAlunoModel({
    required this.mes,
    required this.treinosNoMes,
    required this.diasTreinadosNoMes,
    required this.treinosUltimos7Dias,
    required this.treinosPorDia,
    required this.evolucaoCargas,
    this.ultimoTreino,
    this.diasSemTreinar,
    this.ficha,
  });

  final String mes;
  final int treinosNoMes;
  final int diasTreinadosNoMes;
  final int treinosUltimos7Dias;

  /// Um item por dia do mes: quantidade de treinos concluidos naquele dia.
  final List<int> treinosPorDia;
  final List<EvolucaoCargaAluno> evolucaoCargas;
  final String? ultimoTreino;
  final int? diasSemTreinar;
  final FichaAluno? ficha;

  factory DashboardAlunoModel.fromJson(Map<String, dynamic> json) {
    final dias = json['treinosPorDia'];
    final evolucao = json['evolucaoCargas'];
    final ficha = json['ficha'];
    return DashboardAlunoModel(
      mes: json['mes']?.toString() ?? '',
      treinosNoMes: _inteiro(json['treinosNoMes']),
      diasTreinadosNoMes: _inteiro(json['diasTreinadosNoMes']),
      treinosUltimos7Dias: _inteiro(json['treinosUltimos7Dias']),
      treinosPorDia: dias is List
          ? [for (final d in dias) if (d is Map) _inteiro(d['treinos'])]
          : const [],
      evolucaoCargas: evolucao is List
          ? [for (final e in evolucao) if (e is Map) EvolucaoCargaAluno.fromJson(Map<String, dynamic>.from(e))]
          : const [],
      ultimoTreino: json['ultimoTreino']?.toString(),
      diasSemTreinar: json['diasSemTreinar'] is num ? (json['diasSemTreinar'] as num).toInt() : null,
      ficha: ficha is Map ? FichaAluno.fromJson(Map<String, dynamic>.from(ficha)) : null,
    );
  }

  static int _inteiro(dynamic valor) => valor is num ? valor.toInt() : 0;
}

class FichaAluno {
  const FichaAluno({required this.titulo, this.dataValidade, this.diasParaVencer});

  final String titulo;
  final String? dataValidade;
  final int? diasParaVencer;

  factory FichaAluno.fromJson(Map<String, dynamic> json) => FichaAluno(
        titulo: json['titulo']?.toString() ?? '',
        dataValidade: json['dataValidade']?.toString(),
        diasParaVencer: json['diasParaVencer'] is num ? (json['diasParaVencer'] as num).toInt() : null,
      );
}

class EvolucaoCargaAluno {
  const EvolucaoCargaAluno({
    required this.exercicio,
    required this.cargaAnteriorKg,
    required this.cargaAtualKg,
    required this.variacaoPct,
  });

  final String exercicio;
  final double cargaAnteriorKg;
  final double cargaAtualKg;
  final double variacaoPct;

  factory EvolucaoCargaAluno.fromJson(Map<String, dynamic> json) => EvolucaoCargaAluno(
        exercicio: json['exercicio']?.toString() ?? '',
        cargaAnteriorKg: (json['cargaAnteriorKg'] as num?)?.toDouble() ?? 0,
        cargaAtualKg: (json['cargaAtualKg'] as num?)?.toDouble() ?? 0,
        variacaoPct: (json['variacaoPct'] as num?)?.toDouble() ?? 0,
      );
}
