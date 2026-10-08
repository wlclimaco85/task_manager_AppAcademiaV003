import 'dart:convert';

/// Modelo de Alimento (com valores nutricionais para porção de 100g)
class AlimentoModel {
  final String id;
  final String nome;
  final String categoria; // 'proteinas', 'carboidratos', 'gorduras', 'frutas', 'vegetais', 'laticinios', 'suplementos'
  final double porcaoPadraoGramas; // ex: 100g
  final double calorias; // kcal por 100g
  final double proteinas; // g por 100g
  final double carboidratos; // g por 100g
  final double gorduras; // g por 100g
  final double fibras; // g por 100g
  final String? unidadeMedida; // 'g', 'ml', 'unidade', 'fatia', 'colher'

  const AlimentoModel({
    required this.id,
    required this.nome,
    required this.categoria,
    this.porcaoPadraoGramas = 100.0,
    required this.calorias,
    required this.proteinas,
    required this.carboidratos,
    required this.gorduras,
    this.fibras = 0.0,
    this.unidadeMedida = 'g',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'categoria': categoria,
        'porcaoPadraoGramas': porcaoPadraoGramas,
        'calorias': calorias,
        'proteinas': proteinas,
        'carboidratos': carboidratos,
        'gorduras': gorduras,
        'fibras': fibras,
        'unidadeMedida': unidadeMedida,
      };

  factory AlimentoModel.fromMap(Map<String, dynamic> map) => AlimentoModel(
        id: map['id']?.toString() ?? '',
        nome: map['nome']?.toString() ?? '',
        categoria: map['categoria']?.toString() ?? 'geral',
        porcaoPadraoGramas:
            (map['porcaoPadraoGramas'] as num?)?.toDouble() ?? 100.0,
        calorias: (map['calorias'] as num?)?.toDouble() ?? 0.0,
        proteinas: (map['proteinas'] as num?)?.toDouble() ?? 0.0,
        carboidratos: (map['carboidratos'] as num?)?.toDouble() ?? 0.0,
        gorduras: (map['gorduras'] as num?)?.toDouble() ?? 0.0,
        fibras: (map['fibras'] as num?)?.toDouble() ?? 0.0,
        unidadeMedida: map['unidadeMedida']?.toString() ?? 'g',
      );
}

/// Item de Alimento dentro de uma Refeição (calcula macros proporcionais à quantidade)
class ItemRefeicaoModel {
  final String alimentoId;
  final String alimentoNome;
  final double quantidadeGramas;
  final double calorias;
  final double proteinas;
  final double carboidratos;
  final double gorduras;
  final String? observacao;

  const ItemRefeicaoModel({
    required this.alimentoId,
    required this.alimentoNome,
    required this.quantidadeGramas,
    required this.calorias,
    required this.proteinas,
    required this.carboidratos,
    required this.gorduras,
    this.observacao,
  });

  factory ItemRefeicaoModel.calcular({
    required AlimentoModel alimento,
    required double quantidadeGramas,
    String? observacao,
  }) {
    final fator = quantidadeGramas / alimento.porcaoPadraoGramas;
    return ItemRefeicaoModel(
      alimentoId: alimento.id,
      alimentoNome: alimento.nome,
      quantidadeGramas: quantidadeGramas,
      calorias: double.parse((alimento.calorias * fator).toStringAsFixed(1)),
      proteinas: double.parse((alimento.proteinas * fator).toStringAsFixed(1)),
      carboidratos:
          double.parse((alimento.carboidratos * fator).toStringAsFixed(1)),
      gorduras: double.parse((alimento.gorduras * fator).toStringAsFixed(1)),
      observacao: observacao,
    );
  }

  Map<String, dynamic> toMap() => {
        'alimentoId': alimentoId,
        'alimentoNome': alimentoNome,
        'quantidadeGramas': quantidadeGramas,
        'calorias': calorias,
        'proteinas': proteinas,
        'carboidratos': carboidratos,
        'gorduras': gorduras,
        'observacao': observacao,
      };

  factory ItemRefeicaoModel.fromMap(Map<String, dynamic> map) =>
      ItemRefeicaoModel(
        alimentoId: map['alimentoId']?.toString() ?? '',
        alimentoNome: map['alimentoNome']?.toString() ?? '',
        quantidadeGramas:
            (map['quantidadeGramas'] as num?)?.toDouble() ?? 100.0,
        calorias: (map['calorias'] as num?)?.toDouble() ?? 0.0,
        proteinas: (map['proteinas'] as num?)?.toDouble() ?? 0.0,
        carboidratos: (map['carboidratos'] as num?)?.toDouble() ?? 0.0,
        gorduras: (map['gorduras'] as num?)?.toDouble() ?? 0.0,
        observacao: map['observacao']?.toString(),
      );
}

/// Refeição (ex: Café da Manhã, Almoço, Jantar, Pré-Treino)
class RefeicaoModel {
  final String id;
  final String nome;
  final String horario; // '07:30', '12:30', etc.
  final List<ItemRefeicaoModel> itens;

