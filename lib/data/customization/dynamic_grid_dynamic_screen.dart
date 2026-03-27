// lib/data/customization/dynamic_grid_dynamic_screen.dart
// ------------------------------------------------------------
// DynamicGridDynamicScreen
// - Usa GenericMobileGridScreen do novo grid_page.dart
// - Remove dependência do antigo generic_grid_card_1_1.dart
// - Mantém logs AppLogger e compatibilidade total
// ------------------------------------------------------------

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/customization/generic_grid/grid_models.dart';
import 'package:task_manager_flutter/data/customization/generic_grid/grid_page.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/services/tela_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

import '../models/telas_model.dart';
import '../models/auth_utility.dart';
import '../services/auth_service.dart';

typedef SecurityCheck = bool Function(String permission);
typedef OnItemTap = void Function(
    Map<String, dynamic> item, BuildContext context);

class DynamicGridDynamicScreen extends StatefulWidget {
  final String telaNome;
  final SecurityCheck hasPermission;
  final String? storageKey;
  final OnItemTap? onItemTap;
  final Widget Function(Map<String, dynamic> item)? detailScreenBuilder;
  final Map<String, dynamic>? extraParams;
  final VoidCallback? onUserBannerTapped;
  final VoidCallback? onBannerRefresh;
  final Map<String, dynamic>? additionalFormData;
  final Map<String, dynamic> Function(Map<String, dynamic>? item)?
      dynamicAdditionalFormData;

  const DynamicGridDynamicScreen({
    super.key,
    required this.telaNome,
    required this.hasPermission,
    this.storageKey,
    this.onItemTap,
    this.detailScreenBuilder,
    this.extraParams,
    this.onUserBannerTapped,
    this.onBannerRefresh,
    this.additionalFormData,
    this.dynamicAdditionalFormData,
  });

  @override
  State<DynamicGridDynamicScreen> createState() =>
      _DynamicGridDynamicScreenState();
}

class _DynamicGridDynamicScreenState extends State<DynamicGridDynamicScreen> {
  late Future<TelaConfig> _telaFuture;
  late TelaService _telaService;

  @override
  void initState() {
    super.initState();
    _telaService = TelaService(networkCaller: NetworkCaller());
    _telaFuture = _loadTelaConfig();
  }

  Future<TelaConfig> _loadTelaConfig() async {
    L.i('🚀 Carregando tela dinâmica: ${widget.telaNome}');
    try {
      final userInfo = AuthUtility.userInfo;
      final empId = userInfo?.login?.empresa?.id;
      final clienteId = userInfo?.data?.login?.empresa?.id ?? userInfo?.data?.login?.parceiro?.id;

      final tela = await _telaService.getTelaFromCache(
        widget.telaNome,
        empId: empId,
        clienteId: clienteId,
      );
      if (tela != null) {
        L.i('✅ Tela carregada: ${tela.nome} '
            '(Campos=${tela.fields.length}, Actions=${tela.actions.length})');
        return tela;
      } else {
        throw Exception('Tela ${widget.telaNome} não encontrada.');
      }
    } catch (e, st) {
      L.e('💥 Erro em _loadTelaConfig(): $e\n$st');
      rethrow;
    }
  }

