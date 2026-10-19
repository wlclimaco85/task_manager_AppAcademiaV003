import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../../../data/models/auth_utility.dart';
import '../../../data/constants/custom_colors.dart';
import '../../../data/services/perfil_conta_service.dart';
import '../../../data/services/cadastro_inicial_service.dart';
import '../../../data/services/fitness_push_notification_service.dart';
import '../../../data/utils/fitness_access.dart';
import '../../../data/models/fitness/personal_pix_cobranca_model.dart';
import '../../../data/services/personal_gestao_offline_repository.dart';
import '../../widgets/personal_qr_code_pix_dialog.dart';
import '../../widgets/perfil_fitness_header.dart';
import '../../widgets/fitness_notificacoes_sheet.dart';
import '../editar_dados_usuario_screen.dart';
import 'cadastro_inicial_screen.dart';
import 'privacidade_aparencia_screen.dart';

String prepararFotoPerfil(Uint8List bytes) {
  if (bytes.length > 10 * 1024 * 1024)
    throw const FormatException('Escolha uma imagem de até 10 MB.');
  final decodificada = img.decodeImage(bytes);
  final foto = decodificada == null ? null : img.bakeOrientation(decodificada);
  if (foto == null)
    throw const FormatException('Imagem inválida. Escolha JPG, PNG ou WebP.');
  final pequena = foto.width > 800 || foto.height > 800
      ? img.copyResize(
          foto,
          width: foto.width >= foto.height ? 800 : null,
          height: foto.height > foto.width ? 800 : null,
        )
      : foto;
  return 'data:image/jpeg;base64,${base64Encode(img.encodeJpg(pequena, quality: 85))}';
}

class MeuPerfilScreen extends StatefulWidget {
  final PerfilContaService? service;
  final Future<Uint8List?> Function()? selecionarFoto;
  const MeuPerfilScreen({super.key, this.service, this.selecionarFoto});
  @override
  State<MeuPerfilScreen> createState() => _MeuPerfilScreenState();
}

