import 'package:flutter/material.dart';
import '../customization/generic_grid_card.dart';

class Setor {
  int? id;
  String? nome;

  Setor({this.id, this.nome});

  Setor.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nome = json['nome'];
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nome': nome};
  }

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: "Nome",
      fieldName: "nome",
      icon: Icons.apartment,
      isInForm: true,
      isFilterable: true,
    ),
  ];
}
