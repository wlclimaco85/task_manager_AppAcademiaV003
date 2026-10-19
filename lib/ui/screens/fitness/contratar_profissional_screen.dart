import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/fitness/profissional_vitrine_model.dart';
import 'package:task_manager_flutter/data/services/profissionais_vitrine_repository.dart';
import 'package:task_manager_flutter/ui/screens/fitness/checkout_pagamento_screen.dart';

/// Tela de Vitrine / Contratação de Profissionais (Personal Trainer & Nutricionista)
/// Foco Estratégico em Uberaba - MG com:
/// - Filtro Dinâmico por Academias de Uberaba (SmartFit Shopping, Leopoldino, World Fitness, Mega Fit, Fisio & Forma)
/// - Opção para o Personal Cadastrar Nova Academia
/// - Visualização da Disponibilidade / Grade de Horários Livres
/// - Listagem e Contratação Direta de Planos com WhatsApp
class ContratarProfissionalScreen extends StatefulWidget {
  const ContratarProfissionalScreen({super.key});

  @override
  State<ContratarProfissionalScreen> createState() =>
      _ContratarProfissionalScreenState();
}

class _ContratarProfissionalScreenState
    extends State<ContratarProfissionalScreen> {
  final ProfissionaisVitrineRepository _repo =
      ProfissionaisVitrineRepository();
  final TextEditingController _buscaController = TextEditingController();

  CategoriaProfissional? _categoriaFiltro;
  String _academiaFiltro = 'Todas de Uberaba';
  bool _loading = true;
  List<ProfissionalVitrineModel> _profissionais = [];
  List<AcademiaAtendimentoModel> _academiasDisponiveis = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final lista = await _repo.getProfissionais(
      categoria: _categoriaFiltro,
      academiaFiltro: _academiaFiltro == 'Todas de Uberaba' ? null : _academiaFiltro,
      buscaTexto: _buscaController.text,
    );
    final academias = await _repo.getAcademiasCadastradas();

    if (mounted) {
      setState(() {
        _profissionais = lista;
        _academiasDisponiveis = academias;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        backgroundColor: GridColors.card,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Personais & Nutris em Uberaba',
                  style: TextStyle(
                    color: GridColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.location_on, color: CustomColors.primaryGreen, size: 16),
              ],
            ),
            Text(
              'Encontre os melhores profissionais na sua academia',
              style: TextStyle(color: GridColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_outlined, color: CustomColors.primaryGreen),
            tooltip: 'Cadastrar Academia',
            onPressed: () => _modalCadastrarAcademia(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header com Busca, Filtros e Academias
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: GridColors.card,
              border: Border(
                bottom: BorderSide(color: GridColors.divider, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Campo de Busca
                TextField(
                  controller: _buscaController,
                  onChanged: (_) => _carregar(),
                  style: TextStyle(color: GridColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome, especialidade ou academia em Uberaba...',
                    hintStyle:
                        TextStyle(color: GridColors.textSecondary, fontSize: 12),
                    prefixIcon:
                        const Icon(Icons.search, color: CustomColors.primaryGreen),
                    suffixIcon: _buscaController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: GridColors.textSecondary, size: 18),
                            onPressed: () {
                              _buscaController.clear();
                              _carregar();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: GridColors.inputBackground,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: GridColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: GridColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: CustomColors.primaryGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Chips de Categoria e Dropdown de Academias de Uberaba
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChipCategoria(
                        label: 'Todos',
                        selecionado: _categoriaFiltro == null,
                        onTap: () {
                          setState(() => _categoriaFiltro = null);
                          _carregar();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildChipCategoria(
                        label: '🏋️ Personais',
                        selecionado:
                            _categoriaFiltro == CategoriaProfissional.personal,
                        onTap: () {
                          setState(() => _categoriaFiltro =
                              CategoriaProfissional.personal);
                          _carregar();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildChipCategoria(
                        label: '🥗 Nutricionistas',
                        selecionado: _categoriaFiltro ==
                            CategoriaProfissional.nutricionista,
                        onTap: () {
                          setState(() => _categoriaFiltro =
                              CategoriaProfissional.nutricionista);
                          _carregar();
                        },
                      ),
                      const SizedBox(width: 12),
                      // Dropdown de Academias de Uberaba
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: GridColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: GridColors.divider),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _academiaFiltro,
                            dropdownColor: GridColors.card,
                            style: TextStyle(
                                color: GridColors.textPrimary, fontSize: 12),
                            icon: const Icon(Icons.arrow_drop_down,
                                color: CustomColors.primaryGreen, size: 20),
                            items: [
                              const DropdownMenuItem(
                                  value: 'Todas de Uberaba',
                                  child: Text('📍 Todas de Uberaba')),
                              ..._academiasDisponiveis.map((a) => DropdownMenuItem(
                                    value: a.nome,
                                    child: Text(
                                      a.nome.length > 26
                                          ? '${a.nome.substring(0, 24)}...'
                                          : a.nome,
                                    ),
                                  )),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _academiaFiltro = val);
                                _carregar();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de Cards de Profissionais
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: CustomColors.primaryGreen),
                  )
                : _profissionais.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search,
                                size: 56, color: GridColors.textSecondary),
                            const SizedBox(height: 12),
                            Text(
                              'Nenhum profissional encontrado',
                              style: TextStyle(
                                  color: GridColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tente alterar os filtros de academia de Uberaba.',
                              style: TextStyle(
                                  color: GridColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _profissionais.length,
                        itemBuilder: (context, index) {
                          final prof = _profissionais[index];
                          return _buildCardProfissional(prof);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipCategoria({
    required String label,
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado
              ? CustomColors.primaryGreen
              : GridColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionado
                ? CustomColors.primaryGreen
                : GridColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selecionado ? GridColors.textOnPrimary : GridColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCardProfissional(ProfissionalVitrineModel prof) {
    final bool isPersonal = prof.categoria == CategoriaProfissional.personal;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GridColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topo: Avatar, Nome, Categoria e Preço Mínimo
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isPersonal
                          ? CustomColors.primaryGreen.withOpacity(0.2)
                          : GridColors.info.withOpacity(0.2),
                      child: Icon(
                        isPersonal
                            ? Icons.fitness_center
                            : Icons.restaurant_menu,
                        color: isPersonal
                            ? CustomColors.primaryGreen
                            : GridColors.info,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  prof.nome,
                                  style: TextStyle(
                                    color: GridColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isPersonal
                                          ? CustomColors.primaryGreen
                                          : GridColors.info)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isPersonal ? 'PERSONAL' : 'NUTRI',
                                  style: TextStyle(
                                    color: isPersonal
                                        ? CustomColors.primaryGreen
                                        : GridColors.info,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${prof.registroProfissional} • ${prof.anosExperiencia} anos exp. em Uberaba',
                            style: TextStyle(
                                color: GridColors.textSecondary, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: GridColors.secondaryDark, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${prof.avaliacaoMedia} (${prof.totalAvaliacoes} avaliações)',
                                style: const TextStyle(
                                  color: GridColors.secondaryDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'a partir de',
                          style: TextStyle(
                              color: GridColors.textSecondary, fontSize: 10),
                        ),
                        Text(
                          'R\$ ${prof.precoMinimoMensal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: CustomColors.primaryGreen,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '/mês',
                          style: TextStyle(
                              color: GridColors.textSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Especialidade & Bio
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: GridColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Especialidade: ${prof.especialidade}',
                        style: TextStyle(
                          color: GridColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prof.bioResumo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: GridColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Academias Atendidas em Uberaba (Badges)
                Text(
                  'Academias que Atende em Uberaba:',
                  style: TextStyle(
                    color: GridColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: prof.academiasAtendidas
                      .map((acad) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: GridColors.card,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: GridColors.divider),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on,
                                    size: 12,
                                    color: CustomColors.primaryGreen),
                                const SizedBox(width: 4),
                                Text(
                                  acad.nome,
                                  style: TextStyle(
                                    color: GridColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),

                // Resumo de Horários Livres
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule,
                              size: 14, color: GridColors.primaryDark),
                          const SizedBox(width: 4),
                          Text(
                            '${prof.totalHorariosLivres} horários livres disponíveis esta semana',
                            style: TextStyle(
                              color: GridColors.primaryDark,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Botões de Ação: Ver Disponibilidade & Planos
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: GridColors.inputBackground,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: GridColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _modalDetalhesHorarios(context, prof),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GridColors.textPrimary,
                      side: BorderSide(color: GridColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.calendar_month, size: 16),
                    label: const Text('Ver Disponibilidade',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _modalContratarPacotes(context, prof),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CustomColors.primaryGreen,
                      foregroundColor: GridColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Planos & Contratar',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MODAL: GRADE DETALHADA DE HORÁRIOS LIVRES / OCUPADOS
  // ─────────────────────────────────────────────────────────────────────────────

  void _modalDetalhesHorarios(
      BuildContext context, ProfissionalVitrineModel prof) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GridColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Disponibilidade: ${prof.nome}',
                        style: TextStyle(
                          color: GridColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Consulte os horários vagos para agendamento presencial',
                        style: TextStyle(
                            color: GridColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: GridColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...prof.gradeHorarios.map((grade) => Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: GridColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GridColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              grade.diaSemana,
                              style: const TextStyle(
                                color: CustomColors.primaryGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Expediente: ${grade.horarioInicio} - ${grade.horarioFim}',
                              style: TextStyle(
                                  color: GridColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Horários Livres (Disponíveis):',
                          style: TextStyle(
                              color: GridColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: grade.horariosDisponiveis.isEmpty
                              ? [
                                  Text('Sem horários livres neste dia',
                                      style: TextStyle(
                                          color: GridColors.textSecondary,
                                          fontSize: 11))
                                ]
                              : grade.horariosDisponiveis
                                  .map((h) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: CustomColors.primaryGreen
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: CustomColors
                                                  .primaryGreen),
                                        ),
                                        child: Text(
                                          h,
                                          style: const TextStyle(
                                            color: CustomColors.primaryGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                        ),
                        if (grade.horariosOcupados.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Horários Ocupados (Já Reservados):',
                            style: TextStyle(
                                color: GridColors.textSecondary, fontSize: 11),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: grade.horariosOcupados
                                .map((h) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: GridColors.card,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        h,
                                        style: TextStyle(
                                          color: GridColors.textSecondary,
                                          fontSize: 11,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MODAL: PACOTES DE CONTRATAÇÃO & CONTATO WHATSAPP
  // ─────────────────────────────────────────────────────────────────────────────

  void _modalContratarPacotes(
      BuildContext context, ProfissionalVitrineModel prof) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GridColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Planos & Valores: ${prof.nome}',
                      style: TextStyle(
                        color: GridColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'WhatsApp Direto: ${prof.whatsapp}',
                      style: const TextStyle(
                          color: CustomColors.primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close, color: GridColors.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...prof.pacotes.map((pacote) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: GridColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: pacote.destaque
                          ? CustomColors.primaryGreen
                          : GridColors.divider,
                      width: pacote.destaque ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              pacote.titulo,
                              style: TextStyle(
                                color: GridColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            'R\$ ${pacote.precoMensal.toStringAsFixed(2)}/mês',
                            style: const TextStyle(
                              color: CustomColors.primaryGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pacote.descricao,
                        style: TextStyle(
                            color: GridColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CheckoutPagamentoScreen(
                                      pacote: pacote,
                                      profissional: prof,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CustomColors.primaryGreen,
                                foregroundColor: GridColors.textOnPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.payment, size: 16),
                              label: const Text('Pagar com Pix/Cartão',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Iniciando conversa no WhatsApp com ${prof.nome} (${prof.whatsapp}) para o plano "${pacote.titulo}"!'),
                                    backgroundColor: CustomColors.primaryGreen,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: GridColors.textOnPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.chat, size: 16),
                              label: const Text('Dúvidas? WhatsApp',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MODAL: CADASTRAR NOVA ACADEMIA
  // ─────────────────────────────────────────────────────────────────────────────

  void _modalCadastrarAcademia(BuildContext context) {
    final nomeController = TextEditingController();
    final enderecoController = TextEditingController();
    final bairroController =
        TextEditingController(text: 'Centro, Uberaba - MG');

    showModalBottomSheet(
      context: context,
      backgroundColor: GridColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cadastrar Nova Academia em Uberaba',
              style: TextStyle(
                color: GridColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nomeController,
              style: TextStyle(color: GridColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Nome da Academia',
                labelStyle: TextStyle(color: GridColors.textSecondary),
                filled: true,
                fillColor: GridColors.inputBackground,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: enderecoController,
              style: TextStyle(color: GridColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Endereço (Rua, Número)',
                labelStyle: TextStyle(color: GridColors.textSecondary),
                filled: true,
                fillColor: GridColors.inputBackground,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bairroController,
              style: TextStyle(color: GridColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Bairro e Cidade',
                labelStyle: TextStyle(color: GridColors.textSecondary),
                filled: true,
                fillColor: GridColors.inputBackground,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nomeController.text.trim().isEmpty) return;
                  final novaAcademia = AcademiaAtendimentoModel(
                    id: 'acad-${DateTime.now().millisecondsSinceEpoch}',
                    nome: nomeController.text.trim(),
                    endereco: enderecoController.text.trim(),
                    bairroCidade: bairroController.text.trim(),
                  );
                  await _repo.cadastrarNovaAcademia(novaAcademia);
                  Navigator.pop(ctx);
                  _carregar();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Academia "${novaAcademia.nome}" cadastrada com sucesso em Uberaba!'),
                        backgroundColor: CustomColors.primaryGreen,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.primaryGreen,
                  foregroundColor: GridColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Cadastrar Academia',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
