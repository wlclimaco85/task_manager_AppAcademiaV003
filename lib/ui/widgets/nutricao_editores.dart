import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/fechamento_modal_seguro.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/fitness/nutricao_farmaco_model.dart';
import 'package:task_manager_flutter/data/services/nutricao_farmaco_offline_repository.dart';

String? _obrigatorio(String? v) =>
    (v?.trim().isEmpty ?? true) ? 'Informe este campo.' : null;
double? _numero(String? v) =>
    double.tryParse((v ?? '').trim().replaceAll(',', '.'));
String? _positivo(String? v) {
  final n = _numero(v);
  return n == null || !n.isFinite || n <= 0
      ? 'Informe uma quantidade maior que zero.'
      : null;
}

Widget _entrada(TextEditingController c, String label,
        {bool numero = false, String? Function(String?)? validar}) =>
    Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
            controller: c,
            keyboardType: numero
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            decoration: InputDecoration(labelText: label),
            validator: validar ?? _obrigatorio));

class SuplementoEditor extends StatefulWidget {
  final SuplementoProtocoloModel? suplemento;
  const SuplementoEditor({super.key, this.suplemento});
  @override
  State<SuplementoEditor> createState() => _SuplementoEditorState();
}

class _SuplementoEditorState extends State<SuplementoEditor> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController(),
      _marca = TextEditingController(),
      _pote = TextEditingController(),
      _dose = TextEditingController();
  String _unidade = 'g';
  String? _horario;
  bool _salvando = false;
  String? _erro;
  static const _opcoes = [
    'Ao acordar',
    'Jejum',
    'Café da manhã',
    'Almoço',
    'Lanche da tarde',
    'Jantar',
    'Pré-Treino',
    'Durante o treino',
    'Pós-Treino',
    'Antes de dormir'
  ];
  @override
  void initState() {
    super.initState();
    final s = widget.suplemento;
    if (s != null) {
      _nome.text = s.nome;
      _marca.text = s.marca;
      _pote.text = s.quantidadePote?.toString() ?? '';
      _dose.text = s.dosagem;
      _unidade = s.unidadePote;
      _horario = s.horario.isEmpty ? null : s.horario;
    }
  }

  @override
  void dispose() {
    for (final c in [_nome, _marca, _pote, _dose]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    final s = widget.suplemento;
    try {
      await NutricaoFarmacoOfflineRepository().salvarSuplemento(
          SuplementoProtocoloModel(
              id: s?.id ?? 'sup_${DateTime.now().microsecondsSinceEpoch}',
              alunoId: s?.alunoId ??
                  AuthUtility.userInfo.login?.id?.toString() ??
                  '',
              nome: _nome.text.trim(),
              marca: _marca.text.trim(),
              quantidadePote: _numero(_pote.text),
              unidadePote: _unidade,
              dosagem: _dose.text.trim(),
              horario: _horario!,
              dataInicio: s?.dataInicio ??
                  DateTime.now().toIso8601String().split('T').first,
              dataFim: s?.dataFim,
              ativo: s?.ativo ?? true,
              observacoes: s?.observacoes));
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted)
        setState(() =>
            _erro = 'Não foi possível salvar. Seus campos foram mantidos.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      FechamentoModalSeguro(child: _dialogo(context));

  Widget _dialogo(BuildContext context) => AlertDialog(
          title: Text(widget.suplemento == null
              ? 'Cadastrar suplemento'
              : 'Editar suplemento'),
          content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                  child: Form(
                      key: _form,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        _entrada(_nome, 'Nome do suplemento'),
                        _entrada(_marca, 'Marca'),
                        Row(children: [
                          Expanded(
                              child: _entrada(_pote, 'Quantidade do pote',
                                  numero: true, validar: _positivo)),
                          const SizedBox(width: 12),
                          SizedBox(
                              width: 110,
                              child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: _unidade,
                                  decoration: const InputDecoration(
                                      labelText: 'Unidade'),
                                  items: [
                                    for (final u in {
                                      'g',
                                      'kg',
                                      'ml',
                                      'L',
                                      'cápsulas',
                                      'unidades',
                                      _unidade
                                    })
                                      DropdownMenuItem(value: u, child: Text(u))
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _unidade = v!)))
                        ]),
                        _entrada(_dose, 'Dosagem por uso'),
                        DropdownButtonFormField<String>(
                            initialValue: _horario,
                            isExpanded: true,
                            decoration: const InputDecoration(
                                labelText: 'Horário / modo de uso'),
                            items: [
                              for (final h in {
                                ..._opcoes,
                                if (_horario != null) _horario!
                              })
                                DropdownMenuItem(value: h, child: Text(h))
                            ],
                            validator: _obrigatorio,
                            onChanged: (v) => setState(() => _horario = v)),
                        TextButton.icon(
                            onPressed: () async {
                              final h = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now());
                              if (h != null && mounted)
                                setState(() => _horario =
                                    '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}');
                            },
                            icon: const Icon(Icons.schedule),
                            label: const Text('Escolher horário exato')),
                        if (_erro != null)
                          Text(_erro!,
                              style: const TextStyle(color: Colors.red)),
                      ])))),
          actions: [
            TextButton(
                onPressed: _salvando ? null : () => Navigator.pop(context),
                child: const Text('Cancelar')),
            FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: GridColors.primary,
                    foregroundColor: Colors.white),
                onPressed: _salvando ? null : _salvar,
                child: Text(_salvando ? 'Salvando...' : 'Salvar'))
          ]);
}

