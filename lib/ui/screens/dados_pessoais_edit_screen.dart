import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/grid_colors.dart';

// Helper grande (já existente, NÃO alterado)
import 'package:task_manager_flutter/ui/widgets/edit_form_helpers.dart';

class DadosPessoaisEditScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const DadosPessoaisEditScreen({super.key, required this.initialData});

  @override
  State<DadosPessoaisEditScreen> createState() =>
      _DadosPessoaisEditScreenState();
}

class _DadosPessoaisEditScreenState extends State<DadosPessoaisEditScreen> {
  final _formKey = GlobalKey<FormState>();

  File? _photo;
  String? _photoBase64;
  bool _imageTooLarge = false;

  late TextEditingController _nome;
  late TextEditingController _cpf;
  late TextEditingController _telefone1;
  late TextEditingController _telefone2;
  late TextEditingController _email;
  late TextEditingController _logradouro;
  late TextEditingController _numero;
  late TextEditingController _cep;
  late TextEditingController _bairro;

  // Localização
  List<PaisModel> _paises = [];
  List<EstadoModel> _estados = [];
  List<CidadeModel> _cidades = [];
  PaisModel? _paisSelecionado;
  EstadoModel? _estadoSelecionado;
  CidadeModel? _cidadeSelecionada;

  // Carregando dropdowns
  bool _loadingEstados = false;
  bool _loadingCidades = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;

    _nome = TextEditingController(text: safeToString(d['nome']));
    _cpf = TextEditingController(text: safeToString(d['cpf']));
    _telefone1 = TextEditingController(text: safeToString(d['telefone1']));
    _telefone2 = TextEditingController(text: safeToString(d['telefone2']));
    _email = TextEditingController(text: safeToString(d['email']));
    _logradouro = TextEditingController(text: safeToString(d['logradouro']));
    _numero = TextEditingController(text: safeToString(d['numero']));
    _cep = TextEditingController(text: safeToString(d['cep']));
    _bairro = TextEditingController(text: safeToString(d['bairro']));

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Países
    _paises = await fetchPaises();

    // Pré-seleção por IDs
    final paisId = safeToInt(widget.initialData['paisId']);
    final estadoId = safeToInt(widget.initialData['estadoId']);
    final cidadeId = safeToInt(widget.initialData['cidadeId']);

    if (paisId != null) {
      _paisSelecionado = _paises.firstWhere(
        (p) => p.id == paisId,
        orElse: () => PaisModel(id: 0, nome: ''),
      );
      if (_paisSelecionado!.id != 0) {
        _loadingEstados = true;
        setState(() {});
        _estados = await fetchEstados(_paisSelecionado!.id);
        _loadingEstados = false;

        if (estadoId != null) {
          _estadoSelecionado = _estados.firstWhere(
            (e) => e.id == estadoId,
            orElse: () => EstadoModel(id: 0, nome: '', paisId: 0),
          );
          if (_estadoSelecionado!.id != 0) {
            _loadingCidades = true;
            setState(() {});
            _cidades = await fetchCidades(_estadoSelecionado!.id);
            _loadingCidades = false;

            if (cidadeId != null) {
              _cidadeSelecionada = _cidades.firstWhere(
                (c) => c.id == cidadeId,
                orElse: () => CidadeModel(id: 0, nome: '', estadoId: 0),
              );
            }
          }
        }
      }
    }

