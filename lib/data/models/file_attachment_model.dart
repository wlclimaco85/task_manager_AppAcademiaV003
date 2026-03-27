import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/aplicativo_model.dart';
import 'package:task_manager_flutter/data/models/audit_model.dart';
import 'package:task_manager_flutter/data/models/empresa_model.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/models/parceiro_model.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

import '../customization/generic_grid_card.dart';

class FileAttachment {
  int? id;
  String? fileName;
  String? fileType;
  String? filePath;
  List<int>? fileData; // bytea (Java) → List<int>
  DateTime? uploadDate;
  Diretorio? diretorio;
  Empresa? empresa;
  Parceiro? parceiro;
  Aplicativo? aplicativo;
  Audit? audit;

  FileAttachment({
    this.id,
    this.fileName,
    this.fileType,
    this.filePath,
    this.fileData,
    this.uploadDate,
    this.diretorio,
    this.empresa,
    this.parceiro,
    this.aplicativo,
    this.audit,
  });

  // === Deserialização (fromJson)
  FileAttachment.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fileName = json['fileName'];
    fileType = json['fileType'];
    filePath = json['filePath'];

    // bytea do backend → base64 → bytes
    if (json['fileData'] != null) {
      try {
        if (json['fileData'] is String) {
          fileData = base64.decode(json['fileData']);
        } else if (json['fileData'] is List) {
          fileData = List<int>.from(json['fileData']);
        }
      } catch (_) {
        fileData = [];
      }
    }

    uploadDate = json['uploadDate'] != null
        ? DateTime.tryParse(json['uploadDate'])
        : null;

    diretorio = json['diretorio'] != null
        ? Diretorio.fromJson(json['diretorio'])
        : null;
    empresa =
        json['empresa'] != null ? Empresa.fromJson(json['empresa']) : null;
    parceiro =
        json['parceiro'] != null ? Parceiro.fromJson(json['parceiro']) : null;
    aplicativo = json['aplicativo'] != null
        ? Aplicativo.fromJson(json['aplicativo'])
        : null;
    audit = json['audit'] != null ? Audit.fromJson(json['audit']) : null;
  }

  // === Serialização (toJson)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['fileName'] = fileName;
    data['fileType'] = fileType;
    data['filePath'] = filePath;
    data['fileData'] = fileData != null ? base64.encode(fileData!) : null;
    data['uploadDate'] = uploadDate?.toIso8601String();
    if (diretorio != null) data['diretorio'] = diretorio!.toJson();
    if (empresa != null) data['empresa'] = empresa!.toJson();
    if (parceiro != null) data['parceiro'] = parceiro!.toJson();
    if (aplicativo != null) data['aplicativo'] = aplicativo!.toJson();
    if (audit != null) data['audit'] = audit!.toJson();
    return data;
  }

  // === NOVO: Helper para exibir imagem
  Uint8List get imageBytes {
    if (fileData != null && fileData!.isNotEmpty) {
      return Uint8List.fromList(fileData!);
    }
    return Uint8List(0);
  }

  /// Retorna um widget de imagem pronto para exibição (útil em avatars e logos)
  Widget toImageWidget({
    double size = 64,
    BoxFit fit = BoxFit.cover,
    Widget? fallback,
  }) {
    if (imageBytes.isNotEmpty) {
      return ClipOval(
        child: Image.memory(
          imageBytes,
          width: size,
          height: size,
          fit: fit,
          errorBuilder: (context, error, stack) {
            return fallback ??
                Icon(Icons.image_not_supported,
                    color: Colors.grey[600], size: size / 2);
          },
        ),
      );
    }
    return fallback ??
        Icon(Icons.insert_drive_file, color: Colors.grey[600], size: size / 2);
  }

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: "Nome do Arquivo",
      fieldName: "fileName",
      icon: Icons.file_present,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Tipo",
      fieldName: "fileType",
      icon: Icons.type_specimen,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Data de Upload",
      fieldName: "uploadDate",
      icon: Icons.calendar_today,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    FieldConfig(
      label: "Diretório",
      fieldName: "diretorioId",
      displayFieldName: "diretorio.nome",
      icon: Icons.folder,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async {
        return await loadDiretorios();
      },
      dropdownValueField: 'id',
      dropdownDisplayField: 'nome',
      isRequired: false,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    FieldConfig(
      label: "Empresa",
      fieldName: "empresaId",
      displayFieldName: "empresa.nome",
      icon: Icons.business,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async {
        return await loadCategorias();
      },
      dropdownValueField: 'id',
      dropdownDisplayField: 'nome',
      isRequired: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
  ];

  static Future<List<Map<String, dynamic>>> loadCategorias() async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.getCategorias,
    );

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['account'] ?? [];
      return data
          .map(
            (item) => {
              'value': item['id'].toString(),
              'label': item['descricao'],
            },
          )
          .toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> loadDiretorios() async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.allDiretorios,
    );

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map(
            (item) => {'value': item['id'].toString(), 'label': item['nome']},
          )
          .toList();
    }
    return [];
  }
}

// === Classes de apoio mínimas ===

class Diretorio {
  int? id;
  String? nome;

  Diretorio({this.id, this.nome});

  Diretorio.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nome = json['nome'];
  }

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome};
}