class _MeuPerfilScreenState extends State<MeuPerfilScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController(),
      _telefone = TextEditingController(),
      _instagram = TextEditingController(),
      _bio = TextEditingController();
  final _valorMensalidade = TextEditingController(text: '200.00');
  String _tipoChavePix = TipoChavePix.cpfCnpj;
  final _chavePix = TextEditingController();
  final _nomeTitularPix = TextEditingController();
  final _cidadePix = TextEditingController(text: 'SAO PAULO');
  final _pixCopiaECola = TextEditingController();
  bool get _ehPersonal => podeGerenciarAlunos(AuthUtility.userInfo);
  late final _service = widget.service ?? PerfilContaService();
  late final _conta = AuthUtility.userInfo.login?.id;
  bool _carregado = false;
  bool _carregando = true, _salvando = false, _fotoCarregando = false;
  bool _cadastroIncompleto = false;
  int _notificacoesNaoLidas = 0;
  String? _erro, _foto;
  String _email = '', _cpf = '';
  bool _mesmaConta() => AuthUtility.userInfo.login?.id == _conta;
  @override
  void initState() {
    super.initState();
    _carregar();
    _carregarIndicadores();
  }

  Future<void> _carregarIndicadores() async {
    final ehAluno = !podeGerenciarAlunos(AuthUtility.userInfo);
    var incompleto = false;
    if (ehAluno) {
      final dados = await CadastroInicialService.carregar();
      final pendencias = CadastroInicialService.pendencias(dados);
      incompleto = pendencias.isNotEmpty;
    }
    final notificacoes = await FitnessPushNotificationService().getNotificacoes();
    if (!mounted) return;
    setState(() {
      _cadastroIncompleto = incompleto;
      _notificacoesNaoLidas = notificacoes.where((n) => !n.lida).length;
    });
  }

  Future<void> _abrirNotificacoes() async {
    await mostrarCentralNotificacoes(
      context,
      onAtualizarIndicadores: _carregarIndicadores,
      onAbrirAvaliacaoInicial: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CadastroInicialScreen()),
        );
        _carregarIndicadores();
      },
    );
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final p = await _service.carregar();
      if (!mounted) return;
      if (!_mesmaConta())
        throw StateError('A conta mudou. Abra o perfil novamente.');
      _nome.text = p['nome'] as String? ?? '';
      _telefone.text = p['telefone'] as String? ?? '';
      _instagram.text = p['instagram'] as String? ?? '';
      _bio.text = p['linkBio'] as String? ?? '';
      _email = p['email'] as String? ?? '';
      _cpf = p['cpf'] as String? ?? '';
      _foto = p['foto'] as String?;
      if (_ehPersonal) {
        final pixConfig = await PersonalGestaoOfflineRepository().getPixCobranca();
        _valorMensalidade.text = pixConfig.valorMensalidadePadrao > 0
            ? pixConfig.valorMensalidadePadrao.toStringAsFixed(2)
            : '200.00';
        _tipoChavePix = pixConfig.tipoChavePix;
        _chavePix.text = pixConfig.chavePix;
        _nomeTitularPix.text = pixConfig.nomeTitular.isNotEmpty
            ? pixConfig.nomeTitular
            : (_nome.text.isNotEmpty ? _nome.text : '');
        _cidadePix.text = pixConfig.cidade;
        _pixCopiaECola.text = pixConfig.pixCopiaECola;
      }
      _carregado = true;
    } catch (e) {
      if (mounted) _erro = _mensagem(e);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String _mensagem(Object e) => e is StateError
      ? e.message.toString()
      : e is FormatException
          ? e.message
          : 'Não foi possível concluir. Tente novamente.';
  Future<void> _escolherFoto() async {
    setState(() {
      _fotoCarregando = true;
      _erro = null;
    });
    try {
      Uint8List? bytes;
      if (widget.selecionarFoto != null) {
        bytes = await widget.selecionarFoto!();
      } else {
        final arquivo = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 90,
        );
        if (arquivo != null) {
          if (await arquivo.length() > 10 * 1024 * 1024)
            throw const FormatException('Escolha uma imagem de até 10 MB.');
          bytes = await arquivo.readAsBytes();
        }
      }
      if (bytes == null) return;
      final foto = await compute(prepararFotoPerfil, bytes);
      if (mounted) setState(() => _foto = foto);
    } catch (e) {
      if (mounted) setState(() => _erro = _mensagem(e));
    } finally {
      if (mounted) setState(() => _fotoCarregando = false);
    }
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    if (!_mesmaConta()) {
      setState(() => _erro = 'A conta mudou. Abra o perfil novamente.');
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await _service.salvar({
        'nome': _nome.text.trim(),
        'telefone': _telefone.text.trim(),
        'instagram': _instagram.text.trim(),
        'linkBio': _bio.text.trim(),
        'foto': _foto ?? '',
      });
      if (_ehPersonal) {
        final valor = double.tryParse(_valorMensalidade.text.replaceAll(',', '.')) ?? 200.0;
        await PersonalGestaoOfflineRepository().salvarPixCobranca(
          PersonalPixCobrancaModel(
            valorMensalidadePadrao: valor,
            tipoChavePix: _tipoChavePix,
            chavePix: _chavePix.text.trim(),
            nomeTitular: _nomeTitularPix.text.trim().isNotEmpty
                ? _nomeTitularPix.text.trim()
                : _nome.text.trim(),
            cidade: _cidadePix.text.trim().isNotEmpty
                ? _cidadePix.text.trim()
                : 'SAO PAULO',
            pixCopiaECola: _pixCopiaECola.text.trim(),
          ),
        );
      }
      if (mounted && _mesmaConta()) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Perfil atualizado com sucesso!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) setState(() => _erro = _mensagem(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _abrirDialogoQrCode() {
    final valor = double.tryParse(_valorMensalidade.text.replaceAll(',', '.')) ?? 200.0;
    final model = PersonalPixCobrancaModel(
      valorMensalidadePadrao: valor,
      tipoChavePix: _tipoChavePix,
      chavePix: _chavePix.text.trim(),
      nomeTitular: _nomeTitularPix.text.trim().isNotEmpty
          ? _nomeTitularPix.text.trim()
          : _nome.text.trim(),
      cidade: _cidadePix.text.trim().isNotEmpty
          ? _cidadePix.text.trim()
          : 'SAO PAULO',
      pixCopiaECola: _pixCopiaECola.text.trim(),
    );
    PersonalQrCodePixDialog.show(context, pixConfig: model);
  }

  void _gerarPixAutomatico() {
    final chave = _chavePix.text.trim();
    if (chave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma chave Pix primeiro.')),
      );
      return;
    }
    final valor = double.tryParse(_valorMensalidade.text.replaceAll(',', '.')) ?? 200.0;
    final titular = _nomeTitularPix.text.trim().isNotEmpty
        ? _nomeTitularPix.text.trim()
        : (_nome.text.trim().isNotEmpty ? _nome.text.trim() : 'PERSONAL');
    final cidade = _cidadePix.text.trim().isNotEmpty ? _cidadePix.text.trim() : 'SAO PAULO';

    final codigoGerado = PersonalPixCobrancaModel.gerarPayloadPixBacen(
      chave: chave,
      nome: titular,
      cidade: cidade,
      valor: valor,
    );
    setState(() {
      _pixCopiaECola.text = codigoGerado;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Código Pix Copia e Cola padrão BACEN gerado com sucesso!'),
        backgroundColor: CustomColors.primaryGreen,
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [
      _nome,
      _telefone,
      _instagram,
      _bio,
      _valorMensalidade,
      _chavePix,
      _nomeTitularPix,
      _cidadePix,
      _pixCopiaECola,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = _salvando || _fotoCarregando;
    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_erro != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _erro!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    if (_erro != null && !_carregado)
                      TextButton(
                        onPressed: _carregar,
                        child: const Text('Tentar novamente'),
                      ),
                    if (_carregado)
                      Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PerfilFitnessHeader(
                              nome: _nome.text,
                              perfil: 'Minha conta',
                              foto: _foto,
                              cadastroIncompleto: _cadastroIncompleto,
                              notificacoesNaoLidas: _notificacoesNaoLidas,
                              onCadastroIncompleto: () async {
                                await mostrarDialogoAvaliacaoInicialPendente(
                                  context,
                                  onFazerAgora: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const CadastroInicialScreen()),
                                    );
                                    _carregarIndicadores();
                                  },
                                );
                              },
                              onNotificacoes: _abrirNotificacoes,
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton.icon(
                                  onPressed: ocupado ? null : _escolherFoto,
                                  icon: const Icon(Icons.add_a_photo_outlined),
                                  label: Text(
                                    _fotoCarregando
                                        ? 'Preparando foto...'
                                        : 'Escolher foto',
                                  ),
                                ),
                                if (_foto?.isNotEmpty ?? false)
                                  TextButton(
                                    onPressed: ocupado
                                        ? null
                                        : () => setState(() => _foto = ''),
                                    child: const Text('Remover foto'),
                                  ),
                              ],
                            ),
                            const Text(
                              'A foto só será alterada ao salvar o perfil.',
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _nome,
                              enabled: !ocupado,
                              maxLength: 150,
                              decoration: const InputDecoration(
                                labelText: 'Nome',
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Informe seu nome.'
                                  : null,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              initialValue: _email,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'E-mail da conta',
                              ),
                            ),
                            if (_cpf.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              TextFormField(
                                initialValue: _cpf,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'CPF/CNPJ',
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _telefone,
                              enabled: !ocupado,
                              maxLength: 30,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Telefone',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _instagram,
                              enabled: !ocupado,
                              maxLength: 100,
                              decoration: const InputDecoration(
                                labelText: 'Instagram',
                                hintText: '@seuusuario',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _bio,
                              enabled: !ocupado,
                              maxLength: 500,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                labelText: 'Link da bio',
                                hintText: 'https://...',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                final u = Uri.tryParse(v.trim());
                                return u == null ||
                                        !['http', 'https'].contains(u.scheme) ||
                                        u.host.isEmpty
                                    ? 'Informe um link http ou https válido.'
                                    : null;
                              },
                            ),
                            if (_ehPersonal) ...[
                              const SizedBox(height: 24),
                              _buildSecaoPixPersonal(ocupado),
                            ],
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: ocupado ? null : _salvar,
                              icon: const Icon(Icons.check),
                              label: Text(
                                _salvando ? 'Salvando...' : 'Salvar perfil',
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 28),
                    OutlinedButton.icon(
                      key: const Key('abrir_privacidade_aparencia'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacidadeAparenciaScreen()),
                      ),
                      icon: const Icon(Icons.shield_outlined),
                      label: const Text('Privacidade e aparência'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('abrir_dados_cadastro'),
                      onPressed: _abrirDadosCadastro,
                      icon: const Icon(Icons.badge_outlined),
                      label: const Text('Editar dados de cadastro'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSecaoPixPersonal(bool ocupado) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade900
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CustomColors.primaryGreen.withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CustomColors.primaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.qr_code_2,
                  color: CustomColors.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cobrança Pix & Mensalidade',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Configure para gerar o QR Code e código Copia e Cola para seus alunos.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Valor da Mensalidade Padrão
          TextFormField(
            controller: _valorMensalidade,
            enabled: !ocupado,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valor da Mensalidade Padrão (R\$)',
              prefixText: 'R\$ ',
              hintText: '200,00',
              helperText: 'Valor padrão cobrado aos seus alunos',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          // Tipo de Chave Pix
          DropdownButtonFormField<String>(
            value: _tipoChavePix,
            decoration: const InputDecoration(
              labelText: 'Tipo de Chave Pix',
            ),
            items: TipoChavePix.todos.map((t) {
              return DropdownMenuItem<String>(
                value: t,
                child: Text(t),
              );
            }).toList(),
            onChanged: ocupado
                ? null
                : (val) {
                    if (val != null) {
                      setState(() => _tipoChavePix = val);
                    }
                  },
          ),
          const SizedBox(height: 14),

          // Chave Pix
          TextFormField(
            controller: _chavePix,
            enabled: !ocupado,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Chave Pix',
              hintText: 'CPF, telefone, e-mail ou chave aleatória',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          // Nome do Titular da Conta
          TextFormField(
            controller: _nomeTitularPix,
            enabled: !ocupado,
            maxLength: 50,
            decoration: const InputDecoration(
              labelText: 'Nome do Titular da Conta (para o Pix)',
              hintText: 'Ex: Carlos Personal',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          // Cidade
          TextFormField(
            controller: _cidadePix,
            enabled: !ocupado,
            maxLength: 30,
            decoration: const InputDecoration(
              labelText: 'Cidade (para o Pix)',
              hintText: 'Ex: SAO PAULO',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          // Pix Copia e Cola
          TextFormField(
            controller: _pixCopiaECola,
            enabled: !ocupado,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Pix Copia e Cola',
              hintText: 'Cole o código Pix do seu banco ou gere automaticamente abaixo',
              helperText: 'Código EMV / BR Code utilizado pelos apps bancários',
              suffixIcon: _pixCopiaECola.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: ocupado
                          ? null
                          : () => setState(() => _pixCopiaECola.clear()),
                      tooltip: 'Limpar código',
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),

          // Ações de geração e teste
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: ocupado ? null : _gerarPixAutomatico,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Gerar Pix Copia e Cola BACEN'),
              ),
              ElevatedButton.icon(
                onPressed: ocupado ? null : _abrirDialogoQrCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.qr_code, size: 20),
                label: const Text(
                  'Ver meu QR Code Pix',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _abrirDadosCadastro() {
    final id = AuthUtility.userInfo.data?.codDadosPessoal?.id;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cadastro pessoal não encontrado para esta conta.'),
      ));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditarDadosUsuarioScreen(dadosPessoaisId: id)),
    );
  }
}
