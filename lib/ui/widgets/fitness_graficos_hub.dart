import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/fitness/graficos_fitness_dados.dart';

class FitnessGraficosHub extends StatefulWidget {
  final Future<GraficosFitnessDados>? dados;
  const FitnessGraficosHub({super.key, this.dados});
  @override
  State<FitnessGraficosHub> createState() => _FitnessGraficosHubState();
}

class _FitnessGraficosHubState extends State<FitnessGraficosHub> {
  late final _dados = widget.dados ?? GraficosFitnessDados.carregar();
  int _dias = 30;
  String _medida = 'Peso';
  String? _ficha;
  @override
  Widget build(BuildContext context) => FutureBuilder<GraficosFitnessDados>(
      future: _dados,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Text(
              'Não foi possível carregar os gráficos. Tente atualizar a tela.');
        if (!snapshot.hasData)
          return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Carregando gráficos dos registros reais...'));
        final dados = snapshot.data!;
        final ficha = _ficha ??
            (dados.fichas.isEmpty ? null : dados.fichas.keys.first);
        final series = dados.series(
            dias: _dias,
            agora: DateTime.now(),
            medida: _medida,
            treinoId: ficha);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Minha evolução',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const Text(
              'Registros da sua conta • disponíveis também pelo cache offline'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final dias in [7, 30, 90])
              ChoiceChip(
                  label: Text('$dias dias'),
                  selected: _dias == dias,
                  onSelected: (_) => setState(() => _dias = dias))
          ]),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _medida,
            isExpanded: true,
            decoration:
                const InputDecoration(labelText: 'Peso ou medida corporal'),
            items: [
              for (final m in dados.medidas)
                DropdownMenuItem(value: m, child: Text(m))
            ],
            onChanged: (v) => setState(() => _medida = v!),
          ),
          if (dados.fichas.isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 20),
                child: DropdownButtonFormField<String>(
                    initialValue: ficha,
                    isExpanded: true,
                    decoration: const InputDecoration(
                        labelText: 'Ficha de treino para peso e frequência'),
                    items: [
                      for (final e in dados.fichas.entries)
                        DropdownMenuItem(
                            value: e.key,
                            child:
                                Text(e.value, overflow: TextOverflow.ellipsis))
                    ],
                    onChanged: (v) => setState(() => _ficha = v))),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final largura = constraints.maxWidth >= 900
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(spacing: 12, runSpacing: 12, children: [
              for (final serie in series)
                SizedBox(width: largura, child: _GraficoReal(serie: serie))
            ]);
          }),
        ]);
      });
}

class _GraficoReal extends StatelessWidget {
  final SerieFitness serie;
  const _GraficoReal({required this.serie});
  @override
  Widget build(BuildContext context) {
    final pontos = serie.pontos;
    String data(double x) {
      final d = DateTime.fromMillisecondsSinceEpoch(x.round());
      return '${d.day}/${d.month}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: GridColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GridColors.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(serie.titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(serie.unidade,
            style: const TextStyle(color: GridColors.textSecondary)),
        const SizedBox(height: 12),
        if (pontos.isEmpty)
          const SizedBox(
              height: 100,
              child: Center(child: Text('Sem registros neste período.')))
        else
          SizedBox(
              height: 180,
              child: LineChart(LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          getTitlesWidget: (v, meta) => Text(
                              v.toStringAsFixed(v.abs() >= 10 ? 0 : 1),
                              style: const TextStyle(fontSize: 10)))),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: (pontos.length <= 1
                                  ? 86400000
                                  : (pontos.last.data.millisecondsSinceEpoch -
                                              pontos.first.data
                                                  .millisecondsSinceEpoch)
                                          .abs() /
                                      3)
                              .clamp(86400000, double.infinity)
                              .toDouble(),
                          getTitlesWidget: (v, meta) => Text(data(v),
                              style: const TextStyle(fontSize: 10)))),
                ),
                lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (items) => [
                              for (final p in items)
                                LineTooltipItem(
                                    '${data(p.x)}\n${p.y.toStringAsFixed(1)} ${serie.unidade}',
                                    const TextStyle(color: Colors.white))
                            ])),
                lineBarsData: [
                  LineChartBarData(
                      isCurved: false,
                      color: GridColors.primary,
                      spots: [
                        for (final p in pontos)
                          FlSpot(
                              p.data.millisecondsSinceEpoch.toDouble(), p.valor)
                      ],
                      dotData: FlDotData(show: pontos.length < 35),
                      belowBarData: BarAreaData(show: false))
                ],
              ))),
      ]),
    );
  }
}