  const RefeicaoModel({
    required this.id,
    required this.nome,
    required this.horario,
    required this.itens,
  });

  double get totalCalorias =>
      itens.fold(0.0, (acc, item) => acc + item.calorias);
  double get totalProteinas =>
      itens.fold(0.0, (acc, item) => acc + item.proteinas);
  double get totalCarboidratos =>
      itens.fold(0.0, (acc, item) => acc + item.carboidratos);
  double get totalGorduras =>
      itens.fold(0.0, (acc, item) => acc + item.gorduras);

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'horario': horario,
        'itens': itens.map((e) => e.toMap()).toList(),
      };

  factory RefeicaoModel.fromMap(Map<String, dynamic> map) => RefeicaoModel(
        id: map['id']?.toString() ?? '',
        nome: map['nome']?.toString() ?? '',
        horario: map['horario']?.toString() ?? '12:00',
        itens: (map['itens'] as List<dynamic>?)
                ?.map((e) =>
                    ItemRefeicaoModel.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

/// Plano / Protocolo de Dieta
class DietaProtocoloModel {
  final String id;
  final String alunoId;
  final String titulo; // ex: "Cutting Agressivo 2000kcal", "Bulking Limpo 3200kcal"
  final String objetivo; // 'emagrecimento', 'hipertrofia', 'manutencao', 'recomposicao'
  final double caloriasMeta;
  final double proteinasMeta;
  final double carboidratosMeta;
  final double gordurasMeta;
  final String dataInicio; // 'YYYY-MM-DD'
  final String? dataFim; // 'YYYY-MM-DD'
  final bool ativa;
  final List<RefeicaoModel> refeicoes;
  final String? observacoes;

  const DietaProtocoloModel({
    required this.id,
    required this.alunoId,
    required this.titulo,
    required this.objetivo,
    required this.caloriasMeta,
    required this.proteinasMeta,
    required this.carboidratosMeta,
    required this.gordurasMeta,
    required this.dataInicio,
    this.dataFim,
    this.ativa = true,
    required this.refeicoes,
    this.observacoes,
  });

  double get totalCaloriasReal =>
      refeicoes.fold(0.0, (acc, r) => acc + r.totalCalorias);
  double get totalProteinasReal =>
      refeicoes.fold(0.0, (acc, r) => acc + r.totalProteinas);
  double get totalCarboidratosReal =>
      refeicoes.fold(0.0, (acc, r) => acc + r.totalCarboidratos);
  double get totalGordurasReal =>
      refeicoes.fold(0.0, (acc, r) => acc + r.totalGorduras);

  Map<String, dynamic> toMap() => {
        'id': id,
        'alunoId': alunoId,
        'titulo': titulo,
        'objetivo': objetivo,
        'caloriasMeta': caloriasMeta,
        'proteinasMeta': proteinasMeta,
        'carboidratosMeta': carboidratosMeta,
        'gordurasMeta': gordurasMeta,
        'dataInicio': dataInicio,
        'dataFim': dataFim,
        'ativa': ativa,
        'refeicoes': refeicoes.map((e) => e.toMap()).toList(),
        'observacoes': observacoes,
      };

  factory DietaProtocoloModel.fromMap(Map<String, dynamic> map) =>
      DietaProtocoloModel(
        id: map['id']?.toString() ?? '',
        alunoId: map['alunoId']?.toString() ?? '',
        titulo: map['titulo']?.toString() ?? 'Dieta Personalizada',
        objetivo: map['objetivo']?.toString() ?? 'hipertrofia',
        caloriasMeta: (map['caloriasMeta'] as num?)?.toDouble() ?? 2000.0,
        proteinasMeta: (map['proteinasMeta'] as num?)?.toDouble() ?? 150.0,
        carboidratosMeta:
            (map['carboidratosMeta'] as num?)?.toDouble() ?? 200.0,
        gordurasMeta: (map['gordurasMeta'] as num?)?.toDouble() ?? 60.0,
        dataInicio: map['dataInicio']?.toString() ??
            DateTime.now().toIso8601String().substring(0, 10),
        dataFim: map['dataFim']?.toString(),
        ativa: map['ativa'] != false,
        refeicoes: (map['refeicoes'] as List<dynamic>?)
                ?.map((e) => RefeicaoModel.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        observacoes: map['observacoes']?.toString(),
      );
}

/// Modelo de Medicamento / Hormônio / Ciclo / Protetor
class MedicamentoProtocoloModel {
  final String id;
  final String alunoId;
  final String nomeComposto; // ex: "Enantato de Testosterona", "Oxandrolona", "Anastrozol", "Silimarina"
  final String dosagem; // ex: "250mg", "20mg", "0.5mg"
  final String frequencia; // ex: "1x na semana", "DSDN", "12 em 12 horas", "TSD"
  final String viaAdministracao; // 'Intramuscular', 'Oral', 'Subcutânea', 'Tópica'
  final String categoria; // 'ergogenico_ciclo', 'tpc_protetor', 'manipulado_farmacia', 'geral'
  final String dataInicio; // 'YYYY-MM-DD'
  final String? dataFim; // 'YYYY-MM-DD'
  final bool ativo;
  final String? horario; // '08:00', 'Noite'
  final String? observacoes; // 'Tomar junto com refeição com gordura'

  const MedicamentoProtocoloModel({
    required this.id,
    required this.alunoId,
    required this.nomeComposto,
    required this.dosagem,
    required this.frequencia,
    this.viaAdministracao = 'Oral',
    required this.categoria,
    required this.dataInicio,
    this.dataFim,
    this.ativo = true,
    this.horario,
    this.observacoes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'alunoId': alunoId,
        'nomeComposto': nomeComposto,
        'dosagem': dosagem,
        'frequencia': frequencia,
        'viaAdministracao': viaAdministracao,
        'categoria': categoria,
        'dataInicio': dataInicio,
        'dataFim': dataFim,
        'ativo': ativo,
        'horario': horario,
        'observacoes': observacoes,
      };

  factory MedicamentoProtocoloModel.fromMap(Map<String, dynamic> map) =>
      MedicamentoProtocoloModel(
        id: map['id']?.toString() ?? '',
        alunoId: map['alunoId']?.toString() ?? '',
        nomeComposto: map['nomeComposto']?.toString() ?? '',
        dosagem: map['dosagem']?.toString() ?? '',
        frequencia: map['frequencia']?.toString() ?? '1x ao dia',
        viaAdministracao: map['viaAdministracao']?.toString() ?? 'Oral',
        categoria: map['categoria']?.toString() ?? 'geral',
        dataInicio: map['dataInicio']?.toString() ??
            DateTime.now().toIso8601String().substring(0, 10),
        dataFim: map['dataFim']?.toString(),
        ativo: map['ativo'] != false,
        horario: map['horario']?.toString(),
        observacoes: map['observacoes']?.toString(),
      );
}

/// Modelo de Suplementação
class SuplementoProtocoloModel {
  final String id;
  final String alunoId;
  final String nome; // ex: "Creatina Monohidratada", "Whey Protein Isolado", "Ômega 3", "Beta Alanina"
  final String dosagem; // ex: "5g", "30g (1 scoop)", "2 cápsulas"
  final String horario; // 'Pós-Treino', 'Jejum', 'Antes de Dormir', 'Pré-Treino'
  final String dataInicio; // 'YYYY-MM-DD'
  final String? dataFim; // 'YYYY-MM-DD'
  final bool ativo;
  final String? observacoes;

  const SuplementoProtocoloModel({
    required this.id,
    required this.alunoId,
    required this.nome,
    required this.dosagem,
    required this.horario,
    required this.dataInicio,
    this.dataFim,
    this.ativo = true,
    this.observacoes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'alunoId': alunoId,
        'nome': nome,
        'dosagem': dosagem,
        'horario': horario,
        'dataInicio': dataInicio,
        'dataFim': dataFim,
        'ativo': ativo,
        'observacoes': observacoes,
      };

  factory SuplementoProtocoloModel.fromMap(Map<String, dynamic> map) =>
      SuplementoProtocoloModel(
        id: map['id']?.toString() ?? '',
        alunoId: map['alunoId']?.toString() ?? '',
        nome: map['nome']?.toString() ?? '',
        dosagem: map['dosagem']?.toString() ?? '',
        horario: map['horario']?.toString() ?? 'Pós-Treino',
        dataInicio: map['dataInicio']?.toString() ??
            DateTime.now().toIso8601String().substring(0, 10),
        dataFim: map['dataFim']?.toString(),
        ativo: map['ativo'] != false,
        observacoes: map['observacoes']?.toString(),
      );
}

/// Evento na Linha do Tempo Unificada (Timeline Fitness 360)
class TimelineFitnessEventModel {
  final DateTime data;
  final String tipo; // 'avaliacao_fisica', 'inicio_dieta', 'fim_dieta', 'inicio_medicamento', 'fim_medicamento', 'inicio_suplemento'
  final String titulo;
  final String descricao;
  final double? pesoKg;
  final double? percentualGordura;
  final String? tagCorHex;

  const TimelineFitnessEventModel({
    required this.data,
    required this.tipo,
    required this.titulo,
    required this.descricao,
    this.pesoKg,
    this.percentualGordura,
    this.tagCorHex,
  });
}