class DietaEditor extends StatefulWidget {
  final DietaProtocoloModel? dieta;
  const DietaEditor({super.key, this.dieta});
  @override
  State<DietaEditor> createState() => _DietaEditorState();
}

class _DietaEditorState extends State<DietaEditor> {
  final _form = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _metas = List.generate(4, (_) => TextEditingController());
  late final List<RefeicaoModel> _refeicoes;
  bool _salvando = false;
  String? _erro;
  @override
  void initState() {
    super.initState();
    final d = widget.dieta;
    _titulo.text = d?.titulo ?? '';
    _refeicoes = List.of(d?.refeicoes ?? []);
    if (d != null) {
      final valores = [
        d.caloriasMeta,
        d.proteinasMeta,
        d.carboidratosMeta,
        d.gordurasMeta
      ];
      for (var i = 0; i < 4; i++) {
        if (valores[i] > 0) _metas[i].text = valores[i].toString();
      }
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    for (final c in _metas) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _editarRefeicao([int? index]) async {
    final r = await showDialog<RefeicaoModel>(
        context: context,
        builder: (_) => _RefeicaoEditor(
            refeicao: index == null ? null : _refeicoes[index]));
    if (r != null && mounted)
      setState(() {
        if (index == null) {
          _refeicoes.add(r);
        } else {
          _refeicoes[index] = r;
        }
      });
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    if (_refeicoes.isEmpty) {
      setState(() => _erro = 'Adicione pelo menos uma refeição com alimentos.');
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    final d = widget.dieta;
    try {
      await NutricaoFarmacoOfflineRepository().salvarDieta(DietaProtocoloModel(
          id: d?.id ?? 'dieta_${DateTime.now().microsecondsSinceEpoch}',
          alunoId:
              d?.alunoId ?? AuthUtility.userInfo.login?.id?.toString() ?? '',
          titulo: _titulo.text.trim(),
          objetivo: d?.objetivo ?? '',
          caloriasMeta: _numero(_metas[0].text) ?? 0,
          proteinasMeta: _numero(_metas[1].text) ?? 0,
          carboidratosMeta: _numero(_metas[2].text) ?? 0,
          gordurasMeta: _numero(_metas[3].text) ?? 0,
          dataInicio: d?.dataInicio ??
              DateTime.now().toIso8601String().split('T').first,
          dataFim: d?.dataFim,
          ativa: d?.ativa ?? true,
          observacoes: d?.observacoes,
          refeicoes: List.of(_refeicoes)));
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted)
        setState(() =>
            _erro = 'Não foi possível salvar. Suas refeições foram mantidas.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      FechamentoModalSeguro(child: _dialogo(context));

  Widget _dialogo(BuildContext context) => AlertDialog(
          title: Text(widget.dieta == null ? 'Nova dieta' : 'Editar dieta'),
          content: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                  child: Form(
                      key: _form,
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _entrada(_titulo, 'Título da dieta'),
                            const Text(
                                'Metas opcionais — preencha somente se já definidas.'),
                            const SizedBox(height: 12),
                            for (var i = 0; i < 4; i++)
                              _entrada(
                                  _metas[i],
                                  [
                                    'Calorias (kcal)',
                                    'Proteínas (g)',
                                    'Carboidratos (g)',
                                    'Gorduras (g)'
                                  ][i],
                                  numero: true, validar: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                final n = _numero(v);
                                return n == null || !n.isFinite || n < 0
                                    ? 'Informe um valor válido.'
                                    : null;
                              }),
                            const Text('Refeições e alimentos',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            if (_refeicoes.isEmpty)
                              const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text('Nenhuma refeição adicionada.')),
                            for (var i = 0; i < _refeicoes.length; i++)
                              ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                      '${_refeicoes[i].nome} (${_refeicoes[i].horario})'),
                                  subtitle: Text(_refeicoes[i]
                                      .itens
                                      .map((a) =>
                                          '${a.alimentoNome}: ${a.quantidadeGramas} g')
                                      .join('\n')),
                                  onTap: () => _editarRefeicao(i),
                                  trailing: Wrap(children: [
                                    IconButton(
                                        tooltip: 'Editar refeição',
                                        onPressed: () => _editarRefeicao(i),
                                        icon: const Icon(Icons.edit_outlined)),
                                    IconButton(
                                        tooltip: 'Remover refeição',
                                        onPressed: () => setState(
                                            () => _refeicoes.removeAt(i)),
                                        icon: const Icon(Icons.delete_outline))
                                  ])),
                            OutlinedButton.icon(
                                onPressed:
                                    _salvando ? null : () => _editarRefeicao(),
                                icon: const Icon(Icons.add),
                                label: const Text('Adicionar refeição')),
                            if (_erro != null)
                              Text(_erro!,
                                  style: const TextStyle(color: Colors.red)),
                          ])))),
          actions: [
            TextButton(
                onPressed: _salvando ? null : () => Navigator.pop(context),
                child: const Text('Cancelar')),
            FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: GridColors.primary,
                    foregroundColor: Colors.white),
                onPressed: _salvando ? null : _salvar,
                child: Text(_salvando ? 'Salvando...' : 'Salvar dieta'))
          ]);
}

