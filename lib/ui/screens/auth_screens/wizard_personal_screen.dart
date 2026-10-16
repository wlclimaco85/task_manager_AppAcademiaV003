import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/redes_sociais_cadastro.dart';
import 'package:task_manager_flutter/ui/widgets/campos_redes_sociais_cadastro.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:task_manager_flutter/data/repository/cadastro_repository.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';
import 'package:task_manager_flutter/data/utils/cadastro_personal_regras.dart';
import 'package:task_manager_flutter/data/utils/grid_colors.dart';

/// Wizard de cadastro do Personal Trainer em 5 passos (layout definido pelo
/// agente de UX/UI): 1) Sua conta, 2) Registro e contato (CREF/WhatsApp),
/// 3) Onde e quando atende, 4) Planos e valores, 5) Revisão.
class WizardPersonalScreen extends StatefulWidget {
  const WizardPersonalScreen({super.key});

  @override
  State<WizardPersonalScreen> createState() => _WizardPersonalScreenState();
}

class _AcademiaDisponivel {
  final int id;
  final String nome;

  _AcademiaDisponivel({required this.id, required this.nome});

  factory _AcademiaDisponivel.fromJson(Map<String, dynamic> json) =>
      _AcademiaDisponivel(id: json['id'] as int, nome: json['nome'] as String? ?? '');
}

/// Plano em edição no passo 4.
class _PlanoEdicao {
  _PlanoEdicao({String nome = '', this.aulas = 8}) : nome = TextEditingController(text: nome);

  final TextEditingController nome;
  final valor = TextEditingController();
  final descricao = TextEditingController();
  int aulas;
  String modalidade = 'academia';
  int? academiaId;

  void dispose() {
    nome.dispose();
    valor.dispose();
    descricao.dispose();
  }
}

class _WizardPersonalScreenState extends State<WizardPersonalScreen> {
  static const _titulos = [
    'Sua conta',
    'Registro e contato',
    'Onde e quando você atende',
    'Planos e valores',
    'Revisão',
  ];
  static const _subtitulos = [
    'Para você entrar no app com segurança.',
    'O CREF dá confiança ao aluno; o WhatsApp é como ele vai falar com você.',
    'Os alunos encontram você pela academia e pelo horário.',
    'Deixe claro quanto custa treinar com você.',
    'É assim que os alunos vão ver seu perfil.',
  ];
  static const _modosSemAcademia = ['Independente', 'Domicílio', 'Online'];

  final PageController _pageController = PageController();
  final CadastroRepository _cadastroRepository = CadastroRepository();

  int _passoAtual = 0;
  bool _enviando = false;

  // Passo 1
  final _formConta = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirmarSenha = TextEditingController();
  final _cpf = TextEditingController();
  final _telefone = TextEditingController();
  final _instagram = TextEditingController();
  final _linkBio = TextEditingController();
  final _cep = TextEditingController();
  final _cepFocus = FocusNode();
  String? _erroCep;
  bool _buscandoCep = false;
  final _logradouro = TextEditingController();
  final _numero = TextEditingController();
  final _bairro = TextEditingController();
  final _cidade = TextEditingController();
  final _estado = TextEditingController();
  bool _obscurarSenha = true;
  DateTime? _dataNascimento;
  String? _sexo;

  // Passo 2
  final _formRegistro = GlobalKey<FormState>();
  final _crefNumero = TextEditingController();
  String _crefCategoria = 'G';
  String? _crefUf;
  final _whatsapp = TextEditingController();
  bool _whatsappIgualTelefone = true;
  final _bio = TextEditingController();

  // Passo 5 e navegação
  bool _declaracaoAceita = false;
  String? _erroDeclaracao;
  bool _voltarParaRevisao = false;

  // Passo 3
  bool _carregandoAcademias = false;
  String? _erroAcademias;
  List<_AcademiaDisponivel> _academias = [];
  final List<FaixaAtendimento> _faixas = [];
  int? _academiaPrincipalId;
  String? _erroLocais;

  // Passo 4
  final _formPlanos = GlobalKey<FormState>();
  final _valorAvulso = TextEditingController();
  final List<_PlanoEdicao> _planos = [];

  @override
  void initState() {
    super.initState();
    _cepFocus.addListener(_aoSairCep);
    _carregarAcademias();
    _telefone.addListener(_sincronizarWhatsapp);
    _restaurarRascunho();
  }

  void _aoSairCep() {
    if (!_cepFocus.hasFocus) _buscarCep();
  }

