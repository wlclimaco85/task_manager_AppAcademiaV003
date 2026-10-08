import 'dart:convert';

/// Modelo de Feedback / Comentário deixado pelo aluno em um treino
class PersonalAlunoFeedbackModel {
  final String id;
  final String treinoId;
  final String divisaoNome;
  final String data;
  final int rpe; // Esforço percebido 1-10
  final String comentario;
  final String? exercicioDestaque;

  const PersonalAlunoFeedbackModel({
    required this.id,
    required this.treinoId,
    required this.divisaoNome,
    required this.data,
    required this.rpe,
    required this.comentario,
    this.exercicioDestaque,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'treinoId': treinoId,
      'divisaoNome': divisaoNome,
      'data': data,
      'rpe': rpe,
      'comentario': comentario,
      'exercicioDestaque': exercicioDestaque,
    };
  }

  factory PersonalAlunoFeedbackModel.fromMap(Map<String, dynamic> map) {
    return PersonalAlunoFeedbackModel(
      id: map['id']?.toString() ?? '',
      treinoId: map['treinoId']?.toString() ?? '',
      divisaoNome: map['divisaoNome']?.toString() ?? 'Geral',
      data: map['data']?.toString() ?? '',
      rpe: (map['rpe'] as num?)?.toInt() ?? 7,
      comentario: map['comentario']?.toString() ?? '',
      exercicioDestaque: map['exercicioDestaque']?.toString(),
    );
  }
}

/// Status financeiro da mensalidade do aluno
enum StatusMensalidadeAluno {
  pago,
  pendente,
  atrasado,
}

/// Modelo de Aluno sob Gestão do Personal
class PersonalAlunoGestaoModel {
  final String id;
  final String nome;
  final String email;
  final String telefone;
  final String fotoUrl;
  final String objetivo;
  final String nivel; // Iniciante, Intermediario, Avancado
  final bool ativo;

  // Gestão de Treino & Alertas
  final String? treinoAtualNome;
  final String? dataInicioTreino;
  final int validadeTreinoDias; // ex: 30, 45, 60 dias
  final String? dataVencimentoTreino;
  final int diasSemTreinar;
  final int frequenciaSemanalMedia; // ex: 4 dias/semana
  final double volumeTotalKg; // Tonelagem levantada
  final int totalTreinosConcluidos;
  final List<PersonalAlunoFeedbackModel> feedbacks;

  // Controle Financeiro Simples
  final double valorMensalidade;
  final int diaVencimento; // ex: dia 10
  final StatusMensalidadeAluno statusMensalidade;
  final String? dataUltimoPagamento;
  final String mesReferencia; // ex: "10/2026"

  const PersonalAlunoGestaoModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    this.fotoUrl = '',
    this.objetivo = 'Hipertrofia & Definição',
    this.nivel = 'Intermediário',
    this.ativo = true,
    this.treinoAtualNome,
    this.dataInicioTreino,
    this.validadeTreinoDias = 45,
    this.dataVencimentoTreino,
    this.diasSemTreinar = 0,
    this.frequenciaSemanalMedia = 4,
    this.volumeTotalKg = 0.0,
    this.totalTreinosConcluidos = 0,
    this.feedbacks = const [],
    this.valorMensalidade = 250.0,
    this.diaVencimento = 10,
    this.statusMensalidade = StatusMensalidadeAluno.pago,
    this.dataUltimoPagamento,
    this.mesReferencia = '10/2026',
  });

  /// Retorna quantos dias faltam para a ficha de treino vencer (negativo se já venceu)
  int get diasParaVencerTreino {
    if (dataVencimentoTreino == null || dataVencimentoTreino!.isEmpty) {
      return validadeTreinoDias;
    }
    try {
      final venc = DateTime.parse(dataVencimentoTreino!);
      final hoje = DateTime.now();
      return venc.difference(hoje).inDays;
    } catch (_) {
      return 15;
    }
  }

  /// Indica se a ficha está vencida ou prestes a vencer (alerta em <= 7 dias)
  bool get alertaTreinoVencendo => diasParaVencerTreino <= 7;
  bool get treinoVencido => diasParaVencerTreino <= 0;

  /// Alerta se o aluno está em débito / atrasado
  bool get alertaInadimplente =>
      statusMensalidade == StatusMensalidadeAluno.atrasado;

  PersonalAlunoGestaoModel copyWith({
    String? id,
    String? nome,
    String? email,
    String? telefone,
    String? fotoUrl,
    String? objetivo,
    String? nivel,
    bool? ativo,
    String? treinoAtualNome,
    String? dataInicioTreino,
    int? validadeTreinoDias,
    String? dataVencimentoTreino,
    int? diasSemTreinar,
    int? frequenciaSemanalMedia,
    double? volumeTotalKg,
    int? totalTreinosConcluidos,
    List<PersonalAlunoFeedbackModel>? feedbacks,
    double? valorMensalidade,
    int diaVencimento = 10,
    StatusMensalidadeAluno? statusMensalidade,
    String? dataUltimoPagamento,
    String? mesReferencia,
  }) {
    return PersonalAlunoGestaoModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      objetivo: objetivo ?? this.objetivo,
      nivel: nivel ?? this.nivel,
      ativo: ativo ?? this.ativo,
      treinoAtualNome: treinoAtualNome ?? this.treinoAtualNome,
      dataInicioTreino: dataInicioTreino ?? this.dataInicioTreino,
      validadeTreinoDias: validadeTreinoDias ?? this.validadeTreinoDias,
      dataVencimentoTreino: dataVencimentoTreino ?? this.dataVencimentoTreino,
      diasSemTreinar: diasSemTreinar ?? this.diasSemTreinar,
      frequenciaSemanalMedia:
          frequenciaSemanalMedia ?? this.frequenciaSemanalMedia,
      volumeTotalKg: volumeTotalKg ?? this.volumeTotalKg,
      totalTreinosConcluidos:
          totalTreinosConcluidos ?? this.totalTreinosConcluidos,
      feedbacks: feedbacks ?? this.feedbacks,
      valorMensalidade: valorMensalidade ?? this.valorMensalidade,
      diaVencimento: diaVencimento,
      statusMensalidade: statusMensalidade ?? this.statusMensalidade,
      dataUltimoPagamento: dataUltimoPagamento ?? this.dataUltimoPagamento,
      mesReferencia: mesReferencia ?? this.mesReferencia,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'fotoUrl': fotoUrl,
      'objetivo': objetivo,
      'nivel': nivel,
      'ativo': ativo,
      'treinoAtualNome': treinoAtualNome,
      'dataInicioTreino': dataInicioTreino,
      'validadeTreinoDias': validadeTreinoDias,
      'dataVencimentoTreino': dataVencimentoTreino,
      'diasSemTreinar': diasSemTreinar,
      'frequenciaSemanalMedia': frequenciaSemanalMedia,
      'volumeTotalKg': volumeTotalKg,
      'totalTreinosConcluidos': totalTreinosConcluidos,
      'feedbacks': feedbacks.map((f) => f.toMap()).toList(),
      'valorMensalidade': valorMensalidade,
      'diaVencimento': diaVencimento,
      'statusMensalidade': statusMensalidade.name,
      'dataUltimoPagamento': dataUltimoPagamento,
      'mesReferencia': mesReferencia,
    };
  }

  factory PersonalAlunoGestaoModel.fromMap(Map<String, dynamic> map) {
    return PersonalAlunoGestaoModel(
      id: map['id']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      telefone: map['telefone']?.toString() ?? '',
      fotoUrl: map['fotoUrl']?.toString() ?? '',
      objetivo: map['objetivo']?.toString() ?? 'Hipertrofia',
      nivel: map['nivel']?.toString() ?? 'Intermediário',
      ativo: map['ativo'] != false,
      treinoAtualNome: map['treinoAtualNome']?.toString(),
      dataInicioTreino: map['dataInicioTreino']?.toString(),
      validadeTreinoDias: (map['validadeTreinoDias'] as num?)?.toInt() ?? 45,
      dataVencimentoTreino: map['dataVencimentoTreino']?.toString(),
      diasSemTreinar: (map['diasSemTreinar'] as num?)?.toInt() ?? 0,
      frequenciaSemanalMedia:
          (map['frequenciaSemanalMedia'] as num?)?.toInt() ?? 4,
      volumeTotalKg: (map['volumeTotalKg'] as num?)?.toDouble() ?? 0.0,
      totalTreinosConcluidos:
          (map['totalTreinosConcluidos'] as num?)?.toInt() ?? 0,
      feedbacks: (map['feedbacks'] as List<dynamic>?)
              ?.map((f) =>
                  PersonalAlunoFeedbackModel.fromMap(f as Map<String, dynamic>))
              .toList() ??
          [],
      valorMensalidade: (map['valorMensalidade'] as num?)?.toDouble() ?? 250.0,
      diaVencimento: (map['diaVencimento'] as num?)?.toInt() ?? 10,
      statusMensalidade: StatusMensalidadeAluno.values.firstWhere(
        (s) => s.name == map['statusMensalidade'],
        orElse: () => StatusMensalidadeAluno.pago,
      ),
      dataUltimoPagamento: map['dataUltimoPagamento']?.toString(),
      mesReferencia: map['mesReferencia']?.toString() ?? '10/2026',
    );
  }
}

