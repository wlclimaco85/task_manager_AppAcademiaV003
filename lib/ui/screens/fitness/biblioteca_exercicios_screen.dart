import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/fitness/exercicio_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';

/// Tela da Biblioteca de Exercícios (Padrão MFIT Personal)
/// Suporta visualização, filtros musculares, detalhes biomecânicos e modo seleção.
class BibliotecaExerciciosScreen extends StatefulWidget {
  final bool modoSelecao; // Quando aberta pelo montador de treinos

  const BibliotecaExerciciosScreen({
    super.key,
    this.modoSelecao = false,
  });

  @override
  State<BibliotecaExerciciosScreen> createState() =>
      _BibliotecaExerciciosScreenState();
}

class _BibliotecaExerciciosScreenState
    extends State<BibliotecaExerciciosScreen> {
  final _repository = FitnessOfflineRepository();
  final _searchController = TextEditingController();

  String _grupoSelecionado = 'Todos';
  String _filtroTexto = '';
  List<ExercicioModel> _exercicios = [];
  bool _loading = true;

  final List<String> _gruposMusculares = [
    'Todos',
    'Peitoral',
    'Costas',
    'Quadríceps',
    'Posterior',
    'Glúteo',
    'Ombros',
    'Bíceps',
    'Tríceps',
    'Abdômen',
    'Cárdio',
  ];

  @override
  void initState() {
    super.initState();
    _carregarExercicios();
  }

  Future<void> _carregarExercicios() async {
    setState(() => _loading = true);
    final lista = await _repository.getExercicios(
      grupoMuscular: _grupoSelecionado == 'Todos' ? null : _grupoSelecionado,
    );
    if (mounted) {
      setState(() {
        _exercicios = lista;
        _loading = false;
      });
    }
  }

  List<ExercicioModel> get _exerciciosFiltrados {
    if (_filtroTexto.trim().isEmpty) return _exercicios;
    final query = _filtroTexto.toLowerCase().trim();
    return _exercicios.where((e) {
      return e.nome.toLowerCase().contains(query) ||
          e.grupoMuscular.toLowerCase().contains(query) ||
          (e.equipamento != null &&
              e.equipamento!.toLowerCase().contains(query));
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktopOrWeb = width >= 800;

    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        title: Text(
          widget.modoSelecao ? 'Selecionar Exercício' : 'Biblioteca de Exercícios',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Novo Exercício',
            icon: const Icon(Icons.add, color: GridColors.primary),
            onPressed: _abrirModalNovoExercicio,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktopOrWeb ? 1100 : double.infinity),
          child: Column(
            children: [
              // 1. Barra de Pesquisa
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _filtroTexto = val),
                  decoration: InputDecoration(
                    hintText: 'Buscar exercício por nome ou músculo...',
                    prefixIcon: const Icon(Icons.search, color: GridColors.textSecondary),
                    suffixIcon: _filtroTexto.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _filtroTexto = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),

              // 2. Chips de Grupos Musculares (Carrossel Horizontal)
              SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  scrollDirection: Axis.horizontal,
                  itemCount: _gruposMusculares.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final grupo = _gruposMusculares[index];
                    final isSelected = grupo == _grupoSelecionado;

                    return FilterChip(
                      selected: isSelected,
                      showCheckmark: false,
                      label: Text(
                        grupo,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? GridColors.textOnPrimary : GridColors.textPrimary,
                        ),
                      ),
                      backgroundColor: GridColors.card,
                      selectedColor: GridColors.primary,
                      side: BorderSide(
                        color: isSelected ? GridColors.primary : GridColors.divider,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (val) {
                        setState(() => _grupoSelecionado = grupo);
                        _carregarExercicios();
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 6),

              // 3. Lista de Exercícios Filtrada
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: GridColors.primary))
                    : _exerciciosFiltrados.isEmpty
                        ? _buildEstadoVazio()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _exerciciosFiltrados.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final ex = _exerciciosFiltrados[index];
                              return _buildCardExercicio(ex);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: GridColors.buttonBackground,
        foregroundColor: GridColors.buttonText,
        icon: const Icon(Icons.add),
        label: const Text('Novo Exercício', style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: _abrirModalNovoExercicio,
      ),
    );
  }

  Widget _buildCardExercicio(ExercicioModel ex) {
    return Card(
      elevation: 0,
      color: GridColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: GridColors.divider, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (widget.modoSelecao) {
            Navigator.pop(context, ex);
          } else {
            _mostrarDetalhesExercicio(ex);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar / Ícone de Equipamento
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: GridColors.primarySubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconePorGrupo(ex.grupoMuscular),
                  color: GridColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Título e Detalhes
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.nome,
                      style: const TextStyle(
                        color: GridColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: GridColors.primarySubtle,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ex.grupoMuscular,
                            style: const TextStyle(
                              color: GridColors.primaryDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (ex.equipamento != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• ${ex.equipamento}',
                            style: const TextStyle(
                              color: GridColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Ação de Seleção ou Seta
              Icon(
                widget.modoSelecao ? Icons.add_circle_outline : Icons.chevron_right,
                color: GridColors.primary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center_outlined, size: 54, color: GridColors.textMuted),
            const SizedBox(height: 14),
            const Text(
              'Nenhum exercício encontrado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: GridColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tente buscar outro termo ou cadastre um novo exercício personalizado.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: GridColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalhesExercicio(ExercicioModel ex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: GridColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: GridColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ex.nome,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: GridColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: GridColors.primarySubtle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ex.grupoMuscular,
                      style: const TextStyle(
                        color: GridColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (ex.equipamento != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Equipamento: ${ex.equipamento}',
                  style: const TextStyle(color: GridColors.textSecondary, fontSize: 13),
                ),
              ],
              const Divider(height: 28, color: GridColors.divider),
              const Text(
                'Execução Biomecânica:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: GridColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                ex.instrucoes.isNotEmpty
                    ? ex.instrucoes
                    : 'Execute o movimento com controle e amplitude completa.',
                style: const TextStyle(fontSize: 13, height: 1.4, color: GridColors.textSecondary),
              ),
              if (ex.errosComuns != null && ex.errosComuns!.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Erros Comuns a Evitar:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: GridColors.error,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ex.errosComuns!,
                  style: const TextStyle(fontSize: 13, height: 1.35, color: GridColors.textSecondary),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar Detalhes'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _abrirModalNovoExercicio() {
    final nomeCtrl = TextEditingController();
    final equipCtrl = TextEditingController();
    final instrucaoCtrl = TextEditingController();
    String grupo = _grupoSelecionado == 'Todos' ? 'Peitoral' : _grupoSelecionado;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Cadastrar Novo Exercício', style: TextStyle(fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomeCtrl,
                      decoration: const InputDecoration(labelText: 'Nome do Exercício *'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: grupo,
                      decoration: const InputDecoration(labelText: 'Grupo Muscular'),
                      items: _gruposMusculares
                          .where((g) => g != 'Todos')
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => grupo = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: equipCtrl,
                      decoration: const InputDecoration(labelText: 'Equipamento (Ex: Halteres, Barra)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: instrucaoCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Instruções de Execução'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nomeCtrl.text.trim().isEmpty) return;
                    final novo = ExercicioModel(
                      id: 'ex_custom_${DateTime.now().millisecondsSinceEpoch}',
                      nome: nomeCtrl.text.trim(),
                      grupoMuscular: grupo,
                      equipamento: equipCtrl.text.trim().isNotEmpty ? equipCtrl.text.trim() : null,
                      instrucoes: instrucaoCtrl.text.trim(),
                      isCustom: true,
                    );
                    await _repository.addExercicio(novo);
                    Navigator.pop(context);
                    _carregarExercicios();
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _iconePorGrupo(String grupo) {
    switch (grupo.toLowerCase()) {
      case 'peitoral':
        return Icons.fitness_center;
      case 'costas':
        return Icons.accessibility_new;
      case 'quadríceps':
      case 'posterior':
      case 'glúteo':
        return Icons.directions_walk;
      case 'ombros':
        return Icons.shield_outlined;
      case 'bíceps':
      case 'tríceps':
        return Icons.sports_gymnastics;
      case 'cárdio':
        return Icons.directions_run;
      default:
        return Icons.fitness_center;
    }
  }
}
