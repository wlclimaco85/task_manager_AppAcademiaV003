// lib/dashboard/dashboard_page.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/conta_model.dart';
import 'package:task_manager_flutter/data/services/conta_caller.dart';
import 'package:task_manager_flutter/data/utils/grid_colors.dart';

final token =
    AuthUtility.userInfo?.token; // Assuming userInfo.token is available

class ContaEvolucaoChart extends StatefulWidget {
  final int contaId;
  final int days;
  const ContaEvolucaoChart({super.key, required this.contaId, this.days = 30});

  @override
  State<ContaEvolucaoChart> createState() => _ContaEvolucaoChartState();
}

class _ContaEvolucaoChartState extends State<ContaEvolucaoChart> {
  List<ContaSaldoDia> serie = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      serie =
          await ContaApi().evolucao(contaId: widget.contaId, days: widget.days);
      setState(() => loading = false);
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
          height: 260, child: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return SizedBox(
          height: 260,
          child: Center(
              child: Text(error!,
                  style: const TextStyle(color: Colors.redAccent))));
    }
    if (serie.isEmpty) {
      return const SizedBox(
          height: 260, child: Center(child: Text('Sem dados de evolução.')));
    }

    final spots = <FlSpot>[
      for (int i = 0; i < serie.length; i++)
        FlSpot(i.toDouble(), serie[i].saldo)
    ];

    return Container(
      height: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: LineChart(LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= serie.length) return const SizedBox.shrink();
                final d = serie[i].day;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${d.day}/${d.month}',
                      style: const TextStyle(
                          fontSize: 10, color: GridColors.textSecondary)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: GridColors.secondary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            spots: spots,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(colors: [
                GridColors.secondary.withOpacity(0.35),
                Colors.transparent
              ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            ),
          ),
        ],
        minY: 0,
      )),
    );
  }
}
