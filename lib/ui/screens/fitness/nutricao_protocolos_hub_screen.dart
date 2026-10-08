import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/fitness/nutricao_farmaco_model.dart';
import 'package:task_manager_flutter/data/services/nutricao_farmaco_offline_repository.dart';

/// Central de Nutrição, Farmacologia, Suplementação & Timeline Fitness 360
class NutricaoProtocolosHubScreen extends StatefulWidget {
  const NutricaoProtocolosHubScreen({super.key});

  @override
  State<NutricaoProtocolosHubScreen> createState() =>
      _NutricaoProtocolosHubScreenState();
}

class _NutricaoProtocolosHubScreenState
    extends State<NutricaoProtocolosHubScreen>
    with SingleTickerProviderStateMixin {
  final _repository = NutricaoFarmacoOfflineRepository();
  late TabController _tabController;

  List<DietaProtocoloModel> _dietas = [];
  List<MedicamentoProtocoloModel> _medicamentos = [];
  List<SuplementoProtocoloModel> _suplementos = [];
  List<TimelineFitnessEventModel> _timelineEventos = [];
  List<AlimentoModel> _alimentos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _loading = true);
    final dietas = await _repository.getDietas();
    final medicamentos = await _repository.getMedicamentos();
    final suplementos = await _repository.getSuplementos();
    final timeline = await _repository.getTimelineEventos();
    final alimentos = await _repository.getAlimentos();

    if (mounted) {
      setState(() {
        _dietas = dietas;
        _medicamentos = medicamentos;
        _suplementos = suplementos;
        _timelineEventos = timeline;
        _alimentos = alimentos;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktopOrWeb = width >= 800;

    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        backgroundColor: GridColors.card,
        foregroundColor: GridColors.textPrimary,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.restaurant_menu, color: GridColors.primary, size: 24),
            SizedBox(width: 8),
            Text(
              'Nutrição & Protocolos 360',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: GridColors.primary,
          unselectedLabelColor: GridColors.textSecondary,
          indicatorColor: GridColors.primary,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant), text: 'Dietas & Macros'),
            Tab(icon: Icon(Icons.medication), text: 'Medicamentos & Ciclos'),
            Tab(icon: Icon(Icons.science), text: 'Suplementos'),
            Tab(icon: Icon(Icons.timeline), text: 'Timeline 360'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: GridColors.primary))
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: isDesktopOrWeb ? 1100 : double.infinity),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabDietas(),
                    _buildTabMedicamentos(),
                    _buildTabSuplementos(),
                    _buildTabTimeline360(),
                  ],
                ),
              ),
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. ABA DIETAS & MACROS (COM CÁLCULO AUTOMÁTICO DE ALIMENTOS)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildTabDietas() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header com Botão de Adicionar Nova Dieta
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Protocolos Nutricionais',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: GridColors.textPrimary),
                ),
                Text(
                  '${_dietas.length} plano(s) cadastrado(s)',
                  style: const TextStyle(color: GridColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nova Dieta'),
              onPressed: _abrirDialogCriarDieta,
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_dietas.isEmpty)
          _buildEmptyCard('Nenhuma dieta cadastrada.', Icons.restaurant_outlined)
        else
          for (final dieta in _dietas) _buildCardDieta(dieta),
      ],
    );
  }

  Widget _buildCardDieta(DietaProtocoloModel dieta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GridColors.inputBorder),
        boxShadow: const [
          BoxShadow(color: GridColors.shadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dieta.titulo,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: GridColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📅 Vigência: ${dieta.dataInicio} ${dieta.dataFim != null ? 'até ${dieta.dataFim}' : '(Em andamento)'}',
                      style: const TextStyle(color: GridColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: dieta.ativa ? GridColors.primarySubtle : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  dieta.ativa ? 'Ativa' : 'Encerrada',
                  style: TextStyle(
                    color: dieta.ativa ? GridColors.primary : GridColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Painel de Metas de Macronutrientes
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroItem('Calorias', '${dieta.totalCaloriasReal.toStringAsFixed(0)} / ${dieta.caloriasMeta.toStringAsFixed(0)} kcal', const Color(0xFFEA580C)),
                _buildMacroItem('Proteínas', '${dieta.totalProteinasReal.toStringAsFixed(0)} / ${dieta.proteinasMeta.toStringAsFixed(0)}g', const Color(0xFF059669)),
                _buildMacroItem('Carbos', '${dieta.totalCarboidratosReal.toStringAsFixed(0)} / ${dieta.carboidratosMeta.toStringAsFixed(0)}g', const Color(0xFF2563EB)),
                _buildMacroItem('Gorduras', '${dieta.totalGordurasReal.toStringAsFixed(0)} / ${dieta.gordurasMeta.toStringAsFixed(0)}g', const Color(0xFFD97706)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Refeições da Dieta
          const Text('Refeições Prescritas:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: GridColors.textPrimary)),
          const SizedBox(height: 8),

          for (final ref in dieta.refeicoes)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.symmetric(vertical: 4),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${ref.nome} (${ref.horario})',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text('${ref.totalCalorias.toStringAsFixed(0)} kcal',
                        style: const TextStyle(color: GridColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
                subtitle: Text(
                  '${ref.itens.length} alimento(s) • P: ${ref.totalProteinas.toStringAsFixed(0)}g C: ${ref.totalCarboidratos.toStringAsFixed(0)}g G: ${ref.totalGorduras.toStringAsFixed(0)}g',
                  style: const TextStyle(color: GridColors.textSecondary, fontSize: 11),
                ),
                children: [
                  for (final item in ref.itens)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 6, color: GridColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${item.alimentoNome} (${item.quantidadeGramas.toStringAsFixed(0)}g)',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            '${item.calorias.toStringAsFixed(0)} kcal (P:${item.proteinas.toStringAsFixed(0)}g C:${item.carboidratos.toStringAsFixed(0)}g G:${item.gorduras.toStringAsFixed(0)}g)',
                            style: const TextStyle(fontSize: 11, color: GridColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, String valor, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(valor, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: GridColors.textPrimary)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. ABA MEDICAMENTOS & CICLOS (HORMÔNIOS / BOMBA / PROTETORES)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildTabMedicamentos() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medicamentos & Ciclos',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: GridColors.textPrimary),
                ),
                Text(
                  '${_medicamentos.length} protocolo(s) de compostos',
                  style: const TextStyle(color: GridColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444), // Red
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Novo Protocolo'),
              onPressed: _abrirDialogCriarMedicamento,
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_medicamentos.isEmpty)
          _buildEmptyCard('Nenhum medicamento ou composto em uso.', Icons.medication_outlined)
        else
          for (final med in _medicamentos) _buildCardMedicamento(med),
      ],
    );
  }

  Widget _buildCardMedicamento(MedicamentoProtocoloModel med) {
    final isErgogenico = med.categoria == 'ergogenico_ciclo';
    final corDestaque = isErgogenico ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: corDestaque.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(color: GridColors.shadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: corDestaque.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.medication, color: corDestaque, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med.nomeComposto,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: GridColors.textPrimary),
                          ),
                          Text(
                            '${med.dosagem} • ${med.frequencia} (${med.viaAdministracao})',
                            style: TextStyle(color: corDestaque, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: med.ativo ? corDestaque.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  med.ativo ? 'Em Uso' : 'Finalizado',
                  style: TextStyle(
                    color: med.ativo ? corDestaque : GridColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: GridColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Período: ${med.dataInicio} ${med.dataFim != null ? 'até ${med.dataFim}' : '(Contínuo)'}',
                style: const TextStyle(color: GridColors.textSecondary, fontSize: 12),
              ),
              if (med.horario != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.access_time, size: 14, color: GridColors.textSecondary),
                const SizedBox(width: 4),
                Text(med.horario!, style: const TextStyle(color: GridColors.textSecondary, fontSize: 12)),
              ],
            ],
          ),
          if (med.observacoes != null && med.observacoes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Obs: ${med.observacoes}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. ABA SUPLEMENTOS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildTabSuplementos() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suplementação Diária',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: GridColors.textPrimary),
                ),
                Text(
                  '${_suplementos.length} item(ns) em uso',
                  style: const TextStyle(color: GridColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB), // Blue
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Novo Suplemento'),
              onPressed: _abrirDialogCriarSuplemento,
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_suplementos.isEmpty)
          _buildEmptyCard('Nenhum suplemento cadastrado.', Icons.science_outlined)
        else
          for (final sup in _suplementos) _buildCardSuplemento(sup),
      ],
    );
  }

  Widget _buildCardSuplemento(SuplementoProtocoloModel sup) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.science, color: Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sup.nome,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: GridColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${sup.dosagem} • Horário: ${sup.horario}',
                  style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700, fontSize: 12),
                ),
                if (sup.observacoes != null)
                  Text(sup.observacoes!, style: const TextStyle(color: GridColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. ABA TIMELINE FITNESS 360 (GRÁFICO COM PESO, % GORDURA E PROTOCOLOS)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildTabTimeline360() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        const Text(
          'Timeline de Evolução 360°',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: GridColors.textPrimary),
        ),
        const Text(
          'Cruzamento temporal de Peso, % de Gordura, Dietas, Medicamentos e Suplementos',
          style: TextStyle(color: GridColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 16),

        // Gráfico Interativo com fl_chart
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
          decoration: BoxDecoration(
            color: GridColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: GridColors.inputBorder),
            boxShadow: const [
              BoxShadow(color: GridColors.shadow, blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Evolução Corporal (Peso x % Gordura)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  Row(
                    children: [
                      _buildLegendaDot('Peso (kg)', const Color(0xFF059669)),
                      const SizedBox(width: 12),
                      _buildLegendaDot('% Gordura', const Color(0xFFF59E0B)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 10,
                      getDrawingHorizontalLine: (value) =>
                          FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          interval: 20,
                          getTitlesWidget: (val, _) => Text('${val.toInt()}',
                              style: const TextStyle(color: GridColors.textSecondary, fontSize: 10)),
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (val, _) {
                            final idx = val.toInt();
                            if (idx == 0) return const Text('Mês -3', style: TextStyle(fontSize: 10));
                            if (idx == 1) return const Text('Mês -2', style: TextStyle(fontSize: 10));
                            if (idx == 2) return const Text('Mês -1', style: TextStyle(fontSize: 10));
                            if (idx == 3) return const Text('Atual', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold));
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      // Linha de Peso (kg): 88.5 -> 85.8 -> 83.2 -> 81.4
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 88.5),
                          FlSpot(1, 85.8),
                          FlSpot(2, 83.2),
                          FlSpot(3, 81.4),
                        ],
                        isCurved: true,
                        color: const Color(0xFF059669),
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF059669).withValues(alpha: 0.1),
                        ),
                      ),
                      // Linha de % BF: 19.2% -> 16.4% -> 13.8% -> 11.2%
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 19.2),
                          FlSpot(1, 16.4),
                          FlSpot(2, 13.8),
                          FlSpot(3, 11.2),
                        ],
                        isCurved: true,
                        color: const Color(0xFFF59E0B),
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Lista Cronológica de Eventos e Protocolos
        const Text(
          'Marcos & Linha do Tempo',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: GridColors.textPrimary),
        ),
        const SizedBox(height: 12),

        for (final ev in _timelineEventos) _buildTimelineEventCard(ev),
      ],
    );
  }

  Widget _buildLegendaDot(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: GridColors.textSecondary)),
      ],
    );
  }

  Widget _buildTimelineEventCard(TimelineFitnessEventModel ev) {
    final cor = _parseColor(ev.tagCorHex ?? '#10B981');
    final dataFormatada =
        '${ev.data.day.toString().padLeft(2, '0')}/${ev.data.month.toString().padLeft(2, '0')}/${ev.data.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconParaTipo(ev.tipo), color: cor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(ev.titulo,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    Text(dataFormatada,
                        style: const TextStyle(color: GridColors.textSecondary, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(ev.descricao,
                    style: const TextStyle(color: GridColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconParaTipo(String tipo) {
    switch (tipo) {
      case 'avaliacao_fisica':
        return Icons.insights;
      case 'inicio_dieta':
      case 'fim_dieta':
        return Icons.restaurant;
      case 'inicio_medicamento':
      case 'fim_medicamento':
        return Icons.medication;
      default:
        return Icons.science;
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return GridColors.primary;
    }
  }

  Widget _buildEmptyCard(String msg, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GridColors.inputBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: GridColors.textSecondary),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: GridColors.textSecondary)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DIÁLOGOS DE CADASTRO
  // ─────────────────────────────────────────────────────────────────────────────

  void _abrirDialogCriarDieta() {
    final tituloCtrl = TextEditingController(text: 'Dieta Nova Fase');
    final caloriasCtrl = TextEditingController(text: '2400');
    final proteinasCtrl = TextEditingController(text: '180');
    final carbosCtrl = TextEditingController(text: '250');
    final gordurasCtrl = TextEditingController(text: '70');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Nova Dieta', style: TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloCtrl,
                  decoration: const InputDecoration(labelText: 'Título da Dieta'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: caloriasCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Calorias (kcal)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: proteinasCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Proteínas (g)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: carbosCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Carbos (g)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: gordurasCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Gorduras (g)'),
                      ),
                    ),
                  ],
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
              style: ElevatedButton.styleFrom(backgroundColor: GridColors.primary, foregroundColor: Colors.white),
              onPressed: () async {
                final nova = DietaProtocoloModel(
                  id: 'dieta_${DateTime.now().millisecondsSinceEpoch}',
                  alunoId: 'aluno_1',
                  titulo: tituloCtrl.text.trim(),
                  objetivo: 'hipertrofia',
                  caloriasMeta: double.tryParse(caloriasCtrl.text) ?? 2400,
                  proteinasMeta: double.tryParse(proteinasCtrl.text) ?? 180,
                  carboidratosMeta: double.tryParse(carbosCtrl.text) ?? 250,
                  gordurasMeta: double.tryParse(gordurasCtrl.text) ?? 70,
                  dataInicio: DateTime.now().toIso8601String().substring(0, 10),
                  refeicoes: const [
                    RefeicaoModel(
                      id: 'ref_1',
                      nome: 'Café da Manhã',
                      horario: '08:00',
                      itens: [
                        ItemRefeicaoModel(alimentoId: 'alim_12', alimentoNome: 'Ovo Cozido', quantidadeGramas: 100, calorias: 144, proteinas: 12.6, carboidratos: 1.2, gorduras: 9.6),
                        ItemRefeicaoModel(alimentoId: 'alim_7', alimentoNome: 'Aveia em Flocos', quantidadeGramas: 60, calorias: 236, proteinas: 8.3, carboidratos: 40.0, gorduras: 5.1),
                      ],
                    ),
                  ],
                );
                await _repository.salvarDieta(nova);
                Navigator.pop(context);
                _carregarDados();
              },
              child: const Text('Criar Dieta'),
            ),
          ],
        );
      },
    );
  }

  void _abrirDialogCriarMedicamento() {
    final nomeCtrl = TextEditingController();
    final dosagemCtrl = TextEditingController(text: '250mg');
    final freqCtrl = TextEditingController(text: '1x por semana');
    String categoria = 'ergogenico_ciclo';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Cadastrar Medicamento / Ciclo', style: TextStyle(fontWeight: FontWeight.w800)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Medicamento / Composto',
                        hintText: 'Ex: Enantato de Testosterona, Oxandrolona',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: categoria,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: const [
                        DropdownMenuItem(value: 'ergogenico_ciclo', child: Text('Hormônio / Ciclo')),
                        DropdownMenuItem(value: 'tpc_protetor', child: Text('Protetor / TPC')),
                        DropdownMenuItem(value: 'manipulado_farmacia', child: Text('Manipulado / Farmácia')),
                        DropdownMenuItem(value: 'geral', child: Text('Geral / Contínuo')),
                      ],
                      onChanged: (val) => setDialogState(() => categoria = val ?? 'ergogenico_ciclo'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: dosagemCtrl,
                      decoration: const InputDecoration(labelText: 'Dosagem (ex: 250mg, 10mg)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: freqCtrl,
                      decoration: const InputDecoration(labelText: 'Frequência (ex: 1x semana, DSDN)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
                  onPressed: () async {
                    if (nomeCtrl.text.trim().isEmpty) return;
                    final novo = MedicamentoProtocoloModel(
                      id: 'med_${DateTime.now().millisecondsSinceEpoch}',
                      alunoId: 'aluno_1',
                      nomeComposto: nomeCtrl.text.trim(),
                      dosagem: dosagemCtrl.text.trim(),
                      frequencia: freqCtrl.text.trim(),
                      categoria: categoria,
                      dataInicio: DateTime.now().toIso8601String().substring(0, 10),
                    );
                    await _repository.salvarMedicamento(novo);
                    Navigator.pop(context);
                    _carregarDados();
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

  void _abrirDialogCriarSuplemento() {
    final nomeCtrl = TextEditingController();
    final dosagemCtrl = TextEditingController(text: '5g');
    final horarioCtrl = TextEditingController(text: 'Pós-Treino');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Cadastrar Suplemento', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome do Suplemento',
                  hintText: 'Ex: Creatina Monohidratada, Whey Protein',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dosagemCtrl,
                decoration: const InputDecoration(labelText: 'Dosagem (ex: 5g, 30g)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: horarioCtrl,
                decoration: const InputDecoration(labelText: 'Horário / Modo de Uso'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              onPressed: () async {
                if (nomeCtrl.text.trim().isEmpty) return;
                final novo = SuplementoProtocoloModel(
                  id: 'sup_${DateTime.now().millisecondsSinceEpoch}',
                  alunoId: 'aluno_1',
                  nome: nomeCtrl.text.trim(),
                  dosagem: dosagemCtrl.text.trim(),
                  horario: horarioCtrl.text.trim(),
                  dataInicio: DateTime.now().toIso8601String().substring(0, 10),
                );
                await _repository.salvarSuplemento(novo);
                Navigator.pop(context);
                _carregarDados();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}
