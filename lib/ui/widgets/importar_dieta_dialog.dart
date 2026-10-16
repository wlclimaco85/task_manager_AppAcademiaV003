import 'package:flutter/material.dart';
import '../../data/models/fitness/nutricao_farmaco_model.dart';
import '../../data/services/importacao_dieta_parser.dart';
import '../../data/services/importacao_dieta_preparacao.dart';
import 'fechamento_modal_seguro.dart';

class DietaImportada {
  final List<RefeicaoModel> refeicoes;
  final List<AlimentoModel> novosAlimentos;
  const DietaImportada(this.refeicoes, this.novosAlimentos);
}

class ImportarDietaDialog extends StatefulWidget {
  final ResultadoImportacaoDieta resultado;
  final List<AlimentoModel> catalogo;
  const ImportarDietaDialog(
      {super.key, required this.resultado, required this.catalogo});
  @override
  State<ImportarDietaDialog> createState() => _ImportarDietaDialogState();
}

class _ImportarDietaDialogState extends State<ImportarDietaDialog> {
  late final _preparacao =
      ImportacaoDietaPreparacao(widget.resultado, widget.catalogo);
  String? _erro;
  Future<void> _escolher(ItemImportacaoDieta item) async {
    var busca = '';
    final a = await showDialog<AlimentoModel>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, atualizar) => AlertDialog(
                  title: const Text('Escolher alimento cadastrado'),
                  content: SizedBox(
                      width: 550,
                      height: 380,
                      child: Column(children: [
                        TextField(
                            decoration: const InputDecoration(
                                labelText: 'Buscar alimento'),
                            onChanged: (v) => atualizar(
                                () => busca = normalizarNomeAlimento(v))),
                        Expanded(
                            child: ListView(children: [
                          for (final a in [
                            ...widget.catalogo,
                            ..._preparacao.novos
                          ].where((a) =>
                              normalizarNomeAlimento(a.nome).contains(busca)))
                            ListTile(
                                title: Text(a.nome),
                                subtitle: Text(
                                    '${a.calorias} kcal / ${a.porcaoPadraoGramas} g'),
                                onTap: () => Navigator.pop(ctx, a)),
                        ])),
                      ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'))
                  ],
                )));
    if (a != null && mounted)
      setState(() {
        item.alimento = a;
        _erro = null;
      });
  }

  Future<void> _cadastrar(ItemImportacaoDieta item) async {
    final a = await showDialog<AlimentoModel>(
        context: context,
        builder: (_) => _NovoAlimentoImportado(
            linha: item.linha,
            existentes: [...widget.catalogo, ..._preparacao.novos]));
    if (a != null && mounted)
      setState(() {
        _preparacao.novos.add(a);
        for (final outro in _preparacao.itens.where((i) =>
            i.alimento == null &&
            normalizarNomeAlimento(i.linha.alimento) ==
                normalizarNomeAlimento(item.linha.alimento))) {
          outro.alimento = a;
        }
        item.alimento = a;
        _erro = null;
      });
  }

  @override
  Widget build(BuildContext context) => FechamentoModalSeguro(
          child: Dialog(
        child: SizedBox(
          width: 720,
          height: MediaQuery.sizeOf(context).height * .85,
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Revisar importação',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text(
                        'Nada é salvo agora. As refeições serão acrescentadas à dieta. '
                        'Os alimentos novos serão cadastrados somente ao salvar a dieta.'),
                    for (final aviso in widget.resultado.avisos)
                      Text(aviso,
                          style: const TextStyle(color: Colors.deepOrange)),
                    const SizedBox(height: 8),
                    Expanded(
                        child: ListView.builder(
                            itemCount: _preparacao.itens.length,
                            itemBuilder: (_, i) {
                              final item = _preparacao.itens[i];
                              final l = item.linha;
                              final novo = _preparacao.novos
                                  .any((a) => a.id == item.alimento?.id);
                              return Card(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    CheckboxListTile(
                                      value: item.incluir,
                                      onChanged: (v) => setState(
                                          () => item.incluir = v ?? false),
                                      title: Text(
                                          '${l.refeicao} • ${l.horario}\n${l.alimento} — ${l.quantidadeGramas} g'),
                                      subtitle: Text(item.alimento == null
                                          ? 'Pendente: escolha ou cadastre o alimento.'
                                          : '${novo ? "Novo alimento" : "Reutilizar cadastro"}: ${item.alimento!.nome}'),
                                    ),
                                    if (item.incluir)
                                      Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              12, 0, 12, 8),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                for (final aviso in item.avisos)
                                                  Text(aviso,
                                                      style: const TextStyle(
                                                          color: Colors
                                                              .deepOrange)),
                                                if (item.alimento != null)
                                                  Text(
                                                      'Por ${item.alimento!.porcaoPadraoGramas} g: '
                                                      '${item.alimento!.calorias} kcal • P ${item.alimento!.proteinas} g • '
                                                      'C ${item.alimento!.carboidratos} g • G ${item.alimento!.gorduras} g'),
                                                Wrap(children: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          _escolher(item),
                                                      child: const Text(
                                                          'Escolher do catálogo')),
                                                  TextButton(
                                                      onPressed: () =>
                                                          _cadastrar(item),
                                                      child: const Text(
                                                          'Cadastrar alimento')),
                                                ]),
                                              ])),
                                  ]));
                            })),
                    if (_erro != null)
                      Text(_erro!, style: const TextStyle(color: Colors.red)),
                    Wrap(alignment: WrapAlignment.end, spacing: 8, children: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar')),
                      FilledButton(
                          onPressed: () {
                            try {
                              final refeicoes = _preparacao.gerarRefeicoes();
                              Navigator.pop(
                                  context,
                                  DietaImportada(
                                      refeicoes, _preparacao.novosUtilizados));
                            } on StateError catch (e) {
                              setState(() => _erro = e.message.toString());
                            }
                          },
                          child: Text(
                              'Aplicar à dieta (${_preparacao.itens.where((i) => i.incluir).length})')),
                    ]),
                  ])),
        ),
      ));
}

