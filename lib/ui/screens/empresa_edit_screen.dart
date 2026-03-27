import 'dart:convert';
import 'dart:io';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/regime_tributario_model.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/services/upload_file_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/edit_form_helpers.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/empresa_model.dart';

class EmpresaEditScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const EmpresaEditScreen({super.key, required this.initialData});

  @override
  State<EmpresaEditScreen> createState() => _EmpresaEditScreenState();
}

class _EmpresaEditScreenState extends State<EmpresaEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final UploadFileCaller _uploadCaller = UploadFileCaller();

  File? _logo;
  bool _imageTooLarge = false;

  // Controllers
  late TextEditingController _nome;
  late TextEditingController _razaoSocial;
  late TextEditingController _email;
  late TextEditingController _site;
  late TextEditingController _contato;
  late TextEditingController _emailContato;
  late TextEditingController _telefoneContato;
  late TextEditingController _telefone;
  late TextEditingController _rua;
  late TextEditingController _numero;
  late TextEditingController _cep;
  late TextEditingController _cnpj;
  late TextEditingController _ie;

  // Ambiente e Regime
  static const _ambientes = ['HOMOLOGACAO', 'PRODUCAO'];
  String? _ambiente;
  RegimeTributario? _regimeSelecionado;
  List<RegimeTributario> _regimes = [];

  // Localização
  List<PaisModel> _paises = [];
  List<EstadoModel> _estados = [];
  List<CidadeModel> _cidades = [];
  PaisModel? _paisSelecionado;
  EstadoModel? _estadoSelecionado;
  CidadeModel? _cidadeSelecionada;

  bool _loadingEstados = false;
  bool _loadingCidades = false;

  Map<String, dynamic>? _appCache;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _nome = TextEditingController(text: safeToString(d['nome']));
    _razaoSocial = TextEditingController(text: safeToString(d['razaoSocial']));
    _email = TextEditingController(text: safeToString(d['email']));
    _site = TextEditingController(text: safeToString(d['site']));
    _contato = TextEditingController(text: safeToString(d['contato']));
    _emailContato =
        TextEditingController(text: safeToString(d['emailContato']));
    _telefoneContato =
        TextEditingController(text: safeToString(d['telefoneContato']));
    _telefone = TextEditingController(text: safeToString(d['telefone']));
    _rua = TextEditingController(text: safeToString(d['rua']));
    _numero = TextEditingController(text: safeToString(d['numero']));
    _cep = TextEditingController(text: safeToString(d['cep']));
    _cnpj = TextEditingController(text: safeToString(d['cnpj']));
    _ie = TextEditingController(text: safeToString(d['ie']));
    _ambiente = safeToString(d['ambiente']).isNotEmpty ? d['ambiente'] : null;

    _appCache = {'id': 1, 'nome': 'AppAcademia'};

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // Verifica cache
      final cachedPaisId = prefs.getInt('cachedPaisId');
      final cachedEstadoId = prefs.getInt('cachedEstadoId');

      // Carrega países
      _paises = await fetchPaises();

      if (_paises.isEmpty) {
        debugPrint('⚠️ Nenhum país retornado do backend.');
      }

      // Se tiver cache, tenta usar
      if (cachedPaisId != null) {
        _paisSelecionado = _paises.firstWhere(
          (p) => p.id == cachedPaisId,
          orElse: () => _paises.firstWhere(
            (p) => p.nome.toLowerCase().contains('brasil'),
            orElse: () => _paises.first,
          ),
        );
      } else {
        // Fallback “Brasil”
        _paisSelecionado = _paises.firstWhere(
          (p) => p.nome.toLowerCase().contains('brasil'),
          orElse: () => _paises.first,
        );
      }

      // Estados
      _loadingEstados = true;
      setState(() {});
      _estados = await fetchEstados(_paisSelecionado!.id);
      _loadingEstados = false;

      if (_estados.isEmpty) {
        debugPrint('⚠️ Nenhum estado retornado do backend.');
      }

      // Estado cacheado ou padrão “Minas Gerais”
      if (cachedEstadoId != null) {
        _estadoSelecionado = _estados.firstWhere(
          (e) => e.id == cachedEstadoId,
          orElse: () => _estados.firstWhere(
            (e) => e.nome.toLowerCase().contains('minas'),
            orElse: () => _estados.first,
          ),
        );
      } else {
        _estadoSelecionado = _estados.firstWhere(
          (e) => e.nome.toLowerCase().contains('minas'),
          orElse: () => _estados.first,
        );
      }

      // Cidades
      if (_estadoSelecionado != null) {
        _loadingCidades = true;
        setState(() {});
        _cidades = await fetchCidades(_estadoSelecionado!.id);
        _loadingCidades = false;
      }

      // Atualiza cache
      await prefs.setInt('cachedPaisId', _paisSelecionado!.id);
      await prefs.setInt('cachedEstadoId', _estadoSelecionado!.id);

      // Regimes
      await _loadRegimes();
    } catch (e) {
      debugPrint('❌ Erro no bootstrap: $e');
    }

    setState(() {});
  }

  Future<void> _loadRegimes() async {
    try {
      final List<Map<String, dynamic>> items =
          await RegimeTributario.loadDropdownData();
      _regimes = items
          .map((m) => RegimeTributario(
                id: int.tryParse(m['value']?.toString() ?? ''),
                descricao: m['label']?.toString(),
              ))
          .where((r) => r.id != null)
          .cast<RegimeTributario>()
          .toList();

      final regimeId = safeToInt(widget.initialData['regimeId']);
      if (regimeId != null) {
        _regimeSelecionado = _regimes.firstWhere((r) => r.id == regimeId,
            orElse: () => RegimeTributario());
      }
    } catch (e) {
      debugPrint('Erro carregar regimes: $e');
    }
  }

  Future<void> _pickLogo(ImageSource src) async {
    final (file, base64Str) = await pickImageWithValidation(src);
    if (base64Str == 'LIMITE_EXCEDIDO') {
      setState(() => _imageTooLarge = true);
      return;
    }
    if (file != null) {
      setState(() {
        _logo = file;
        _imageTooLarge = false;
      });
    }
  }

  InputDecoration _inputStyle(String label, IconData icon, {Widget? suffix}) {
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
      int? uploadedFileId;
      if (_logo != null) {
        final fileBytes = await _logo!.readAsBytes();
        final platformFile = PlatformFile(
          name: _logo!.path.split('/').last,
          path: _logo!.path,
          bytes: fileBytes,
          size: await _logo!.length(),
        );

        uploadedFileId = await _uploadCaller.uploadFiless(
          file: platformFile,
          empresaId: widget.initialData['id'],
          diretorioId: 1,
        );

        debugPrint('📁 File uploaded. ID: $uploadedFileId');
      }

      String clean(String text) =>
          text.replaceAll(RegExp(r'[^0-9a-zA-Z@.\s-]'), '');
      String onlyDigits(String? s) => (s ?? '').replaceAll(RegExp(r'\D'), '');

      final Map<String, dynamic> body = {
        'id': safeToInt(widget.initialData['id']),
        'nome': _nome.text.trim(),
        'razaoSocial': _razaoSocial.text.trim(),
        'email': _email.text.trim(),
        'site': _site.text.trim(),
        'contato': _contato.text.trim(),
        'emailContato': _emailContato.text.trim(),
        'telefoneContato': clean(_telefoneContato.text),
        'telefone': clean(onlyDigits(_telefone.text)),
        'rua': _rua.text.trim(),
        'numero': _numero.text.trim(),
        'cep': clean(onlyDigits(clean(_cep.text))),
        'cnpj': clean(onlyDigits(clean(_cnpj.text))),
        'ie': clean(onlyDigits(clean(_ie.text))),
        'ambiente': _ambiente,
        'regime': {'id': _regimeSelecionado?.id},
        'aplicativo': {'id': _appCache?['id'] ?? 1},
        'pais': {'id': _paisSelecionado?.id},
        'estado': {'id': _estadoSelecionado?.id},
        'cidade': {'id': _cidadeSelecionada?.id},
        if (uploadedFileId != null && uploadedFileId > 0)
          'fileAttachment': {'id': uploadedFileId},
      };

      debugPrint('--- EMPRESA SAVE PAYLOAD ---');
      debugPrint(const JsonEncoder.withIndent('  ').convert(body));

      final resp = await NetworkCaller().putRequest(
        ApiLinks.updateEmpresa(widget.initialData['id'].toString()),
        body,
      );

      if (!mounted) return;
      Navigator.pop(context); // Fecha o loading inicial

      if (resp.isSuccess) {
        // Mostra o modal de recarregamento
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.35),
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => const SizedBox.shrink(),
          transitionBuilder: (context, anim1, anim2, child) {
            final scale = Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            );
            return Opacity(
              opacity: anim1.value,
              child: Transform.scale(
                scale: scale.value,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 28),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 2.8,
                          valueColor:
                              AlwaysStoppedAnimation(GridColors.primary),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Recarregando empresa...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );

        // Faz o fetch da empresa atualizada
        final refreshed = await NetworkCaller().getRequest(
            ApiLinks.empresaById(widget.initialData['id'].toString()));

        await Future.delayed(const Duration(milliseconds: 600));
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Fecha recarregando
        }

        if (refreshed.isSuccess && refreshed.body != null) {
          widget.initialData
            ..clear()
            ..addAll(Map<String, dynamic>.from(refreshed.body!));

          final d = widget.initialData;
          _nome.text = safeToString(d['nome']);
          _razaoSocial.text = safeToString(d['razaoSocial']);
          _email.text = safeToString(d['email']);
          _site.text = safeToString(d['site']);
          _contato.text = safeToString(d['contato']);
          _emailContato.text = safeToString(d['emailContato']);
          _telefoneContato.text = safeToString(d['telefoneContato']);
          _telefone.text = safeToString(d['telefone']);
          _rua.text = safeToString(d['rua']);
          _numero.text = safeToString(d['numero']);
          _cep.text = safeToString(d['cep']);
          _cnpj.text = safeToString(d['cnpj']);
          _ie.text = safeToString(d['ie']);
          _ambiente =
              safeToString(d['ambiente']).isNotEmpty ? d['ambiente'] : null;

          // Atualiza o cache global corretamente
          if (AuthUtility.userInfo?.login != null && refreshed.body != null) {
            final empresaAtualizada = Empresa.fromJson(refreshed.body!);
            AuthUtility.userInfo!.login!.empresa = empresaAtualizada;
            await AuthUtility.setUserInfo(AuthUtility.userInfo!);
            debugPrint('✅ Empresa atualizada em AuthUtility com sucesso');
          }

          setState(() {});
        }

        // Exibe o check verde
        await showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.2),
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const SizedBox.shrink(),
          transitionBuilder: (context, anim1, anim2, child) {
            final scale = Tween<double>(begin: 0.6, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
            );
            return Opacity(
              opacity: anim1.value,
              child: Transform.scale(
                scale: scale.value,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 80,
                    ),
                  ),
                ),
              ),
            );
          },
        );

        // Fecha o ícone verde corretamente
        await Future.delayed(const Duration(seconds: 1));
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Empresa atualizada com sucesso!'),
          backgroundColor: GridColors.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro: ${resp.body ?? "Falha ao atualizar a empresa"}'),
          backgroundColor: GridColors.error,
        ));
      }
    } catch (e) {
      Navigator.pop(context);
      debugPrint('❌ Erro ao salvar empresa: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao salvar: $e'),
        backgroundColor: GridColors.error,
      ));
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _razaoSocial.dispose();
    _email.dispose();
    _site.dispose();
    _contato.dispose();
    _emailContato.dispose();
    _telefoneContato.dispose();
    _telefone.dispose();
    _rua.dispose();
    _numero.dispose();
    _cep.dispose();
    _cnpj.dispose();
    _ie.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        title: const Text('Editar Empresa',
            style: TextStyle(
                color: GridColors.textPrimary, fontWeight: FontWeight.bold)),
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
                    file: _logo,
                    imageUrl: widget.initialData['logo'],
                    placeholderIcon: Icons.apartment,
                    onTap: () => showImageSourceDialog(context, _pickLogo),
                  ),
                  if (_imageTooLarge)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('⚠️ A imagem deve ter no máximo 2MB',
                          style: TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  const SizedBox(height: 24),
                  buildTextField('Nome *', _nome, required: true),
                  buildTextField('Razão Social', _razaoSocial),
                  buildTextFieldMasked('CNPJ', _cnpj,
                      mask: MaskedInputFormatter('00.000.000/0000-00'),
                      required: true,
                      type: TextInputType.number),
                  buildTextFieldMasked('IE', _ie,
                      mask: MaskedInputFormatter('000.000.000.000'),
                      type: TextInputType.number),
                  buildTextField('Email', _email,
                      type: TextInputType.emailAddress),
                  buildTextField('Site', _site),
                  buildTextField('Contato', _contato),
                  buildTextField('Email do Contato', _emailContato,
                      type: TextInputType.emailAddress),
                  buildTextFieldMasked('Telefone do Contato', _telefoneContato,
                      mask: MaskedInputFormatter('(00) 00000-0000'),
                      type: TextInputType.phone),
                  buildTextFieldMasked('Telefone', _telefone,
                      mask: MaskedInputFormatter('(00) 00000-0000'),
                      type: TextInputType.phone),

                  const SizedBox(height: 16),
                  DropdownSearch<PaisModel>(
                    items: _paises,
                    selectedItem: _paisSelecionado,
                    itemAsString: (p) => p.nome,
                    onChanged: (v) async {
                      setState(() => _paisSelecionado = v);
                      if (v != null) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt('cachedPaisId', v.id);
                        _estados = await fetchEstados(v.id);
                        setState(() {});
                      }
                    },
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: _inputStyle('País', Icons.flag),
                    ),
                    validator: (v) => v == null ? 'Selecione o país' : null,
                    popupProps: const PopupProps.menu(showSearchBox: true),
                  ),
                  const SizedBox(height: 16),

                  DropdownSearch<EstadoModel>(
                    items: _estados,
                    selectedItem: _estadoSelecionado,
                    itemAsString: (e) => e.nome,
                    onChanged: (v) async {
                      setState(() => _estadoSelecionado = v);
                      if (v != null) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt('cachedEstadoId', v.id);
                        _cidades = await fetchCidades(v.id);
                        setState(() {});
                      }
                    },
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: _inputStyle(
                        _loadingEstados ? 'Estado (carregando...)' : 'Estado',
                        Icons.map_outlined,
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
                      dropdownSearchDecoration: _inputStyle(
                        _loadingCidades ? 'Cidade (carregando...)' : 'Cidade',
                        Icons.location_city,
                      ),
                    ),
                    validator: (v) => v == null ? 'Selecione a cidade' : null,
                    popupProps: const PopupProps.menu(showSearchBox: true),
                  ),

                  const SizedBox(height: 24),

                  // Localização (agora no topo)

                  buildTextField('Rua', _rua),
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

                  const SizedBox(height: 24),
                  DropdownSearch<RegimeTributario>(
                    items: _regimes,
                    selectedItem: _regimeSelecionado,
                    itemAsString: (r) => r.descricao ?? '',
                    onChanged: (v) => setState(() => _regimeSelecionado = v),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration:
                          _inputStyle('Regime Tributário', Icons.balance),
                    ),
                    validator: (v) =>
                        v == null ? 'Selecione um regime tributário' : null,
                    popupProps: const PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                            decoration:
                                InputDecoration(hintText: 'Pesquisar...'))),
                  ),
                  const SizedBox(height: 16),
                  DropdownSearch<String>(
                    items: _ambientes,
                    selectedItem: _ambiente,
                    onChanged: (v) => setState(() => _ambiente = v),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration:
                          _inputStyle('Ambiente', Icons.settings),
                    ),
                    validator: (v) => v == null ? 'Selecione o ambiente' : null,
                    popupProps: const PopupProps.menu(showSearchBox: false),
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
                    child: const Text('SALVAR ALTERAÇÕES',
                        style: TextStyle(
                            color: GridColors.buttonText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
