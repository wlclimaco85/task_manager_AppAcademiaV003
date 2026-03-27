import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

import '../customization/generic_grid_card.dart';
import 'regime_tributario_model.dart';
import 'setor_model.dart';

class ObrigacaoFiscal {
  int? id;
  String codigo;
  String descricao;
  int diaVencimento;
  RegimeTributario? regimeTributario;
  Setor? setor;

  ObrigacaoFiscal({
    this.id,
    required this.codigo,
    required this.descricao,
    required this.diaVencimento,
    this.regimeTributario,
    this.setor,
  });

  factory ObrigacaoFiscal.fromJson(Map<String, dynamic> json) {
    return ObrigacaoFiscal(
      id: json['id'],
      codigo: json['codigo'],
      descricao: json['descricao'],
      diaVencimento: json['diaVencimento'],
      regimeTributario: json['regimeTributarioId'] != null
          ? RegimeTributario.fromJson(json['regimeTributario'])
          : null,
      setor: json['setorId'] != null ? Setor.fromJson(json['setor']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'descricao': descricao,
      'diaVencimento': diaVencimento,
      'regimeTributario': regimeTributario,
      'setor': setor,
    };
  }

  // Classes auxiliares para as entidades relacionadas
  static Future<List<Map<String, dynamic>>> loadFormasPagamento() async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.allRegimetributario,
    );

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map(
            (item) => {'value': item['id'], 'label': item['codigo'].toString()},
          )
          .toList();
    }
    return [];
  }

  // Classes auxiliares para as entidades relacionadas
  static Future<List<Map<String, dynamic>>> loadSetores() async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.allSetores,
    );

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['account'] ?? [];
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

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: "ID",
      fieldName: "id",
      icon: Icons.key,
      isInForm: false,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: true,
    ),
    const FieldConfig(
      label: "Codigo",
      fieldName: "codigo",
      icon: Icons.attach_money,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Descricao",
      fieldName: "descricao",
      icon: Icons.description,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Periodicidade",
      fieldName: "periodicidade",
      icon: Icons.calendar_today,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
      fieldType: FieldType.dropdown,
      dropdownOptions: [
        {'value': 'MENSAL', 'label': 'Mensal'},
        {'value': 'TRIMESTRAL', 'label': 'Trimestral'},
        {'value': 'SEMESTRAL', 'label': 'Semestral'},
        {'value': 'ANUAL', 'label': 'Anual'},
      ], //('MENSAL', 'TRIMESTRAL', 'ANUAL', 'SEMESTRAL'))
      dropdownSelectedValue: 'MENSAL', // Valor padrão selecionado
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: true, // Altere para false se não for obrigatório
    ),
    const FieldConfig(
      label: "Ativo",
      fieldName: "ativo",
      icon: Icons.check_circle,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.boolean,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Gerar Chamado",
      fieldName: "gerChamado",
      icon: Icons.assignment,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.boolean,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Dia Vencimento",
      fieldName: "diaVencimento",
      icon: Icons.calendar_today,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Descricao",
      fieldName: "descricao",
      icon: Icons.info,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
      isInForm: false,
    ),
    FieldConfig(
      label: "Regime Tributario",
      fieldName: "regimeTributario.id",
      displayFieldName: "regimeTributario.codigo",
      icon: Icons.business,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async => await loadFormasPagamento(),
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    FieldConfig(
      label: "Setor Resposnsabilidade",
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
  ];
}
