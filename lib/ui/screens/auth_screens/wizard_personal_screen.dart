import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/repository/cadastro_repository.dart';
import 'package:task_manager_flutter/data/utils/grid_colors.dart';

/// Wizard de cadastro do Personal Trainer, em 2 passos:
/// 1) Dados pessoais e endereço (+ CREF), 2) Academia e planos.
class WizardPersonalScreen extends StatefulWidget {
  const WizardPersonalScreen({super.key});

  @override
  State<WizardPersonalScreen> createState() => _WizardPersonalScreenState();
}

/// Representa uma academia disponível para o personal escolher no passo 2.
class _AcademiaDisponivel {
  final int id;
  final String nome;

  _AcademiaDisponivel({required this.id, required this.nome});

  factory _AcademiaDisponivel.fromJson(Map<String, dynamic> json) {
    return _AcademiaDisponivel(
      id: json['id'] as int,
      nome: json['nome'] as String? ?? '',
    );
  }
}

/// Representa um plano oferecido pelo personal, preenchido no passo 2.
class _PlanoControllers {
  final nomeController = TextEditingController();
  final descricaoController = TextEditingController();
  final valorController = TextEditingController();
  final qtdAulaController = TextEditingController();

  void dispose() {
    nomeController.dispose();
    descricaoController.dispose();
    valorController.dispose();
    qtdAulaController.dispose();
  }
}

class _WizardPersonalScreenState extends State<WizardPersonalScreen> {
  static const int _totalPassos = 2;

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
  final _crefController = TextEditingController();

  bool _obscurarSenha = true;
  bool _obscurarConfirmarSenha = true;
  DateTime? _dataNascimento;
  String? _sexo;

  // Passo 2 - Academia e planos
  bool _carregandoAcademias = false;
  String? _erroCarregarAcademias;
  List<_AcademiaDisponivel> _academiasDisponiveis = [];
  int? _academiaSelecionadaId;
  final List<_PlanoControllers> _planos = [];

  @override
  void initState() {
    super.initState();
    _carregarAcademiasDisponiveis();
  }

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
    _crefController.dispose();
    for (final plano in _planos) {
      plano.dispose();
    }
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

  Future<void> _carregarAcademiasDisponiveis() async {
    setState(() {
      _carregandoAcademias = true;
      _erroCarregarAcademias = null;
    });

    try {
      final academiasJson =
          await _cadastroRepository.listarAcademiasDisponiveis();
      setState(() {
        _academiasDisponiveis =
            academiasJson.map(_AcademiaDisponivel.fromJson).toList();
      });
    } catch (e) {
      setState(() {
        _erroCarregarAcademias = 'Não foi possível carregar as academias.';
      });
    } finally {
      setState(() => _carregandoAcademias = false);
    }
  }

  void _adicionarPlano() {
    setState(() => _planos.add(_PlanoControllers()));
  }

  void _removerPlano(int indice) {
    setState(() {
      _planos[indice].dispose();
      _planos.removeAt(indice);
    });
  }

  bool _validarPassoAtual() {
    switch (_passoAtual) {
      case 0:
        return _formKeyDadosPessoais.currentState?.validate() ?? false;
      case 1:
        if (_academiaSelecionadaId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selecione a academia que atende.'),
              backgroundColor: GridColors.error,
            ),
          );
          return false;
        }
        return true;
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

  List<Map<String, dynamic>> _montarPlanos() {
    return _planos
        .map((plano) => {
              'nome': plano.nomeController.text.trim(),
              'descricao': plano.descricaoController.text.trim(),
              'valor': double.tryParse(
                  plano.valorController.text.trim().replaceAll(',', '.')),
              'qtdAula': int.tryParse(plano.qtdAulaController.text.trim()),
            })
        .toList();
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
      'cref': _crefController.text.trim(),
      'academiaId': _academiaSelecionadaId,
      'planos': _montarPlanos(),
    };

    final resposta = await _cadastroRepository.registrarPersonal(body);

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
      appBar: AppBar(title: const Text('Criar conta - Personal')),
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
                _buildPassoAcademiaPlanos(),
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
          const SizedBox(height: 12),
          _campoTexto(
            controller: _crefController,
            label: 'CREF',
            validator: (valor) => (valor == null || valor.trim().isEmpty)
                ? 'Informe o CREF'
                : null,
          ),
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
  // Passo 2 - Academia e planos
  // ---------------------------------------------------------------------
  Widget _buildPassoAcademiaPlanos() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _TituloPasso(titulo: 'Academia e planos'),
        const SizedBox(height: 16),
        _campoAcademia(),
        const SizedBox(height: 24),
        const _TituloPasso(titulo: 'Planos'),
        const SizedBox(height: 8),
        const Text(
          'Cadastre os planos que você oferece (opcional).',
          style: TextStyle(color: GridColors.textPrimary, fontSize: 14),
        ),
        const SizedBox(height: 16),
        for (var indice = 0; indice < _planos.length; indice++)
          _buildCardPlano(indice),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: GridColors.secondary, width: 2),
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: _adicionarPlano,
          icon: const Icon(Icons.add, color: GridColors.textPrimary),
          label: const Text(
            'Adicionar plano',
            style: TextStyle(color: GridColors.textPrimary, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _campoAcademia() {
    if (_carregandoAcademias) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: GridColors.secondary),
        ),
      );
    }

    if (_erroCarregarAcademias != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          _erroCarregarAcademias!,
          style: const TextStyle(color: GridColors.error),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _academiaSelecionadaId,
      decoration: _decoracaoCampo('Academia que atende'),
      dropdownColor: GridColors.primary,
      style: const TextStyle(color: GridColors.textPrimary),
      items: [
        for (final academia in _academiasDisponiveis)
          DropdownMenuItem(value: academia.id, child: Text(academia.nome)),
      ],
      onChanged: (valor) => setState(() => _academiaSelecionadaId = valor),
    );
  }

  Widget _buildCardPlano(int indice) {
    final plano = _planos[indice];

    return Card(
      color: GridColors.card,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Plano ${indice + 1}',
                  style: const TextStyle(
                    color: GridColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: GridColors.error),
                  onPressed: () => _removerPlano(indice),
                ),
              ],
            ),
            _campoTextoClaro(
              controller: plano.nomeController,
              label: 'Nome do plano',
            ),
            const SizedBox(height: 12),
            _campoTextoClaro(
              controller: plano.descricaoController,
              label: 'Descrição',
            ),
            const SizedBox(height: 12),
            _campoTextoClaro(
              controller: plano.valorController,
              label: 'Valor (R\$)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            _campoTextoClaro(
              controller: plano.qtdAulaController,
              label: 'Quantidade de aulas',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
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

  /// Campo de texto usado dentro dos cards de plano (fundo claro do Card),
  /// com o rótulo na cor de texto secundária para manter contraste.
  Widget _campoTextoClaro({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: GridColors.textSecondary),
      decoration: _decoracaoCampo(label)
          .copyWith(labelStyle: const TextStyle(color: GridColors.textSecondary)),
    );
  }
}

/// Indicador de progresso simples do wizard (ex.: "Passo 1 de 2").
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
