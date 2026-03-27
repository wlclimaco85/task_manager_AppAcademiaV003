import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

import '../customization/generic_grid_card.dart';
import 'empresa_model.dart';
import 'login_model.dart';
import 'parceiro_model.dart';
import 'setor_model.dart';

enum StatusChamadoEnum {
  ABERTO(1, "Aberto"),
  EM_ANDAMENTO(2, "Em Andamento"),
  FECHADO(3, "Fechado"),
  CANCELADO(4, "Cancelado"),
  AGUARDANDO_CLIENTE(5, "Aguardando Retorno Cliente"),
  BLOQUEADO(6, "Bloqueado");

  const StatusChamadoEnum(this.value, this.label);
  final int value;
  final String label;

  static StatusChamadoEnum fromValue(int value) {
    return values.firstWhere((e) => e.value == value);
  }

  static StatusChamadoEnum fromString(String name) {
    return values.firstWhere((e) => e.name.toUpperCase() == name.toUpperCase());
  }

  static Map<int, String> get map => Map.fromEntries(
        StatusChamadoEnum.values.asMap().entries.map(
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

enum PrioridadeChamadoEnum {
  BAIXA(1, "Baixa"),
  MEDIA(2, "Média"),
  ALTA(3, "Alta"),
  URGENTE(4, "Urgente");

  const PrioridadeChamadoEnum(this.value, this.label);
  final int value;
  final String label;

  static PrioridadeChamadoEnum fromValue(int value) {
    return values.firstWhere((e) => e.value == value);
  }

  static PrioridadeChamadoEnum fromString(String name) {
    return values.firstWhere((e) => e.name.toUpperCase() == name.toUpperCase());
  }

  static Map<int, String> get map => Map.fromEntries(
        PrioridadeChamadoEnum.values.asMap().entries.map(
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

class Chamado {
  int? id;
  String titulo;
  String descricao;
  String? motivoFechamento;
  StatusChamadoEnum status;
  PrioridadeChamadoEnum prioridade;
  Empresa empresa;
  Login? usuarioAbertura;
  Login? usuarioFechamento;
  Parceiro? parceiro;
  Setor? setor;
  DateTime dataAbertura;
  DateTime? dataFechamento;

  Chamado({
    this.id,
    required this.titulo,
    required this.descricao,
    this.motivoFechamento,
    required this.status,
    required this.prioridade,
    required this.empresa,
    this.usuarioAbertura,
    this.usuarioFechamento,
    this.parceiro,
    this.setor,
    required this.dataAbertura,
    this.dataFechamento,
  });

  factory Chamado.fromJson(Map<String, dynamic> json) {
    return Chamado(
      id: json['id'],
      titulo: json['titulo'],
      descricao: json['descricao'],
      motivoFechamento: json['motivoFechamento'],
      status: StatusChamadoEnum.fromString(json['status']),
      prioridade: PrioridadeChamadoEnum.fromString(json['prioridade']),
      empresa: Empresa.fromJson(json['empresa']),
      usuarioAbertura: json['usuarioAbertura'] != null
          ? Login.fromJson(json['usuarioAbertura'])
          : null,
      usuarioFechamento: json['usuarioFechamento'] != null
          ? Login.fromJson(json['usuarioFechamento'])
          : null,
      parceiro:
          json['parceiro'] != null ? Parceiro.fromJson(json['parceiro']) : null,
      setor: json['setor'] != null ? Setor.fromJson(json['setor']) : null,
      dataAbertura: json['dataAbertura'] != null
          ? DateTime.parse(json['dataAbertura'])
          : DateTime.now(),
      dataFechamento: json['dataFechamento'] != null
          ? DateTime.parse(json['dataFechamento'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'motivoFechamento': motivoFechamento,
      'status': status.value,
      'prioridade': prioridade.value,
      'empresa': empresa.toJson(),
      'usuarioAbertura': usuarioAbertura?.toJson(),
      'usuarioFechamento': usuarioFechamento?.toJson(),
      'parceiro': parceiro?.toJson(),
      'setor': setor?.toJson(),
      'dataAbertura': dataAbertura.toIso8601String(),
      'dataFechamento': dataFechamento?.toIso8601String(),
    };
  }

  // Classes auxiliares para as entidades relacionadas
  static Future<List<Map<String, dynamic>>> loadSetores() async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.allSetores,
    );

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map(
            (item) => {
              'value': item['id'],
              'label': item['descricao'].toString(),
            },
          )
          .toList();
    }
    return [];
  }

  static List<Map<String, dynamic>> getStatusDropdownItems() {
    return StatusChamadoEnum.values
        .map((e) => {'value': e.value, 'label': e.label})
        .toList();
  }

  static List<Map<String, dynamic>> getPrioridadeDropdownItems() {
    return PrioridadeChamadoEnum.values
        .map((e) => {'value': e.value, 'label': e.label})
        .toList();
  }

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: "Título",
      fieldName: "titulo",
      icon: Icons.title,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: true,
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
      label: "Status",
      fieldName: "status",
      icon: Icons.info,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
      fieldType: FieldType.dropdown,
      dropdownOptions: [
        {'value': 'ABERTO', 'label': 'Aberto'},
        {'value': 'EM_ANDAMENTO', 'label': 'Em Andamento'},
        {'value': 'FECHADO', 'label': 'Fechado'},
        {'value': 'CANCELADO', 'label': 'Cancelado'},
      ], //('MENSAL', 'TRIMESTRAL', 'ANUAL', 'SEMESTRAL'))
      dropdownSelectedValue: 'ABERTO', // Valor padrão selecionado
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      enabled: false,
    ),
    const FieldConfig(
      label: "Prioridade",
      fieldName: "prioridade",
      icon: Icons.priority_high,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
      fieldType: FieldType.dropdown,
      dropdownOptions: [
        {'value': 'BAIXA', 'label': 'Baixa'},
        {'value': 'MEDIA', 'label': 'Media'},
        {'value': 'ALTA', 'label': 'Alta'},
        {'value': 'URGENTE', 'label': 'Urgente'},
      ],
      dropdownSelectedValue: 0, // Valor padrão selecionado
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
    ),
    FieldConfig(
      label: "Setor",
      fieldName: "setor.id",
      displayFieldName: "setor.descricao",
      icon: Icons.business,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async => await loadSetores(),
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Motivo Fechamento",
      fieldName: "motivoFechamento",
      icon: Icons.close,
      isInForm: false,
      isVisibleByDefault: false,
      isFixed: false,
      fieldType: FieldType.text,
    ),
  ];
}
