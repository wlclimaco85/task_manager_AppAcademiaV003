/// Situacao da mensalidade de um aluno no mes, vista pela academia.
enum StatusMensalidadeAcademia { pago, pendente, atrasado }

class FinanceiroAcademiaAluno {
  final String alunoId;
  final String nome;
  final String telefone;
  final double valor;
  final int diaVencimento;
  final StatusMensalidadeAcademia status;
  final String? dataPagamento;

  const FinanceiroAcademiaAluno({
    required this.alunoId,
    required this.nome,
    required this.telefone,
    required this.valor,
    required this.diaVencimento,
    required this.status,
    this.dataPagamento,
  });

  bool get pago => status == StatusMensalidadeAcademia.pago;

  factory FinanceiroAcademiaAluno.fromMap(Map<String, dynamic> map) {
    return FinanceiroAcademiaAluno(
      alunoId: map['alunoId']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      telefone: map['telefone']?.toString() ?? '',
      valor: (map['valor'] as num?)?.toDouble() ?? 0,
      diaVencimento: (map['diaVencimento'] as num?)?.toInt() ?? 10,
      status: switch (map['status']) {
        'PAGO' => StatusMensalidadeAcademia.pago,
        'ATRASADO' => StatusMensalidadeAcademia.atrasado,
        _ => StatusMensalidadeAcademia.pendente,
      },
      dataPagamento: map['dataPagamento']?.toString(),
    );
  }
}

/// Financeiro de um mes: alunos matriculados e totais (recebido, pendente, atrasado).
class FinanceiroAcademiaMes {
  final String mes;
  final List<FinanceiroAcademiaAluno> alunos;
  final double recebido;
  final double pendente;
  final double atrasado;

  const FinanceiroAcademiaMes({
    required this.mes,
    required this.alunos,
    required this.recebido,
    required this.pendente,
    required this.atrasado,
  });

  factory FinanceiroAcademiaMes.fromMap(Map<String, dynamic> map) {
    final totais = map['totais'] is Map ? Map<String, dynamic>.from(map['totais'] as Map) : <String, dynamic>{};
    final lista = map['alunos'] is List ? map['alunos'] as List : const [];
    return FinanceiroAcademiaMes(
      mes: map['mes']?.toString() ?? '',
      alunos: [
        for (final item in lista)
          if (item is Map) FinanceiroAcademiaAluno.fromMap(Map<String, dynamic>.from(item)),
      ],
      recebido: (totais['recebido'] as num?)?.toDouble() ?? 0,
      pendente: (totais['pendente'] as num?)?.toDouble() ?? 0,
      atrasado: (totais['atrasado'] as num?)?.toDouble() ?? 0,
    );
  }
}
