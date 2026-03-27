import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/aplicativo_model.dart';
import 'package:task_manager_flutter/data/models/audit_model.dart';
import 'package:task_manager_flutter/data/models/file_attachment_model.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/models/regime_tributario_model.dart';
import 'package:task_manager_flutter/data/models/pais_model.dart';
import 'package:task_manager_flutter/data/models/estado_model.dart';
import 'package:task_manager_flutter/data/models/cidade_model.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import '../customization/generic_grid_card.dart';

enum Ambiente { HOMOLOGACAO, PRODUCAO }

// --------------------------------------------
// Helper genérico para tratar string ou objeto
// --------------------------------------------
T? parseModel<T>(dynamic value, T Function(Map<String, dynamic>) fromJson) {
  if (value == null) return null;

  if (value is String) {
    // Caso venha só o nome
    return fromJson({'nome': value});
  }

  if (value is Map<String, dynamic>) {
    // Caso venha objeto completo
    return fromJson(value);
  }

  return null;
}

class Empresa {
  int? id;
  String? nome;
  String? razaoSocial;
  String? email;
  String? site;
  String? contato;
  String? emailContato;
  String? telefoneContato;
  String? telefone;
  String? rua;
  String? numero;
  String? cep;
  String? cnpj;
  String? ie;
  Ambiente? ambiente;

  Aplicativo? aplicativo;
  RegimeTributario? regime;
  FileAttachment? fileAttachment;
  PaisModel? pais;
  EstadoModel? estado;
  CidadeModel? cidade;
  Audit? audit;

  Empresa({
    this.id,
    this.nome,
    this.razaoSocial,
    this.email,
    this.site,
    this.contato,
    this.emailContato,
    this.telefoneContato,
    this.telefone,
    this.rua,
    this.numero,
    this.cep,
    this.cnpj,
    this.ie,
    this.ambiente,
    this.aplicativo,
    this.regime,
    this.fileAttachment,
    this.pais,
    this.estado,
    this.cidade,
    this.audit,
  });

  // === Deserialização (fromJson)
  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}'),
      nome: json['nome'],
      razaoSocial: json['razaoSocial'],
      email: json['email'],
      site: json['site'],
      contato: json['contato'],
      emailContato: json['emailContato'],
      telefoneContato: json['telefoneContato'],
      telefone: json['telefone'],
      rua: json['rua'],
      numero: json['numero'],
      cep: json['cep'],
      cnpj: json['cnpj'],
      ie: json['ie'],

      ambiente: json['ambiente'] != null
          ? Ambiente.values.firstWhere(
              (e) =>
                  e.name.toUpperCase() ==
                  json['ambiente'].toString().toUpperCase(),
              orElse: () => Ambiente.HOMOLOGACAO,
            )
          : null,

      aplicativo: json['aplicativo'] != null
          ? Aplicativo.fromJson(json['aplicativo'])
          : null,

      regime: json['regime'] != null
          ? RegimeTributario.fromJson(json['regime'])
          : null,

      fileAttachment: json['fileAttachment'] != null
          ? FileAttachment.fromJson(json['fileAttachment'])
          : null,

      // ------------------------------
      // Tratamento melhorado aqui
      // ------------------------------
      pais: parseModel(json['pais'], (m) => PaisModel.fromJson(m)),
      estado: parseModel(json['estado'], (m) => EstadoModel.fromJson(m)),
      cidade: parseModel(json['cidade'], (m) => CidadeModel.fromJson(m)),

      audit: json['audit'] != null ? Audit.fromJson(json['audit']) : null,
    );
  }

  // === Serialização (toJson)
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['nome'] = nome;
    data['razaoSocial'] = razaoSocial;
    data['email'] = email;
    data['site'] = site;
    data['contato'] = contato;
    data['emailContato'] = emailContato;
    data['telefoneContato'] = telefoneContato;
    data['telefone'] = telefone;
    data['rua'] = rua;
    data['numero'] = numero;
    data['cep'] = cep;
    data['cnpj'] = cnpj;
    data['ie'] = ie;
    data['ambiente'] = ambiente?.name;

    if (aplicativo != null) data['aplicativo'] = aplicativo!.toJson();
    if (regime != null) data['regime'] = regime!.toJson();
    if (fileAttachment != null)
      data['fileAttachment'] = fileAttachment!.toJson();
    if (pais != null) data['pais'] = pais!.toJson();
    if (estado != null) data['estado'] = estado!.toJson();
    if (cidade != null) data['cidade'] = cidade!.toJson();
    if (audit != null) data['audit'] = audit!.toJson();

    return data;
  }

  // === Helper para exibir logo (imagem da empresa)
  Uint8List get logoBytes {
    if (fileAttachment?.fileData != null &&
        fileAttachment!.fileData!.isNotEmpty) {
      return Uint8List.fromList(fileAttachment!.fileData!);
    }
    return Uint8List(0);
  }

  Widget logoWidget({
    double size = 64,
    BoxFit fit = BoxFit.cover,
    Widget? fallback,
  }) {
    if (logoBytes.isNotEmpty) {
      return ClipOval(
        child: Image.memory(
          logoBytes,
          width: size,
          height: size,
          fit: fit,
          errorBuilder: (context, error, stack) {
            return fallback ??
                Icon(Icons.business, color: Colors.grey[600], size: size / 2);
          },
        ),
      );
    }
    return fallback ??
        Icon(Icons.business, color: Colors.grey[600], size: size / 2);
  }

  // === Funções auxiliares (para dropdowns e grids)
  static Future<List<Map<String, dynamic>>> loadAplicativos() async {
    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.allAplicativos);

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map(
            (item) => {
              'value': item['id'].toString(),
              'label': item['nome'] ?? '',
            },
          )
          .toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> loadRegimes() async {
    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.allRegimetributario);

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map(
            (item) => {
              'value': item['id'].toString(),
              'label': item['codigo'] ?? '',
            },
          )
          .toList();
    }
    return [];
  }

  // === Configurações para o grid/form genérico
  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: "Nome",
      fieldName: "nome",
      icon: Icons.business,
      isInForm: true,
      isFilterable: true,
    ),
    const FieldConfig(
      label: "Razão Social",
      fieldName: "razaoSocial",
      icon: Icons.apartment,
      isInForm: true,
      isFilterable: true,
    ),
    const FieldConfig(
      label: "Email",
      fieldName: "email",
      icon: Icons.email,
      isInForm: true,
    ),
    const FieldConfig(
      label: "Telefone",
      fieldName: "telefone",
      icon: Icons.phone,
      isInForm: true,
    ),
    const FieldConfig(
      label: "Contato",
      fieldName: "contato",
      icon: Icons.person,
      isInForm: true,
    ),
    FieldConfig(
      label: "Aplicativo",
      fieldName: "aplicativo",
      displayFieldName: "aplicativo.nome",
      icon: Icons.apps,
      isInForm: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async => await loadAplicativos(),
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: true,
    ),
    FieldConfig(
      label: "Regime Tributário",
      fieldName: "regime",
      displayFieldName: "regime.codigo",
      icon: Icons.balance,
      isInForm: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async => await loadRegimes(),
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: true,
    ),
  ];
}