  // conversão de campos (TelaField → FieldConfig)
  List<FieldConfig> _convertToFieldConfigs(List<TelaField> fields) {
    L.i('🧱 Convertendo ${fields.length} campos para FieldConfig...');
    return fields.map((f) {
      List<Map<String, dynamic>>? dropdownOptions;
      if (f.dropdownOptions.isNotEmpty) {
        dropdownOptions = f.dropdownOptions
            .map((opt) => {
                  'value': opt.optionValue,
                  'label': opt.optionLabel ?? opt.optionValue?.toString() ?? '',
                })
            .toList();
      }

      return FieldConfig(
        label: f.label,
        fieldName: f.fieldName,
        displayFieldName: f.displayFieldName,
        isFilterable: f.isFilterable,
        isInForm: f.isInForm,
        flex: f.flex,
        maxLines: f.maxLines,
        icon: f.iconData,
        isSortable: f.isSortable,
        fieldType: FieldType.values[f.fieldType.index],
        dropdownOptions: dropdownOptions,
        dropdownFutureBuilder: f.dropdownEndpoint != null
            ? _createDropdownFutureBuilder(f.dropdownEndpoint!)
            : null,
        dropdownValueField: f.dropdownValueField,
        dropdownDisplayField: f.dropdownDisplayField,
        isRequired: f.isRequired,
        validator: _createValidator(f),
        isVisibleByDefault: f.isVisibleByDefault,
        isFixed: f.isFixed,
        enabled: f.enabled,
        defaultValue: f.defaultValue,
        fileConfig: f.fieldType == TelaFieldType.file
            ? FileConfig(
                allowedExtensions: f.allowedExtensions,
                allowMultiple: f.allowMultipleFiles,
                maxFileSize: f.maxFileSize,
                fileFieldName: f.fileFieldName,
              )
            : null,
        showInCard: f.showInCard,
        firstDate: f.firstDate,
        lastDate: f.lastDate,
        dateFormat: f.dateFormat,
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> Function()? _createDropdownFutureBuilder(
      String endpoint) {
    return () async {
      L.d('🌐 Carregando dropdown: $endpoint');
      try {
        final resp = await NetworkCaller().getRequest(endpoint);
        if (resp.isSuccess && resp.body != null) {
          final list = _extractAnyList(resp.body);
          return list
              .map<Map<String, dynamic>>((it) => {
                    'value': it['value'] ?? it['id'],
                    'label': it['label'] ?? it['name'] ?? it['value'] ?? '',
                  })
              .toList();
        }
      } catch (e, st) {
        L.e('❌ Erro dropdown: $e\n$st');
      }
      return [];
    };
  }

  List<Map<String, dynamic>> _extractAnyList(dynamic body) {
    try {
      if (body is List) {
        return body
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else if (body is Map) {
        final inner =
            body['data'] ?? body['dados'] ?? body['items'] ?? body['content'];
        if (inner is List) {
          return inner
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } else if (body is String) {
        return _extractAnyList(jsonDecode(body));
      }
    } catch (e) {
      L.e('💥 Erro em _extractAnyList: $e');
    }
    return [];
  }

  String? Function(String?)? _createValidator(TelaField f) {
    if (!f.isRequired) return null;
    return (v) => (v == null || v.isEmpty) ? '${f.label} é obrigatório' : null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<TelaConfig>(
          future: _telaFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: const Text('Erro')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Erro ao carregar tela: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            setState(() => _telaFuture = _loadTelaConfig()),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Scaffold(
                  body: Center(child: Text('Nenhuma tela encontrada.')));
            }

            final tela = snapshot.data!;
            final serverActions = tela.actions.map((a) {
              return ServerAction(
                label: a.label,
                icon: _iconFromName(a.icon),
                method: a.method,
                endpoint: ApiLinks.baseUrl + a.endpoint,
                confirmMessage: a.confirmMessage,
                requiredPermission: a.requiredPermission,
              );
            }).toList();

            return GenericMobileGridScreen(
              title: tela.titulo,
              fetchEndpoint: ApiLinks.baseUrl + tela.fetchEndpoint,
              createEndpoint: ApiLinks.baseUrl + tela.createEndpoint,
              updateEndpoint: ApiLinks.baseUrl + tela.updateEndpoint,
              deleteEndpoint: ApiLinks.baseUrl + tela.deleteEndpoint,
              hasPermission: widget.hasPermission,
              asyncHasPermission: AuthService().hasPermission,
              fieldConfigs: _convertToFieldConfigs(tela.fields),
              idFieldName: tela.idFieldName,
              dateFieldName: tela.dateFieldName,
              storageKey: widget.storageKey ?? 'dynamic_${tela.nome}',
              onItemTap: widget.onItemTap,
              detailScreenBuilder: widget.detailScreenBuilder,
              extraParams: widget.extraParams,
              enableSearch: tela.enableSearch,
              enableDebugMode: tela.enableDebugMode,
              useUserBannerAppBar: tela.useUserBannerAppBar,
              onUserBannerTapped: widget.onUserBannerTapped,
              onBannerRefresh: widget.onBannerRefresh,
              additionalFormData: widget.additionalFormData,
              dynamicAdditionalFormData: widget.dynamicAdditionalFormData,
              serverActions: serverActions,
            );
          },
        ),

        // Console flutuante de logs
        const AppLoggerOverlay(),
      ],
    );
  }

  IconData? _iconFromName(String? name) {
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
      case 'check':
      case 'ok':
        return Icons.check_circle;
      default:
        return Icons.play_circle_outline;
    }
  }
}
