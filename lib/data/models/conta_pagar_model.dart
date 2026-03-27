import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/utils.dart';
import 'package:task_manager_flutter/data/services/parceiro_caller.dart';
import 'package:task_manager_flutter/data/services/formaPagamento_caller.dart';
import '../customization/generic_grid_card.dart';
import 'audit_model.dart';
import 'empresa_model.dart';
import 'file_attachment_model.dart';
import 'forma_pagamento_model.dart';
import 'parceiro_model.dart';
import 'conta_bancaria_model.dart';

enum StatusConta {
  ABERTO(1, "Aberto"),
  BAIXADA(2, "Baixado"),
  ANTECIPADA(3, "Antecipado"),
  CANCELADA(4, "Cancelado");

  const StatusConta(this.value, this.label);
  final int value;
  final String label;

  static StatusConta fromValue(int value) {
    return values.firstWhere((e) => e.value == value);
  }

  static StatusConta fromString(String name) {
    return values.firstWhere((e) => e.name.toUpperCase() == name.toUpperCase());
  }

  static Map<int, String> get map => Map.fromEntries(
        StatusConta.values.asMap().entries.map(
              (entry) => MapEntry(entry.key + 1, _format(entry.value.name)),
            ),
      );

  static String _format(String name) {
    return name
        .replaceAll("_", " ")
        .toLowerCase()
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

class ContaPagar {
  int? id;
  String descricao;
  double valor;
  DateTime dataVencimento;
  DateTime? dataBaixa;
  double? valorBaixa;
  double? valorMulta;
  double? valorJuros;
  double? valorDesconto;
  StatusConta status;
  Empresa empresa;
  Parceiro? parceiro;
  Parceiro? parceiroDev;
  FileAttachment? file;
  FormaPagamento? formaPagamento;
  Audit audit;
  ContaBancaria? contaBaixa;

  ContaPagar({
    this.id,
    required this.descricao,
    required this.valor,
    required this.dataVencimento,
    this.dataBaixa,
    this.valorBaixa,
    this.valorMulta,
    this.valorJuros,
    this.valorDesconto,
    required this.status,
    required this.empresa,
    this.parceiro,
    this.parceiroDev,
    this.file,
    this.formaPagamento,
    required this.audit,
    this.contaBaixa,
  });

  factory ContaPagar.fromJson(Map<String, dynamic> json) {
    return ContaPagar(
      id: json['id'],
      descricao: json['descricao'],
      valor: json['valor']?.toDouble() ?? 0.0,
      dataVencimento: DateTime.parse(json['dataVencimento']),
      dataBaixa:
          json['dataBaixa'] != null ? DateTime.parse(json['dataBaixa']) : null,
      valorBaixa: json['valorBaixa']?.toDouble(),
      valorMulta: json['valorMulta']?.toDouble(),
      valorJuros: json['valorJuros']?.toDouble(),
      valorDesconto: json['valorDesconto']?.toDouble(),
      status: _parseStatus(json['status']),
      empresa: Empresa.fromJson(json['empresa']),
      parceiro:
          json['parceiro'] != null ? Parceiro.fromJson(json['parceiro']) : null,
      parceiroDev: json['parceiroDev'] != null
          ? Parceiro.fromJson(json['parceiroDev'])
          : null,
      file: json['file'] != null ? FileAttachment.fromJson(json['file']) : null,
      formaPagamento: json['formaPagamento'] != null
          ? FormaPagamento.fromJson(json['formaPagamento'])
          : null,
      audit: Audit.fromJson(json['audit'] ?? {}),
      contaBaixa: json['contaBaixa'] != null
          ? ContaBancaria.fromJson(json['contaBaixa'])
          : null,
    );
  }

  static StatusConta _parseStatus(dynamic status) {
    if (status is int) {
      switch (status) {
        case 0:
          return StatusConta.ABERTO;
        case 1:
          return StatusConta.BAIXADA;
        case 2:
          return StatusConta.CANCELADA;
        default:
          return StatusConta.ABERTO;
      }
    } else if (status is String) {
      switch (status) {
        case 'ABERTA':
          return StatusConta.ABERTO;
        case 'BAIXADA':
          return StatusConta.BAIXADA;
        case 'CANCELADA':
          return StatusConta.CANCELADA;
        default:
          return StatusConta.ABERTO;
      }
    } else {
      return StatusConta.ABERTO;
    }
  }

  int _statusToInt(StatusConta status) {
    switch (status) {
      case StatusConta.ABERTO:
        return 0;
      case StatusConta.BAIXADA:
        return 1;
      case StatusConta.CANCELADA:
        return 2;
      case StatusConta.ANTECIPADA:
        return 3;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descricao': descricao,
      'valor': valor,
      'dataVencimento': dataVencimento.toIso8601String(),
      'dataBaixa': dataBaixa?.toIso8601String(),
      'valorBaixa': valorBaixa,
      'valorMulta': valorMulta,
      'valorJuros': valorJuros,
      'valorDesconto': valorDesconto,
      'status': _statusToInt(status),
      'empresa': empresa.toJson(),
      'parceiro': parceiro?.toJson(),
      'parceiroDev': parceiroDev?.toJson(),
      'file': file?.toJson(),
      'formaPagamento': formaPagamento?.toJson(),
      'audit': audit.toJson(),
      'contaBaixa': contaBaixa?.toJson(),
    };
  }

  static List<FieldConfig> fieldConfigs = [
    FieldConfig(
        label: "Parceiro",
        fieldName: "parceiro.id",
        displayFieldName: "parceiro.nome",
        icon: Icons.business,
        isInForm: true,
        isFilterable: true,
        fieldType: FieldType.dropdown,
        dropdownFutureBuilder: () async =>
            await ParceiroCaller().fetchParceiroDropdown(),
        dropdownValueField: 'value',
        dropdownDisplayField: 'label',
        isRequired: true,
        isVisibleByDefault: true,
        isFixed: false,
        enabled: false,
        dropdownSelectedValue: pegarEmpresaLogada()),
    FieldConfig(
      label: "Fornecedor",
      fieldName: "parceiroDev.id",
      displayFieldName: "parceiroDev.nome",
      icon: Icons.business,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async =>
          await ParceiroCaller().fetchParceiroDropdown(),
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Descrição",
      fieldName: "descricao",
      icon: Icons.description,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Valor",
      fieldName: "valor",
      icon: Icons.attach_money,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
      fieldType: FieldType.number,
    ),
    const FieldConfig(
      label: "Data Vencimento",
      fieldName: "dataVencimento",
      icon: Icons.calendar_today,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
      fieldType: FieldType.date,
    ),
    const FieldConfig(
      label: "Data Baixa",
      fieldName: "dataBaixa",
      icon: Icons.calendar_today,
      isVisibleByDefault: false,
      isFixed: false,
      isInForm: false,
      fieldType: FieldType.date,
    ),
    const FieldConfig(
      label: "Valor Baixa",
      fieldName: "valorBaixa",
      icon: Icons.attach_money,
      isVisibleByDefault: false,
      isFixed: false,
      isInForm: false,
      fieldType: FieldType.number,
    ),
    const FieldConfig(
      label: "Valor Multa",
      fieldName: "valorMulta",
      icon: Icons.attach_money,
      isInForm: true,
      isVisibleByDefault: false,
      isFixed: false,
      fieldType: FieldType.number,
    ),
    const FieldConfig(
      label: "Valor Juros",
      fieldName: "valorJuros",
      icon: Icons.attach_money,
      isInForm: true,
      isVisibleByDefault: false,
      isFixed: false,
      fieldType: FieldType.number,
    ),
    const FieldConfig(
      label: "Valor Desconto",
      fieldName: "valorDesconto",
      icon: Icons.attach_money,
      isInForm: true,
      isVisibleByDefault: false,
      isFixed: false,
      fieldType: FieldType.number,
    ),
    FieldConfig(
      label: "Forma Pagamento",
      fieldName: "formaPagamento.id",
      displayFieldName: "formaPagamento.nome",
      icon: Icons.payment,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async =>
          await FormaPagamentoCaller().fetchFormasPagamentoDropDown(),
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Status",
      fieldName: "status",
      icon: Icons.check_circle,
      isFilterable: true,
      isVisibleByDefault: false,
      isFixed: false,
      fieldType: FieldType.dropdown,
      dropdownOptions: [
        {'value': 0, 'label': 'Aberto'},
        {'value': 1, 'label': 'Baixada '},
        {'value': 2, 'label': 'Cancelado'},
      ],
      dropdownSelectedValue: 0, // Valor padrão selecionado
      enabled: false,
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
    ),
    const FieldConfig(
      label: "Anexo",
      fieldName: "file.id",
      displayFieldName: "file.nome",
      fieldType: FieldType.file,
    ),
  ];
}
