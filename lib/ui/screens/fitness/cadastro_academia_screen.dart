import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/services/academia_cadastro_service.dart';
import 'package:task_manager_flutter/data/utils/academia_cadastro_regras.dart';

const _diasSemana = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];

/// Cadastro completo da academia para o dono: dados, horarios, planos e personais vinculados.
class CadastroAcademiaScreen extends StatefulWidget {
  const CadastroAcademiaScreen({super.key});

  @override
  State<CadastroAcademiaScreen> createState() => _CadastroAcademiaScreenState();
}

class _CadastroAcademiaScreenState extends State<CadastroAcademiaScreen> {
  final _formDados = GlobalKey<FormState>();
  final _campos = <String, TextEditingController>{
    for (final c in const ['nome', 'cnpj', 'telefone', 'email', 'endereco', 'numero', 'bairro', 'cidade', 'uf', 'cep', 'observacao'])
      c: TextEditingController(),
  };
  final _horarios = <int, _Horario>{for (var d = 1; d <= 7; d++) d: _Horario()};

  bool _carregando = true;
  bool _salvando = false;
  String? _erroCarregamento;
  List<Map<String, dynamic>> _planos = const [];
  List<Map<String, dynamic>> _personais = const [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    for (final c in _campos.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erroCarregamento = null;
    });
    try {
      final cadastro = await AcademiaCadastroService.obter();
      final dados = cadastro['dados'];
      if (dados is Map) {
        for (final entrada in _campos.entries) {
          entrada.value.text = dados[entrada.key]?.toString() ?? '';
        }
      }
      final horarios = cadastro['horarios'];
      for (final h in _horarios.values) {
        h.ativo = false;
      }
      if (horarios is List) {
        for (final item in horarios) {
          if (item is! Map) continue;
          final dia = (item['diaSemana'] as num?)?.toInt();
          final horario = dia == null ? null : _horarios[dia];
          if (horario == null) continue;
          horario
            ..ativo = true
            ..abertura = _hm(item['abertura']?.toString())
            ..fechamento = _hm(item['fechamento']?.toString());
        }
      }
      final planos = cadastro['planos'];
      final personais = cadastro['personais'];
      setState(() {
        _planos = planos is List ? [for (final p in planos) if (p is Map) Map<String, dynamic>.from(p)] : const [];
        _personais = personais is List ? [for (final p in personais) if (p is Map) Map<String, dynamic>.from(p)] : const [];
      });
    } catch (e) {
      setState(() => _erroCarregamento = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _carregando = false);
    }
  }

  Future<void> _salvarDados() async {
    if (!(_formDados.currentState?.validate() ?? false)) return;
    await _executar(() async {
      final dados = {for (final e in _campos.entries) e.key: e.value.text.trim()};
      await AcademiaCadastroService.salvarDados(dados);
      _mostrar('Dados da academia salvos');
    });
  }

  Future<void> _salvarHorarios() async {
    final lista = <Map<String, dynamic>>[];
    for (final entrada in _horarios.entries) {
      final h = entrada.value;
      if (!h.ativo) continue;
      final erro = AcademiaCadastroRegras.horario(_fmt(h.abertura), _fmt(h.fechamento));
      if (erro != null) {
        _mostrar('${_diasSemana[entrada.key - 1]}: $erro', erro: true);
        return;
      }
      lista.add({'diaSemana': entrada.key, 'abertura': _fmt(h.abertura), 'fechamento': _fmt(h.fechamento)});
    }
    await _executar(() async {
      await AcademiaCadastroService.salvarHorarios(lista);
      _mostrar('Horários salvos');
    });
  }

  Future<void> _executar(Future<void> Function() acao) async {
    setState(() => _salvando = true);
    try {
      await acao();
      await _carregar();
    } catch (e) {
      _mostrar(e.toString().replaceFirst('Exception: ', ''), erro: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _mostrar(String mensagem, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensagem),
      backgroundColor: erro ? Theme.of(context).colorScheme.error : null,
    ));
  }

  Future<void> _editarPlano([Map<String, dynamic>? plano]) async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _PlanoDialog(plano: plano),
    );
    if (resultado == null) return;
    await _executar(() async {
      if (plano == null) {
        await AcademiaCadastroService.criarPlano(resultado);
      } else {
        await AcademiaCadastroService.atualizarPlano((plano['id'] as num).toInt(), resultado);
      }
      _mostrar('Plano salvo');
    });
  }

  Future<void> _excluirPlano(Map<String, dynamic> plano) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir plano'),
        content: Text('Excluir o plano "${plano['nome']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmou != true) return;
    await _executar(() async {
      await AcademiaCadastroService.excluirPlano((plano['id'] as num).toInt());
      _mostrar('Plano excluído');
    });
  }

  Future<void> _vincularPersonal() async {
    final escolhido = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _BuscaPersonalDialog(),
    );
    if (escolhido == null) return;
    await _executar(() async {
      await AcademiaCadastroService.vincularPersonal((escolhido['personalId'] as num).toInt());
      _mostrar('Personal vinculado');
    });
  }

  Future<void> _desvincularPersonal(Map<String, dynamic> personal) async {
    await _executar(() async {
      await AcademiaCadastroService.desvincularPersonal((personal['personalId'] as num).toInt());
      _mostrar('Personal removido da academia');
    });
  }

  static TimeOfDay? _hm(String? texto) {
    if (texto == null || !RegExp(r'^\d{2}:\d{2}$').hasMatch(texto)) return null;
    final partes = texto.split(':');
    return TimeOfDay(hour: int.parse(partes[0]), minute: int.parse(partes[1]));
  }

  static String _fmt(TimeOfDay? t) => t == null
      ? ''
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro da academia')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erroCarregamento != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_erroCarregamento!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _carregar, child: const Text('Tentar novamente')),
                      ],
                    ),
                  ),
                )
              : AbsorbPointer(
                  absorbing: _salvando,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _secao('Dados da academia', _formDados, [
                        _campo('nome', 'Nome da academia *', validar: AcademiaCadastroRegras.nomeObrigatorio),
                        _campo('cnpj', 'CNPJ', teclado: TextInputType.number, validar: AcademiaCadastroRegras.cnpjOpcional),
                        _campo('telefone', 'Telefone', teclado: TextInputType.phone),
                        _campo('email', 'E-mail', teclado: TextInputType.emailAddress, validar: AcademiaCadastroRegras.emailOpcional),
                        _campo('cep', 'CEP', teclado: TextInputType.number, validar: AcademiaCadastroRegras.cepOpcional),
                        _campo('endereco', 'Endereço'),
                        _campo('numero', 'Número'),
                        _campo('bairro', 'Bairro'),
                        _campo('cidade', 'Cidade'),
                        _campo('uf', 'UF', validar: AcademiaCadastroRegras.ufOpcional),
                        _campo('observacao', 'Observações', linhas: 3),
                        const SizedBox(height: 8),
                        FilledButton(onPressed: _salvarDados, child: const Text('Salvar dados')),
                      ]),
                      _secao('Horário de funcionamento', null, [
                        for (final entrada in _horarios.entries) _linhaHorario(entrada.key, entrada.value),
                        const SizedBox(height: 8),
                        FilledButton(onPressed: _salvarHorarios, child: const Text('Salvar horários')),
                      ]),
                      _secao('Planos', null, [
                        if (_planos.isEmpty)
                          const Text('Nenhum plano cadastrado.')
                        else
                          for (final p in _planos)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('${p['nome'] ?? ''}'),
                              subtitle: Text('R\$ ${(p['valor'] as num?)?.toStringAsFixed(2) ?? '0,00'}'
                                  '${p['qtdAula'] == null ? '' : ' · ${p['qtdAula']} aula(s)'}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editarPlano(p), tooltip: 'Editar plano'),
                                  IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _excluirPlano(p), tooltip: 'Excluir plano'),
                                ],
                              ),
                            ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _editarPlano(),
                          icon: const Icon(Icons.add),
                          label: const Text('Novo plano'),
                        ),
                      ]),
                      _secao('Personais vinculados', null, [
                        if (_personais.isEmpty)
                          const Text('Nenhum personal vinculado a esta academia.')
                        else
                          for (final p in _personais)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.fitness_center),
                              title: Text('${p['nome'] ?? ''}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.link_off),
                                tooltip: 'Remover personal',
                                onPressed: () => _desvincularPersonal(p),
                              ),
                            ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _vincularPersonal,
                          icon: const Icon(Icons.person_add_alt),
                          label: const Text('Vincular personal'),
                        ),
                      ]),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _secao(String titulo, GlobalKey<FormState>? formKey, List<Widget> filhos) {
    final conteudo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...filhos,
      ],
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: formKey == null ? conteudo : Form(key: formKey, child: conteudo),
      ),
    );
  }

  Widget _campo(
    String chave,
    String rotulo, {
    TextInputType? teclado,
    int linhas = 1,
    String? Function(String?)? validar,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: _campos[chave],
        keyboardType: teclado,
        minLines: 1,
        maxLines: linhas,
        decoration: InputDecoration(labelText: rotulo, border: const OutlineInputBorder()),
        validator: validar,
      ),
    );
  }

  Widget _linhaHorario(int dia, _Horario h) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(_diasSemana[dia - 1])),
          Switch(value: h.ativo, onChanged: (v) => setState(() => h.ativo = v)),
          TextButton(
            onPressed: h.ativo ? () => _escolherHora(h, abertura: true) : null,
            child: Text(_fmt(h.abertura).isEmpty ? 'Abre' : _fmt(h.abertura)),
          ),
          const Text('–'),
          TextButton(
            onPressed: h.ativo ? () => _escolherHora(h, abertura: false) : null,
            child: Text(_fmt(h.fechamento).isEmpty ? 'Fecha' : _fmt(h.fechamento)),
          ),
        ],
      ),
    );
  }

  Future<void> _escolherHora(_Horario h, {required bool abertura}) async {
    final escolhida = await showTimePicker(
      context: context,
      initialTime: (abertura ? h.abertura : h.fechamento) ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (escolhida == null) return;
    setState(() {
      if (abertura) {
        h.abertura = escolhida;
      } else {
        h.fechamento = escolhida;
      }
    });
  }
}