  Future<void> _buscarCep() async {
    final cep = _cep.text.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8 || _buscandoCep) return;
    setState(() { _buscandoCep = true; _erroCep = null; });
    try {
      final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/'))
          .timeout(const Duration(seconds: 10));
      if (!mounted || _cep.text.replaceAll(RegExp(r'\D'), '') != cep) return;
      if (response.statusCode != 200) throw Exception('CEP indisponível');
      final data = jsonDecode(response.body);
      if (data['erro'] == true || data['erro'] == 'true') {
        setState(() => _erroCep = 'CEP não encontrado.');
      } else {
        setState(() {
          _logradouro.text = data['logradouro'] ?? '';
          _bairro.text = data['bairro'] ?? '';
          _cidade.text = data['localidade'] ?? '';
          _estado.text = data['uf'] ?? '';
        });
      }
    } catch (error, stack) {
      AppLogger.i.error('Não foi possível consultar o CEP.', stack);
      if (mounted) setState(() => _erroCep = 'Não foi possível buscar o CEP. Preencha o endereço ou tente novamente.');
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  // ───────────────────────── rascunho local ─────────────────────────

  Map<String, dynamic> _rascunho() => limparRascunho({
        'passo': _passoAtual,
        'nome': _nome.text,
        'email': _email.text,
        'cpf': _cpf.text,
        'telefone': _telefone.text,
        'instagram': _instagram.text,
        'linkBio': _linkBio.text,
        'dataNascimento': _dataNascimento?.toIso8601String(),
        'sexo': _sexo,
        'cep': _cep.text,
        'logradouro': _logradouro.text,
        'numero': _numero.text,
        'bairro': _bairro.text,
        'cidade': _cidade.text,
        'estado': _estado.text,
        'crefNumero': _crefNumero.text,
        'crefCategoria': _crefCategoria,
        'crefUf': _crefUf,
        'whatsapp': _whatsapp.text,
        'whatsappIgualTelefone': _whatsappIgualTelefone,
        'bio': _bio.text,
        'faixas': [for (final f in _faixas) f.toRascunho()],
        'academiaPrincipalId': _academiaPrincipalId,
        'valorAvulso': _valorAvulso.text,
        'planos': [
          for (final p in _planos)
            {'nome': p.nome.text, 'aulas': p.aulas, 'valor': p.valor.text, 'descricao': p.descricao.text, 'modalidade': p.modalidade, 'academiaId': p.academiaId},
        ],
      });

  bool get _temDados =>
      _nome.text.isNotEmpty || _email.text.isNotEmpty || _instagram.text.isNotEmpty || _linkBio.text.isNotEmpty || _faixas.isNotEmpty || _planos.isNotEmpty;

  Future<void> _salvarRascunho() async {
    if (!_temDados) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(chaveRascunhoPersonal, jsonEncode(_rascunho()));
    } catch (e, st) {
      AppLogger.i.error('Falha ao salvar rascunho do cadastro do personal: $e', st);
    }
  }

