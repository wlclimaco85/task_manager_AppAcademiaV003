// lib/data/models/telas_model.dart
// ------------------------------------------------------------
// Modelo de tela (TelaConfig) + campos (TelaField) + ações (TelaAction)
// - Suporta actions vindas do banco (lista "actions")
// - Parser resiliente para estruturas com "data", "dados", etc.
// - Enum TelaFieldType (modelo) separado do FieldType do UI para evitar conflitos.
// ------------------------------------------------------------

import 'package:flutter/material.dart';

/// Enum de tipos de campo vindo do servidor.
/// (Separado do FieldType do grid para evitar colisão de tipos.)
enum TelaFieldType {
  text,
  number,
  email,
  date,
  multiline,
  dropdown,
  boolean,
  file,
  password,
  phone,
  cpf,
  cnpj,
  currency,
  percentage,
  url,
}

class DropdownOption {
  final dynamic optionValue;
  final String? optionLabel;

  DropdownOption({required this.optionValue, this.optionLabel});

  factory DropdownOption.fromJson(Map<String, dynamic> json) {
    return DropdownOption(
      optionValue: json['optionValue'] ?? json['value'] ?? json['id'],
      optionLabel: json['optionLabel'] ?? json['label'] ?? json['name'],
    );
  }

  Map<String, dynamic> toJson() => {
        'optionValue': optionValue,
        'optionLabel': optionLabel,
      };
}

class TelaField {
  final String label;
  final String fieldName;
  final String? displayFieldName;

  final bool isFilterable;
  final bool isInForm;
  final bool showInInsert; // para filtrar no insert
  final bool showInUpdate; // para filtrar no update
  final bool isSortable;

  final int flex;
  final int maxLines;

  final String? icon; // nome textual recebido do back
  final IconData? iconData; // derivado do "icon", se quiser usar direto
  final TelaFieldType fieldType;

  final List<DropdownOption> dropdownOptions;
  final String? dropdownEndpoint;
  final String dropdownValueField;
  final String dropdownDisplayField;
  final dynamic dropdownSelectedValue;

  final bool isRequired;
  final bool isVisibleByDefault;
  final bool isFixed; // não pode ocultar no selector
  final bool enabled;
  final dynamic defaultValue;

  // arquivo
  final List<String> allowedExtensions;
  final bool allowMultipleFiles;
  final int maxFileSize;
  final String fileFieldName;

  // data
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String dateFormat;

  final bool showInCard;

  TelaField({
    required this.label,
    required this.fieldName,
    this.displayFieldName,
    this.isFilterable = true,
    this.isInForm = true,
    this.showInInsert = true,
    this.showInUpdate = true,
    this.isSortable = true,
    this.flex = 1,
    this.maxLines = 1,
    this.icon,
    this.iconData,
    this.fieldType = TelaFieldType.text,
    this.dropdownOptions = const [],
    this.dropdownEndpoint,
    this.dropdownValueField = 'value',
    this.dropdownDisplayField = 'label',
    this.dateFormat = 'dd/MM/yyyy',
    this.firstDate,
    this.lastDate,
    this.defaultValue,
    this.dropdownSelectedValue,
    this.isRequired = false,
    this.isVisibleByDefault = true,
    this.isFixed = false,
    this.enabled = true,
    this.allowedExtensions = const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    this.allowMultipleFiles = false,
    this.maxFileSize = 5 * 1024 * 1024,
    this.fileFieldName = 'file',
    this.showInCard = true,
  });

