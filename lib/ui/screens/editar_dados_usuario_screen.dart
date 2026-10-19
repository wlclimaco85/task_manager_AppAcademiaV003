import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/services/dados_usuario_service.dart';
import 'package:task_manager_flutter/ui/widgets/edit_form_helpers.dart';

/// Edita os dados do cadastro do usuario logado, inclusive a foto.
class EditarDadosUsuarioScreen extends StatefulWidget {
  final int dadosPessoaisId;

  const EditarDadosUsuarioScreen({super.key, required this.dadosPessoaisId});

  @override
  State<EditarDadosUsuarioScreen> createState() => _EditarDadosUsuarioScreenState();
}

class _EditarDadosUsuarioScreenState extends State<EditarDadosUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    for (final campo in DadosUsuarioService.camposEditaveis) campo: TextEditingController(),
  };

  Map<String, dynamic>? _atual;
  bool _carregando = true;
  bool _salvando = false;
  String? _fotoAtual;
  File? _fotoNova;
  String? _fotoNovaDataUri;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final dados = await DadosUsuarioService.buscar(widget.dadosPessoaisId);
    if (!mounted) return;
    if (dados != null) {
      for (final entrada in _controllers.entries) {
        entrada.value.text = (dados[entrada.key] ?? '').toString();
      }
      _fotoAtual = dados['photo']?.toString();
    }
    setState(() {
      _atual = dados;
      _carregando = false;
    });
  }

  Future<void> _escolherFoto(ImageSource origem) async {
    final (arquivo, base64Str) = await pickImageWithValidation(origem);
    if (!mounted) return;
    if (base64Str == 'LIMITE_EXCEDIDO') {
      _mostrarErro('A imagem deve ter no máximo 2MB.');
      return;
    }
    if (arquivo != null && base64Str != null) {
      setState(() {
        _fotoNova = arquivo;
        _fotoNovaDataUri = 'data:image/jpeg;base64,$base64Str';
      });
    }
  }

  Future<void> _salvar() async {
    if (_atual == null || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _salvando = true);

    final edicao = {for (final e in _controllers.entries) e.key: e.value.text};
    final corpo = DadosUsuarioService.montarCorpo(
      _atual!,
      edicao,
      fotoDataUri: _fotoNovaDataUri,
    );
    final ok = await DadosUsuarioService.salvar(widget.dadosPessoaisId, corpo);
    if (!mounted) return;

    if (!ok) {
      setState(() => _salvando = false);
      _mostrarErro('Não foi possível salvar. Verifique a conexão e tente de novo.');
      return;
    }
    _atualizarSessao(corpo);
    Navigator.pop(context, true);
  }

  /// Reflete nome e foto no cabecalho sem precisar fazer login de novo.
  void _atualizarSessao(Map<String, dynamic> corpo) {
    final sessao = AuthUtility.session.value;
    final cadastro = sessao.data?.codDadosPessoal;
    if (cadastro != null) {
      cadastro.nome = corpo['nome']?.toString() ?? cadastro.nome;
      cadastro.photo = corpo['photo']?.toString() ?? cadastro.photo;
    }
    AuthUtility.session.value = sessao;
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensagem),
      backgroundColor: GridColors.error,
    ));
  }

  Widget _avatar() {
    ImageProvider? imagem;
    if (_fotoNova != null) {
      imagem = FileImage(_fotoNova!);
    } else if (_fotoAtual != null && _fotoAtual!.startsWith('data:image')) {
      try {
        imagem = MemoryImage(base64Decode(_fotoAtual!.split(',').last));
      } catch (_) {
        imagem = null;
      }
    } else if (_fotoAtual != null && _fotoAtual!.startsWith('http')) {
      imagem = NetworkImage(_fotoAtual!);
    }

    return Center(
      child: Semantics(
        button: true,
        label: 'Alterar foto',
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => showImageSourceDialog(context, _escolherFoto),
          child: Stack(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: GridColors.primarySubtle,
                backgroundImage: imagem,
                child: imagem == null
                    ? Icon(Icons.person, size: 52, color: GridColors.primary)
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: GridColors.primary,
                  child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(String rotulo, String campo,
      {TextInputType? teclado, String? Function(String?)? validador}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controllers[campo],
        keyboardType: teclado,
        decoration: InputDecoration(labelText: rotulo, border: const OutlineInputBorder()),
        validator: validador,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar meus dados')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _atual == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Não foi possível carregar seus dados.'),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _carregar, child: const Text('Tentar novamente')),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _avatar(),
                      const SizedBox(height: 20),
                      _campo('Nome', 'nome',
                          validador: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null),
                      _campo('E-mail', 'email', teclado: TextInputType.emailAddress),
                      _campo('Telefone 1', 'telefone1', teclado: TextInputType.phone),
                      _campo('Telefone 2', 'telefone2', teclado: TextInputType.phone),
                      _campo('CEP', 'cep', teclado: TextInputType.number),
                      _campo('Logradouro', 'logradouro'),
                      _campo('Número', 'numero'),
                      _campo('Bairro', 'bairro'),
                      _campo('Cidade', 'cidade'),
                      _campo('Estado', 'estado'),
                      _campo('País', 'pais'),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GridColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _salvando ? null : _salvar,
                          child: _salvando
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Salvar alterações'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
