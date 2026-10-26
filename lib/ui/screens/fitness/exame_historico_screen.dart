import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/services/exame_laudo_service.dart';

/// Evolucao de cada item do laudo ao longo das datas.
/// Cor do ponto: vermelho acima da referencia, amarelo abaixo, verde dentro.
class ExameHistoricoScreen extends StatefulWidget {
  const ExameHistoricoScreen({super.key});

  @override
  State<ExameHistoricoScreen> createState() => _ExameHistoricoScreenState();
}

class _ExameHistoricoScreenState extends State<ExameHistoricoScreen> {
  late Future<List<Map<String, dynamic>>> _futuro;
  // Grupos escolhidos nos filtros (um ou varios). Vazio = mostra todos.
  final Set<String> _gruposSelecionados = {};
  // Status da ultima medicao (verde, amarelo, vermelho). Vazio = mostra todos.
  final Set<String> _statusSelecionados = {};

  // Rotulos do filtro: Normal = verde (dentro), Atencao = amarelo (abaixo), Cuidado = vermelho (acima).
  static const _opcoesStatus = [
    (status: 'verde', rotulo: 'Normal'),
    (status: 'amarelo', rotulo: 'Atenção'),
    (status: 'vermelho', rotulo: 'Cuidado'),
  ];

  @override
  void initState() {
    super.initState();
    _futuro = ExameLaudoService().series();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evolução dos exames')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Não foi possível carregar o histórico agora. ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final series = snapshot.data ?? const [];
          if (series.isEmpty) {
            return const Center(
              child: Text('Nenhum exame com itens ainda. Envie um laudo PDF para ver a evolução.'),
            );
          }
          final grupos = {for (final s in series) (s['grupo'] ?? 'Outros').toString()}.toList()..sort();
          final visiveis = series.where((s) {
            final grupoOk = _gruposSelecionados.isEmpty ||
                _gruposSelecionados.contains((s['grupo'] ?? 'Outros').toString());
            final statusOk = _statusSelecionados.isEmpty ||
                _statusSelecionados.contains(statusDoUltimo(s));
            return grupoOk && statusOk;
          }).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text('Todos (${series.length})'),
                    selected: _gruposSelecionados.isEmpty,
                    onSelected: (_) => setState(_gruposSelecionados.clear),
                  ),
                  for (final grupo in grupos)
                    FilterChip(
                      label: Text(grupo),
                      selected: _gruposSelecionados.contains(grupo),
                      onSelected: (selecionado) => setState(() {
                        if (selecionado) {
                          _gruposSelecionados.add(grupo);
                        } else {
                          _gruposSelecionados.remove(grupo);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final opcao in _opcoesStatus)
                    FilterChip(
                      avatar: CircleAvatar(
                        backgroundColor: corDoStatus(opcao.status),
                        radius: 6,
                      ),
                      label: Text(opcao.rotulo),
                      selected: _statusSelecionados.contains(opcao.status),
                      onSelected: (selecionado) => setState(() {
                        if (selecionado) {
                          _statusSelecionados.add(opcao.status);
                        } else {
                          _statusSelecionados.remove(opcao.status);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (visiveis.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nenhum item neste filtro.', textAlign: TextAlign.center),
                ),
              for (final serie in visiveis)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CartaoSerie(serie: serie),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Cor do ponto e do selo conforme o status (vermelho, amarelo, verde).
Color corDoStatus(String? status) {
  switch (status) {
    case 'vermelho':
      return Colors.red.shade400;
    case 'amarelo':
      return Colors.amber.shade600;
    case 'verde':
      return Colors.green.shade500;
    default:
      return Colors.grey.shade500;
  }
}

/// Status do ultimo ponto da serie; null quando o item nao tem referencia no laudo.
String? statusDoUltimo(Map<String, dynamic> serie) {
  final pontos = (serie['pontos'] as List? ?? const []).cast<Map<String, dynamic>>();
  return pontos.isEmpty ? null : pontos.last['status'] as String?;
}

/// Data ISO (2026-10-17) em dia/mes/ano (17/10/26), para nao confundir exames de anos diferentes.
String _dataCurta(String iso) {
  final partes = iso.split('-');
  if (partes.length < 3) return iso;
  return '${partes[2]}/${partes[1]}/${partes[0].substring(2)}';
}

class _CartaoSerie extends StatelessWidget {
  final Map<String, dynamic> serie;

  const _CartaoSerie({required this.serie});

  @override
  Widget build(BuildContext context) {
    final pontos = (serie['pontos'] as List).cast<Map<String, dynamic>>();
    final unidade = serie['unidade'] ?? '';
    final refMin = serie['refMin'];
    final refMax = serie['refMax'];
    final ultimo = pontos.isEmpty ? null : pontos.last;

    final spots = <FlSpot>[
      for (var i = 0; i < pontos.length; i++)
        FlSpot(i.toDouble(), (pontos[i]['valor'] as num).toDouble()),
    ];

    final ys = spots.map((s) => s.y).toList()
      ..addAll([
        if (refMin != null) (refMin as num).toDouble(),
        if (refMax != null) (refMax as num).toDouble(),
      ]);
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final folga = (maxY - minY) * 0.15 + 0.5;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(serie['nome'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                if (ultimo != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: corDoStatus(ultimo['status'] as String?),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${ultimo['valor']} $unidade',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${serie['grupo'] ?? 'Outros'} · '
                '${refMin != null && refMax != null ? 'Referência: $refMin a $refMax $unidade' : 'Sem referência no laudo'}'
                '${ultimo != null ? ' · Última: ${_dataCurta(ultimo['data'].toString())}' : ''}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 170,
              child: LineChart(
                LineChartData(
                  // Valores nunca negativos: a margem nao deve mostrar eixo abaixo de zero.
                  minY: minY >= 0 ? (minY - folga).clamp(0, double.infinity).toDouble() : minY - folga,
                  maxY: maxY + folga,
                  minX: -0.3,
                  maxX: (pontos.length - 1).toDouble() + 0.3,
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  rangeAnnotations: RangeAnnotations(
                    horizontalRangeAnnotations: [
                      if (refMin != null && refMax != null)
                        HorizontalRangeAnnotation(
                          y1: (refMin as num).toDouble(),
                          y2: (refMax as num).toDouble(),
                          color: Colors.green.withValues(alpha: 0.12),
                        ),
                    ],
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, meta) => Text(v.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (v, meta) {
                          final i = v.round();
                          if (i < 0 || i >= pontos.length || (v - i).abs() > 0.01) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(_dataCurta(pontos[i]['data'].toString()),
                                style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: Colors.grey,
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                          radius: 5,
                          color: corDoStatus(pontos[index]['status'] as String?),
                          strokeWidth: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
