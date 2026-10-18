import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/services/cadastro_inicial_service.dart';
import 'package:task_manager_flutter/ui/widgets/avatar_com_indicador.dart';
import 'package:task_manager_flutter/ui/widgets/edit_form_helpers.dart';

/// Cadastro inicial do aluno: foto e medidas. Nada aqui e obrigatorio.
class CadastroInicialScreen extends StatefulWidget {
  const CadastroInicialScreen({super.key});

  @override
  State<CadastroInicialScreen> createState() => _CadastroInicialScreenState();
}

class _CadastroInicialScreenState extends State<CadastroInicialScreen> {
  final Map<String, TextEditingController> _controllers = {
    for (final m in CadastroInicialService.medidas) m.chave: TextEditingController(),
  };
  String? _fotoDataUri;
  File? _fotoPreview;
  bool _carregando = true;
  bool _salvando = false;
  // Sem resposta do servidor nao ha como afirmar que falta personal: default true, sem alarme.
  bool _temPersonal = true;

  /// Campos ja preenchidos no formulario (foto + medidas), atualizado enquanto o aluno digita.
  int get _camposPreenchidos {
    final dados = <String, dynamic>{
      'foto': _fotoDataUri,
      for (final m in CadastroInicialService.medidas) m.chave: _controllers[m.chave]!.text.trim(),
    };
    return CadastroInicialService.totalCampos - CadastroInicialService.pendencias(dados).length;
  }

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
    final remoto = await CadastroInicialService.buscarRemoto();
    final dados = remoto?.dados ?? await CadastroInicialService.carregar();
    if (!mounted) return;
    for (final m in CadastroInicialService.medidas) {
      final valor = dados[m.chave];
      if (valor != null) _controllers[m.chave]!.text = valor.toString();
    }
    setState(() {
      _fotoDataUri = dados['foto'] as String?;
      _temPersonal = remoto?.temPersonal ?? true;
      _carregando = false;
    });
  }

  Future<void> _escolherFoto(ImageSource origem) async {
    final (arquivo, base64Str) = await pickImageWithValidation(origem);
    if (!mounted) return;
    if (base64Str == 'LIMITE_EXCEDIDO') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('A imagem deve ter no máximo 2MB.'),
        backgroundColor: CustomColors.primaryGreen,
      ));
      return;
    }
    if (arquivo != null && base64Str != null) {
      setState(() {
        _fotoPreview = arquivo;
        _fotoDataUri = 'data:image/jpeg;base64,$base64Str';
      });
    }
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    final novos = <String, dynamic>{'foto': _fotoDataUri};
    for (final m in CadastroInicialService.medidas) {
      final texto = _controllers[m.chave]!.text.trim().replaceAll(',', '.');
      novos[m.chave] = double.tryParse(texto);
    }
    await CadastroInicialService.salvar(novos);
    final enviado = await CadastroInicialService.enviar(await CadastroInicialService.carregar());
    if (!mounted) return;
    if (!enviado) {
      // Copia local ja ficou gravada; o aluno pode tentar de novo sem perder o que digitou.
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Não foi possível salvar no servidor agora. Seus dados ficaram neste aparelho.'),
        backgroundColor: CustomColors.primaryGreen,
      ));
      return;
    }
    Navigator.pop(context, true);
  }

  Widget _avatar() {
    ImageProvider? imagem;
    if (_fotoPreview != null) {
      imagem = FileImage(_fotoPreview!);
    } else if (_fotoDataUri != null && _fotoDataUri!.startsWith('data:image')) {
      imagem = MemoryImage(base64Decode(_fotoDataUri!.split(',').last));
    }
    return Center(
      child: AvatarComIndicador(
        mostrarAlerta: !_temPersonal,
        rotulo: 'Você ainda não tem personal',
        titulo: 'Você ainda não tem personal',
        corpo: 'Sem personal vinculado, seu acompanhamento não aparece para um profissional. '
            'Peça ao seu personal para vincular seu cadastro.',
        avatar: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => showImageSourceDialog(context, _escolherFoto),
          child: CircleAvatar(
            radius: 52,
            backgroundColor: CustomColors.primaryGreen.withValues(alpha: 0.15),
            backgroundImage: imagem,
            child: imagem == null
                ? const Icon(Icons.add_a_photo_outlined, size: 36, color: CustomColors.primaryGreen)
                : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro inicial')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Foto e medidas ajudam o personal a acompanhar sua evolução. '
                  'Nada aqui é obrigatório: você pode preencher agora ou depois.',
                ),
                const SizedBox(height: 12),
                Text(
                  '$_camposPreenchidos de ${CadastroInicialService.totalCampos} campos preenchidos',
                  key: const Key('cadastro_inicial_progresso'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: CustomColors.primaryGreen),
                ),
                const SizedBox(height: 20),
                _avatar(),
                const SizedBox(height: 20),
                for (final m in CadastroInicialService.medidas)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: _controllers[m.chave],
                      onChanged: (_) => setState(() {}),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: '${m.rotulo} (${m.unidade})',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _salvando ? null : _salvar,
                  style: FilledButton.styleFrom(backgroundColor: CustomColors.primaryGreen),
                  child: Text(_salvando ? 'Salvando...' : 'Salvar'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Fazer depois'),
                ),
              ],
            ),
    );
  }
}
