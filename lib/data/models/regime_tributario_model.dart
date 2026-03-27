import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import '../customization/generic_grid_card.dart';

class RegimeTributario {
  int? id;
  String? codigo;
  String? descricao;
  Map<String, dynamic>?
      aplicativo; // pode virar um model Aplicativo futuramente

  RegimeTributario({this.id, this.codigo, this.descricao, this.aplicativo});

  // Deserialização
  RegimeTributario.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    codigo = json['codigo'];
    descricao = json['descricao'];
    aplicativo = json['aplicativo'];
  }

  // Serialização
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['codigo'] = codigo;
    data['descricao'] = descricao;
    data['aplicativo'] = aplicativo;
    return data;
  }

  static List<RegimeTributario> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map(
          (item) => RegimeTributario.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  // 🔹 Carrega lista de regimes tributários para dropdown
  static Future<List<Map<String, dynamic>>> loadDropdownData() async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.allAplicativos,
    );

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map(
            (item) => {
              'value': item['id'].toString(),
              'label': "${item['nome']}",
            },
          )
          .toList();
    }
    return [];
  }

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: "Código",
      fieldName: "codigo",
      icon: Icons.qr_code,
      isInForm: true,
      isFilterable: true,
      isRequired: true,
    ),
    const FieldConfig(
      label: "Descrição",
      fieldName: "descricao",
      icon: Icons.description,
      isInForm: true,
      isFilterable: true,
      isRequired: true,
    ),
    FieldConfig(
      label: "Aplicativo",
      fieldName: "aplicativo",
      displayFieldName: "aplicativo.nome",
      icon: Icons.apps,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async {
        return await loadDropdownData();
      },
      dropdownValueField: 'value', // Altere para 'value'
      dropdownDisplayField: 'label', // Altere para 'label'
      isRequired: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
  ];
}
