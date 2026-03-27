// lib/dashboard/dashboard_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/utils/grid_colors.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';

final token =
    AuthUtility.userInfo?.token; // Assuming userInfo.token is available

class AlertItem {
  final String tipo; // PAGAR/RECEBER
  final int id;
  final String descricao;
  final double valor;
  final DateTime dataVencimento;
  AlertItem(
      this.tipo, this.id, this.descricao, this.valor, this.dataVencimento);
  factory AlertItem.fromJson(Map<String, dynamic> j) => AlertItem(
        j['tipo'],
        j['id'],
        j['descricao'],
        (j['valor'] as num).toDouble(),
        DateTime.parse(j['dataVencimento']),
      );
}

class AlertsPanel extends StatefulWidget {
  final int empresaId;
  final int? parceiroId;
  final int daysSoon;
  const AlertsPanel(
      {super.key, required this.empresaId, this.parceiroId, this.daysSoon = 5});

  @override
  State<AlertsPanel> createState() => _AlertsPanelState();
}

class _AlertsPanelState extends State<AlertsPanel> {
  List<AlertItem> overdue = [];
  List<AlertItem> dueSoon = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final overdueUri = Uri.parse(ApiLinks.overdue).replace(queryParameters: {
        'empresaId': widget.empresaId.toString(),
        if (widget.parceiroId != null)
          'parceiroId': widget.parceiroId.toString(),
      });
      final dueUri = Uri.parse(ApiLinks.dueSoon).replace(queryParameters: {
        'empresaId': widget.empresaId.toString(),
        if (widget.parceiroId != null)
          'parceiroId': widget.parceiroId.toString(),
        'days': widget.daysSoon.toString(),
      });
      final r1 = await http.get(
        overdueUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json', // Important: Add Accept header
        },
      );
      final r2 = await http.get(
        dueUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json', // Important: Add Accept header
        },
      );
      if (r1.statusCode != 200 || r2.statusCode != 200) {
        throw Exception('HTTP ${r1.statusCode}/${r2.statusCode}');
      }
      setState(() {
        overdue = (jsonDecode(r1.body) as List)
            .map((e) => AlertItem.fromJson(e))
            .toList();
        dueSoon = (jsonDecode(r2.body) as List)
            .map((e) => AlertItem.fromJson(e))
            .toList();
        loading = false;
      });
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
          height: 180, child: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return SizedBox(
          height: 180,
          child: Center(
              child: Text(error!, style: const TextStyle(color: Colors.red))));
    }

    Widget list(String title, List<AlertItem> items, Color color) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: GridColors.textSecondary)),
            const SizedBox(height: 8),
            for (final a in items.take(5))
              ListTile(
                dense: true,
                leading: Icon(Icons.warning, color: color),
                title: Text(a.descricao, style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                    'Venc.: ${a.dataVencimento.day}/${a.dataVencimento.month} — R\$ ${a.valor.toStringAsFixed(2)}'),
                trailing: Text(a.tipo, style: TextStyle(color: color)),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        list('Atrasados', overdue, Colors.red),
        const SizedBox(height: 12),
        list('Vencendo em ${widget.daysSoon} dias', dueSoon, Colors.orange),
      ],
    );
  }
}