  Future<void> _apagarRascunho() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(chaveRascunhoPersonal);
    } catch (e, st) {
      AppLogger.i.error('Falha ao apagar rascunho do cadastro do personal: $e', st);
    }
  }

  Future<void> _restaurarRascunho() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(chaveRascunhoPersonal);
      if (raw == null || !mounted) return;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      String s(String k) => m[k]?.toString() ?? '';
      setState(() {
        _nome.text = s('nome');
        _email.text = s('email');
        _cpf.text = s('cpf');
        _whatsappIgualTelefone = m['whatsappIgualTelefone'] != false;
        _telefone.text = s('telefone');
        _instagram.text = s('instagram');
        _linkBio.text = s('linkBio');
        _dataNascimento = DateTime.tryParse(s('dataNascimento'));
        _sexo = m['sexo'] as String?;
        _cep.text = s('cep');
        _logradouro.text = s('logradouro');
        _numero.text = s('numero');
        _bairro.text = s('bairro');
        _cidade.text = s('cidade');
        _estado.text = s('estado');
        _crefNumero.text = s('crefNumero');
        _crefCategoria = m['crefCategoria'] == 'P' ? 'P' : 'G';
        _crefUf = ufs.contains(m['crefUf']) ? m['crefUf'] as String : null;
        _whatsapp.text = s('whatsapp');
        _bio.text = s('bio');
        _faixas
          ..clear()
          ..addAll([
            for (final f in (m['faixas'] as List? ?? const []))
              FaixaAtendimento.fromRascunho(Map<String, dynamic>.from(f as Map)),
          ]);
        _academiaPrincipalId = m['academiaPrincipalId'] as int?;
        _valorAvulso.text = s('valorAvulso');
        for (final p in (m['planos'] as List? ?? const [])) {
          final mp = Map<String, dynamic>.from(p as Map);
          _planos.add(_PlanoEdicao(nome: mp['nome']?.toString() ?? '', aulas: (mp['aulas'] as int?) ?? 8)
            ..valor.text = mp['valor']?.toString() ?? ''
            ..descricao.text = mp['descricao']?.toString() ?? ''
            ..modalidade = mp['modalidade']?.toString() ?? 'academia'
            ..academiaId = (mp['academiaId'] as num?)?.toInt());
        }
      });
      final passo = (m['passo'] as int? ?? 0).clamp(0, _titulos.length - 1);
      if (passo > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) _pageController.jumpToPage(passo);
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Retomamos seu cadastro de onde você parou. Digite a senha novamente.')));
      }
    } catch (e, st) {
      AppLogger.i.error('Falha ao restaurar rascunho do cadastro do personal: $e', st);
    }
  }

  Future<bool> _confirmarSaida() async {
    if (!_temDados) return true;
    await _salvarRascunho();
    if (!mounted) return true;
    final sair = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do cadastro?'),
        content: const Text('Seus dados ficam salvos neste aparelho para você continuar depois.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Continuar cadastro')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sair')),
        ],
      ),
    );
    return sair ?? false;
  }

  @override
  void dispose() {
    _cepFocus.removeListener(_aoSairCep);
    _cepFocus.dispose();
    for (final c in [
      _nome,
      _email,
      _senha,
      _confirmarSenha,
      _cpf,
      _telefone,
      _instagram,
      _linkBio,
      _cep,
      _logradouro,
      _numero,
      _bairro,
      _cidade,
      _estado,
      _crefNumero,
      _whatsapp,
      _valorAvulso,
      _bio,
    ]) {
      c.dispose();
    }
    for (final p in _planos) {
      p.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _sincronizarWhatsapp() {
    if (_whatsappIgualTelefone) _whatsapp.text = _telefone.text;
  }

  Future<void> _carregarAcademias() async {
    setState(() {
      _carregandoAcademias = true;
      _erroAcademias = null;
    });
    try {
      final json = await _cadastroRepository.listarAcademiasDisponiveis();
      if (!mounted) return;
      setState(() => _academias = json.map(_AcademiaDisponivel.fromJson).toList());
    } catch (e, st) {
      AppLogger.i.error('Falha ao carregar academias no cadastro do personal: $e', st);
      if (mounted) setState(() => _erroAcademias = 'Não conseguimos carregar as academias.');
    } finally {
      if (mounted) setState(() => _carregandoAcademias = false);
    }
  }

  // ───────────────────────── navegação ─────────────────────────

  bool _validarPasso(int passo) {
    switch (passo) {
      case 0:
        return _formConta.currentState?.validate() ?? false;
      case 1:
        return _formRegistro.currentState?.validate() ?? false;
      case 2:
        final erro = _faixas.isEmpty ? 'Adicione pelo menos um local de atendimento' : null;
        setState(() => _erroLocais = erro);
        return erro == null;
      case 3:
        return _formPlanos.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  void _irPara(int passo) {
    _pageController.animateToPage(passo,
        duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
  }

  void _continuar() {
    if (!_validarPasso(_passoAtual)) return;
    if (_voltarParaRevisao) {
      setState(() => _voltarParaRevisao = false);
      _irPara(_titulos.length - 1);
      return;
    }
    if (_passoAtual < _titulos.length - 1) _irPara(_passoAtual + 1);
  }

  /// "Editar" na revisão: abre o passo e volta direto à revisão ao salvar.
  void _editarNaRevisao(int passo) {
    setState(() => _voltarParaRevisao = true);
    _irPara(passo);
  }

  // ───────────────────────── envio ─────────────────────────

  List<Map<String, dynamic>> _planosApi() => [
        for (final p in _planos)
          {
            'nome': p.nome.text.trim(),
            'descricao': p.descricao.text.trim(),
            'valor': lerMoeda(p.valor.text),
            'qtdAula': p.aulas,
            'modalidade': p.modalidade,
            'academiaId': p.modalidade == 'academia' ? p.academiaId : null,
          },
      ];

  Future<void> _concluir() async {
    if (!_declaracaoAceita) {
      setState(() => _erroDeclaracao = 'Confirme a declaração para concluir.');
      return;
    }
    setState(() => _enviando = true);
    final body = <String, dynamic>{
      'nome': _nome.text.trim(),
      'email': _email.text.trim(),
      'senha': _senha.text,
      'cpf': _cpf.text.trim(),
      'telefone1': _telefone.text.trim(),
      'instagram': normalizarInstagramCadastro(_instagram.text),
      'linkBio': _linkBio.text.trim(),
      'dtNascimento': _dataNascimento?.toIso8601String().substring(0, 10),
      'sexo': _sexo,
      'cep': _cep.text.trim(),
      'logradouro': _logradouro.text.trim(),
      'numero': _numero.text.trim(),
      'bairro': _bairro.text.trim(),
      'cidade': _cidade.text.trim(),
      'estado': _estado.text.trim(),
      'cref': montarCref(_crefNumero.text, _crefCategoria, _crefUf ?? ''),
      'whatsapp': whatsappComDdi(_whatsapp.text),
      'bio': _bio.text.trim(),
      'vlrAula': lerMoeda(_valorAvulso.text),
      'academiaId': _academiaPrincipalId,
      'atendimentos': [for (final f in _faixas) f.toApi()],
      'planos': _planosApi(),
    };
    final resposta = await _cadastroRepository.registrarPersonal(body);
    if (!mounted) return;
    setState(() => _enviando = false);
    if (resposta['error'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(resposta['message']?.toString() ?? 'Não foi possível concluir o cadastro.'),
        backgroundColor: GridColors.error,
        action: SnackBarAction(label: 'Tentar de novo', textColor: Colors.white, onPressed: _concluir),
      ));
      return;
    }
    await _apagarRascunho();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro realizado com sucesso! Faça login para continuar.')));
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final ultimo = _passoAtual == _titulos.length - 1;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmarSaida() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: GridColors.background,
        appBar: AppBar(title: const Text('Criar conta - Personal')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(children: [
                _progresso(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) {
                      setState(() => _passoAtual = i);
                      _salvarRascunho();
                    },
                    children: [
                      _passoConta(),
                      _passoRegistro(),
                      _passoLocais(),
                      _passoPlanos(),
                      _passoRevisao(),
                    ],
                  ),
                ),
                _rodape(ultimo),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _progresso() => Semantics(
        label: 'Passo ${_passoAtual + 1} de ${_titulos.length}, ${_titulos[_passoAtual]}',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              for (var i = 0; i < _titulos.length; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: i < _passoAtual ? () => _irPara(i) : null,
                    child: Container(
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i <= _passoAtual ? GridColors.primary : GridColors.divider,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 8),
            Text('Passo ${_passoAtual + 1} de ${_titulos.length} · ${_titulos[_passoAtual]}',
                style: const TextStyle(color: GridColors.textSecondary, fontSize: 13)),
          ]),
        ),
      );

  /// Declaração obrigatória, fixa acima do botão "Concluir cadastro".
  Widget _declaracao() => CheckboxListTile(
        key: const Key('chk_declaracao'),
        contentPadding: EdgeInsets.zero,
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        value: _declaracaoAceita,
        onChanged: (v) => setState(() {
          _declaracaoAceita = v ?? false;
          _erroDeclaracao = null;
        }),
        title: const Text('Declaro que as informações são verdadeiras e que meu CREF está ativo.'),
        subtitle: _erroDeclaracao == null
            ? null
            : Text(_erroDeclaracao!, style: const TextStyle(color: GridColors.error)),
      );

  Widget _rodape(bool ultimo) => Material(
        color: GridColors.background,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (ultimo) _declaracao(),
            _botoesRodape(ultimo),
          ]),
        ),
      );

  Widget _botoesRodape(bool ultimo) => Row(children: [
        if (_passoAtual > 0) ...[
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: _enviando ? null : () => _irPara(_passoAtual - 1),
              child: const Text('Voltar'),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton(
            key: const Key('btn_wizard_continuar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: GridColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _enviando ? null : (ultimo ? _concluir : _continuar),
            child: _enviando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(ultimo
                    ? 'Concluir cadastro'
                    : (_voltarParaRevisao ? 'Salvar e voltar à revisão' : 'Continuar')),
          ),
        ),
      ]);

  Widget _cabecalhoPasso(int passo) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_titulos[passo],
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: GridColors.textPrimary)),
          const SizedBox(height: 4),
          Text(_subtitulos[passo], style: const TextStyle(color: GridColors.textSecondary)),
        ]),
      );

  InputDecoration _decoracao(String label, {String? ajuda, Widget? sufixo, String? prefixo}) =>
      InputDecoration(
        labelText: label,
        helperText: ajuda,
        helperMaxLines: 2,
        suffixIcon: sufixo,
        prefixText: prefixo,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _campo(
    TextEditingController c,
    String label, {
    String? Function(String?)? validator,
    TextInputType? teclado,
    bool obscure = false,
    Widget? sufixo,
    String? ajuda,
    List<TextInputFormatter>? formatadores,
    bool readOnly = false,
    FocusNode? focusNode,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          focusNode: focusNode,
          obscureText: obscure,
          readOnly: readOnly,
          keyboardType: teclado,
          inputFormatters: formatadores,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: _decoracao(label, ajuda: ajuda, sufixo: sufixo),
          validator: validator,
        ),
      );

  // ───────────────────────── Passo 1: conta ─────────────────────────

  Widget _passoConta() => Form(
        key: _formConta,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _cabecalhoPasso(0),
          _campo(_nome, 'Nome completo *',
              validator: (v) => (v ?? '').trim().split(' ').length < 2 ? 'Informe seu nome completo' : null),
          _campo(_email, 'E-mail *',
              teclado: TextInputType.emailAddress,
              validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim())
                  ? null
                  : 'E-mail inválido'),
          _campo(_senha, 'Senha *',
              obscure: _obscurarSenha,
              ajuda: 'Mínimo de 6 caracteres',
              sufixo: IconButton(
                tooltip: _obscurarSenha ? 'Mostrar senha' : 'Ocultar senha',
                icon: Icon(_obscurarSenha ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurarSenha = !_obscurarSenha),
              ),
              validator: (v) => (v ?? '').length < 6 ? 'A senha precisa ter pelo menos 6 caracteres' : null),
          _campo(_confirmarSenha, 'Confirmar senha *',
              obscure: _obscurarSenha, validator: (v) => v != _senha.text ? 'As senhas não coincidem' : null),
          _campo(_cpf, 'CPF *',
              teclado: TextInputType.number,
              formatadores: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
              validator: (v) => somenteDigitos(v ?? '').length != 11 ? 'CPF inválido (11 dígitos)' : null),
          _campo(_telefone, 'Telefone *',
              teclado: TextInputType.phone,
              formatadores: [_MascaraCelular()],
              validator: (v) => somenteDigitos(v ?? '').length < 10 ? 'Informe o telefone com DDD' : null),
          CamposRedesSociaisCadastro(instagram:_instagram,linkBio:_linkBio),
          InkWell(
            onTap: () async {
              final hoje = DateTime.now();
              final d = await showDatePicker(
                context: context,
                initialDate: _dataNascimento ?? DateTime(hoje.year - 25),
                firstDate: DateTime(1900),
                lastDate: hoje,
              );
              if (d != null) setState(() => _dataNascimento = d);
            },
            child: InputDecorator(
              decoration:
                  _decoracao('Data de nascimento (opcional)', sufixo: const Icon(Icons.calendar_today)),
              child: Text(_dataNascimento == null
                  ? 'Selecione'
                  : '${_dataNascimento!.day.toString().padLeft(2, '0')}/'
                      '${_dataNascimento!.month.toString().padLeft(2, '0')}/${_dataNascimento!.year}'),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _sexo,
            decoration: _decoracao('Sexo (opcional)'),
            items: const [
              DropdownMenuItem(value: 'M', child: Text('Masculino')),
              DropdownMenuItem(value: 'F', child: Text('Feminino')),
            ],
            onChanged: (v) => setState(() => _sexo = v),
          ),
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Adicionar endereço (opcional)'),
            children: [
              _campo(_cep, 'CEP', teclado: TextInputType.number, focusNode: _cepFocus,
                sufixo: _buscandoCep ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) : IconButton(tooltip: 'Buscar CEP', onPressed: _buscarCep, icon: const Icon(Icons.search))),
              if (_erroCep != null) Text(_erroCep!, style: const TextStyle(color: Colors.red)),
              _campo(_logradouro, 'Logradouro'),
              _campo(_numero, 'Número'),
              _campo(_bairro, 'Bairro'),
              _campo(_cidade, 'Cidade'),
              _campo(_estado, 'Estado'),
            ],
          ),
        ]),
      );

  // ───────────────────────── Passo 2: registro e contato ─────────────────────────

  Widget _passoRegistro() => Form(
        key: _formRegistro,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _cabecalhoPasso(1),
          const Text('CREF *', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Está na sua carteira do CREF. G = graduado, P = provisionado. Ex.: 012345-G/MG',
              style: TextStyle(color: GridColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                key: const Key('campo_cref_numero'),
                controller: _crefNumero,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6)
                ],
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: _decoracao('Número'),
                onChanged: (_) => setState(() {}),
                validator: (_) => validarCref(_crefNumero.text, _crefCategoria, _crefUf),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'G', label: Text('G')),
                  ButtonSegment(value: 'P', label: Text('P')),
                ],
                selected: {_crefCategoria},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _crefCategoria = s.first),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                key: const Key('campo_cref_uf'),
                value: _crefUf,
                isExpanded: true,
                decoration: _decoracao('UF'),
                items: [for (final uf in ufs) DropdownMenuItem(value: uf, child: Text(uf))],
                onChanged: (v) => setState(() => _crefUf = v),
              ),
            ),
          ]),
          if (_crefNumero.text.isNotEmpty && _crefUf != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Seu CREF: ${montarCref(_crefNumero.text, _crefCategoria, _crefUf!)}',
                  style: const TextStyle(color: GridColors.primary, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 20),
          const Text('WhatsApp profissional *', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('É por aqui que os alunos vão entrar em contato com você.',
              style: TextStyle(color: GridColors.textSecondary, fontSize: 13)),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _whatsappIgualTelefone,
            title: const Text('Mesmo número do telefone'),
            onChanged: (v) => setState(() {
              _whatsappIgualTelefone = v ?? false;
              _sincronizarWhatsapp();
            }),
          ),
          TextFormField(
            key: const Key('campo_whatsapp'),
            controller: _whatsapp,
            readOnly: _whatsappIgualTelefone,
            keyboardType: TextInputType.phone,
            inputFormatters: [_MascaraCelular()],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: _decoracao('WhatsApp', ajuda: 'Celular com DDD', prefixo: '+55 '),
            onChanged: (_) => setState(() {}),
            validator: (v) => validarWhatsapp(v ?? ''),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Testar no WhatsApp'),
              onPressed: validarWhatsapp(_whatsapp.text) != null
                  ? null
                  : () async {
                      final uri = Uri.parse('https://wa.me/${whatsappComDdi(_whatsapp.text)}'
                          '?text=${Uri.encodeComponent('Teste do meu perfil no Eu Atleta')}');
                      try {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } catch (e, st) {
                        AppLogger.i.error('Falha ao abrir WhatsApp: $e', st);
                      }
                    },
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('campo_bio'),
            controller: _bio,
            maxLength: 160,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: _decoracao('Mini-bio (opcional)',
                ajuda:
                    'Conte em uma frase como você trabalha. Ex.: "Foco em hipertrofia e emagrecimento, 8 anos de experiência."'),
          ),
        ]),
      );

  // ───────────────────────── Passo 3: locais e horários ─────────────────────────

  Widget _passoLocais() {
    final locais = <String, List<FaixaAtendimento>>{};
    for (final f in _faixas) {
      locais.putIfAbsent('${f.academiaId ?? 'sem'}|${f.localNome}', () => []).add(f);
    }
    final soSemAcademia = _faixas.isNotEmpty && _faixas.every((f) => f.academiaId == null);
    return ListView(padding: const EdgeInsets.all(16), children: [
      _cabecalhoPasso(2),
      if (_carregandoAcademias)
        Semantics(
          label: 'Carregando academias',
          child: Column(children: [
            for (var i = 0; i < 2; i++)
              Container(
                height: 56,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: GridColors.divider, borderRadius: BorderRadius.circular(12)),
              ),
          ]),
        ),
      if (_erroAcademias != null)
        Row(children: [
          Expanded(child: Text(_erroAcademias!, style: const TextStyle(color: GridColors.error))),
          TextButton(onPressed: _carregarAcademias, child: const Text('Tentar de novo')),
        ]),
      if (_faixas.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Nenhum local ainda. Onde você costuma treinar seus alunos?',
              style: TextStyle(color: GridColors.textSecondary)),
        ),
      for (final entrada in locais.entries) _cardLocal(entrada.value),
      if (soSemAcademia)
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('Você não aparecerá na busca por academia; alunos te acham pelo nome.',
              style: TextStyle(color: GridColors.secondaryDark, fontSize: 13)),
        ),
      if (_erroLocais != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(_erroLocais!, style: const TextStyle(color: GridColors.error)),
        ),
      const SizedBox(height: 8),
      ElevatedButton.icon(
        key: const Key('btn_add_academia'),
        style: ElevatedButton.styleFrom(
            backgroundColor: GridColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48)),
        onPressed: _academias.isEmpty ? null : () => _editarFaixa(semAcademia: false),
        icon: const Icon(Icons.add),
        label: const Text('Atender em uma academia'),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        key: const Key('btn_add_sem_academia'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: () => _editarFaixa(semAcademia: true),
        icon: const Icon(Icons.home_work_outlined),
        label: const Text('Atendo sem academia'),
      ),
      if (_faixas.any((f) => f.academiaId != null))
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text('Os alunos filtram personais pela academia principal.',
              style: TextStyle(color: GridColors.textSecondary, fontSize: 13)),
        ),
    ]);
  }

  Widget _cardLocal(List<FaixaAtendimento> faixas) {
    final local = faixas.first;
    final principal = local.academiaId != null && local.academiaId == _academiaPrincipalId;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(local.academiaId != null ? Icons.fitness_center : Icons.home_work_outlined,
                color: GridColors.primary),
            const SizedBox(width: 8),
            Expanded(
                child:
                    Text(local.localNome, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
            if (principal)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration:
                    BoxDecoration(color: GridColors.secondary, borderRadius: BorderRadius.circular(8)),
                child: const Text('Principal',
                    style:
                        TextStyle(color: GridColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            if (local.academiaId != null && !principal)
              TextButton(
                onPressed: () => setState(() => _academiaPrincipalId = local.academiaId),
                child: const Text('Tornar principal'),
              ),
          ]),
          for (final f in faixas)
            Row(children: [
              const SizedBox(width: 32),
              Expanded(child: Text(f.resumo)),
              IconButton(
                tooltip: 'Remover horário',
                icon: const Icon(Icons.delete_outline, color: GridColors.error),
                onPressed: () => _removerFaixa(f),
              ),
            ]),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Outra faixa de horário'),
              onPressed: () => _editarFaixa(
                  semAcademia: local.academiaId == null,
                  academiaId: local.academiaId,
                  localNome: local.localNome,
                  diasIniciais: faixas.last.dias),
            ),
          ),
        ]),
      ),
    );
  }

  void _removerFaixa(FaixaAtendimento f) {
    final indice = _faixas.indexOf(f);
    setState(() {
      _faixas.remove(f);
      if (!_faixas.any((x) => x.academiaId == _academiaPrincipalId)) {
        _academiaPrincipalId =
            _faixas.map((x) => x.academiaId).firstWhere((id) => id != null, orElse: () => null);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Horário removido'),
      action: SnackBarAction(
        label: 'Desfazer',
        onPressed: () => setState(() {
          _faixas.insert(indice.clamp(0, _faixas.length), f);
          _academiaPrincipalId ??= f.academiaId;
        }),
      ),
    ));
  }

  Future<void> _editarFaixa({
    required bool semAcademia,
    int? academiaId,
    String? localNome,
    Set<int> diasIniciais = const {},
  }) async {
    final nova = await showModalBottomSheet<FaixaAtendimento>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditorFaixa(
        semAcademia: semAcademia,
        academias: [for (final a in _academias) (a.id, a.nome)],
        academiaFixa: academiaId,
        localFixo: localNome,
        diasIniciais: diasIniciais,
        modosSemAcademia: _modosSemAcademia,
        existentes: List.of(_faixas),
      ),
    );
    if (nova == null) return;
    setState(() {
      _faixas.add(nova);
      _erroLocais = null;
      if (nova.academiaId != null) _academiaPrincipalId ??= nova.academiaId;
    });
  }

  // ───────────────────────── Passo 4: planos e valores ─────────────────────────

  Widget _passoPlanos() {
    final avulso = lerMoeda(_valorAvulso.text);
    return Form(
      key: _formPlanos,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        _cabecalhoPasso(3),
        TextFormField(
          key: const Key('campo_valor_avulso'),
          controller: _valorAvulso,
          keyboardType: TextInputType.number,
          inputFormatters: [_MascaraMoeda()],
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: _decoracao('Valor da aula avulsa *', ajuda: 'Quanto custa uma aula sem pacote'),
          onChanged: (_) => setState(() {}),
          validator: (v) => (lerMoeda(v ?? '') ?? 0) <= 0 ? 'Informe o valor da aula avulsa' : null,
        ),
        const SizedBox(height: 20),
        const Text('Planos (opcional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 4),
        const Text('Toque em um modelo para começar; você só digita o valor.',
            style: TextStyle(color: GridColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (nome, aulas) in presetsPlano)
            ActionChip(
              label: Text(nome),
              onPressed: () => setState(() => _planos.add(_PlanoEdicao(nome: nome, aulas: aulas))),
            ),
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: const Text('Criar plano'),
            onPressed: () => setState(() => _planos.add(_PlanoEdicao(nome: ''))),
          ),
        ]),
        const SizedBox(height: 12),
        if (_planos.isEmpty)
          const Text('Sem planos por enquanto. Alunos verão só o valor avulso.',
              style: TextStyle(color: GridColors.textSecondary)),
        for (var i = 0; i < _planos.length; i++) _cardPlano(i, avulso),
      ]),
    );
  }

  Widget _cardPlano(int i, double? avulso) {
    final p = _planos[i];
    final porAula = valorPorAula(lerMoeda(p.valor.text), p.aulas);
    final maisCaro = porAula != null && avulso != null && porAula > avulso;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: p.nome,
                maxLength: 40,
                decoration: _decoracao('Nome do plano *').copyWith(counterText: ''),
                validator: (v) {
                  final nome = (v ?? '').trim();
                  if (nome.isEmpty) return 'Dê um nome ao plano';
                  final repetidos =
                      _planos.where((x) => x.nome.text.trim().toLowerCase() == nome.toLowerCase());
                  return repetidos.length > 1 ? 'Já existe um plano com esse nome' : null;
                },
              ),
            ),
            IconButton(
              tooltip: 'Duplicar plano',
              icon: const Icon(Icons.copy_outlined),
              onPressed: () => setState(() => _planos.insert(
                  i + 1,
                  _PlanoEdicao(nome: '${p.nome.text.trim()} (cópia)', aulas: p.aulas)
                    ..valor.text = p.valor.text
                    ..descricao.text = p.descricao.text
                    ..modalidade = p.modalidade
                    ..academiaId = p.academiaId)),
            ),
            IconButton(
              tooltip: 'Remover plano',
              icon: const Icon(Icons.delete_outline, color: GridColors.error),
              onPressed: () => setState(() => _planos.removeAt(i).dispose()),
            ),
          ]),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: ValueKey(('modalidade', p)),
            initialValue: p.modalidade,
            decoration: _decoracao('Modalidade do atendimento'),
            items: const [
              DropdownMenuItem(value: 'online', child: Text('Online')),
              DropdownMenuItem(value: 'domicilio', child: Text('A domicílio')),
              DropdownMenuItem(value: 'academia', child: Text('Em academia')),
            ],
            onChanged: (v) => setState(() {
              p.modalidade = v!;
              if (v != 'academia') p.academiaId = null;
            }),
          ),
          if (p.modalidade == 'academia') ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: ValueKey(('academia', p)),
              initialValue: p.academiaId ?? 0,
              isExpanded: true,
              decoration: _decoracao('Academia do plano'),
              items: [
                const DropdownMenuItem(value: 0, child: Text('Sem academia definida')),
                for (final a in _academias)
                  DropdownMenuItem(value: a.id, child: Text(a.nome, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => p.academiaId = v == 0 ? null : v),
            ),
          ],
          const SizedBox(height: 10),
          Row(children: [
            const Text('Aulas por mês'),
            const Spacer(),
            IconButton(
              tooltip: 'Menos aulas',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: p.aulas > 1 ? () => setState(() => p.aulas--) : null,
            ),
            Text('${p.aulas}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            IconButton(
              tooltip: 'Mais aulas',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: p.aulas < 31 ? () => setState(() => p.aulas++) : null,
            ),
          ]),
          TextFormField(
            controller: p.valor,
            keyboardType: TextInputType.number,
            inputFormatters: [_MascaraMoeda()],
            decoration: _decoracao('Valor do plano por mês *'),
            onChanged: (_) => setState(() {}),
            validator: (v) => (lerMoeda(v ?? '') ?? 0) <= 0 ? 'Informe o valor do plano' : null,
          ),
          if (porAula != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('≈ ${formatarMoeda(porAula)} por aula',
                  style: const TextStyle(color: GridColors.textSecondary)),
            ),
          if (maisCaro)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Este plano sai mais caro que a aula avulsa.',
                  style: TextStyle(color: GridColors.secondaryDark, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 10),
          TextFormField(
            controller: p.descricao,
            maxLength: 200,
            maxLines: 2,
            decoration: _decoracao('Descrição (opcional)'),
          ),
        ]),
      ),
    );
  }

  // ───────────────────────── Passo 5: revisão ─────────────────────────

  Widget _passoRevisao() {
    final nome = _nome.text.trim();
    final iniciais =
        nome.isEmpty ? '?' : nome.split(RegExp(r'\s+')).take(2).map((p) => p[0].toUpperCase()).join();
    final principal = _academias.where((a) => a.id == _academiaPrincipalId).map((a) => a.nome).firstOrNull;
    final menorPlano = _planos
        .map((p) => lerMoeda(p.valor.text))
        .whereType<double>()
        .fold<double?>(null, (m, v) => m == null || v < m ? v : m);
    final cref = _crefUf == null ? '—' : montarCref(_crefNumero.text, _crefCategoria, _crefUf!);

    Widget secao(String titulo, int passo, List<String> linhas) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 4, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700))),
                TextButton(onPressed: () => _editarNaRevisao(passo), child: const Text('Editar')),
              ]),
              for (final l in linhas) Text(l, style: const TextStyle(color: GridColors.textSecondary)),
            ]),
          ),
        );

    return ListView(padding: const EdgeInsets.all(16), children: [
      _cabecalhoPasso(4),
      Card(
        color: GridColors.primarySubtle,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: GridColors.primary,
              child: Text(iniciais,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nome.isEmpty ? 'Seu nome' : nome,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Row(children: [
                  const Icon(Icons.verified, size: 16, color: GridColors.primary),
                  const SizedBox(width: 4),
                  Text('CREF $cref'),
                ]),
                if (principal != null)
                  Text(principal, style: const TextStyle(color: GridColors.textSecondary)),
                if (_bio.text.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(_bio.text.trim(), style: const TextStyle(fontStyle: FontStyle.italic)),
                  ),
                Text(
                  menorPlano != null
                      ? 'A partir de ${formatarMoeda(menorPlano)}/mês'
                      : 'Aula avulsa: ${_valorAvulso.text.isEmpty ? '—' : _valorAvulso.text}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ]),
            ),
            const Icon(Icons.chat, color: GridColors.textMuted),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      secao('Conta', 0, [
        nome,
        _email.text.trim(),
        _telefone.text,
        if (_instagram.text.trim().isNotEmpty)
          'Instagram: @${normalizarInstagramCadastro(_instagram.text) ?? _instagram.text.trim()}',
        if (_linkBio.text.trim().isNotEmpty)
          'Link da bio: ${_linkBio.text.trim()}',
      ]),
      secao('Registro e contato', 1, [
        'CREF $cref',
        'WhatsApp +55 ${_whatsapp.text}',
        if (_bio.text.trim().isNotEmpty) 'Bio: ${_bio.text.trim()}',
      ]),
      secao('Locais e horários', 2, [
        for (final f in _faixas) '${f.localNome}: ${f.resumo}',
        if (_faixas.isEmpty) 'Nenhum local informado',
      ]),
      secao('Planos e valores', 3, [
        'Aula avulsa: ${_valorAvulso.text.isEmpty ? '—' : _valorAvulso.text}',
        for (final p in _planos) '${p.nome.text} · ${p.aulas} aulas/mês · ${p.valor.text} · ${p.modalidade == 'domicilio' ? 'A domicílio' : p.modalidade == 'online' ? 'Online' : 'Em academia'}',
      ]),
    ]);
  }
}

