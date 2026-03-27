// lib/dashboard/dashboard_page.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/conta_model.dart';
import 'package:task_manager_flutter/data/services/conta_caller.dart';
import 'package:task_manager_flutter/data/utils/grid_colors.dart';

final token =
    AuthUtility.userInfo?.token; // Assuming userInfo.token is available

class ContasBalancesChart extends StatefulWidget {
  final int empresaId;
  final int? parceiroId;
  const ContasBalancesChart(
      {super.key, required this.empresaId, this.parceiroId});

  @override
  State<ContasBalancesChart> createState() => _ContasBalancesChartState();
}

class _ContasBalancesChartState extends State<ContasBalancesChart> {
  List<ContaBancariaModel> contas = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      contas = await ContaApi().listarSaldos(
          empresaId: widget.empresaId, parceiroId: widget.parceiroId);
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
    if (contas.isEmpty) {
      return const SizedBox(
          height: 260, child: Center(child: Text('Sem contas bancárias.')));
    }

    final total = contas.fold<double>(0, (p, c) => p + c.saldo.abs());
    final sections = <PieChartSectionData>[];
    for (final c in contas) {
      final v = total == 0 ? 0.0 : (c.saldo.abs() / total) * 100;
      sections.add(PieChartSectionData(
        value: v,
        title: c.saldo.toStringAsFixed(0),
        color: c.saldo >= 0 ? Colors.green : Colors.red,
        radius: 60,
      ));
    }

    return Container(
      height: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Text('Saldos por Conta',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
              child: PieChart(
                  PieChartData(sections: sections, centerSpaceRadius: 36))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: contas
                .map((c) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: c.saldo >= 0 ? Colors.green : Colors.red,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('${c.nome}  (R\$ ${c.saldo.toStringAsFixed(2)})',
                            style: const TextStyle(
                                fontSize: 12, color: GridColors.textSecondary)),
                      ],
                    ))
                .toList(),
          )
        ],
      ),
    );
  }
}