class _RefeicaoEditor extends StatefulWidget {
  final RefeicaoModel? refeicao;
  const _RefeicaoEditor({this.refeicao});
  @override
  State<_RefeicaoEditor> createState() => _RefeicaoEditorState();
}

class _RefeicaoEditorState extends State<_RefeicaoEditor> {
  final _form = GlobalKey<FormState>();
  final _horario = TextEditingController();
  String? _nome, _erro;
  late final List<ItemRefeicaoModel> _itens;
  static const _tipos = [
    'Café da manhã',
    'Lanche da manhã',
    'Almoço',
    'Lanche da tarde',
    'Jantar',
    'Ceia',
    'Pré-treino',
    'Pós-treino'
  ];
  @override
  void initState() {
    super.initState();
    _nome = widget.refeicao?.nome;
    _horario.text = widget.refeicao?.horario ?? '';
    _itens = List.of(widget.refeicao?.itens ?? []);
  }

  @override
  void dispose() {
    _horario.dispose();
    super.dispose();
  }

  Future<void> _alimento({int? index}) async {
    final item = await showDialog<ItemRefeicaoModel>(
        context: context,
        builder: (_) =>
            _AlimentoEditor(item: index == null ? null : _itens[index]));
    if (item != null && mounted)
      setState(() {
        if (index == null) {
          _itens.add(item);
        } else {
          _itens[index] = item;
        }
      });
  }

  @override
  Widget build(BuildContext context) =>
      FechamentoModalSeguro(child: _dialogo(context));

