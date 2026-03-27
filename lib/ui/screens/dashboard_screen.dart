// lib/dashboard/dashboard_page.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/dashboard_model.dart';
import 'package:task_manager_flutter/data/services/dashboard_caller.dart';
import 'package:task_manager_flutter/data/utils/grid_colors.dart';
import 'package:task_manager_flutter/data/utils/security_matrix.dart';
import 'package:task_manager_flutter/data/utils/utils.dart';
import 'package:task_manager_flutter/ui/screens/chats_daily_chart.dart';
// novos imports dos widgets de dashboard
import 'package:task_manager_flutter/ui/screens/dashboard_alerts_screen.dart';
import 'package:task_manager_flutter/ui/screens/dashboard_client_distribution_screen.dart';
import 'package:task_manager_flutter/ui/screens/dashboard_finance_fluxo_diario_screen.dart';
import 'package:task_manager_flutter/ui/screens/dashboard_finance_trend_screen.dart';
import 'package:task_manager_flutter/ui/screens/dashboard_kpis_screen.dart';
import 'package:task_manager_flutter/ui/screens/dashboard_quarterly_screen.dart';
import 'package:task_manager_flutter/ui/screens/dashboard_tickets_trend_screen.dart';

// 🔹 novos imports dos gráficos de contas bancárias
import 'package:task_manager_flutter/ui/screens/dashboard_contas_balances_screen.dart';
import 'package:task_manager_flutter/ui/screens/dashboard_conta_evolucao_screen.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<FinancePoint> finance = [];
  TicketStatusCounts? tickets;
  List<ChatsDailyPoint> chats = [];
  bool loading = true;
  String? error;

  final int empresaId = pegarEmpresaLogada();
  final int? parceiroId = pegarParceiroLogada();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    debugPrint('[_load] start');

    Future<List<FinancePoint>> seriesF() async {
      try {
        return await DashboardApiClient().fetchFinanceSeries(months: 6);
      } catch (e, st) {
        debugPrint('[finance] FAILED: $e\n$st');
        return [];
      }
    }

    Future<TicketStatusCounts> ticketF() async {
      try {
        return await DashboardApiClient().fetchTicketStatusCounts();
      } catch (e, st) {
        debugPrint('[tickets] FAILED: $e\n$st');
        return TicketStatusCounts(open: 0, inProgress: 0, closed: 0);
      }
    }

    Future<List<ChatsDailyPoint>> chatsF() async {
      try {
        return await DashboardApiClient().fetchChatsDaily(days: 7);
      } catch (e, st) {
        debugPrint('[chats] FAILED: $e\n$st');
        return [];
      }
    }

    try {
      final results = await Future.wait([
        seriesF(),
        ticketF(),
        chatsF(),
      ], eagerError: false);

      setState(() {
        finance = results[0] as List<FinancePoint>;
        tickets = results[1] as TicketStatusCounts;
        chats = results[2] as List<ChatsDailyPoint>;
        loading = false;
      });
      debugPrint('[_load] SUCCESS (some graphs may have partial data)');
    } catch (e, st) {
      debugPrint('[_load] unexpected global fail: $e\n$st');
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: Center(
          child: Text(
            error!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
          ),
        ),
      );
    }

    final sec = SecurityMatrix.current();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: GridColors.primary,
        foregroundColor: GridColors.textPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 🔹 1) KPIs
            if (sec.canView(AppScreen.dashKpis)) ...[
              _sectionTitle('📈 Indicadores-Chave'),
              const SizedBox(height: 8),
              KpiCards(empresaId: empresaId, parceiroId: parceiroId),
              const SizedBox(height: 28),
            ],

            // 🔹 2) Financeiro (cards)
            if (sec.canView(AppScreen.dashFinanceCards)) ...[
              _sectionTitle('📊 Financeiro'),
              const SizedBox(height: 8),
              _financeCards(),
              const SizedBox(height: 16),
            ],

            // 🔹 3) Fluxo Diário
            if (sec.canView(AppScreen.dashFluxoDiario)) ...[
              _sectionTitle('💵 Fluxo Diário (–10 dias / +30 dias)'),
              const SizedBox(height: 8),
              FinanceFluxoDiarioChart(
                empresaId: empresaId,
                parceiroId: parceiroId,
                daysBack: 10,
                daysForward: 30,
              ),
              const SizedBox(height: 28),
            ],

            // 🔹 4) Tendência Financeira
            if (sec.canView(AppScreen.dashTendenciaFinanceira)) ...[
              _sectionTitle('📊 Tendência Financeira (últimos 6 meses)'),
              const SizedBox(height: 8),
              FinanceTrendChart(empresaId: empresaId, parceiroId: parceiroId),
              const SizedBox(height: 28),
            ],

            // 🔹 5) Distribuição por Clientes
            if (sec.canView(AppScreen.dashDistribuicaoClientes)) ...[
              _sectionTitle('👥 Distribuição por Clientes'),
              const SizedBox(height: 8),
              ClientDistributionPie(empresaId: empresaId, parceiroId: parceiroId),
              const SizedBox(height: 28),
            ],

            // 🔹 6) Comparativo Trimestral
            if (sec.canView(AppScreen.dashComparativoTrimestral)) ...[
              _sectionTitle('📆 Comparativo Trimestral'),
              const SizedBox(height: 8),
              QuarterlyBars(empresaId: empresaId, parceiroId: parceiroId),
              const SizedBox(height: 28),
            ],

            // 🔹 7) Alertas e Vencimentos
            if (sec.canView(AppScreen.dashAlertas)) ...[
              _sectionTitle('⚠️ Alertas de Vencimentos'),
              const SizedBox(height: 8),
              AlertsPanel(empresaId: empresaId, parceiroId: parceiroId),
              const SizedBox(height: 28),
            ],

            // 🔹 8) Chamados (cards + pizza)
            if (sec.canView(AppScreen.dashChamadosCards)) ...[
              _sectionTitle('📞 Chamados'),
              const SizedBox(height: 8),
              _ticketsCards(),
              const SizedBox(height: 16),
            ],
            if (sec.canView(AppScreen.dashChamadosPie)) ...[
              _ticketsPie(),
              const SizedBox(height: 28),
            ],

            // 🔹 9) Tendência de Chamados
            if (sec.canView(AppScreen.dashTendenciaChamados)) ...[
              _sectionTitle('📈 Tendência de Chamados (últimos meses)'),
              const SizedBox(height: 8),
              TicketsTrendChart(
                empresaId: empresaId,
                parceiroId: parceiroId,
                months: 6,
              ),
              const SizedBox(height: 28),
            ],

            // 🔹 10) Chats linha
            if (sec.canView(AppScreen.dashChatsLinha)) ...[
              _sectionTitle('💬 Chats (últimos 7 dias)'),
              const SizedBox(height: 8),
              _chatsLine(),
              const SizedBox(height: 28),
            ],

            // 🔹 11) Chat diário
            if (sec.canView(AppScreen.dashChatsDiario)) ...[
              _sectionTitle('📅 Atividade de Chats Diária'),
              const SizedBox(height: 8),
              ChatsDailyChart(
                empresaId: empresaId,
                parceiroId: parceiroId,
                days: 7,
              ),
              const SizedBox(height: 28),
            ],

            // 🔹 12) Saldo por Conta Bancária
            if (sec.canView(AppScreen.dashSaldoContas)) ...[
              _sectionTitle('🏦 Saldo por Conta Bancária'),
              const SizedBox(height: 8),
              ContasBalancesChart(
                empresaId: empresaId,
                parceiroId: parceiroId,
              ),
              const SizedBox(height: 28),
            ],

            // 🔹 13) Evolução de Saldos
            if (sec.canView(AppScreen.dashEvolucaoSaldos)) ...[
              _sectionTitle('📈 Evolução de Saldos (últimos 30 dias)'),
              const SizedBox(height: 8),
              const ContaEvolucaoChart(contaId: 1),
              const SizedBox(height: 28),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: GridColors.textSecondary,
      ),
    );
  }

  Widget _infoCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        height: 90,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: GridColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _financeCards() {
    final last = finance.isNotEmpty ? finance.last : FinancePoint('—', 0, 0);
    final saldo = last.receivable - last.payable;
    return Row(
      children: [
        _infoCard('A Receber', 'R\$ ${last.receivable.toStringAsFixed(2)}',
            Colors.green),
        _infoCard(
            'A Pagar', 'R\$ ${last.payable.toStringAsFixed(2)}', Colors.red),
        _infoCard(
            'Saldo', 'R\$ ${saldo.toStringAsFixed(2)}', GridColors.primary),
      ],
    );
  }

  Widget _ticketsCards() {
    final t = tickets!;
    return Row(
      children: [
        _infoCard('Abertos', t.open.toString(), Colors.orange),
        _infoCard('Em Andamento', t.inProgress.toString(), Colors.blue),
        _infoCard('Fechados', t.closed.toString(), Colors.green),
      ],
    );
  }

  Widget _ticketsPie() {
    final t = tickets!;
    final total = (t.open + t.inProgress + t.closed).clamp(1, 1 << 31);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      height: 240,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              value: t.open / total,
              color: Colors.orange,
              title: 'Abertos',
            ),
            PieChartSectionData(
              value: t.inProgress / total,
              color: Colors.blue,
              title: 'Andamento',
            ),
            PieChartSectionData(
              value: t.closed / total,
              color: Colors.green,
              title: 'Fechados',
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatsLine() {
    final points = chats;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      height: 230,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final d = points[i].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${d.day}/${d.month}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: GridColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 28),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: GridColors.secondary,
              spots: [
                for (int i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].openChats.toDouble()),
              ],
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    GridColors.secondary.withOpacity(0.4),
                    Colors.transparent
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