  factory TelaField.fromJson(Map<String, dynamic> json) {
    // Backend manda fieldType como string ("text", "dropdown", etc.)
    // mas o cache local pode ter salvo como índice inteiro
    TelaFieldType tft;
    final rawType = json['fieldType'];
    if (rawType is int) {
      tft = rawType >= 0 && rawType < TelaFieldType.values.length
          ? TelaFieldType.values[rawType]
          : TelaFieldType.text;
    } else if (rawType is String) {
      tft = TelaFieldType.values.firstWhere(
        (e) => e.name.toLowerCase() == rawType.toLowerCase(),
        orElse: () => TelaFieldType.text,
      );
    } else {
      tft = TelaFieldType.text;
    }

    final iconName = json['icon']?.toString();
    return TelaField(
      label: json['label']?.toString() ?? json['titulo']?.toString() ?? 'Campo',
      fieldName:
          json['fieldName']?.toString() ?? json['nome']?.toString() ?? '',
      displayFieldName: json['displayFieldName']?.toString(),
      isFilterable:
          json['isFilterable'] == null ? true : (json['isFilterable'] == true),
      isInForm:
          json['isInForm'] == null ? true : (json['isInForm'] as bool? ?? true),
      showInInsert: json['showInInsert'] == null
          ? true
          : (json['showInInsert'] as bool? ?? true),
      showInUpdate: json['showInUpdate'] == null
          ? true
          : (json['showInUpdate'] as bool? ?? true),
      isSortable: json['isSortable'] == null
          ? true
          : (json['isSortable'] as bool? ?? true),
      flex: json['flex'] is int ? json['flex'] as int : 1,
      maxLines: json['maxLines'] is int ? json['maxLines'] as int : 1,
      icon: iconName,
      iconData: _iconFromName(iconName),
      fieldType: tft,
      dropdownOptions: (json['dropdownOptions'] is List
              ? (json['dropdownOptions'] as List)
              : const [])
          .whereType<Map>()
          .map((e) => DropdownOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      dropdownEndpoint: json['dropdownEndpoint']?.toString(),
      dropdownValueField: json['dropdownValueField']?.toString() ?? 'value',
      dropdownDisplayField: json['dropdownDisplayField']?.toString() ?? 'label',
      dropdownSelectedValue: json['dropdownSelectedValue'],
      isRequired: json['isRequired'] == true,
      isVisibleByDefault: json['isVisibleByDefault'] ?? true,
      isFixed: json['isFixed'] == true,
      enabled:
          json['enabled'] == null ? true : (json['enabled'] as bool? ?? true),
      defaultValue: json['defaultValue'],
      allowedExtensions: (json['allowedExtensions'] is List
              ? (json['allowedExtensions'] as List)
              : const [])
          .whereType<String>()
          .toList(),
      allowMultipleFiles: json['allowMultipleFiles'] == true,
      maxFileSize:
          json['maxFileSize'] is int ? json['maxFileSize'] : 5 * 1024 * 1024,
      fileFieldName: json['fileFieldName']?.toString() ?? 'file',
      firstDate: json['firstDate'] != null
          ? DateTime.tryParse(json['firstDate'].toString())
          : null,
      lastDate: json['lastDate'] != null
          ? DateTime.tryParse(json['lastDate'].toString())
          : null,
      dateFormat: json['dateFormat']?.toString() ?? 'dd/MM/yyyy',
      showInCard: json['showInCard'] == null
          ? true
          : (json['showInCard'] as bool? ?? true),
    );
  }

  static IconData? _iconFromName(String? name) {
    if (name == null) return null;
    switch (name) {
      case 'add':
        return Icons.add;
      case 'edit':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'visibility':
      case 'view':
        return Icons.visibility;
      case 'file':
        return Icons.attach_file;
      case 'email':
        return Icons.email;
      case 'phone':
        return Icons.phone;
      case 'calendar':
        return Icons.calendar_today;
      default:
        return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'fieldName': fieldName,
        'displayFieldName': displayFieldName,
        'isFilterable': isFilterable,
        'isInForm': isInForm,
        'showInInsert': showInInsert,
        'showInUpdate': showInUpdate,
        'isSortable': isSortable,
        'flex': flex,
        'maxLines': maxLines,
        'icon': icon,
        'fieldType': fieldType.index,
        'dropdownOptions': dropdownOptions.map((e) => e.toJson()).toList(),
        'dropdownEndpoint': dropdownEndpoint,
        'dropdownValueField': dropdownValueField,
        'dropdownDisplayField': dropdownDisplayField,
        'dropdownSelectedValue': dropdownSelectedValue,
        'isRequired': isRequired,
        'isVisibleByDefault': isVisibleByDefault,
        'isFixed': isFixed,
        'enabled': enabled,
        'defaultValue': defaultValue,
        'allowedExtensions': allowedExtensions,
        'allowMultipleFiles': allowMultipleFiles,
        'maxFileSize': maxFileSize,
        'fileFieldName': fileFieldName,
        'firstDate': firstDate?.toIso8601String(),
        'lastDate': lastDate?.toIso8601String(),
        'dateFormat': dateFormat,
        'showInCard': showInCard,
      };
}

class TelaAction {
  final String label;
  final String? icon; // nome textual
  final String method; // GET/POST/PUT/DELETE
  final String endpoint; // pode conter :id
  final String? confirmMessage; // opcional (se não vier, usa padrão)

  // opcional (se quiser permissionamento por ação):
  final String? requiredPermission; // ex: "approve", "close" etc.

  TelaAction({
    required this.label,
    this.icon,
    required this.method,
    required this.endpoint,
    this.confirmMessage,
    this.requiredPermission,
  });

  factory TelaAction.fromJson(Map<String, dynamic> json) {
    return TelaAction(
      label: json['label']?.toString() ?? 'Ação',
      icon: json['icon']?.toString(),
      method: (json['method']?.toString() ?? 'GET').toUpperCase(),
      endpoint: json['endpoint']?.toString() ?? '',
      confirmMessage: json['confirmMessage']?.toString(),
      requiredPermission: json['requiredPermission']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'icon': icon,
        'method': method,
        'endpoint': endpoint,
        'confirmMessage': confirmMessage,
        'requiredPermission': requiredPermission,
      };
}

class TelaConfig {
  final int id;
  final String nome;
  final String titulo;

  final String fetchEndpoint;
  final String createEndpoint;
  final String updateEndpoint; // ':id'
  final String deleteEndpoint; // ':id'

  final List<TelaField> fields;

  final String idFieldName;
  final String? dateFieldName;
  final String? storageKey;

  final bool enableSearch;
  final bool enableDebugMode;
  final bool useUserBannerAppBar;

  // 🔥 novas ações vindas do banco
  final List<TelaAction> actions;

  TelaConfig({
    required this.id,
    required this.nome,
    required this.titulo,
    required this.fetchEndpoint,
    required this.createEndpoint,
    required this.updateEndpoint,
    required this.deleteEndpoint,
    required this.fields,
    this.idFieldName = 'id',
    this.dateFieldName,
    this.storageKey,
    this.enableSearch = true,
    this.enableDebugMode = false,
    this.useUserBannerAppBar = false,
    this.actions = const [],
  });

  factory TelaConfig.fromJson(Map<String, dynamic> raw) {
    // aceita tanto "direto" quanto {data: {...}} ou {dados: {...}}
    final json = _unwrapDataOrDados(raw);

    final fieldsJson = (json['fields'] is List ? json['fields'] as List : [])
        .whereType<Map>()
        .map((e) => TelaField.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final actionsJson =
        (json['actions'] is List ? json['actions'] as List : const [])
            .whereType<Map>()
            .map((e) => TelaAction.fromJson(Map<String, dynamic>.from(e)))
            .toList();

    return TelaConfig(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      nome: json['nome']?.toString() ?? 'tela',
      titulo: json['titulo']?.toString() ?? json['title']?.toString() ?? 'Tela',
      fetchEndpoint: json['fetchEndpoint']?.toString() ?? '',
      createEndpoint: json['createEndpoint']?.toString() ?? '',
      updateEndpoint: json['updateEndpoint']?.toString() ?? '',
      deleteEndpoint: json['deleteEndpoint']?.toString() ?? '',
      fields: fieldsJson,
      idFieldName: json['idFieldName']?.toString() ?? 'id',
      dateFieldName: json['dateFieldName']?.toString(),
      storageKey: json['storageKey']?.toString(),
      enableSearch: json['enableSearch'] == null
          ? true
          : (json['enableSearch'] as bool? ?? true),
      enableDebugMode: json['enableDebugMode'] == true,
      useUserBannerAppBar: json['useUserBannerAppBar'] == true,
      actions: actionsJson,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'titulo': titulo,
        'fetchEndpoint': fetchEndpoint,
        'createEndpoint': createEndpoint,
        'updateEndpoint': updateEndpoint,
        'deleteEndpoint': deleteEndpoint,
        'fields': fields.map((e) => e.toJson()).toList(),
        'idFieldName': idFieldName,
        'dateFieldName': dateFieldName,
        'storageKey': storageKey,
        'enableSearch': enableSearch,
        'enableDebugMode': enableDebugMode,
        'useUserBannerAppBar': useUserBannerAppBar,
        'actions': actions.map((e) => e.toJson()).toList(),
      };

  static Map<String, dynamic> _unwrapDataOrDados(Map<String, dynamic> raw) {
    dynamic cur = raw;
    if (cur is Map && (cur['data'] != null || cur['dados'] != null)) {
      final sub = cur['data'] ?? cur['dados'];
      if (sub is Map) return Map<String, dynamic>.from(sub);
      if (sub is List && sub.isNotEmpty && sub.first is Map) {
        return Map<String, dynamic>.from(sub.first as Map);
      }
    }
    if (cur is Map && cur.containsKey('content') && cur['content'] is Map) {
      return Map<String, dynamic>.from(cur['content']);
    }
    if (cur is Map) return Map<String, dynamic>.from(cur);
    return <String, dynamic>{};
  }
}

class UserFieldPreference {
  final int id;
  final int userId;
  final int telaId;
  final String fieldName;
  final bool isVisible;
  final double? widthPreference;
  final int orderPreference;

  UserFieldPreference({
    required this.id,
    required this.userId,
    required this.telaId,
    required this.fieldName,
    required this.isVisible,
    this.widthPreference,
    this.orderPreference = 0,
  });

  factory UserFieldPreference.fromJson(Map<String, dynamic> json) {
    return UserFieldPreference(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      telaId: json['telaId'] ??
          (json['tela'] != null ? json['tela']['id'] ?? 0 : 0),
      fieldName: json['fieldName'] ?? '',
      isVisible: json['isVisible'] ?? true,
      widthPreference: json['widthPreference']?.toDouble(),
      orderPreference: json['orderPreference'] ?? 0,
    );
  }
}
