// lib/data/customization/grid_form.dart
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

import 'grid_theme.dart';
import 'grid_models.dart';
import 'grid_network.dart';
import 'grid_utils.dart';

class GridFormDialog extends StatefulWidget {
  final String titleNew;
  final String titleEdit;
  final List<FieldConfig> fieldConfigs;
  final String createEndpoint;
  final String updateEndpoint; // ':id'
  final Future<Map<String, String>> Function()? authHeadersProvider;
  final String? baseUrlForMultipart;
  final Map<String, dynamic>? additionalFormData;
  final Map<String, dynamic> Function(Map<String, dynamic>? item)?
      dynamicAdditionalFormData;
  final Map<String, dynamic>? editingItem;
  final String idFieldName;

  const GridFormDialog({
    super.key,
    required this.titleNew,
    required this.titleEdit,
    required this.fieldConfigs,
    required this.createEndpoint,
    required this.updateEndpoint,
    this.authHeadersProvider,
    this.baseUrlForMultipart,
    this.additionalFormData,
    this.dynamicAdditionalFormData,
    required this.editingItem,
    required this.idFieldName,
  });

  @override
  State<GridFormDialog> createState() => _GridFormDialogState();
}

class _GridFormDialogState extends State<GridFormDialog> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, List<PlatformFile>> _fileCache = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    L.d('[GridForm] initState');
    for (final c in widget.fieldConfigs.where((x) => x.isInForm)) {
      final initial =
          getNestedValue(widget.editingItem, c.fieldName)?.toString() ??
              (c.defaultValue?.toString() ?? '');
      _controllers[c.fieldName] = TextEditingController(text: initial);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingItem != null;

    return Dialog(
      backgroundColor: GridColors.primary, // fundo banco
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.84,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: GridColors.primary, // fundo banco
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Icon(Icons.edit, color: GridColors.textPrimary),
              const SizedBox(width: 8),
              Text(
                isEditing ? widget.titleEdit : widget.titleNew,
                style: const TextStyle(
                  color: GridColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: GridColors.textPrimary),
              ),
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: widget.fieldConfigs
                      .where((c) => c.isInForm)
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildFormField(c),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: GridColors.textPrimary),
                    foregroundColor: GridColors.textPrimary,
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.success, // verde padrão
                    foregroundColor: GridColors.textPrimary,
                  ),
                  child: Text(isEditing ? 'Salvar' : 'Adicionar'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(FieldConfig c) {
    final ctrl = _controllers[c.fieldName]!;

    switch (c.fieldType) {
      case FieldType.dropdown:
        return _buildDropdown(c, ctrl);
      case FieldType.boolean:
        final v = ctrl.text.toLowerCase() == 'true';
        return Row(children: [
          Checkbox(
            value: v,
            onChanged: c.enabled
                ? (nv) {
                    ctrl.text = (nv ?? false).toString();
                    setState(() {});
                  }
                : null,
          ),
          Text(c.label, style: const TextStyle(color: GridColors.textPrimary)),
        ]);
      case FieldType.multiline:
        return _textField(c, ctrl, maxLines: 4);
      case FieldType.date:
        return _dateField(c, ctrl);
      case FieldType.file:
        return _fileField(c, ctrl);
      default:
        return _textField(c, ctrl);
    }
  }

  InputBorder _redBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            const BorderSide(color: GridColors.error, width: 2), // vermelho
      );

  Widget _textField(FieldConfig c, TextEditingController ctrl,
      {int? maxLines}) {
    return TextField(
      controller: ctrl,
      enabled: c.enabled,
      maxLines: maxLines ?? c.maxLines,
      decoration: InputDecoration(
        labelText: c.label + (c.isRequired ? ' *' : ''),
        filled: true,
        fillColor: Colors.white,
        border: _redBorder(), // borda vermelha padrão
        enabledBorder: _redBorder(), // borda vermelha
        focusedBorder: _redBorder(), // borda vermelha focada
      ),
      keyboardType: keyboardForFieldType(c.fieldType),
    );
  }

  Widget _dateField(FieldConfig c, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      enabled: c.enabled,
      decoration: InputDecoration(
        labelText: c.label + (c.isRequired ? ' *' : ''),
        suffixIcon: const Icon(Icons.calendar_today, color: GridColors.error),
        filled: true,
        fillColor: Colors.white,
        border: _redBorder(),
        enabledBorder: _redBorder(),
        focusedBorder: _redBorder(),
      ),
      onTap: c.enabled
          ? () async {
              final picked = await showDatePicker(
                context: context,
                initialDate:
                    tryParseDate(ctrl.text, c.dateFormat) ?? DateTime.now(),
                firstDate: c.firstDate ?? DateTime(1900),
                lastDate: c.lastDate ?? DateTime(2100),
                locale: const Locale('pt', 'BR'),
              );
              if (picked != null) {
                ctrl.text = DateFormat(c.dateFormat).format(picked);
                setState(() {});
              }
            }
          : null,
      validator: c.validator,
    );
  }

  Widget _fileField(FieldConfig c, TextEditingController ctrl) {
    final picked = _fileCache[c.fieldName] ?? [];
    final cfg = c.fileConfig ?? const FileConfig();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (picked.isNotEmpty)
        ...picked.map((f) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: const Icon(Icons.attach_file),
                title: Text(f.name, overflow: TextOverflow.ellipsis),
                subtitle: Text('${(f.size / 1024).toStringAsFixed(1)} KB'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: GridColors.error),
                  onPressed: () {
                    setState(() {
                      _fileCache[c.fieldName]?.remove(f);
                      if (_fileCache[c.fieldName]!.isEmpty) {
                        _fileCache.remove(c.fieldName);
                      }
                      ctrl.clear();
                    });
                  },
                ),
              ),
            )),
      ElevatedButton.icon(
        onPressed: c.enabled
            ? () async {
                try {
                  final res = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: cfg.allowedExtensions,
                    allowMultiple: cfg.allowMultiple,
                    withData: true,
                  );
                  if (res != null && res.files.isNotEmpty) {
                    final valid = res.files
                        .where((f) => f.size <= cfg.maxFileSize)
                        .toList();
                    if (valid.length != res.files.length) {
                      _snack('Alguns arquivos excedem o tamanho permitido.');
                    }
                    setState(() {
                      _fileCache[c.fieldName] = valid;
                      ctrl.text = valid.map((e) => e.name).join(', ');
                    });
                  }
                } catch (e) {
                  _snack('Erro ao selecionar arquivo: $e');
                }
              }
            : null,
        icon: const Icon(Icons.attach_file),
        label:
            Text(picked.isEmpty ? 'Selecionar Arquivo' : 'Adicionar Arquivo'),
      ),
      if (cfg.allowedExtensions.isNotEmpty) const SizedBox(height: 6),
      if (cfg.allowedExtensions.isNotEmpty)
        const Text(
          'Extensões permitidas: pdf, doc, docx, jpg, jpeg, png',
          style: TextStyle(fontSize: 12, color: Colors.white),
        ),
    ]);
  }

  Widget _buildDropdown(FieldConfig c, TextEditingController ctrl) {
    Future<List<Map<String, dynamic>>> fetchOptions() async {
      if (c.dropdownFutureBuilder != null) {
        return await c.dropdownFutureBuilder!();
      }
      return c.dropdownOptions ?? [];
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchOptions(),
      builder: (context, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        if (s.hasError) {
          return const Text('Erro ao carregar opções',
              style: TextStyle(color: Colors.white));
        }
        final opts = s.data ?? [];

        final seen = <String, Map<String, dynamic>>{};
        for (final o in opts) {
          final v = o[c.dropdownValueField]?.toString() ?? '';
          if (v.isNotEmpty && !seen.containsKey(v)) seen[v] = o;
        }
        final unique = seen.values.toList();

        String? current = ctrl.text.isNotEmpty
            ? ctrl.text
            : (c.defaultValue ?? c.dropdownSelectedValue)?.toString();

        String? safeValue;
        for (final o in unique) {
          final ov = o[c.dropdownValueField]?.toString();
          if (ov == current) {
            safeValue = ov;
            break;
          }
        }

        final items = <DropdownMenuItem<String?>>[];
        if (!c.isRequired || safeValue == null) {
          items.add(const DropdownMenuItem<String?>(
            value: null,
            child: Text('Selecione...', style: TextStyle(color: Colors.grey)),
          ));
        }
        for (final o in unique) {
          final ov = o[c.dropdownValueField]?.toString();
          final ol =
              o[c.dropdownDisplayField]?.toString() ?? ov?.toString() ?? '';
          items.add(DropdownMenuItem<String?>(value: ov, child: Text(ol)));
        }

        final validValue =
            items.any((i) => i.value == safeValue) ? safeValue : null;

        return DropdownButtonFormField<String?>(
          isExpanded: true,
          initialValue: validValue,
          items: items,
          onChanged: c.enabled
              ? (v) {
                  ctrl.text = v ?? '';
                  setState(() {});
                }
              : null,
          decoration: InputDecoration(
            labelText: c.label + (c.isRequired ? ' *' : ''),
            filled: true,
            fillColor: Colors.white,
            border: _redBorder(),
            enabledBorder: _redBorder(),
            focusedBorder: _redBorder(),
          ),
          validator: (v) {
            if (c.isRequired && (v == null || v.isEmpty)) {
              return '${c.label} é obrigatório';
            }
            return c.validator?.call(v?.toString());
          },
        );
      },
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final isEditing = widget.editingItem != null;
      final endpoint = isEditing
          ? widget.updateEndpoint.replaceFirst(
              ':id',
              (getNestedValue(widget.editingItem, widget.idFieldName) ?? '')
                  .toString())
          : widget.createEndpoint;

      final formData = <String, dynamic>{};

      // extra fixos
      if (widget.additionalFormData != null) {
        addAllNested(formData, widget.additionalFormData!);
      }
      // extra dinâmicos (dependem do item editado)
      if (widget.dynamicAdditionalFormData != null) {
        final dyn = widget.dynamicAdditionalFormData!(widget.editingItem);
        addAllNested(formData, dyn);
      }

      // dropdowns que usam selectedValue default
      for (final c in widget.fieldConfigs) {
        if (c.fieldType == FieldType.dropdown &&
            c.dropdownSelectedValue != null) {
          addToFormData(formData, c.fieldName, c.dropdownSelectedValue);
        }
      }

      // campos normais
      for (final c in widget.fieldConfigs
          .where((x) => x.isInForm && x.fieldType != FieldType.file)) {
        final ctrl = _controllers[c.fieldName];
        final valueText = ctrl?.text ?? '';
        if (valueText.isEmpty) continue;

        if (c.fieldType == FieldType.date) {
          final iso = tryDateToIso(valueText, c.dateFormat);
          addToFormData(formData, c.fieldName, iso ?? valueText);
        } else if (c.fieldType == FieldType.number) {
          final numVal = num.tryParse(valueText);
          addToFormData(formData, c.fieldName, numVal ?? valueText);
        } else {
          addToFormData(formData, c.fieldName, valueText);
        }
      }

      // arquivos
      final filesToUpload = <MultipartFieldFile>[];
      for (final c
          in widget.fieldConfigs.where((x) => x.fieldType == FieldType.file)) {
        final picked = _fileCache[c.fieldName];
        if (picked != null && picked.isNotEmpty) {
          final cfg = c.fileConfig ?? const FileConfig();
          for (final f in picked) {
            filesToUpload.add(
              MultipartFieldFile(fieldName: cfg.fileFieldName, file: f),
            );
          }
        }
      }

      dynamic resp;
      if (filesToUpload.isNotEmpty) {
        L.d('[GridForm] sending MULTIPART to: $endpoint');
        resp = await sendMultipart(
          endpoint: endpoint,
          isUpdate: isEditing,
          fields: flattenForMultipart(formData),
          files: filesToUpload,
          baseUrlForMultipart: widget.baseUrlForMultipart,
          authHeadersProvider: widget.authHeadersProvider,
        );
      } else {
        final normalized = normalizeDotted(formData);
        L.d('[GridForm] sending JSON to: $endpoint payload: ${jsonEncode(normalized)}');
        resp = isEditing
            ? await putJson(endpoint, normalized)
            : await postJson(endpoint, normalized);
      }

      if (respSuccess(resp)) {
        if (mounted) Navigator.pop(context, true);
        _snack(isEditing ? 'Item atualizado!' : 'Item criado!');
      } else {
        _snack('Erro ao salvar: ${respBody(resp) ?? respStatus(resp)}');
      }
    } catch (e, st) {
      L.e('[GridForm] save error: $e', st);
      _snack('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: GridColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
