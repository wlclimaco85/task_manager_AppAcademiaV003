/// Indicadores do dashboard de personal e academia (resposta de /api/fitness/.../dashboard).
class DashboardFitnessModel {
  DashboardFitnessModel({
    required this.mes,
    required this.resumo,
    required this.semFicha,
    required this.proximosTrocaFicha,
    required this.evoluindo,
    required this.rankingMes,
    required this.melhorDesempenho,
    required this.frequencia,
  });

  final String mes;
  final DashboardResumo resumo;
  final List<DashboardAluno> semFicha;
  final List<DashboardAluno> proximosTrocaFicha;
  final List<DashboardAluno> evoluindo;
  final List<DashboardAluno> rankingMes;
  final List<DashboardAluno> melhorDesempenho;
  final List<DashboardAluno> frequencia;

  factory DashboardFitnessModel.fromJson(Map<String, dynamic> json) {
    List<DashboardAluno> lista(String chave) {
      final valor = json[chave];
      if (valor is! List) return const [];
      return [
        for (final item in valor)
          if (item is Map) DashboardAluno.fromJson(Map<String, dynamic>.from(item)),
      ];
    }

    final resumo = json['resumo'];
    return DashboardFitnessModel(
      mes: json['mes']?.toString() ?? '',
      resumo: DashboardResumo.fromJson(resumo is Map ? Map<String, dynamic>.from(resumo) : const {}),
      semFicha: lista('semFicha'),
      proximosTrocaFicha: lista('proximosTrocaFicha'),
      evoluindo: lista('evoluindo'),
      rankingMes: lista('rankingMes'),
      melhorDesempenho: lista('melhorDesempenho'),
      frequencia: lista('frequencia'),
    );
  }
}

class DashboardResumo {
  const DashboardResumo({
    required this.totalAlunos,
    required this.ativosUltimos30Dias,
    required this.semFicha,
    required this.proximosTrocaFicha,
    required this.evoluindo,
    required this.frequenciaMediaPct,
  });

  final int totalAlunos;
  final int ativosUltimos30Dias;
  final int semFicha;
  final int proximosTrocaFicha;
  final int evoluindo;
  final double? frequenciaMediaPct;

  factory DashboardResumo.fromJson(Map<String, dynamic> json) {
    int inteiro(String chave) => (json[chave] as num?)?.toInt() ?? 0;
    final media = json['frequenciaMediaPct'];
    return DashboardResumo(
      totalAlunos: inteiro('totalAlunos'),
      ativosUltimos30Dias: inteiro('ativosUltimos30Dias'),
      semFicha: inteiro('semFicha'),
      proximosTrocaFicha: inteiro('proximosTrocaFicha'),
      evoluindo: inteiro('evoluindo'),
      frequenciaMediaPct: media is num ? media.toDouble() : null,
    );
  }
}

/// Linha de aluno usada em todas as listas. Campos opcionais aparecem so quando o indicador os traz.
class DashboardAluno {
  const DashboardAluno({
    required this.alunoId,
    required this.nome,
    this.posicao,
    this.treino,
    this.vencimento,
    this.diasRestantes,
    this.treinosNoMes,
    this.frequenciaContratada,
    this.percentual,
    this.cargaAnteriorKg,
    this.cargaAtualKg,
    this.variacaoPct,
  });

  final int alunoId;
  final String nome;
  final int? posicao;
  final String? treino;
  final String? vencimento;
  final int? diasRestantes;
  final int? treinosNoMes;
  final int? frequenciaContratada;
  final double? percentual;
  final double? cargaAnteriorKg;
  final double? cargaAtualKg;
  final double? variacaoPct;

  factory DashboardAluno.fromJson(Map<String, dynamic> json) {
    int? inteiro(String chave) => (json[chave] as num?)?.toInt();
    double? decimal(String chave) => (json[chave] as num?)?.toDouble();
    return DashboardAluno(
      alunoId: inteiro('alunoId') ?? 0,
      nome: json['nome']?.toString().trim().isNotEmpty == true ? json['nome'].toString() : 'Aluno sem nome',
      posicao: inteiro('posicao'),
      treino: json['treino']?.toString(),
      vencimento: json['vencimento']?.toString(),
      diasRestantes: inteiro('diasRestantes'),
      treinosNoMes: inteiro('treinosNoMes'),
      frequenciaContratada: inteiro('frequenciaContratada'),
      percentual: decimal('percentual'),
      cargaAnteriorKg: decimal('cargaAnteriorKg'),
      cargaAtualKg: decimal('cargaAtualKg'),
      variacaoPct: decimal('variacaoPct'),
    );
  }
}
