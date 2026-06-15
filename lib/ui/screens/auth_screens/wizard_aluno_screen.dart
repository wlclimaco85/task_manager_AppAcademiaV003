import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/repository/cadastro_repository.dart';
import 'package:task_manager_flutter/data/utils/grid_colors.dart';

/// Wizard de cadastro do Aluno, em 3 passos:
/// 1) Dados pessoais, 2) Personal Trainer (opcional), 3) Objetivo e peso.
class WizardAlunoScreen extends StatefulWidget {
  const WizardAlunoScreen({super.key});

  @override
  State<WizardAlunoScreen> createState() => _WizardAlunoScreenState();
}

/// Representa um Personal disponível para o aluno escolher no passo 2.
class _PersonalDisponivel {
  final int id;
  final String nome;
  final String cref;
  final List<_ModalidadeDisponivel> modalidades;

  _PersonalDisponivel({
    required this.id,
    required this.nome,
    required this.cref,
    required this.modalidades,
  });

  factory _PersonalDisponivel.fromJson(Map<String, dynamic> json) {
    final modalidadesJson = json['modalidades'] as List<dynamic>? ?? [];
    return _PersonalDisponivel(
      id: json['id'] as int,
      nome: json['nome'] as String? ?? '',
      cref: json['cref'] as String? ?? '',
      modalidades: modalidadesJson
          .map((m) =>
              _ModalidadeDisponivel.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Representa uma modalidade vinculada a um Personal.
class _ModalidadeDisponivel {
  final int id;
  final String nome;

  _ModalidadeDisponivel({required this.id, required this.nome});

  factory _ModalidadeDisponivel.fromJson(Map<String, dynamic> json) {
    return _ModalidadeDisponivel(
      id: json['id'] as int,
      nome: json['nome'] as String? ?? '',
    );
  }
}

class _WizardAlunoScreenState extends State<WizardAlunoScreen> {
  static const int _totalPassos = 3;

  final PageController _pageController = PageController();
  final CadastroRepository _cadastroRepository = CadastroRepository();

  int _passoAtual = 0;
  bool _enviando = false;

  // Passo 1 - Dados pessoais
  final _formKeyDadosPessoais = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cepController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  bool _obscurarSenha = true;
  bool _obscurarConfirmarSenha = true;
  DateTime? _dataNascimento;
  String? _sexo;

  // Passo 2 - Personal
  bool? _temPersonal;
  bool _carregandoPersonais = false;
  String? _erroCarregarPersonais;
  List<_PersonalDisponivel> _personaisDisponiveis = [];
  _PersonalDisponivel? _personalSelecionado;
  _ModalidadeDisponivel? _modalidadeSelecionada;

  // Passo 3 - Objetivo e peso
  final _formKeyObjetivo = GlobalKey<FormState>();
  final _objetivoController = TextEditingController();
  final _pesoController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _objetivoController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarDataNascimento() async {
    final hoje = DateTime.now();
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: DateTime(hoje.year - 18, hoje.month, hoje.day),
      firstDate: DateTime(1900),
      lastDate: hoje,
    );
    if (dataEscolhida != null) {
      setState(() => _dataNascimento = dataEscolhida);
    }
  }

  String _formatarData(DateTime data) {
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');
    return '${data.year}-$mes-$dia';
  }

  String _formatarDataExibicao(DateTime data) {
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  Future<void> _carregarPersonaisDisponiveis() async {
    setState(() {
      _carregandoPersonais = true;
      _erroCarregarPersonais = null;
    });

    try {
      final personaisJson =
          await _cadastroRepository.listarPersonaisDisponiveis();
      setState(() {
        _personaisDisponiveis =
            personaisJson.map(_PersonalDisponivel.fromJson).toList();
      });
    } catch (e) {
      setState(() {
        _erroCarregarPersonais = 'Não foi possível carregar os personais.';
      });
    } finally {
      setState(() => _carregandoPersonais = false);
    }
  }

  void _onTemPersonalChanged(bool valor) {
    setState(() {
      _temPersonal = valor;
      if (!valor) {
        _personalSelecionado = null;
        _modalidadeSelecionada = null;
      }
    });
    if (valor && _personaisDisponiveis.isEmpty && !_carregandoPersonais) {
      _carregarPersonaisDisponiveis();
    }
  }

  void _selecionarPersonal(_PersonalDisponivel personal) {
    setState(() {
      _personalSelecionado = personal;
      _modalidadeSelecionada = null;
    });
  }

  bool _validarPassoAtual() {
    switch (_passoAtual) {
      case 0:
        return _formKeyDadosPessoais.currentState?.validate() ?? false;
      case 1:
        // Passo 2 é opcional - só impede avançar se "Sim" foi marcado
        // mas nenhum personal foi selecionado ainda? Não é obrigatório
        // selecionar, então sempre permite avançar.
        return true;
      case 2:
        return _formKeyObjetivo.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  void _proximoPasso() {
    if (!_validarPassoAtual()) return;

    if (_passoAtual < _totalPassos - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _passoAnterior() {
    if (_passoAtual > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _concluirCadastro() async {
    if (!_validarPassoAtual()) return;

    setState(() => _enviando = true);

    final body = <String, dynamic>{
      'nome': _nomeController.text.trim(),
      'email': _emailController.text.trim(),
      'senha': _senhaController.text,
      'cpf': _cpfController.text.trim(),
      'telefone1': _telefoneController.text.trim(),
      'dtNascimento':
          _dataNascimento != null ? _formatarData(_dataNascimento!) : null,
      'sexo': _sexo,
      'logradouro': _logradouroController.text.trim(),
      'numero': _numeroController.text.trim(),
      'cep': _cepController.text.trim(),
      'bairro': _bairroController.text.trim(),
      'cidade': _cidadeController.text.trim(),
      'estado': _estadoController.text.trim(),
      'personalId': _personalSelecionado?.id,
      'modalidadeId': _modalidadeSelecionada?.id,
      'objetivo': _objetivoController.text.trim(),
      'peso': double.tryParse(_pesoController.text.trim().replaceAll(',', '.')),
    };

    final resposta = await _cadastroRepository.registrarAluno(body);

    setState(() => _enviando = false);

    if (!mounted) return;

    final houveErro = resposta['error'] == true;

    if (houveErro) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resposta['message']?.toString() ??
                'Não foi possível concluir o cadastro.',
          ),
          backgroundColor: GridColors.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Cadastro realizado com sucesso! Faça login para continuar.'),
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(title: const Text('Criar conta - Aluno')),
      body: Column(
        children: [
          _ProgressoWizard(passoAtual: _passoAtual, total: _totalPassos),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _passoAtual = index),
              children: [
                _buildPassoDadosPessoais(),
                _buildPassoPersonal(),
                _buildPassoObjetivo(),
              ],
            ),
          ),
          _buildBarraNavegacao(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Passo 1 - Dados pessoais
  // ---------------------------------------------------------------------
  Widget _buildPassoDadosPessoais() {
    return Form(
      key: _formKeyDadosPessoais,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _TituloPasso(titulo: 'Seus dados'),
          const SizedBox(height: 16),
          _campoTexto(
            controller: _nomeController,
            label: 'Nome completo',
            validator: (valor) => (valor == null || valor.trim().isEmpty)
                ? 'Informe o nome'
                : null,
          ),
          const SizedBox(height: 12),
          _campoTexto(
            controller: _emailController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            validator: (valor) {
              if (valor == null || valor.trim().isEmpty) {
                return 'Informe o email';
              }
              if (!valor.contains('@')) {
                return 'Email inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _campoTexto(
            controller: _senhaController,
            label: 'Senha',
            obscureText: _obscurarSenha,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurarSenha ? Icons.visibility_off : Icons.visibility,
                color: GridColors.textPrimary,
              ),
              onPressed: () =>
                  setState(() => _obscurarSenha = !_obscurarSenha),
            ),
            validator: (valor) => (valor == null || valor.isEmpty)
                ? 'Informe a senha'
                : null,
          ),
          const SizedBox(height: 12),
          _campoTexto(
            controller: _confirmarSenhaController,
            label: 'Confirmar senha',
            obscureText: _obscurarConfirmarSenha,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurarConfirmarSenha
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: GridColors.textPrimary,
              ),
              onPressed: () => setState(
                  () => _obscurarConfirmarSenha = !_obscurarConfirmarSenha),
            ),
            validator: (valor) {
              if (valor == null || valor.isEmpty) {
                return 'Confirme a senha';
              }
              if (valor != _senhaController.text) {
                return 'As senhas não coincidem';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _campoTexto(
            controller: _cpfController,
            label: 'CPF',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _campoTexto(
            controller: _telefoneController,
            label: 'Telefone',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _campoData(),
          const SizedBox(height: 12),
          _campoSexo(),
          const SizedBox(height: 24),
          const _TituloPasso(titulo: 'Endereço'),
          const SizedBox(height: 16),
          _campoTexto(
            controller: _cepController,
            label: 'CEP',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _campoTexto(controller: _logradouroController, label: 'Logradouro'),
          const SizedBox(height: 12),
          _campoTexto(controller: _numeroController, label: 'Número'),
          const SizedBox(height: 12),
          _campoTexto(controller: _bairroController, label: 'Bairro'),
          const SizedBox(height: 12),
          _campoTexto(controller: _cidadeController, label: 'Cidade'),
          const SizedBox(height: 12),
          _campoTexto(controller: _estadoController, label: 'Estado'),
        ],
      ),
    );
  }

  Widget _campoData() {
    final texto = _dataNascimento != null
        ? _formatarDataExibicao(_dataNascimento!)
        : '';
    return InkWell(
      onTap: _selecionarDataNascimento,
      child: InputDecorator(
        decoration: _decoracaoCampo('Data de nascimento').copyWith(
          suffixIcon:
              const Icon(Icons.calendar_today, color: GridColors.textPrimary),
        ),
        child: Text(
          texto.isEmpty ? 'Selecione' : texto,
          style: const TextStyle(color: GridColors.textPrimary),
        ),
      ),
    );
  }

  Widget _campoSexo() {
    return DropdownButtonFormField<String>(
      value: _sexo,
      decoration: _decoracaoCampo('Sexo'),
      dropdownColor: GridColors.primary,
      style: const TextStyle(color: GridColors.textPrimary),
      items: const [
        DropdownMenuItem(value: 'M', child: Text('Masculino')),
        DropdownMenuItem(value: 'F', child: Text('Feminino')),
      ],
      onChanged: (valor) => setState(() => _sexo = valor),
    );
  }

  // ---------------------------------------------------------------------
  // Passo 2 - Personal
  // ---------------------------------------------------------------------
  Widget _buildPassoPersonal() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _TituloPasso(titulo: 'Personal Trainer'),
        const SizedBox(height: 16),
        const Text(
          'Você já tem um Personal Trainer?',
          style: TextStyle(color: GridColors.textPrimary, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Sim'),
                selected: _temPersonal == true,
                onSelected: (_) => _onTemPersonalChanged(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Text('Não'),
                selected: _temPersonal == false,
                onSelected: (_) => _onTemPersonalChanged(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_temPersonal == true) _buildListaPersonais(),
      ],
    );
  }

  Widget _buildListaPersonais() {
    if (_carregandoPersonais) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: GridColors.secondary),
        ),
      );
    }

    if (_erroCarregarPersonais != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          _erroCarregarPersonais!,
          style: const TextStyle(color: GridColors.error),
        ),
      );
    }

    if (_personaisDisponiveis.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Nenhum personal disponível no momento.',
          style: TextStyle(color: GridColors.textPrimary),
        ),
      );
    }

    return Column(
      children: [
        for (final personal in _personaisDisponiveis)
          _buildCardPersonal(personal),
      ],
    );
  }

  Widget _buildCardPersonal(_PersonalDisponivel personal) {
    final selecionado = _personalSelecionado?.id == personal.id;

    return Card(
      color: selecionado ? GridColors.secondary : GridColors.card,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RadioListTile<int>(
              value: personal.id,
              groupValue: _personalSelecionado?.id,
              onChanged: (_) => _selecionarPersonal(personal),
              title: Text(
                personal.nome,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selecionado
                      ? GridColors.textPrimary
                      : GridColors.textSecondary,
                ),
              ),
              subtitle: Text(
                'CREF: ${personal.cref}',
                style: TextStyle(
                  color: selecionado
                      ? GridColors.textPrimary
                      : GridColors.textSecondary,
                ),
              ),
            ),
            if (selecionado && personal.modalidades.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: DropdownButtonFormField<int>(
                  value: _modalidadeSelecionada?.id,
                  decoration: _decoracaoCampo('Modalidade (opcional)').copyWith(
                    labelStyle:
                        const TextStyle(color: GridColors.textSecondary),
                  ),
                  style: const TextStyle(color: GridColors.textSecondary),
                  dropdownColor: GridColors.card,
                  items: [
                    for (final modalidade in personal.modalidades)
                      DropdownMenuItem(
                        value: modalidade.id,
                        child: Text(modalidade.nome),
                      ),
                  ],
                  onChanged: (valorId) {
                    setState(() {
                      _modalidadeSelecionada = personal.modalidades
                          .firstWhere((m) => m.id == valorId);
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Passo 3 - Objetivo e peso
  // ---------------------------------------------------------------------
  Widget _buildPassoObjetivo() {
    return Form(
      key: _formKeyObjetivo,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _TituloPasso(titulo: 'Objetivo e peso'),
          const SizedBox(height: 16),
          _campoTexto(
            controller: _objetivoController,
            label: 'Objetivo (ex.: Perder peso, Ganhar massa muscular)',
            validator: (valor) => (valor == null || valor.trim().isEmpty)
                ? 'Informe o objetivo'
                : null,
          ),
          const SizedBox(height: 12),
          _campoTexto(
            controller: _pesoController,
            label: 'Peso (kg)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (valor) {
              if (valor == null || valor.trim().isEmpty) {
                return 'Informe o peso';
              }
              final peso = double.tryParse(valor.trim().replaceAll(',', '.'));
              if (peso == null || peso <= 0) {
                return 'Peso inválido';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Navegação
  // ---------------------------------------------------------------------
  Widget _buildBarraNavegacao() {
    final ultimoPasso = _passoAtual == _totalPassos - 1;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_passoAtual > 0)
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: GridColors.secondary, width: 2),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: _enviando ? null : _passoAnterior,
                child: const Text(
                  'Voltar',
                  style: TextStyle(color: GridColors.textPrimary, fontSize: 18),
                ),
              ),
            ),
          if (_passoAtual > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.secondary,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _enviando
                  ? null
                  : (ultimoPasso ? _concluirCadastro : _proximoPasso),
              child: _enviando
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      ultimoPasso ? 'Concluir cadastro' : 'Próximo',
                      style: const TextStyle(
                          color: GridColors.textPrimary, fontSize: 18),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Widgets auxiliares de campo
  // ---------------------------------------------------------------------
  InputDecoration _decoracaoCampo(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: GridColors.textPrimary),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: GridColors.secondary, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: GridColors.secondary, width: 2.5),
        borderRadius: BorderRadius.circular(12),
      ),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: GridColors.secondary, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: GridColors.error, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _campoTexto({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: GridColors.textPrimary),
      decoration: _decoracaoCampo(label).copyWith(suffixIcon: suffixIcon),
      validator: validator,
    );
  }
}

/// Indicador de progresso simples do wizard (ex.: "Passo 1 de 3").
class _ProgressoWizard extends StatelessWidget {
  const _ProgressoWizard({required this.passoAtual, required this.total});

  final int passoAtual;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (passoAtual + 1) / total,
            color: GridColors.secondary,
            backgroundColor: GridColors.primaryLight,
          ),
          const SizedBox(height: 8),
          Text(
            'Passo ${passoAtual + 1} de $total',
            style: const TextStyle(color: GridColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

/// Título de seção dentro de um passo do wizard.
class _TituloPasso extends StatelessWidget {
  const _TituloPasso({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Text(
      titulo,
      style: const TextStyle(
        color: GridColors.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