    setState(() {});
  }

  Future<void> _pickPhoto(ImageSource src) async {
    final (file, base64Str) = await pickImageWithValidation(src);
    if (base64Str == 'LIMITE_EXCEDIDO') {
      setState(() => _imageTooLarge = true);
      return;
    }
    if (file != null) {
      setState(() {
        _photo = file;
        _photoBase64 = base64Str;
        _imageTooLarge = false;
      });
    }
  }

  InputDecoration _dec(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: GridColors.inputBorder),
      suffixIcon: suffix,
      filled: true,
      fillColor: GridColors.inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: GridColors.inputBorder, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: GridColors.inputBorder, width: 1.6),
      ),
    );
  }

  Future<void> _onPaisChanged(PaisModel? v) async {
    setState(() {
      _paisSelecionado = v;
      _estadoSelecionado = null;
      _cidadeSelecionada = null;
      _estados = [];
      _cidades = [];
      _loadingEstados = v != null;
      _loadingCidades = false;
    });
    if (v != null) {
      _estados = await fetchEstados(v.id);
    }
    setState(() => _loadingEstados = false);
  }

  Future<void> _onEstadoChanged(EstadoModel? v) async {
    setState(() {
      _estadoSelecionado = v;
      _cidadeSelecionada = null;
      _cidades = [];
      _loadingCidades = v != null;
    });
    if (v != null) {
      _cidades = await fetchCidades(v.id);
    }
    setState(() => _loadingCidades = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(GridColors.primary),
        ),
      ),
    );

    try {
      final Map<String, dynamic> req = {
        'id': safeToInt(widget.initialData['id']),
        'nome': _nome.text.trim(),
        'cpf': _cpf.text.trim(),
        'telefone1': _telefone1.text.trim(),
        'telefone2': _telefone2.text.trim(),
        'email': _email.text.trim(),
        'logradouro': _logradouro.text.trim(),
        'numero': _numero.text.trim(), // String no entity
        'cep': _cep.text.trim(),
        'bairro': _bairro.text.trim(),
        'paisId': _paisSelecionado?.id, // Long no entity
        'estadoId': _estadoSelecionado?.id, // Long no entity
        'cidadeId': _cidadeSelecionada?.id, // Long no entity
        'photoBase64': _photoBase64 ?? '',
      };

      // Logs
      debugPrint('--- DADOS PESSOAIS SAVE BODY (JSON) ---');
      debugPrint(const JsonEncoder.withIndent('  ').convert(req));
      debugPrint('--- DADOS PESSOAIS SAVE BODY (TYPES) ---');
      req.forEach(
          (k, v) => debugPrint('$k => ${v == null ? "null" : v.runtimeType}'));

      final resp = await NetworkCaller().putRequest(
          ApiLinks.atualizarDadosPessoais(widget.initialData['id']), req);

      if (!mounted) return;
      Navigator.pop(context);

      if (resp.isSuccess) {
        Navigator.pop(context, req);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Dados pessoais atualizados!'),
          backgroundColor: GridColors.success,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro: ${resp.body ?? "Falha ao atualizar"}'),
          backgroundColor: GridColors.error,
        ));
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao salvar: $e'),
        backgroundColor: GridColors.error,
      ));
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _cpf.dispose();
    _telefone1.dispose();
    _telefone2.dispose();
    _email.dispose();
    _logradouro.dispose();
    _numero.dispose();
    _cep.dispose();
    _bairro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        title: const Text(
          'Editar Dados Pessoais',
          style: TextStyle(
              color: GridColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: GridColors.primary,
        iconTheme: const IconThemeData(color: GridColors.textPrimary),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Card(
            color: GridColors.card,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  EditableImageCircle(
                    file: _photo,
                    imageUrl: widget.initialData['photo'],
                    placeholderIcon: Icons.person,
                    onTap: () => showImageSourceDialog(context, _pickPhoto),
                  ),
                  if (_imageTooLarge)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '⚠️ A imagem deve ter no máximo 2MB',
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Campos
                  buildTextField('Nome *', _nome, required: true),
                  buildTextFieldMasked('CPF', _cpf,
                      mask: MaskedInputFormatter('000.000.000-00'),
                      required: true,
                      type: TextInputType.number),
                  buildTextFieldMasked('Telefone 1', _telefone1,
                      mask: MaskedInputFormatter('(00) 00000-0000'),
                      type: TextInputType.phone),
                  buildTextFieldMasked('Telefone 2', _telefone2,
                      mask: MaskedInputFormatter('(00) 00000-0000'),
                      type: TextInputType.phone),
                  buildTextField('Email', _email,
                      type: TextInputType.emailAddress),

                  const SizedBox(height: 24),

                  buildTextField('Logradouro', _logradouro),
                  Row(
                    children: [
                      Expanded(child: buildTextField('Número', _numero)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: buildTextFieldMasked('CEP', _cep,
                            mask: MaskedInputFormatter('00000-000'),
                            type: TextInputType.number),
                      ),
                    ],
                  ),
                  buildTextField('Bairro', _bairro),

                  const SizedBox(height: 16),

                  DropdownSearch<PaisModel>(
                    items: _paises,
                    selectedItem: _paisSelecionado,
                    itemAsString: (p) => p.nome,
                    onChanged: _onPaisChanged,
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: _dec('País', Icons.flag),
                    ),
                    validator: (v) => v == null ? 'Selecione o país' : null,
                    popupProps: const PopupProps.menu(showSearchBox: true),
                  ),

                  const SizedBox(height: 16),

                  DropdownSearch<EstadoModel>(
                    items: _estados,
                    selectedItem: _estadoSelecionado,
                    itemAsString: (e) => e.nome,
                    onChanged: _onEstadoChanged,
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: _dec(
                        _loadingEstados ? 'Estado (carregando...)' : 'Estado',
                        Icons.map_outlined,
                        suffix: _loadingEstados
                            ? const Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                    ),
                    validator: (v) => v == null ? 'Selecione o estado' : null,
                    popupProps: const PopupProps.menu(showSearchBox: true),
                  ),

                  const SizedBox(height: 16),

                  DropdownSearch<CidadeModel>(
                    items: _cidades,
                    selectedItem: _cidadeSelecionada,
                    itemAsString: (c) => c.nome,
                    onChanged: (v) => setState(() => _cidadeSelecionada = v),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: _dec(
                        _loadingCidades ? 'Cidade (carregando...)' : 'Cidade',
                        Icons.location_city,
                        suffix: _loadingCidades
                            ? const Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                    ),
                    validator: (v) => v == null ? 'Selecione a cidade' : null,
                    popupProps: const PopupProps.menu(showSearchBox: true),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GridColors.buttonBackground,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text(
                      'SALVAR ALTERAÇÕES',
                      style: TextStyle(
                        color: GridColors.buttonText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