/// Bottom sheet para adicionar uma faixa de atendimento (local + dias + horário).
class _EditorFaixa extends StatefulWidget {
  const _EditorFaixa({
    required this.semAcademia,
    required this.academias,
    required this.academiaFixa,
    required this.localFixo,
    required this.diasIniciais,
    required this.modosSemAcademia,
    required this.existentes,
  });

  final bool semAcademia;
  final List<(int, String)> academias;
  final int? academiaFixa;
  final String? localFixo;
  final Set<int> diasIniciais;
  final List<String> modosSemAcademia;
  final List<FaixaAtendimento> existentes;

  @override
  State<_EditorFaixa> createState() => _EditorFaixaState();
}

class _EditorFaixaState extends State<_EditorFaixa> {
  int? _academiaId;
  String? _modo;
  late Set<int> _dias;
  TimeOfDay _inicio = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _fim = const TimeOfDay(hour: 10, minute: 0);
  String? _erro;

  @override
  void initState() {
    super.initState();
    _academiaId = widget.academiaFixa;
    _modo = widget.semAcademia ? (widget.localFixo ?? widget.modosSemAcademia.first) : null;
    _dias = Set.of(widget.diasIniciais);
  }

  String _hora(TimeOfDay t) => formatarHora(t.hour, t.minute);

