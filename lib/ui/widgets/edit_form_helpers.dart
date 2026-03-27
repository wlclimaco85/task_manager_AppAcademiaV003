// lib/ui/widgets/edit_form_helpers.dart
// ===============================================================
// Helper compartilhado para telas de edição
// - Safe converters
// - Modelos (País/Estado/Cidade)
// - Fetchers tolerantes (pode vir body como List ou {data:{dados:[]}} ou {dados:[]})
// - TextFields e mascaras
// - Dropdowns (Material + DropdownSearch com loader)
// - Imagem (picker + dialog + avatar editável)
// - inputStyle padronizado
// - normalizeBody com LOG p/ eliminar erro de conversão int->String
// ===============================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_search/dropdown_search.dart';

import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';

/// ===============================================================
/// SAFE CONVERTERS
/// ===============================================================
String safeToString(dynamic v) => v?.toString() ?? '';
int? safeToInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  final s = v.toString();
  if (s.isEmpty) return null;
  return int.tryParse(s);
}

double? safeToDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

/// ===============================================================
/// MODELOS (com == e hashCode por id, para Dropdowns funcionarem sem asserts)
/// ===============================================================
class PaisModel {
  final int id;
  final String nome;

  PaisModel({required this.id, required this.nome});

  factory PaisModel.fromJson(Map<String, dynamic> j) => PaisModel(
        id: safeToInt(j['id']) ?? 0,
        // aceita nomePt ou nome
        nome: (() {
          final nomePt = j['nomePt'];
          final nome = j['nome'];
          if (nomePt != null && safeToString(nomePt).isNotEmpty) {
            return safeToString(nomePt);
          }
          return safeToString(nome);
        })(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PaisModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

class EstadoModel {
  final int id;
  final String nome;
  final int paisId;

  EstadoModel({required this.id, required this.nome, required this.paisId});

  factory EstadoModel.fromJson(Map<String, dynamic> j) => EstadoModel(
        id: safeToInt(j['id']) ?? 0,
        nome: safeToString(j['nome']),
        paisId: safeToInt(j['paisId']) ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is EstadoModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

class CidadeModel {
  final int id;
  final String nome;
  final int estadoId;

  CidadeModel({required this.id, required this.nome, required this.estadoId});

  factory CidadeModel.fromJson(Map<String, dynamic> j) => CidadeModel(
        id: safeToInt(j['id']) ?? 0,
        nome: safeToString(j['nome']),
        estadoId: safeToInt(j['estadoId']) ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CidadeModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// ===============================================================
/// SERVICES - Fetch País / Estado / Cidade (tolerantes a diferentes formatos)
/// ===============================================================
List<dynamic>? _extractList(dynamic data) {
  // Aceita: List
  if (data is List) return data;
  // Aceita: {data:{dados:[...]}} OU {dados:[...]}
  if (data is Map) {
    final dataNode = data['data'];
    if (dataNode is Map && dataNode['dados'] is List) {
      return dataNode['dados'] as List;
    }
    if (data['dados'] is List) {
      return data['dados'] as List;
    }
  }
  return null;
}

Future<List<PaisModel>> fetchPaises() async {
  try {
    final resp = await NetworkCaller().getRequest(ApiLinks.buscarPaises);
    if (resp.isSuccess) {
      final list = _extractList(resp.body);
      if (list != null) {
        return list
            .map((e) => PaisModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
  } catch (e) {
    debugPrint('Erro buscar países: $e');
  }
  return [];
}

Future<List<EstadoModel>> fetchEstados(int paisId) async {
  try {
    final resp = await NetworkCaller()
        .getRequest(ApiLinks.buscarEstados(paisId.toString()));
    if (resp.isSuccess) {
      final list = _extractList(resp.body);
      if (list != null) {
        return list
            .map((e) => EstadoModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
  } catch (e) {
    debugPrint('Erro buscar estados: $e');
  }
  return [];
}

Future<List<CidadeModel>> fetchCidades(int estadoId) async {
  try {
    final resp = await NetworkCaller()
        .getRequest(ApiLinks.buscarCidades(estadoId.toString()));
    if (resp.isSuccess) {
      final list = _extractList(resp.body);
      if (list != null) {
        return list
            .map((e) => CidadeModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
  } catch (e) {
    debugPrint('Erro buscar cidades: $e');
  }
  return [];
}

/// ===============================================================
/// INPUTS (TextFields com e sem máscara)
/// ===============================================================
Widget buildTextField(
  String label,
  TextEditingController c, {
  TextInputType type = TextInputType.text,
  bool required = false,
  bool readOnly = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextFormField(
      controller: c,
      readOnly: readOnly,
      keyboardType: type,
      style: const TextStyle(color: GridColors.textSecondary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: GridColors.inputBackground,
        labelStyle: const TextStyle(color: GridColors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) {
        if (required && (v == null || v.isEmpty)) return 'Obrigatório';
        return null;
      },
    ),
  );
}

Widget buildTextFieldMasked(
  String label,
  TextEditingController c, {
  MaskedInputFormatter? mask,
  bool required = false,
  TextInputType type = TextInputType.text,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextFormField(
      controller: c,
      keyboardType: type,
      inputFormatters: mask != null ? [mask] : [],
      style: const TextStyle(color: GridColors.textSecondary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: GridColors.inputBackground,
        labelStyle: const TextStyle(color: GridColors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) {
        if (required && (v == null || v.isEmpty)) return 'Obrigatório';
        return null;
      },
    ),
  );
}

/// ===============================================================
/// DROPDOWNS - Material (mantidos por compatibilidade)
/// ===============================================================
Widget buildDropdown<T>({
  required String label,
  required T? value,
  required List<T> items,
  required String Function(T) labelBuilder,
  required void Function(T?) onChanged,
}) {
  // evita erro de valor duplicado ou inexistente
  final validValue = items.contains(value) ? value : null;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: DropdownButtonFormField<T>(
      initialValue: validValue,
      isExpanded: true,
      items: items
          .map((e) => DropdownMenuItem<T>(
                value: e,
                child: Text(labelBuilder(e)),
              ))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: GridColors.inputBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

Widget buildDropdownInt({
  required String label,
  required int? value,
  required List<Map<String, dynamic>> items,
  required void Function(int?) onChanged,
}) {
  final validValue = items.any((e) => e['id'] == value) ? value : null;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: DropdownButtonFormField<int>(
      initialValue: validValue,
      isExpanded: true,
      items: items
          .map((e) => DropdownMenuItem<int>(
                value: e['id'] as int,
                child: Text(e['nome'].toString()),
              ))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: GridColors.inputBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

/// ===============================================================
/// DROPDOWN SEARCH (com loader, estilo, popup com busca)
/// ===============================================================

/// Estilo padronizado (mesmo visual solicitado nas telas)
InputDecoration inputStyle(String label, IconData icon, CustomColors colors) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: GridColors.inputBorder),
    filled: true,
    fillColor: GridColors.inputBackground,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: colors.getBorderInput(), width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: colors.getBorderInput(), width: 1.6),
    ),
  );
}

/// Generics (sincrono) — já com loading controlado via [isLoading]
Widget buildDropdownSearchSync<T>({
  required String label,
  required IconData icon,
  required T? selected,
  required List<T> items,
  required String Function(T) itemAsString,
  required void Function(T?) onChanged,
  String? validatorMsg,
  required bool isLoading,
  bool showSearchBox = true,
  CustomColors? colors,
}) {
  final colors0 = colors ?? CustomColors();
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: IgnorePointer(
      ignoring: isLoading,
      child: Stack(
        children: [
          DropdownSearch<T>(
            items: items,
            selectedItem: items.contains(selected) ? selected : null,
            itemAsString: (item) => item == null ? '' : itemAsString(item),
            onChanged: onChanged,
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: inputStyle(label, icon, colors0),
            ),
            validator: (v) =>
                (validatorMsg != null && v == null) ? validatorMsg : null,
            popupProps: PopupProps.menu(
              showSearchBox: showSearchBox,
              searchFieldProps: const TextFieldProps(
                decoration: InputDecoration(hintText: 'Pesquisar...'),
              ),
            ),
          ),
          if (isLoading)
            const Positioned.fill(
              child: _DropdownBlockingLoader(),
            ),
        ],
      ),
    ),
  );
}

/// Generics (assíncrono) — usa asyncItems
Widget buildDropdownSearchAsync<T>({
  required String label,
  required IconData icon,
  required T? selected,
  required Future<List<T>> Function(String?) asyncItems,
  required String Function(T) itemAsString,
  required void Function(T?) onChanged,
  String? validatorMsg,
  bool showSearchBox = true,
  CustomColors? colors,
}) {
  final colors0 = colors ?? CustomColors();
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: DropdownSearch<T>(
      selectedItem: selected,
      asyncItems: (filter) => asyncItems(filter),
      itemAsString: (item) => item == null ? '' : itemAsString(item),
      onChanged: onChanged,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: inputStyle(label, icon, colors0),
      ),
      validator: (v) =>
          (validatorMsg != null && v == null) ? validatorMsg : null,
      popupProps: PopupProps.menu(
        showSearchBox: showSearchBox,
        searchFieldProps: const TextFieldProps(
          decoration: InputDecoration(hintText: 'Pesquisar...'),
        ),
      ),
    ),
  );
}

/// Versão INT (id/label) síncrona
Widget buildDropdownSearchInt({
  required String label,
  required IconData icon,
  required int? selectedId,
  required List<Map<String, dynamic>> items, // [{'id':1,'label':'...'}]
  required void Function(int?) onChanged,
  String idKey = 'id',
  String labelKey = 'label',
  String? validatorMsg,
  required bool isLoading,
  bool showSearchBox = true,
  CustomColors? colors,
}) {
  final colors0 = colors ?? CustomColors();
  final selectedMap =
      items.firstWhere((e) => e[idKey] == selectedId, orElse: () => {});
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: IgnorePointer(
      ignoring: isLoading,
      child: Stack(
        children: [
          DropdownSearch<Map<String, dynamic>>(
            items: items,
            selectedItem: selectedMap.isEmpty ? null : selectedMap,
            itemAsString: (m) => safeToString(m[labelKey]),
            onChanged: (m) => onChanged(m == null ? null : m[idKey] as int?),
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: inputStyle(label, icon, colors0),
            ),
            validator: (m) =>
                (validatorMsg != null && m == null) ? validatorMsg : null,
            popupProps: PopupProps.menu(
              showSearchBox: showSearchBox,
              searchFieldProps: const TextFieldProps(
                decoration: InputDecoration(hintText: 'Pesquisar...'),
              ),
            ),
          ),
          if (isLoading)
            const Positioned.fill(
              child: _DropdownBlockingLoader(),
            ),
        ],
      ),
    ),
  );
}

/// Overlay de loading para dropdowns
class _DropdownBlockingLoader extends StatelessWidget {
  const _DropdownBlockingLoader();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// ===============================================================
/// IMAGEM (picker + dialog + círculo editável)
/// ===============================================================
Future<(File?, String?)> pickImageWithValidation(ImageSource src) async {
  final picker = ImagePicker();
  final XFile? file = await picker.pickImage(
    source: src,
    maxWidth: 800,
    maxHeight: 800,
    imageQuality: 80,
  );
  if (file == null) return (null, null);
  final f = File(file.path);
  if (await f.length() > 2 * 1024 * 1024) return (null, 'LIMITE_EXCEDIDO');
  final bytes = await f.readAsBytes();
  return (f, base64Encode(bytes));
}

Future<void> showImageSourceDialog(
  BuildContext context,
  Future<void> Function(ImageSource) onPicked,
) async {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.red, width: 2),
      ),
      title: const Text(
        'Selecionar imagem',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      content: const Text(
        'Escolha a origem da imagem:',
        style: TextStyle(color: Colors.black54, fontSize: 14),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.camera_alt, color: Colors.green),
          label: const Text(
            'Câmera',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            Navigator.pop(context);
            onPicked(ImageSource.camera);
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.photo_library, color: Colors.green),
          label: const Text(
            'Galeria',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            Navigator.pop(context);
            onPicked(ImageSource.gallery);
          },
        ),
      ],
    ),
  );
}

class EditableImageCircle extends StatelessWidget {
  final File? file;
  final String? imageUrl;
  final IconData placeholderIcon;
  final VoidCallback onTap;

  const EditableImageCircle({
    super.key,
    required this.file,
    required this.imageUrl,
    required this.placeholderIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: GridColors.inputBackground,
          borderRadius: BorderRadius.circular(60),
          border: Border.all(color: GridColors.inputBorder, width: 2),
        ),
        child: Stack(
          children: [
            if (file != null)
              ClipOval(
                child: Image.file(
                  file!,
                  width: 116,
                  height: 116,
                  fit: BoxFit.cover,
                ),
              )
            else if (imageUrl != null && imageUrl!.isNotEmpty)
              ClipOval(
                child: Image.network(
                  imageUrl!,
                  width: 116,
                  height: 116,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    placeholderIcon,
                    size: 50,
                    color: GridColors.primary,
                  ),
                ),
              )
            else
              Icon(
                placeholderIcon,
                size: 50,
                color: GridColors.primary,
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: GridColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child:
                    const Icon(Icons.camera_alt, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================================================
/// NORMALIZAÇÃO DE BODY + LOG (mata o erro de conversão int->String)
/// ===============================================================
/// Use assim no save():
///   final rawBody = { 'id': 1, 'nome': _nome.text, 'endereco': {...}, 'regimeId': 3 };
///   final body = normalizeBody(rawBody);
///   final resp = await NetworkCaller().postRequest(ApiLinks.updateEmpresa(id), body);
Map<String, String> normalizeBody(Map<String, dynamic> rawBody) {
  final normalized = rawBody.map((k, v) {
    if (v == null) return MapEntry(k, '');
    if (v is Map || v is List) return MapEntry(k, jsonEncode(v));
    return MapEntry(k, v.toString());
  });

  debugPrint('🛰️ Body normalizado => ${jsonEncode(normalized)}');
  return normalized;
}