  Widget _dialogo(BuildContext context) => AlertDialog(
          title: const Text('Refeição'),
          content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                  child: Form(
                      key: _form,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        DropdownButtonFormField<String>(
                            initialValue: _nome,
                            isExpanded: true,
                            decoration: const InputDecoration(
                                labelText: 'Tipo de refeição'),
                            validator: _obrigatorio,
                            items: [
                              for (final n in {
                                ..._tipos,
                                if (_nome != null) _nome!
                              })
                                DropdownMenuItem(value: n, child: Text(n))
                            ],
                            onChanged: (v) => setState(() => _nome = v)),
                        const SizedBox(height: 12),
                        _entrada(_horario, 'Horário (HH:mm)',
                            validar: (v) =>
                                RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$')
                                        .hasMatch(v ?? '')
                                    ? null
                                    : 'Informe um horário válido (HH:mm).'),
                        for (var i = 0; i < _itens.length; i++)
                          ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(_itens[i].alimentoNome),
                              subtitle: Text('${_itens[i].quantidadeGramas} g'),
                              onTap: () => _alimento(index: i),
                              trailing: IconButton(
                                  tooltip: 'Remover alimento',
                                  onPressed: () =>
                                      setState(() => _itens.removeAt(i)),
                                  icon: const Icon(Icons.delete_outline))),
                        OutlinedButton.icon(
                            onPressed: () => _alimento(),
                            icon: const Icon(Icons.add),
                            label: const Text('Adicionar alimento')),
                        if (_erro != null)
                          Text(_erro!,
                              style: const TextStyle(color: Colors.red)),
                      ])))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () {
                  if (!_form.currentState!.validate()) return;
                  if (_itens.isEmpty) {
                    setState(() => _erro = 'Adicione pelo menos um alimento.');
                    return;
                  }
                  Navigator.pop(
                      context,
                      RefeicaoModel(
                          id: widget.refeicao?.id ??
                              'ref_${DateTime.now().microsecondsSinceEpoch}',
                          nome: _nome!,
                          horario: _horario.text,
                          itens: List.of(_itens)));
                },
                child: const Text('Salvar refeição'))
          ]);
}

class _AlimentoEditor extends StatefulWidget {
  final ItemRefeicaoModel? item;
  const _AlimentoEditor({this.item});
  @override
  State<_AlimentoEditor> createState() => _AlimentoEditorState();
}

class _AlimentoEditorState extends State<_AlimentoEditor> {
  final _form = GlobalKey<FormState>();
  final _busca = TextEditingController(), _quantidade = TextEditingController();
  late final Future<List<AlimentoModel>> _catalogo =
      NutricaoFarmacoOfflineRepository().getAlimentos();
  AlimentoModel? _selecionado;
  String? _erro;
  @override
  void initState() {
    super.initState();
    _quantidade.text = widget.item?.quantidadeGramas.toString() ?? '';
  }

  @override
  void dispose() {
    _busca.dispose();
    _quantidade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FechamentoModalSeguro(child: _dialogo(context));

  Widget _dialogo(BuildContext context) => AlertDialog(
          title: const Text('Alimento e quantidade'),
          content: SizedBox(
              width: 520,
              height: 400,
              child: Form(
                  key: _form,
                  child: Column(children: [
                    TextField(
                        controller: _busca,
                        decoration:
                            const InputDecoration(labelText: 'Buscar alimento'),
                        onChanged: (_) => setState(() {})),
                    Expanded(
                        child: FutureBuilder<List<AlimentoModel>>(
                            future: _catalogo,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData)
                                return const Center(
                                    child: CircularProgressIndicator());
                              final lista = snapshot.data!
                                  .where((a) => a.nome.toLowerCase().contains(
                                      _busca.text.trim().toLowerCase()))
                                  .toList();
                              if (_selecionado == null && widget.item != null) {
                                _selecionado = snapshot.data!
                                    .where(
                                        (a) => a.id == widget.item!.alimentoId)
                                    .firstOrNull;
                              }
                              if (lista.isEmpty)
                                return const Center(
                                    child: Text('Nenhum alimento encontrado.'));
                              return ListView.builder(
                                  itemCount: lista.length,
                                  itemBuilder: (_, i) => ListTile(
                                      title: Text(lista[i].nome),
                                      selected: _selecionado?.id == lista[i].id,
                                      trailing: _selecionado?.id == lista[i].id
                                          ? const Icon(Icons.check_circle,
                                              color: GridColors.primary)
                                          : null,
                                      onTap: () => setState(
                                          () => _selecionado = lista[i])));
                            })),
                    if (_selecionado != null)
                      Text('Selecionado: ${_selecionado!.nome}'),
                    _entrada(_quantidade, 'Quantidade (g)',
                        numero: true, validar: _positivo),
                    if (_erro != null)
                      Text(_erro!, style: const TextStyle(color: Colors.red)),
                  ]))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () {
                  if (!_form.currentState!.validate()) return;
                  if (_selecionado == null) {
                    setState(() => _erro = 'Selecione um alimento.');
                    return;
                  }
                  Navigator.pop(
                      context,
                      ItemRefeicaoModel.calcular(
                          alimento: _selecionado!,
                          quantidadeGramas: _numero(_quantidade.text)!,
                          observacao: widget.item?.observacao));
                },
                child: const Text('Adicionar alimento'))
          ]);
}
