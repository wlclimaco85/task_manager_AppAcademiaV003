import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/customization/generic_grid_card.dart';
import 'empresa_model.dart';

class ContaBancaria {
  int? id;
  String? banco;
  String? agencia;
  String? numero;
  String? descricao;
  double? saldoAtual;
  Empresa empresa;
  int? parceiro;
  bool ativo;

  ContaBancaria({
    this.id,
    this.banco,
    this.agencia,
    this.numero,
    this.descricao,
    this.saldoAtual,
    required this.empresa,
    this.parceiro,
    this.ativo = true,
  });

  factory ContaBancaria.fromJson(Map<String, dynamic> json) {
    return ContaBancaria(
      id: json['id'],
      banco: json['banco'],
      agencia: json['agencia'],
      numero: json['numero'],
      descricao: json['descricao'],
      saldoAtual: (json['saldoAtual'] ?? 0).toDouble(),
      empresa: Empresa.fromJson(json['empresa']),
      parceiro: json['parceiroId'] ?? 1,
      ativo: json['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'banco': banco,
      'agencia': agencia,
      'numero': numero,
      'descricao': descricao,
      'saldoAtual': saldoAtual,
      'empresa': empresa,
      if (parceiro != null) 'parceiro': parceiro!,
      'ativo': ativo,
    };
  }

  // ⚙️ Configuração do grid e formulários
  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: "Banco",
      fieldName: "banco",
      icon: Icons.account_balance,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: true,
      fieldType: FieldType.text,
    ),
    const FieldConfig(
      label: "Agência",
      fieldName: "agencia",
      icon: Icons.business,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
      fieldType: FieldType.text,
    ),
    const FieldConfig(
      label: "Número",
      fieldName: "numero",
      icon: Icons.numbers,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
      fieldType: FieldType.text,
    ),
    const FieldConfig(
      label: "Descrição",
      fieldName: "descricao",
      icon: Icons.description,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
      fieldType: FieldType.text,
    ),
    const FieldConfig(
      label: "Saldo Atual",
      fieldName: "saldoAtual",
      icon: Icons.monetization_on,
      isInForm: false,
      isVisibleByDefault: true,
      isFixed: false,
      fieldType: FieldType.currency,
    ),
    const FieldConfig(
      label: "Ativo",
      fieldName: "ativo",
      icon: Icons.toggle_on,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
      fieldType: FieldType.boolean,
    ),
  ];
}
