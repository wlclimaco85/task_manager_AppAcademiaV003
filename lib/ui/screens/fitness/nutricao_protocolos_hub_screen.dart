import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/nutricao_editores.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/services/pdf/ficha_dieta_pdf.dart';
import 'package:task_manager_flutter/ui/widgets/imprimir_pdf.dart';
import 'package:task_manager_flutter/data/models/fitness/nutricao_farmaco_model.dart';
import 'package:task_manager_flutter/data/services/nutricao_farmaco_offline_repository.dart';
import 'package:task_manager_flutter/data/services/unidade_medida_catalogo.dart';

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

    if (mounted) {
      setState(() {
        _dietas = dietas;
        _medicamentos = medicamentos;
        _suplementos = suplementos;
        _timelineEventos = timeline;
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
          Align(alignment:Alignment.centerRight,child:TextButton.icon(
            onPressed:()=>_abrirDialogCriarDieta(dieta),icon:const Icon(Icons.edit_outlined,size:16),
            label:const Text('Editar refeições e alimentos'))),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: Key('btn_imprimir_dieta_${dieta.id}'),
              icon: const Icon(Icons.print_outlined, size: 16),
              label: const Text('Imprimir PDF'),
              onPressed: () => imprimirPdf(
                context,
                nomeArquivo: nomeArquivoPdf('Dieta', dieta.titulo),
                gerar: () async {
                  final alimentos = {for (final a in await _repository.getAlimentos()) a.id: a};
                  return FichaDietaPdf.dieta(
                    dieta,
                    alunoNome: AuthUtility.userInfo.login?.nome ?? '',
                    alimentos: alimentos,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Painel de Metas de Macronutrientes
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildMacroItem('Calorias', _valorMacro(dieta.totalCaloriasReal, dieta.caloriasMeta, 'kcal'), const Color(0xFFEA580C)),
                _buildMacroItem('Proteínas', _valorMacro(dieta.totalProteinasReal, dieta.proteinasMeta, 'g'), const Color(0xFF059669)),
                _buildMacroItem('Carbos', _valorMacro(dieta.totalCarboidratosReal, dieta.carboidratosMeta, 'g'), const Color(0xFF2563EB)),
                _buildMacroItem('Gorduras', _valorMacro(dieta.totalGordurasReal, dieta.gordurasMeta, 'g'), const Color(0xFFD97706)),
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

  String _valorMacro(double valor, double meta, String unidade) =>
      meta > 0 ? valor.toStringAsFixed(0)+' / '+meta.toStringAsFixed(0)+' '+unidade
          : valor.toStringAsFixed(0)+' '+unidade+' (sem meta)';

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
              onPressed: () => _abrirDialogMedicamento(),
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
                          if (!med.visivelParaPersonal)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.lock_outline, size: 13, color: GridColors.textSecondary),
                                  SizedBox(width: 4),
                                  Text('Privado • oculto para o personal',
                                      style: TextStyle(fontSize: 11, color: GridColors.textSecondary)),
                                ],
                              ),
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
              const Spacer(),
              TextButton.icon(
                key: Key('editar_medicamento_${med.id}'),
                onPressed: () => _abrirDialogMedicamento(med),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(med.ativo ? 'Editar / finalizar' : 'Editar / reabrir'),
              ),
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
                if(sup.marca.isNotEmpty)Text(sup.marca,style:const TextStyle(color:GridColors.textSecondary)),
                if(sup.quantidadePote!=null)Text('Pote: '+sup.quantidadePote!.toString()+' '+sup.unidadePote,style:const TextStyle(color:GridColors.textSecondary)),
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
          IconButton(tooltip: 'Editar suplemento', onPressed:()=>_abrirDialogCriarSuplemento(sup),icon:const Icon(Icons.edit_outlined,color:GridColors.primary)),
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
      case 'exame_laboratorial':
        return Icons.picture_as_pdf;
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

  Future<void> _abrirDialogCriarDieta([DietaProtocoloModel? dieta]) async {
    final salvo=await showDialog<bool>(context:context,builder:(_)=>DietaEditor(dieta:dieta));
    if(salvo==true && mounted) {
      await _carregarDados();
    }
  }

  /// Cria ou edita um medicamento/ciclo. Edicao permite corrigir inicio
  /// (lancamento retroativo) e finalizar/reabrir o uso. Nunca exclui: o
  /// historico fica preservado.
  Future<void> _abrirDialogMedicamento([MedicamentoProtocoloModel? med]) async {
    final unidades = await UnidadeMedidaCatalogo.carregar();
    if (!mounted) return;
    final nomeCtrl = TextEditingController(text: med?.nomeComposto ?? '');
    final quantidadeCtrl = TextEditingController(
        text: med?.doseQuantidade != null ? _formatarQuantidade(med!.doseQuantidade!) : '');
    final freqCtrl = TextEditingController(text: med?.frequencia ?? '1x por semana');
    String categoria = med?.categoria ?? 'ergogenico_ciclo';
    bool privado = med?.privado ?? false;
    String? unidade = med?.doseUnidade ?? (med == null ? unidades.first : null);
    String dataInicio = med?.dataInicio ?? _hojeIso();
    String? dataFim = med?.dataFim;
    final opcoesUnidade = {...unidades, if (unidade != null) unidade}.toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(med == null ? 'Cadastrar Medicamento / Ciclo' : 'Editar Medicamento / Ciclo',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: quantidadeCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Quantidade por uso (ex: 2)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 130,
                          child: DropdownButtonFormField<String>(
                            key: const Key('dropdown_unidade_medicamento'),
                            initialValue: unidade,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Unidade'),
                            items: [
                              for (final u in opcoesUnidade)
                                DropdownMenuItem(value: u, child: Text(u)),
                            ],
                            onChanged: (val) => setDialogState(() => unidade = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: freqCtrl,
                      decoration: const InputDecoration(labelText: 'Frequência (ex: 1x semana, DSDN)'),
                    ),
                    ListTile(
                      key: const Key('data_inicio_medicamento'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event),
                      title: const Text('Data de início'),
                      subtitle: Text(_formatarDataBr(dataInicio)),
                      onTap: () async {
                        final escolhida = await _escolherData(context, dataInicio);
                        if (escolhida != null) setDialogState(() => dataInicio = escolhida);
                      },
                    ),
                    if (dataFim != null)
                      ListTile(
                        key: const Key('data_fim_medicamento'),
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_available),
                        title: const Text('Data de fim'),
                        subtitle: Text(_formatarDataBr(dataFim!)),
                        onTap: () async {
                          final escolhida = await _escolherData(context, dataFim!);
                          if (escolhida != null) setDialogState(() => dataFim = escolhida);
                        },
                        trailing: IconButton(
                          tooltip: 'Reabrir uso (remove a data de fim)',
                          icon: const Icon(Icons.undo),
                          onPressed: () => setDialogState(() => dataFim = null),
                        ),
                      ),
                    if (MedicamentoProtocoloModel.permitePrivado(categoria)) ...[
                      const SizedBox(height: 6),
                      SwitchListTile(
                        key: const Key('switch_ciclo_privado'),
                        contentPadding: EdgeInsets.zero,
                        value: privado,
                        onChanged: (val) => setDialogState(() => privado = val),
                        secondary: const Icon(Icons.lock_outline),
                        title: const Text('Privado'),
                        subtitle: const Text('Não compartilhar este ciclo com o personal'),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                if (med != null && dataFim == null)
                  OutlinedButton(
                    key: const Key('finalizar_uso_medicamento'),
                    onPressed: () => setDialogState(() => dataFim = _hojeIso()),
                    child: const Text('Finalizar uso'),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
                  onPressed: () async {
                    final nome = nomeCtrl.text.trim();
                    final quantidade = double.tryParse(quantidadeCtrl.text.trim().replaceAll(',', '.'));
                    String? erro;
                    if (nome.isEmpty) {
                      erro = 'Informe o nome do medicamento.';
                    } else if (quantidade == null || quantidade <= 0) {
                      erro = 'Informe a quantidade por uso.';
                    } else if (unidade == null) {
                      erro = 'Escolha a unidade de medida.';
                    } else if (dataFim != null && dataFim!.compareTo(dataInicio) < 0) {
                      erro = 'A data de fim não pode ser anterior ao início.';
                    }
                    if (erro != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
                      return;
                    }
                    final salvo = MedicamentoProtocoloModel(
                      id: med?.id ?? 'med_${DateTime.now().millisecondsSinceEpoch}',
                      alunoId: med?.alunoId ?? 'aluno_1',
                      nomeComposto: nome,
                      dosagem: '${_formatarQuantidade(quantidade!)} $unidade',
                      doseQuantidade: quantidade,
                      doseUnidade: unidade,
                      frequencia: freqCtrl.text.trim(),
                      viaAdministracao: med?.viaAdministracao ?? 'Oral',
                      categoria: categoria,
                      dataInicio: dataInicio,
                      dataFim: dataFim,
                      ativo: dataFim == null,
                      horario: med?.horario,
                      observacoes: med?.observacoes,
                      privado: privado && MedicamentoProtocoloModel.permitePrivado(categoria),
                    );
                    await _repository.salvarMedicamento(salvo);
                    if (!context.mounted) return;
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

  static String _hojeIso() => DateTime.now().toIso8601String().substring(0, 10);

  /// 2 -> "2", 0.5 -> "0,5" (exibicao em pt-BR).
  static String _formatarQuantidade(double valor) =>
      valor == valor.truncateToDouble()
          ? valor.toInt().toString()
          : valor.toString().replaceAll('.', ',');

  /// "2026-10-16" -> "16/10/2026".
  static String _formatarDataBr(String iso) {
    final partes = iso.split('-');
    return partes.length == 3 ? '${partes[2]}/${partes[1]}/${partes[0]}' : iso;
  }

  Future<String?> _escolherData(BuildContext context, String isoAtual) async {
    final hoje = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(isoAtual) ?? hoje,
      firstDate: DateTime(2000),
      lastDate: hoje.add(const Duration(days: 365)),
    );
    return escolhida?.toIso8601String().substring(0, 10);
  }

  Future<void> _abrirDialogCriarSuplemento([SuplementoProtocoloModel? suplemento]) async {
    final salvo=await showDialog<bool>(context:context,builder:(_)=>SuplementoEditor(suplemento:suplemento));
    if(salvo==true && mounted) {
      await _carregarDados();
    }
  }
}