class _NovoAlimentoImportado extends StatefulWidget {
  final LinhaImportacaoDieta linha;
  final List<AlimentoModel> existentes;
  const _NovoAlimentoImportado({required this.linha, required this.existentes});
  @override
  State<_NovoAlimentoImportado> createState() => _NovoAlimentoImportadoState();
}

class _NovoAlimentoImportadoState extends State<_NovoAlimentoImportado> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.linha.alimento);
  late final _nutrientes = [
    widget.linha.calorias,
    widget.linha.proteinas,
    widget.linha.carboidratos,
    widget.linha.gorduras,
    widget.linha.fibras,
  ].map((v) => TextEditingController(text: v?.toString() ?? '')).toList();
  @override
  void dispose() {
    _nome.dispose();
    for (final c in _nutrientes) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FechamentoModalSeguro(
          child: AlertDialog(
        title: const Text('Cadastrar alimento importado'),
        content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
                child: Form(
                    key: _form,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text(
                          'Informe valores reais por 100 g. Não deixe nutrientes ausentes como zero sem conferir a fonte.'),
                      TextFormField(
                          controller: _nome,
                          decoration: const InputDecoration(
                              labelText: 'Nome do alimento'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Informe o nome.';
                            if (widget.existentes.any((a) =>
                                normalizarNomeAlimento(a.nome) ==
                                normalizarNomeAlimento(v))) {
                              return 'Esse alimento já existe. Escolha-o no catálogo.';
                            }
                            return null;
                          }),
                      for (var i = 0; i < 5; i++)
                        Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: TextFormField(
                                controller: _nutrientes[i],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: InputDecoration(
                                    labelText: [
                                  'Calorias por 100 g (kcal)',
                                  'Proteínas por 100 g (g)',
                                  'Carboidratos por 100 g (g)',
                                  'Gorduras por 100 g (g)',
                                  'Fibras por 100 g (g)'
                                ][i]),
                                validator: (v) {
                                  final n = double.tryParse(
                                      (v ?? '').trim().replaceAll(',', '.'));
                                  return n == null || !n.isFinite || n < 0
                                      ? 'Informe o valor real, maior ou igual a zero.'
                                      : null;
                                })),
                    ])))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () {
                if (!_form.currentState!.validate()) return;
                final v = _nutrientes
                    .map(
                        (c) => double.parse(c.text.trim().replaceAll(',', '.')))
                    .toList();
                Navigator.pop(
                    context,
                    AlimentoModel(
                      id: 'alim_import_${DateTime.now().microsecondsSinceEpoch}',
                      nome: _nome.text.trim(),
                      categoria: 'geral',
                      calorias: v[0],
                      proteinas: v[1],
                      carboidratos: v[2],
                      gorduras: v[3],
                      fibras: v[4],
                      descricao:
                          'Cadastrado durante importação. Nutrientes informados por 100 g.',
                    ));
              },
              child: const Text('Usar alimento')),
        ],
      ));
}
