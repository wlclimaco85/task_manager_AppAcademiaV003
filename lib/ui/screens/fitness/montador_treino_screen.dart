import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/services/personal_gestao_offline_repository.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
import 'package:task_manager_flutter/ui/screens/fitness/biblioteca_exercicios_screen.dart';

/// Montador Visual de Treinos (Padrão MFIT Personal)
/// Permite ao treinador criar divisões (A, B, C, D), prescrever séries, cargas, descanso e técnicas avançadas.
class MontadorTreinoScreen extends StatefulWidget {
  final PlanoTreinoModel? planoParaEditar;
  final String? alunoId;
  final String? alunoNome;

  const MontadorTreinoScreen({
    super.key,
    this.planoParaEditar,
    this.alunoId,
    this.alunoNome,
  });

  @override
  State<MontadorTreinoScreen> createState() => _MontadorTreinoScreenState();
}

class _MontadorTreinoScreenState extends State<MontadorTreinoScreen>
    with TickerProviderStateMixin {
  final _repository = FitnessOfflineRepository();
  final _tituloController = TextEditingController();
  final _objetivoController = TextEditingController();

  late TabController _tabController;
  List<DivisaoTreinoModel> _divisoes = [];
  bool _salvandoComoTemplate = false;

  final List<String> _letrasDisponiveis = ['A', 'B', 'C', 'D', 'E', 'F'];

  @override
  void initState() {
    super.initState();
    if (widget.planoParaEditar != null) {
      _tituloController.text = widget.planoParaEditar!.titulo;
      _objetivoController.text = widget.planoParaEditar!.objetivo;
      _divisoes = List.from(widget.planoParaEditar!.divisoes);
    } else {
      _tituloController.text = 'Novo Plano de Treino';
      _objetivoController.text = 'Hipertrofia';
      _divisoes = [
        const DivisaoTreinoModel(
          id: 'div_a',
          letra: 'A',
          nome: 'Treino A - Peitoral e Tríceps',
          exercicios: [],
        ),
      ];
    }
    _tabController = TabController(length: _divisoes.length, vsync: this);
  }

  void _atualizarTabController(int novoIndex) {
    _tabController.dispose();
    _tabController = TabController(
      length: _divisoes.length,
      initialIndex: novoIndex.clamp(0, _divisoes.length - 1),
      vsync: this,
    );
    setState(() {});
  }

  void _adicionarDivisao() {
    if (_divisoes.length >= _letrasDisponiveis.length) return;
    final proximaLetra = _letrasDisponiveis.firstWhere(
      (letra) => !_divisoes.any((divisao) => divisao.letra == letra),
    );
    _divisoes.add(DivisaoTreinoModel(
      id: 'div_${proximaLetra.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
      letra: proximaLetra,
      nome: 'Treino $proximaLetra',
      exercicios: [],
    ));
    _atualizarTabController(_divisoes.length - 1);
  }

  void _removerDivisaoAtual() {
    if (_divisoes.length <= 1) return;
    final indexAtual = _tabController.index;
    _divisoes.removeAt(indexAtual);
    _atualizarTabController((indexAtual - 1).clamp(0, _divisoes.length - 1));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tituloController.dispose();
    _objetivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktopOrWeb = width >= 800;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: const Text('Prescrever Treino', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Salvar Ficha',
            icon: Icon(Icons.check, color: GridColors.primary),
            onPressed: _salvarPlano,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: context.appSurface,
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: GridColors.primary,
                    indicatorWeight: 3,
                    labelColor: GridColors.primary,
                    unselectedLabelColor: context.appTextSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    tabs: [
                      for (final div in _divisoes)
                        Tab(text: 'Treino ${div.letra} (${div.exercicios.length})'),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Adicionar divisão de treino',
                  icon: Icon(Icons.add_circle, color: GridColors.primary),
                  onPressed: _adicionarDivisao,
                ),
                if (_divisoes.length > 1)
                  IconButton(
                    tooltip: 'Remover divisão selecionada',
                    icon: const Icon(Icons.remove_circle_outline, color: GridColors.error),
                    onPressed: _removerDivisaoAtual,
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktopOrWeb ? 1100 : double.infinity),
          child: Column(
            children: [
              // 1. Cabeçalho da Ficha (Título e Aluno)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.appBorder),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _tituloController,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Título da Ficha de Treino',
                        hintText: 'Ex: Hipertrofia ABC - Mês 1',
                        prefixIcon: Icon(Icons.fitness_center, color: GridColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _objetivoController,
                            decoration: const InputDecoration(
                              labelText: 'Objetivo',
                              hintText: 'Hipertrofia / Emagrecimento',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: _salvandoComoTemplate,
                              activeColor: GridColors.primary,
                              onChanged: (val) {
                                setState(() => _salvandoComoTemplate = val ?? false);
                              },
                            ),
                            const Text('Salvar Template', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. TabBarView com as divisões de treino
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    for (int i = 0; i < _divisoes.length; i++)
                      _buildDivisaoView(_divisoes[i], i),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Salvar e Publicar Ficha para o Aluno'),
              onPressed: _salvarPlano,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivisaoView(DivisaoTreinoModel divisao, int divisaoIndex) {
    return Column(
      children: [
        // Botão de Adicionar Exercício nesta divisão
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: Text('Adicionar Exercício no Treino ${divisao.letra}'),
              onPressed: () => _selecionarExercicio(divisaoIndex),
            ),
          ),
        ),

        if (divisao.exercicios.length > 1)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('Arraste pelo ícone ⋮⋮ para ordenar. Salve a ficha para manter a ordem.',
              style: TextStyle(fontSize: 12, color: context.appTextSecondary)),
          ),
        // Lista de Exercícios da Divisão
        Expanded(
          child: divisao.exercicios.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_run_outlined, size: 48, color: context.appTextSecondary),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhum exercício no Treino ${divisao.letra}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Toque em "Adicionar Exercício" acima para escolher da biblioteca.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.appTextSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: divisao.exercicios.length,
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      final atual = _divisoes[divisaoIndex];
                      final itens = List<ItemTreinoModel>.from(atual.exercicios);
                      if (newIndex > oldIndex) newIndex -= 1;
                      itens.insert(newIndex, itens.removeAt(oldIndex));
                      _divisoes[divisaoIndex] = DivisaoTreinoModel(
                        id: atual.id,
                        letra: atual.letra,
                        nome: atual.nome,
                        exercicios: itens,
                      );
                    });
                  },
                  itemBuilder: (context, exIndex) {
                    final item = divisao.exercicios[exIndex];
                    return Padding(
                      key: ValueKey(item.id),
                      padding: EdgeInsets.only(
                        bottom: exIndex < divisao.exercicios.length - 1 ? 12 : 0,
                      ),
                      child: _buildCardItemTreino(item, divisaoIndex, exIndex),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCardItemTreino(ItemTreinoModel item, int divIndex, int exIndex) {
    return Card(
      elevation: 0,
      color: context.appSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.appBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Topo do card com nome e ações
            Row(
              children: [
                ReorderableDragStartListener(
                  index: exIndex,
                  child: Tooltip(
                    message: 'Arraste para alterar a ordem',
                    child: SizedBox(
                      width: 56, height: 48,
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.drag_indicator, color: GridColors.primary, size: 22),
                        Text('${exIndex + 1}', style: TextStyle(
                          color: GridColors.primaryDark, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.exercicioNome,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      Text(
                        item.grupoMuscular,
                        style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remover',
                  icon: const Icon(Icons.delete_outline, color: GridColors.error, size: 20),
                  onPressed: () {
                    setState(() {
                      final novaLista = List<ItemTreinoModel>.from(_divisoes[divIndex].exercicios)
                        ..removeAt(exIndex);
                      _divisoes[divIndex] = DivisaoTreinoModel(
                        id: _divisoes[divIndex].id,
                        letra: _divisoes[divIndex].letra,
                        nome: _divisoes[divIndex].nome,
                        exercicios: novaLista,
                      );
                    });
                  },
                ),
              ],
            ),
            Divider(height: 20, color: context.appBorder),
            TextFormField(
              initialValue: item.observacoes,
              decoration: const InputDecoration(labelText: 'Observação para o aluno'),
              maxLines: 3, minLines: 1,
              onChanged: (valor) => _atualizarItem(divIndex, exIndex,
                _divisoes[divIndex].exercicios[exIndex].copyWith(observacoes: valor)),
            ),
            if (item.exerciciosAlternativos.isNotEmpty)
              Text('Alternativas: ${item.exerciciosAlternativos.join(' ou ')}'),
            if (item.exercicioBiset != null)
              Padding(padding: const EdgeInsets.only(top: 8),
                child: Text('Biset com ${item.exercicioBiset!.exercicioNome}\n'
                  '${item.exercicioBiset!.repeticoes} reps • '
                  '${item.exercicioBiset!.cargaSugeridaKg} kg',
                  style: TextStyle(color: GridColors.primaryDark,
                    fontWeight: FontWeight.w600))),
            const SizedBox(height: 10),

            // Controles rápidos: Séries, Repetições, Carga, Descanso
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _buildCampoAjuste(
                  label: 'Séries',
                  valor: '${item.series}',
                  onDecrement: () => _ajustarSeries(divIndex, exIndex, -1),
                  onIncrement: () => _ajustarSeries(divIndex, exIndex, 1),
                ),
                _buildCampoAjuste(
                  label: 'Descanso',
                  valor: '${item.descansoSegundos}s',
                  onDecrement: () => _ajustarDescanso(divIndex, exIndex, -15),
                  onIncrement: () => _ajustarDescanso(divIndex, exIndex, 15),
                ),
                _buildCampoTextoCurto(
                  label: 'Reps',
                  valorInicial: item.repeticoes,
                  onChanged: (val) {
                    _atualizarItem(divIndex, exIndex, item.copyWith(repeticoes: val));
                  },
                ),
                _buildCampoTextoCurto(
                  label: 'Carga (kg)',
                  valorInicial: '${item.cargaSugeridaKg.toInt()}',
                  onChanged: (val) {
                    final d = double.tryParse(val) ?? item.cargaSugeridaKg;
                    _atualizarItem(divIndex, exIndex, item.copyWith(cargaSugeridaKg: d));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampoAjuste({
    required String label,
    required String valor,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.appSurfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 12, color: context.appTextSecondary)),
          Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          InkWell(
            onTap: onDecrement,
            child: Icon(Icons.remove_circle, size: 18, color: context.appTextSecondary),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onIncrement,
            child: Icon(Icons.add_circle, size: 18, color: GridColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoTextoCurto({
    required String label,
    required String valorInicial,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      width: 100,
      child: TextFormField(
        initialValue: valorInicial,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
    );
  }

  void _ajustarSeries(int divIndex, int exIndex, int delta) {
    final item = _divisoes[divIndex].exercicios[exIndex];
    final novas = (item.series + delta).clamp(1, 10);
    _atualizarItem(divIndex, exIndex, item.copyWith(series: novas));
  }

  void _ajustarDescanso(int divIndex, int exIndex, int delta) {
    final item = _divisoes[divIndex].exercicios[exIndex];
    final novo = (item.descansoSegundos + delta).clamp(15, 300);
    _atualizarItem(divIndex, exIndex, item.copyWith(descansoSegundos: novo));
  }

  void _atualizarItem(int divIndex, int exIndex, ItemTreinoModel novoItem) {
    setState(() {
      final novaLista = List<ItemTreinoModel>.from(_divisoes[divIndex].exercicios);
      novaLista[exIndex] = novoItem;
      _divisoes[divIndex] = DivisaoTreinoModel(
        id: _divisoes[divIndex].id,
        letra: _divisoes[divIndex].letra,
        nome: _divisoes[divIndex].nome,
        exercicios: novaLista,
      );
    });
  }

  Future<void> _selecionarExercicio(int divIndex) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BibliotecaExerciciosScreen(modoSelecao: true,
          tituloFicha: _tituloController.text.trim(),
          divisaoDestino: 'Treino ${_divisoes[divIndex].letra}',
          exerciciosNaDivisao: _divisoes[divIndex].exercicios.map((e) => e.exercicioId).toSet(),
          exerciciosNaFicha: {
            for (final id in _divisoes.expand((d) => d.exercicios).map((e) => e.exercicioId).toSet())
              id: [for (final d in _divisoes)
                if (d.exercicios.any((e) => e.exercicioId == id)) 'Treino ${d.letra}'],
          },
          onRemover: (exercicioId) {
            if (!mounted) return;
            setState(() {
              final divisao = _divisoes[divIndex];
              _divisoes[divIndex] = DivisaoTreinoModel(
                id: divisao.id, letra: divisao.letra, nome: divisao.nome,
                exercicios: divisao.exercicios
                    .where((e) => e.exercicioId != exercicioId).toList(),
              );
            });
          },
          onPrescrever: (item) {
            if (!mounted) return;
            setState(() {
              final divisao = _divisoes[divIndex];
              _divisoes[divIndex] = DivisaoTreinoModel(
                id: divisao.id, letra: divisao.letra, nome: divisao.nome,
                exercicios: [...divisao.exercicios, item],
              );
            });
          }),
      ),
    );


  }

  Future<void> _salvarPlano() async {
    if (_tituloController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe o título da ficha.')),
      );
      return;
    }

    final plano = PlanoTreinoModel(
      id: widget.planoParaEditar?.id ?? 'plano_${DateTime.now().millisecondsSinceEpoch}',
      alunoId: widget.alunoId ?? widget.planoParaEditar?.alunoId ??
          AuthUtility.userInfo.login?.id?.toString() ?? 'aluno_demo',
      alunoNome: widget.alunoNome ?? widget.planoParaEditar?.alunoNome ??
          AuthUtility.userInfo.login?.nome ?? 'Aluno Demonstração',
      personalId: widget.planoParaEditar?.personalId ?? '',
      titulo: _tituloController.text.trim(),
      objetivo: _objetivoController.text.trim(),
      dataInicio: DateTime.now().toIso8601String().split('T').first,
      divisoes: _divisoes,
      isTemplate: _salvandoComoTemplate,
      ativo: true,
    );

    await _repository.salvarPlanoTreino(plano);
    bool publicado = true;
    final destinoAlunoId = widget.alunoId ??
        (widget.planoParaEditar?.alunoId != null &&
         widget.planoParaEditar!.alunoId.isNotEmpty &&
         widget.planoParaEditar!.alunoId != AuthUtility.userInfo.login?.id?.toString()
            ? widget.planoParaEditar!.alunoId
            : null);
    if (destinoAlunoId != null && !plano.isTemplate) {
      publicado = await PersonalGestaoOfflineRepository().publicarTreino(destinoAlunoId, plano);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: GridColors.success,
          content: Text(publicado ? 'Ficha de treino salva com sucesso!' : 'Ficha salva no dispositivo. Publicação pendente de sincronização.'),
        ),
      );
      Navigator.pop(context, plano);
    }
  }
}

extension on ItemTreinoModel {
  ItemTreinoModel copyWith({
    int? series,
    String? repeticoes,
    double? cargaSugeridaKg,
    int? descansoSegundos,
    String? tecnica,
    String? observacoes,
  }) {
    return ItemTreinoModel(
      id: id,
      exercicioId: exercicioId,
      exercicioNome: exercicioNome,
      grupoMuscular: grupoMuscular,
      videoUrl: videoUrl,
      series: series ?? this.series,
      repeticoes: repeticoes ?? this.repeticoes,
      cargaSugeridaKg: cargaSugeridaKg ?? this.cargaSugeridaKg,
      descansoSegundos: descansoSegundos ?? this.descansoSegundos,
      tecnica: tecnica ?? this.tecnica,
      observacoes: observacoes ?? this.observacoes,
      exerciciosAlternativos: exerciciosAlternativos,
      exercicioBiset: exercicioBiset == null ? null : ItemTreinoModel.fromMap({
        ...exercicioBiset!.toMap(),
        'series': series ?? this.series,
        'descansoSegundos': descansoSegundos ?? this.descansoSegundos,
      }),
    );
  }
}
