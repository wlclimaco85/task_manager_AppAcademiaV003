// lib/ui/screens/finance_fluxo_diario_chart.dart
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/grid_colors.dart';

final token =
    AuthUtility.userInfo?.token; // Assuming userInfo.token is available

class FinanceFluxoPoint {
  final DateTime day;
  final double payable; // vermelho
  final double receivable; // verde

  FinanceFluxoPoint(this.day, this.payable, this.receivable);

  factory FinanceFluxoPoint.fromJson(Map<String, dynamic> j) {
    return FinanceFluxoPoint(
      DateTime.parse(j['day']),
      (j['payableTotal'] as num?)?.toDouble() ?? 0.0,
      (j['receivableTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class FinanceFluxoDiarioChart extends StatefulWidget {
  final int empresaId;
  final int? parceiroId;
  final int daysBack;
  final int daysForward;

  const FinanceFluxoDiarioChart({
    super.key,
    required this.empresaId,
    this.parceiroId,
    this.daysBack = 10,
    this.daysForward = 30,
  });

  @override
  State<FinanceFluxoDiarioChart> createState() =>
      _FinanceFluxoDiarioChartState();
}

class _FinanceFluxoDiarioChartState extends State<FinanceFluxoDiarioChart> {
  List<FinanceFluxoPoint> data = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uri =
          Uri.parse(ApiLinks.financeFluxoDiario).replace(queryParameters: {
        'empresaId': widget.empresaId.toString(),
        if (widget.parceiroId != null)
          'parceiroId': widget.parceiroId.toString(),
        'daysBack': widget.daysBack.toString(),
        'daysForward': widget.daysForward.toString(),
      });

      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json', // Important: Add Accept header
        },
      );
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final arr = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();

      setState(() {
        data = arr.map((e) => FinanceFluxoPoint.fromJson(e)).toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  String _ddMM(DateTime d) => '${d.day}/${d.month}';

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
          child: Text(
            error!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
        ),
      );
    }
    if (data.isEmpty) {
      return const SizedBox(
        height: 260,
        child: Center(child: Text('Sem dados de fluxo diário (–10 / +30).')),
      );
    }

    // grupos de barras (duas por dia: receivable verde, payable vermelho)
    final groups = <BarChartGroupData>[];
    for (int i = 0; i < data.length; i++) {
      final p = data[i];
      groups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 6,
          barRods: [
            BarChartRodData(toY: p.receivable, color: Colors.green, width: 8),
            BarChartRodData(toY: p.payable, color: Colors.red, width: 8),
          ],
        ),
      );
    }

    return Container(
      height: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _ddMM(data[i].day),
                      style: const TextStyle(
                          fontSize: 10, color: GridColors.textSecondary),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: groups,
        ),
      ),
    );
  }
}
