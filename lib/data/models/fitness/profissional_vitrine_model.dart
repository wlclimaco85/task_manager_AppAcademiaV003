import 'dart:convert';

/// Categoria do Profissional
enum CategoriaProfissional {
  personal,
  nutricionista,
  ambos,
}

/// Dia da semana com horários de atendimento
class HorarioAtendimentoProfissional {
  final String diaSemana; // Segunda, Terça, Quarta, etc.
  final String horarioInicio; // "06:00"
  final String horarioFim; // "21:00"
  final List<String> horariosDisponiveis; // ["07:00", "08:00", "15:00", "18:00"]
  final List<String> horariosOcupados; // ["09:00", "10:00", "19:00"]

  const HorarioAtendimentoProfissional({
    required this.diaSemana,
    required this.horarioInicio,
    required this.horarioFim,
    this.horariosDisponiveis = const [],
    this.horariosOcupados = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'diaSemana': diaSemana,
      'horarioInicio': horarioInicio,
      'horarioFim': horarioFim,
      'horariosDisponiveis': horariosDisponiveis,
      'horariosOcupados': horariosOcupados,
    };
  }

  factory HorarioAtendimentoProfissional.fromMap(Map<String, dynamic> map) {
    return HorarioAtendimentoProfissional(
      diaSemana: map['diaSemana']?.toString() ?? 'Segunda',
      horarioInicio: map['horarioInicio']?.toString() ?? '06:00',
      horarioFim: map['horarioFim']?.toString() ?? '21:00',
      horariosDisponiveis: (map['horariosDisponiveis'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      horariosOcupados: (map['horariosOcupados'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

/// Academia / Local onde o profissional atende
class AcademiaAtendimentoModel {
  final String id;
  final String nome;
  final String endereco;
  final String bairroCidade;
  final String fotoUrl;

  const AcademiaAtendimentoModel({
    required this.id,
    required this.nome,
    required this.endereco,
    required this.bairroCidade,
    this.fotoUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'endereco': endereco,
      'bairroCidade': bairroCidade,
      'fotoUrl': fotoUrl,
    };
  }

  factory AcademiaAtendimentoModel.fromMap(Map<String, dynamic> map) {
    return AcademiaAtendimentoModel(
      id: map['id']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      endereco: map['endereco']?.toString() ?? '',
      bairroCidade: map['bairroCidade']?.toString() ?? '',
      fotoUrl: map['fotoUrl']?.toString() ?? '',
    );
  }
}

/// Pacote / Plano de Contratação do Profissional
class PacoteContratacaoModel {
  final String id;
  final String titulo;
  final String descricao;
  final double precoMensal;
  final int aulasPorSemana; // ex: 3x por semana ou consultoria 100% online
  final bool isConsultoriaOnline;
  final bool destaque;

  const PacoteContratacaoModel({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.precoMensal,
    this.aulasPorSemana = 3,
    this.isConsultoriaOnline = false,
    this.destaque = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'precoMensal': precoMensal,
      'aulasPorSemana': aulasPorSemana,
      'isConsultoriaOnline': isConsultoriaOnline,
      'destaque': destaque,
    };
  }

  factory PacoteContratacaoModel.fromMap(Map<String, dynamic> map) {
    return PacoteContratacaoModel(
      id: map['id']?.toString() ?? '',
      titulo: map['titulo']?.toString() ?? '',
      descricao: map['descricao']?.toString() ?? '',
      precoMensal: (map['precoMensal'] as num?)?.toDouble() ?? 0.0,
      aulasPorSemana: (map['aulasPorSemana'] as num?)?.toInt() ?? 3,
      isConsultoriaOnline: map['isConsultoriaOnline'] == true,
      destaque: map['destaque'] == true,
    );
  }
}

/// Modelo de Vitrine / Contratação de Profissional (Personal ou Nutricionista)
class ProfissionalVitrineModel {
  final String id;
  final String nome;
  final CategoriaProfissional categoria;
  final String registroProfissional; // CREF 123456-G/SP ou CRN 54321/SP
  final String fotoUrl;
  final String especialidade; // Hipertrofia, Emagrecimento, Bodybuilding, Nutrição Esportiva
  final String bioResumo;
  final double avaliacaoMedia; // 4.9
  final int totalAvaliacoes; // 38
  final int anosExperiencia; // 7
  final String whatsapp; // "(11) 98765-4321"
  final String instagram; // "@personal_pro"
  final double precoMinimoMensal; // a partir de R$ 250/mês
  final List<AcademiaAtendimentoModel> academiasAtendidas;
  final List<HorarioAtendimentoProfissional> gradeHorarios;
  final List<PacoteContratacaoModel> pacotes;
  final bool aceitaNovosAlunos;

  const ProfissionalVitrineModel({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.registroProfissional,
    this.fotoUrl = '',
    required this.especialidade,
    required this.bioResumo,
    this.avaliacaoMedia = 4.9,
    this.totalAvaliacoes = 25,
    this.anosExperiencia = 5,
    required this.whatsapp,
    this.instagram = '',
    required this.precoMinimoMensal,
    required this.academiasAtendidas,
    required this.gradeHorarios,
    required this.pacotes,
    this.aceitaNovosAlunos = true,
  });

  /// Retorna quantos horários livres no total o profissional tem na semana
  int get totalHorariosLivres {
    int total = 0;
    for (var g in gradeHorarios) {
      total += g.horariosDisponiveis.length;
    }
    return total;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'categoria': categoria.name,
      'registroProfissional': registroProfissional,
      'fotoUrl': fotoUrl,
      'especialidade': especialidade,
      'bioResumo': bioResumo,
      'avaliacaoMedia': avaliacaoMedia,
      'totalAvaliacoes': totalAvaliacoes,
      'anosExperiencia': anosExperiencia,
      'whatsapp': whatsapp,
      'instagram': instagram,
      'precoMinimoMensal': precoMinimoMensal,
      'academiasAtendidas': academiasAtendidas.map((a) => a.toMap()).toList(),
      'gradeHorarios': gradeHorarios.map((h) => h.toMap()).toList(),
      'pacotes': pacotes.map((p) => p.toMap()).toList(),
      'aceitaNovosAlunos': aceitaNovosAlunos,
    };
  }

  factory ProfissionalVitrineModel.fromMap(Map<String, dynamic> map) {
    return ProfissionalVitrineModel(
      id: map['id']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      categoria: CategoriaProfissional.values.firstWhere(
        (c) => c.name == map['categoria'],
        orElse: () => CategoriaProfissional.personal,
      ),
      registroProfissional: map['registroProfissional']?.toString() ?? '',
      fotoUrl: map['fotoUrl']?.toString() ?? '',
      especialidade: map['especialidade']?.toString() ?? 'Musculação e Treinamento',
      bioResumo: map['bioResumo']?.toString() ?? '',
      avaliacaoMedia: (map['avaliacaoMedia'] as num?)?.toDouble() ?? 4.9,
      totalAvaliacoes: (map['totalAvaliacoes'] as num?)?.toInt() ?? 20,
      anosExperiencia: (map['anosExperiencia'] as num?)?.toInt() ?? 5,
      whatsapp: map['whatsapp']?.toString() ?? '',
      instagram: map['instagram']?.toString() ?? '',
      precoMinimoMensal:
          (map['precoMinimoMensal'] as num?)?.toDouble() ?? 250.0,
      academiasAtendidas: (map['academiasAtendidas'] as List<dynamic>?)
              ?.map((a) =>
                  AcademiaAtendimentoModel.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
      gradeHorarios: (map['gradeHorarios'] as List<dynamic>?)
              ?.map((h) => HorarioAtendimentoProfissional.fromMap(
                  h as Map<String, dynamic>))
              .toList() ??
          [],
      pacotes: (map['pacotes'] as List<dynamic>?)
              ?.map((p) =>
                  PacoteContratacaoModel.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      aceitaNovosAlunos: map['aceitaNovosAlunos'] != false,
    );
  }
}