  Future<void> _escolherHora(bool inicio) async {
    final t = await showTimePicker(context: context, initialTime: inicio ? _inicio : _fim);
    if (t == null) return;
    setState(() => inicio ? _inicio = t : _fim = t);
  }

  void _salvar() {
    final localNome = widget.semAcademia
        ? (_modo ?? widget.modosSemAcademia.first)
        : widget.academias.where((a) => a.$1 == _academiaId).map((a) => a.$2).firstOrNull;
    if (!widget.semAcademia && localNome == null) {
      setState(() => _erro = 'Escolha a academia');
      return;
    }
    final erroFaixa = validarFaixa(_dias, _hora(_inicio), _hora(_fim));
    if (erroFaixa != null) {
      setState(() => _erro = erroFaixa);
      return;
    }
    final faixa = FaixaAtendimento(
      academiaId: widget.semAcademia ? null : _academiaId,
      localNome: localNome!,
      dias: _dias,
      inicio: _hora(_inicio),
      fim: _hora(_fim),
    );
    final conflito = conflitoFaixa(faixa, widget.existentes);
    if (conflito != null) {
      setState(() => _erro = conflito);
      return;
    }
    Navigator.pop(context, faixa);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(widget.semAcademia ? 'Atendimento sem academia' : 'Atendimento em academia',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          if (widget.semAcademia)
            Wrap(spacing: 8, children: [
              for (final m in widget.modosSemAcademia)
                ChoiceChip(
                  label: Text(m),
                  selected: _modo == m,
                  onSelected: widget.localFixo != null ? null : (_) => setState(() => _modo = m),
                ),
            ])
          else
            DropdownButtonFormField<int>(
              key: const Key('editor_academia'),
              value: _academiaId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Academia',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                for (final a in widget.academias)
                  DropdownMenuItem(value: a.$1, child: Text(a.$2, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: widget.academiaFixa != null ? null : (v) => setState(() => _academiaId = v),
            ),
          const SizedBox(height: 16),
          Row(children: [
            const Expanded(child: Text('Dias', style: TextStyle(fontWeight: FontWeight.w700))),
            TextButton(
                onPressed: () => setState(() => _dias = {0, 1, 2, 3, 4}), child: const Text('Seg–Sex')),
            TextButton(
                onPressed: () => setState(() => _dias = {0, 1, 2, 3, 4, 5, 6}), child: const Text('Todos')),
            TextButton(onPressed: () => setState(() => _dias = {}), child: const Text('Limpar')),
          ]),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (var d = 0; d < 7; d++)
              FilterChip(
                key: Key('chip_dia_$d'),
                label: Text(diasSemanaAbrev[d]),
                selected: _dias.contains(d),
                onSelected: (s) => setState(() => s ? _dias.add(d) : _dias.remove(d)),
              ),
          ]),
          const SizedBox(height: 16),
          const Text('Horário', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                icon: const Icon(Icons.schedule),
                label: Text('Das ${_hora(_inicio)}'),
                onPressed: () => _escolherHora(true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                icon: const Icon(Icons.schedule),
                label: Text('Até ${_hora(_fim)}'),
                onPressed: () => _escolherHora(false),
              ),
            ),
          ]),
          if (_dias.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('Resumo: ${resumoDias(_dias)} · ${_hora(_inicio)}–${_hora(_fim)}',
                  style: const TextStyle(color: GridColors.primary, fontWeight: FontWeight.w600)),
            ),
          if (_erro != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_erro!, style: const TextStyle(color: GridColors.error)),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            key: const Key('btn_salvar_faixa'),
            style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48)),
            onPressed: _salvar,
            child: const Text('Salvar horário'),
          ),
        ]),
      ),
    );
  }
}

class _MascaraCelular extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final texto = mascararCelular(newValue.text);
    return TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));
  }
}

class _MascaraMoeda extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final texto = mascararMoeda(newValue.text);
    return TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));
  }
}