class _Horario {
  bool ativo = false;
  TimeOfDay? abertura;
  TimeOfDay? fechamento;
}

class _PlanoDialog extends StatefulWidget {
  const _PlanoDialog({this.plano});

  final Map<String, dynamic>? plano;

  @override
  State<_PlanoDialog> createState() => _PlanoDialogState();
}

class _PlanoDialogState extends State<_PlanoDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nome = TextEditingController(text: '${widget.plano?['nome'] ?? ''}');
  late final TextEditingController _descricao = TextEditingController(text: '${widget.plano?['descricao'] ?? ''}');
  late final TextEditingController _valor = TextEditingController(
      text: widget.plano?['valor'] == null ? '' : '${widget.plano!['valor']}');
  late final TextEditingController _aulas = TextEditingController(
      text: widget.plano?['qtdAula'] == null ? '' : '${widget.plano!['qtdAula']}');

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    _valor.dispose();
    _aulas.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final aulas = int.tryParse(_aulas.text.trim());
    Navigator.pop(context, {
      'nome': _nome.text.trim(),
      'descricao': _descricao.text.trim(),
      'valor': double.parse(_valor.text.trim().replaceAll(',', '.')),
      'qtdAula': aulas,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.plano == null ? 'Novo plano' : 'Editar plano'),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nome,
                decoration: const InputDecoration(labelText: 'Nome *'),
                validator: AcademiaCadastroRegras.nomePlano,
              ),
              TextFormField(controller: _descricao, decoration: const InputDecoration(labelText: 'Descrição')),
              TextFormField(
                controller: _valor,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Valor (R\$) *'),
                validator: AcademiaCadastroRegras.valorPlano,
              ),
              TextFormField(
                controller: _aulas,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Aulas no mês (opcional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _confirmar, child: const Text('Salvar')),
      ],
    );
  }
}

