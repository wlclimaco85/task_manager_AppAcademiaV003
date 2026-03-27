import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';

import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/services/diretorio_caller.dart';
import 'package:task_manager_flutter/data/services/file_caller.dart';
import 'package:task_manager_flutter/data/services/parceiro_caller.dart';
import 'package:task_manager_flutter/data/services/upload_file_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  final FileCaller _caller = FileCaller();

  List<Map<String, dynamic>> _diretorios = [];
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isDownloading = false;

  final Set<int> _expandedTiles = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDiretorios();
  }

  Future<void> _loadDiretorios() async {
    setState(() => _isLoading = true);
    try {
      // Espera-se que o FileCaller().fetchDiretorios() retorne algo como:
      // [{"id":1,"nome":"Pasta A","files":[{"id":10,"fileName":"a.pdf", ...}, ...]}, ...]
      final fetched = await _caller.fetchDiretorios();

      // Garante estrutura segura
      _diretorios = (fetched as List)
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      _showSnackBar(
          "Erro ao carregar diretórios: $e", GridColors.error, Icons.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ========= Upload =========

  Future<File> _writeTempFile(Uint8List bytes,
      {String name = 'preview.pdf'}) async {
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/$name');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _showUploadDialog() async {
    final formKey = GlobalKey<FormState>();
    final diretorioCaller = DiretorioCaller();
    final parceiroCaller = ParceiroCaller();

    List<Map<String, dynamic>> diretorios = [];
    List<Map<String, dynamic>> parceirosMap = [];

    try {
      // fetchDiretoriosDropdown deve entregar lista com {"value": id, "label": nome}
      diretorios = await diretorioCaller.fetchDiretoriosDropdown();

      // fetchParceiross() retornava objetos; transformamos em map para dropdown_search
      final parceiros = await parceiroCaller.fetchParceiross();
      parceirosMap = parceiros
          .map<Map<String, dynamic>>(
              (p) => {'id': p.id, 'nome': p.nome ?? 'Sem nome'})
          .toList();
    } catch (e) {
      _showSnackBar(
          "Erro ao carregar combos: $e", GridColors.error, Icons.error);
    }

    int? diretorioSelecionado;
    int? parceiroSelecionado;
    Uint8List? fileBytes;
    String? fileName;
    String? fileType;
    final TextEditingController nomeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: GridColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: GridColors.primary, width: 2),
          ),
          title: const Text(
            "Enviar Arquivo",
            style: TextStyle(
              color: GridColors.secondary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.attach_file,
                        color: GridColors.secondary),
                    label: const Text("Selecionar Arquivo",
                        style: TextStyle(color: GridColors.secondary)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: GridColors.primary)),
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles();
                      if (result != null) {
                        final f = result.files.first;
                        fileBytes =
                            f.bytes ?? await File(f.path!).readAsBytes();
                        fileName = f.name;
                        fileType = ".${f.name.split('.').last}".toLowerCase();
                        setStateDialog(() => nomeController.text = fileName!);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                      labelText: "Nome do Arquivo",
                      labelStyle: TextStyle(color: GridColors.textSecondary),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: GridColors.primary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: GridColors.primary, width: 2),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Informe o nome" : null,
                  ),
                  const SizedBox(height: 12),

                  // Combo pesquisável: Diretório
                  DropdownSearch<Map<String, dynamic>>(
                    items: diretorios,
                    itemAsString: (e) => e['label'] ?? '',
                    onChanged: (v) => diretorioSelecionado = v?['value'],
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: "Buscar diretório...",
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    dropdownDecoratorProps: const DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: "Diretório",
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: GridColors.primary, width: 2),
                        ),
                      ),
                    ),
                    validator: (v) =>
                        v == null ? "Selecione um diretório" : null,
                  ),
                  const SizedBox(height: 12),

                  // Combo pesquisável: Parceiro
                  DropdownSearch<Map<String, dynamic>>(
                    items: parceirosMap,
                    itemAsString: (p) => p['nome'] ?? '',
                    onChanged: (v) => parceiroSelecionado = v?['id'],
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: "Buscar parceiro...",
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    dropdownDecoratorProps: const DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: "Parceiro",
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: GridColors.primary, width: 2),
                        ),
                      ),
                    ),
                    validator: (v) =>
                        v == null ? "Selecione um parceiro" : null,
                  ),
                  const SizedBox(height: 12),

                  if (fileType != null)
                    Text("Tipo: $fileType",
                        style: const TextStyle(color: GridColors.primaryLight)),

                  if (fileBytes != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: (fileType?.contains("pdf") ?? false)
                            ? SizedBox(
                                height: 200,
                                child: FutureBuilder<File>(
                                  future: _writeTempFile(
                                    fileBytes!,
                                    name:
                                        'preview_${DateTime.now().millisecondsSinceEpoch}.pdf',
                                  ),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                            color: GridColors.secondary),
                                      );
                                    }
                                    return PDFView(
                                        filePath: snapshot.data!.path);
                                  },
                                ),
                              )
                            : ((fileType?.contains("jpg") ?? false) ||
                                    (fileType?.contains("jpeg") ?? false) ||
                                    (fileType?.contains("png") ?? false))
                                ? Image.memory(fileBytes!, height: 150)
                                : const SizedBox.shrink(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar",
                  style: TextStyle(color: GridColors.error)),
            ),
            ElevatedButton.icon(
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: GridColors.textPrimary))
                  : const Icon(Icons.upload, color: GridColors.textPrimary),
              label: const Text("Enviar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.success,
                foregroundColor: GridColors.textPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (_isUploading) return;
                if (formKey.currentState!.validate()) {
                  if (fileBytes == null) {
                    _showSnackBar("Selecione um arquivo antes de enviar.",
                        GridColors.warning, Icons.warning_amber);
                    return;
                  }
                  setStateDialog(() => _isUploading = true);
                  final ok = await _caller.insertFileAttachment(
                    fileBytes: fileBytes!,
                    fileName: nomeController.text,
                    fileType: fileType ?? "unknown",
                    diretorioId: diretorioSelecionado!,
                    parceiroId: parceiroSelecionado!,
                  );
                  setStateDialog(() => _isUploading = false);
                  if (ok) {
                    if (mounted) Navigator.pop(context);
                    await _loadDiretorios();
                    _showSnackBar("Arquivo enviado com sucesso!",
                        GridColors.success, Icons.check_circle);
                  } else {
                    _showSnackBar("Erro ao enviar arquivo!", GridColors.error,
                        Icons.error);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ========= Preview / Download =========

  Future<Uint8List?> _fetchFileBytes(int fileId) async {
    try {
      final String authToken = '${AuthUtility.userInfo?.token}';
      final uri = Uri.parse(ApiLinks.downloadFile(fileId.toString()));
      final res =
          await http.get(uri, headers: {'Authorization': 'Bearer $authToken'});
      if (res.statusCode == 200) return res.bodyBytes;
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao baixar bytes: $e');
      return null;
    }
  }

  void _openPreviewSheet(int fileId, String fileName,
      {required int dirId}) async {
    // registra abertura ao abrir/visualizar
    await UploadFileCaller().registerFileOpened(fileId);

    final ext = fileName.split('.').last.toLowerCase();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => Stack(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: GridColors.card,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: GridColors.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        _fileTypeIcon(ext,
                            size: 20, color: GridColors.textPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: GridColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: GridColors.textPrimary),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  ),

                  // Body (preview)
                  Expanded(
                    child: FutureBuilder<Uint8List?>(
                      future: _fetchFileBytes(fileId),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: GridColors.secondary),
                          );
                        }
                        final bytes = snap.data;
                        if (bytes == null) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Não foi possível gerar a pré-visualização.\nVocê pode fazer o download do arquivo.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        if (ext == 'pdf') {
                          return FutureBuilder<File>(
                            future: _writeTempFile(
                              bytes,
                              name:
                                  'preview_${DateTime.now().millisecondsSinceEpoch}.pdf',
                            ),
                            builder: (context, pdfSnap) {
                              if (!pdfSnap.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                      color: GridColors.secondary),
                                );
                              }
                              return PDFView(filePath: pdfSnap.data!.path);
                            },
                          );
                        } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp']
                            .contains(ext)) {
                          return Center(child: Image.memory(bytes));
                        } else if (['txt', 'csv', 'log'].contains(ext)) {
                          try {
                            final txt = String.fromCharCodes(bytes);
                            return SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Text(txt),
                            );
                          } catch (_) {
                            return const Center(
                                child: Text(
                                    'Prévia indisponível para este tipo de arquivo.'));
                          }
                        } else {
                          return const Center(
                              child: Text(
                                  'Prévia indisponível para este tipo de arquivo.'));
                        }
                      },
                    ),
                  ),

                  // Footer (ações)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.download,
                                color: GridColors.secondary),
                            label: const Text('Baixar',
                                style: TextStyle(color: GridColors.secondary)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: GridColors.primary),
                            ),
                            onPressed: () async {
                              if (_isDownloading) return;
                              setStateDialog(() => _isDownloading = true);
                              await UploadFileCaller().registerFileOpened(
                                  fileId); // registra também no download
                              await UploadFileCaller()
                                  .downloadFile(fileId, fileName);
                              setStateDialog(() => _isDownloading = false);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete,
                                color: GridColors.error),
                            label: const Text('Excluir',
                                style: TextStyle(color: GridColors.error)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: GridColors.primary),
                            ),
                            onPressed: () => _confirmDelete(fileId, dirId),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isDownloading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(color: GridColors.secondary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ========= Delete =========

  void _confirmDelete(int id, int dirId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: GridColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: GridColors.primary, width: 2),
        ),
        title: const Text(
          "Excluir Documento",
          style:
              TextStyle(color: GridColors.primary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Deseja realmente excluir este documento?",
          style: TextStyle(color: GridColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar",
                style: TextStyle(color: GridColors.secondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final ok = await _caller.deleteArquivo(id);
                if (ok) {
                  await _loadDiretorios();
                  _showSnackBar("Arquivo excluído com sucesso!",
                      GridColors.success, Icons.delete_forever);
                } else {
                  _showSnackBar("Falha ao excluir o arquivo", GridColors.error,
                      Icons.error);
                }
              } catch (e) {
                _showSnackBar(
                    "Erro ao excluir: $e", GridColors.error, Icons.error);
              }
            },
            child: const Text("Excluir",
                style: TextStyle(color: GridColors.error)),
          ),
        ],
      ),
    );
  }

  // ========= UI helpers =========

  void _showSnackBar(String msg, Color color, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(icon, color: GridColors.textPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg,
                  style: const TextStyle(color: GridColors.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  Icon _fileTypeIcon(String ext, {double size = 18, Color? color}) {
    final c = color ?? GridColors.secondary;
    switch (ext.toLowerCase()) {
      case 'pdf':
        return Icon(Icons.picture_as_pdf, color: GridColors.error, size: size);
      case 'xls':
      case 'xlsx':
        return Icon(Icons.grid_on, color: c, size: size);
      case 'csv':
      case 'txt':
        return Icon(Icons.description, color: c, size: size);
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
      case 'bmp':
        return Icon(Icons.image, color: c, size: size);
      default:
        return Icon(Icons.insert_drive_file, color: c, size: size);
    }
  }

  // ========= Busca/Filtragem =========
  //
  // Mantém a pasta se o nome da pasta bate com a busca,
  // ou mantém a pasta com apenas os arquivos que batem.
  List<Map<String, dynamic>> _filteredDiretorios() {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return List<Map<String, dynamic>>.from(_diretorios);

    final result = _diretorios
        .map<Map<String, dynamic>>((dir) {
          final pastaNome = (dir['nome'] ?? '').toString().toLowerCase();

          final List files = (dir['files'] ?? []) is List
              ? (dir['files'] as List)
              : <dynamic>[];
          final arquivos = files
              .map<Map<String, dynamic>>(
                  (e) => Map<String, dynamic>.from(e as Map))
              .toList();

          final arquivosFiltrados = arquivos.where((a) {
            final n = (a['fileName'] ?? '').toString().toLowerCase();
            return n.contains(q);
          }).toList();

          if (pastaNome.contains(q)) {
            // mantém todos os arquivos se a pasta bate
            return Map<String, dynamic>.from(dir);
          } else if (arquivosFiltrados.isNotEmpty) {
            // mantém a pasta, porém só com os arquivos filtrados
            final copy = Map<String, dynamic>.from(dir);
            copy['files'] = arquivosFiltrados;
            return copy;
          } else {
            // pasta não entra
            return <String, dynamic>{};
          }
        })
        .where((e) => e.isNotEmpty)
        .toList();

    return List<Map<String, dynamic>>.from(result);
  }

  Widget _buildDiretorioBox(Map<String, dynamic> dir) {
    final int id =
        dir['id'] is int ? dir['id'] as int : int.tryParse('${dir['id']}') ?? 0;
    final String nome = (dir['nome'] ?? 'Sem nome').toString();

    final List filesList =
        (dir['files'] ?? []) is List ? (dir['files'] as List) : <dynamic>[];
    final List<Map<String, dynamic>> arquivos = filesList
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final int total = arquivos.length;
    final int naoLidos = arquivos.where((a) => a['lido'] != true).length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: GridColors.shadow, blurRadius: 6, offset: Offset(0, 2))
        ],
        border: Border.all(color: GridColors.primary, width: 1.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<int>(id),
          initiallyExpanded: _expandedTiles.contains(id),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          trailing: AnimatedRotation(
            turns: _expandedTiles.contains(id) ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.keyboard_arrow_down,
                color: GridColors.textSecondary),
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              if (expanded) {
                _expandedTiles.clear(); // accordion (só um aberto)
                _expandedTiles.add(id);
              } else {
                _expandedTiles.remove(id);
              }
            });
          },
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.folder,
                    color: _expandedTiles.contains(id)
                        ? GridColors.secondaryLight
                        : GridColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    nome,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: GridColors.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  if (naoLidos > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: GridColors.error,
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        "$naoLidos não lidos",
                        style: const TextStyle(
                            color: GridColors.textPrimary, fontSize: 12),
                      ),
                    ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: GridColors.warning,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      "$total docs",
                      style: const TextStyle(
                          color: GridColors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: arquivos.isEmpty
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "Nenhum arquivo disponível",
                  style: TextStyle(color: GridColors.textSecondary),
                ),
              ),
              secondChild: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Column(
                  children: arquivos.map((arq) {
                    final bool lido = arq['lido'] == true;
                    final String fileName =
                        (arq['fileName'] ?? 'Sem nome').toString();
                    final String dataUpload =
                        (arq['dataUpload'] ?? '--').toString();
                    final String ext = fileName.split('.').last.toLowerCase();
                    final int fileId = arq['id'] is int
                        ? (arq['id'] as int)
                        : int.tryParse('${arq['id']}') ?? 0;

                    // JSON real usa "uploadDate"
                    final String dataUploadIso =
                        (arq['uploadDate'] ?? arq['dataUpload'] ?? '--')
                            .toString();
                    String dataFmt = '--';
                    if (dataUploadIso != '--') {
                      try {
                        dataFmt = DateFormat('dd/MM/yyyy HH:mm')
                            .format(DateTime.parse(dataUploadIso));
                      } catch (_) {}
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: GridColors.card,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(color: GridColors.shadow, blurRadius: 4)
                        ],
                      ),
                      child: ListTile(
                        onTap: () =>
                            _openPreviewSheet(fileId, fileName, dirId: id),
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _fileTypeIcon(ext,
                                color: lido
                                    ? GridColors.success
                                    : GridColors.primary),
                            if (!lido)
                              const Positioned(
                                right: -2,
                                top: -2,
                                child: CircleAvatar(
                                    radius: 4,
                                    backgroundColor: GridColors.error),
                              ),
                          ],
                        ),
                        title: Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          "Upload: $dataFmt",
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Baixar',
                              icon: const Icon(Icons.download,
                                  color: GridColors.secondary),
                              onPressed: () async {
                                if (_isDownloading) return;
                                setState(() => _isDownloading = true);
                                await UploadFileCaller()
                                    .registerFileOpened(fileId);
                                await UploadFileCaller()
                                    .downloadFile(fileId, fileName);
                                if (mounted) {
                                  setState(() => _isDownloading = false);
                                }
                              },
                            ),
                            IconButton(
                              tooltip: 'Excluir',
                              icon: const Icon(Icons.delete,
                                  color: GridColors.error),
                              onPressed: () => _confirmDelete(fileId, id),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filteredDiretorios();

    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: UserBannerAppBar(
        screenTitle: "Gerenciador de Arquivos",
        isLoading: _isLoading,
        showFilterButton: false,
        onRefresh: _loadDiretorios,
      ),
      body: Column(
        children: [
          // BUSCA
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: const InputDecoration(
                hintText: 'Buscar pasta ou arquivo…',
                prefixIcon: Icon(Icons.search, color: GridColors.secondary),
                filled: true,
                fillColor: GridColors.card,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: GridColors.primary),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: GridColors.primary, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: GridColors.secondary))
                : filtrados.isEmpty
                    ? const Center(
                        child: Text("Nenhum diretório/arquivo encontrado",
                            style: TextStyle(color: GridColors.textPrimary)))
                    : ListView.builder(
                        itemCount: filtrados.length,
                        itemBuilder: (context, i) =>
                            _buildDiretorioBox(filtrados[i]),
                      ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildFAB(
              Icons.refresh, GridColors.secondary, _loadDiretorios, "refresh"),
          const SizedBox(height: 10),
          _buildFAB(Icons.add, GridColors.secondary, _showUploadDialog, "add"),
        ],
      ),
    );
  }

  Widget _buildFAB(
      IconData icon, Color color, VoidCallback onPressed, String tag) {
    return Container(
      decoration: BoxDecoration(
        color: GridColors.card,
        border: Border.all(color: GridColors.primary, width: 2),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: GridColors.shadow, blurRadius: 8, spreadRadius: 2)
        ],
      ),
      child: FloatingActionButton(
        heroTag: tag,
        backgroundColor: GridColors.card,
        foregroundColor: color,
        elevation: 0,
        onPressed: onPressed,
        child: Icon(icon),
      ),
    );
  }
}