/// Status de Agendamento da Aula
enum StatusAgendamentoAula {
  agendada,
  concluida,
  remarcada,
  cancelada,
}

/// Modelo de Agendamento de Aula Presencial / Consultoria com o Personal
class PersonalAgendamentoAulaModel {
  final String id;
  final String alunoId;
  final String alunoNome;
  final String academiaNome; // ex: "SmartFit Jardins", "Ironberg Alphaville"
  final String data; // YYYY-MM-DD
  final String horarioInicio; // HH:MM ex: "08:00"
  final String horarioFim; // HH:MM ex: "09:00"
  final String tipoAula; // Musculação, Avaliação Física, Consultoria
  final StatusAgendamentoAula status;
  final String? motivoRemarcacao;
  final String? observacao;

  const PersonalAgendamentoAulaModel({
    required this.id,
    required this.alunoId,
    required this.alunoNome,
    required this.academiaNome,
    required this.data,
    required this.horarioInicio,
    required this.horarioFim,
    this.tipoAula = 'Musculação Acompanhada',
    this.status = StatusAgendamentoAula.agendada,
    this.motivoRemarcacao,
    this.observacao,
  });

  PersonalAgendamentoAulaModel copyWith({
    String? id,
    String? alunoId,
    String? alunoNome,
    String? academiaNome,
    String? data,
    String? horarioInicio,
    String? horarioFim,
    String? tipoAula,
    StatusAgendamentoAula? status,
    String? motivoRemarcacao,
    String? observacao,
  }) {
    return PersonalAgendamentoAulaModel(
      id: id ?? this.id,
      alunoId: alunoId ?? this.alunoId,
      alunoNome: alunoNome ?? this.alunoNome,
      academiaNome: academiaNome ?? this.academiaNome,
      data: data ?? this.data,
      horarioInicio: horarioInicio ?? this.horarioInicio,
      horarioFim: horarioFim ?? this.horarioFim,
      tipoAula: tipoAula ?? this.tipoAula,
      status: status ?? this.status,
      motivoRemarcacao: motivoRemarcacao ?? this.motivoRemarcacao,
      observacao: observacao ?? this.observacao,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'alunoId': alunoId,
      'alunoNome': alunoNome,
      'academiaNome': academiaNome,
      'data': data,
      'horarioInicio': horarioInicio,
      'horarioFim': horarioFim,
      'tipoAula': tipoAula,
      'status': status.name,
      'motivoRemarcacao': motivoRemarcacao,
      'observacao': observacao,
    };
  }

  factory PersonalAgendamentoAulaModel.fromMap(Map<String, dynamic> map) {
    return PersonalAgendamentoAulaModel(
      id: map['id']?.toString() ?? '',
      alunoId: map['alunoId']?.toString() ?? '',
      alunoNome: map['alunoNome']?.toString() ?? '',
      academiaNome: map['academiaNome']?.toString() ?? 'Academia Principal',
      data: map['data']?.toString() ?? '',
      horarioInicio: map['horarioInicio']?.toString() ?? '08:00',
      horarioFim: map['horarioFim']?.toString() ?? '09:00',
      tipoAula: map['tipoAula']?.toString() ?? 'Musculação Acompanhada',
      status: StatusAgendamentoAula.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => StatusAgendamentoAula.agendada,
      ),
      motivoRemarcacao: map['motivoRemarcacao']?.toString(),
      observacao: map['observacao']?.toString(),
    );
  }
}