class _BuscaPersonalDialog extends StatefulWidget {
  const _BuscaPersonalDialog();

  @override
  State<_BuscaPersonalDialog> createState() => _BuscaPersonalDialogState();
}

class _BuscaPersonalDialogState extends State<_BuscaPersonalDialog> {
  final _busca = TextEditingController();
  List<Map<String, dynamic>> _resultados = const [];
  String? _erro;
  bool _buscando = false;

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _pesquisar() async {
    final termo = _busca.text.trim();
    if (termo.length < 3) {
      setState(() => _erro = 'Digite ao menos 3 letras');
      return;
    }
    setState(() {
      _buscando = true;
      _erro = null;
    });
    try {
      final lista = await AcademiaCadastroService.buscarPersonais(termo);
      setState(() => _resultados = lista);
    } catch (e) {
      setState(() => _erro = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _buscando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Vincular personal'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _busca,
              decoration: InputDecoration(
                labelText: 'Nome do personal',
                errorText: _erro,
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _pesquisar),
              ),
              onSubmitted: (_) => _pesquisar(),
            ),
            const SizedBox(height: 8),
            if (_buscando) const CircularProgressIndicator(),
            if (!_buscando && _resultados.isEmpty && _erro == null)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Pesquise pelo nome. Só aparecem personais da sua empresa.'),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final p in _resultados)
                    ListTile(
                      title: Text('${p['nome'] ?? ''}'),
                      onTap: () => Navigator.pop(context, p),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
    );
  }
}
