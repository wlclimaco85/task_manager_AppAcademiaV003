import 'dart:convert';

/// Categorias comuns de despesas para o Personal Trainer
class CategoriaContaPagar {
  static const String espacoAcademia = 'Espaço / Academia';
  static const String cref = 'Conselho / CREF';
  static const String equipamentos = 'Equipamentos';
  static const String cursos = 'Cursos / Especializações';
  static const String marketing = 'Marketing / Divulgação';
  static const String transporte = 'Transporte / Combustível';
  static const String outros = 'Outros';

  static const List<String> todas = [
    espacoAcademia,
    cref,
    equipamentos,
    cursos,
    marketing,
    transporte,
    outros,
  ];
}

/// Modelo para Contas a Pagar do Personal Trainer
class PersonalContaPagarModel {
  final String id;
  final String descricao;
  final String categoria;
  final double valor;
  final DateTime dataVencimento;
  final DateTime? dataPagamento;
  final bool pago;
  final String? observacao;

  PersonalContaPagarModel({
    required this.id,
    required this.descricao,
    required this.categoria,
    required this.valor,
    required this.dataVencimento,
    this.dataPagamento,
    this.pago = false,
    this.observacao,
  });

  bool get atrasado {
    if (pago) return false;
    final hoje = DateTime.now();
    final dataLimite = DateTime(dataVencimento.year, dataVencimento.month, dataVencimento.day, 23, 59, 59);
    return hoje.isAfter(dataLimite);
  }

  PersonalContaPagarModel copyWith({
    String? id,
    String? descricao,
    String? categoria,
    double? valor,
    DateTime? dataVencimento,
    DateTime? dataPagamento,
    bool? pago,
    String? observacao,
  }) {
    return PersonalContaPagarModel(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      categoria: categoria ?? this.categoria,
      valor: valor ?? this.valor,
      dataVencimento: dataVencimento ?? this.dataVencimento,
      dataPagamento: dataPagamento ?? this.dataPagamento,
      pago: pago ?? this.pago,
      observacao: observacao ?? this.observacao,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': descricao,
      'categoria': categoria,
      'valor': valor,
      'dataVencimento': dataVencimento.toIso8601String(),
      'dataPagamento': dataPagamento?.toIso8601String(),
      'pago': pago,
      'observacao': observacao,
    };
  }

  factory PersonalContaPagarModel.fromMap(Map<String, dynamic> map) {
    return PersonalContaPagarModel(
      id: map['id']?.toString() ?? '',
      descricao: map['descricao']?.toString() ?? '',
      categoria: map['categoria']?.toString() ?? CategoriaContaPagar.outros,
      valor: (map['valor'] is num) ? (map['valor'] as num).toDouble() : double.tryParse(map['valor']?.toString() ?? '0') ?? 0.0,
      dataVencimento: map['dataVencimento'] != null
          ? DateTime.tryParse(map['dataVencimento'].toString()) ?? DateTime.now()
          : DateTime.now(),
      dataPagamento: map['dataPagamento'] != null
          ? DateTime.tryParse(map['dataPagamento'].toString())
          : null,
      pago: map['pago'] == true,
      observacao: map['observacao']?.toString(),
    );
  }

  String toJson() => json.encode(toMap());

  factory PersonalContaPagarModel.fromJson(String source) =>
      PersonalContaPagarModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
