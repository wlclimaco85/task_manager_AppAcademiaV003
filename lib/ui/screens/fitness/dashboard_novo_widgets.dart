import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/services/dashboard_layout_preferencia.dart';

/// Paleta do layout novo de dashboard (referencia: vermelho, preto e cinza sobre fundo claro).
class DashboardNovoPaleta {
  DashboardNovoPaleta._();

  static const vermelho = Color(0xFFC8102E);
  static const preto = Color(0xFF151515);
  static const cinza = Color(0xFF7D8590);
  static const cinzaClaro = Color(0xFFD1D5DB);
  static const fundo = Color(0xFFF3F4F6);
  static const branco = Colors.white;
}

/// Cartao branco com titulo, usado em cada bloco do dashboard.
class DashboardNovoCard extends StatelessWidget {
  const DashboardNovoCard({super.key, required this.titulo, required this.child, this.trailing});

  final String titulo;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DashboardNovoPaleta.branco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardNovoPaleta.cinzaClaro.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(titulo,
                    style: const TextStyle(
                        color: DashboardNovoPaleta.preto, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Indicador grande (rotulo pequeno + valor em destaque) na faixa de KPIs.
class DashboardKpi {
  const DashboardKpi({required this.rotulo, required this.valor, this.destaque = false});

  final String rotulo;
  final String valor;
  final bool destaque;
}

/// Faixa horizontal de KPIs; rola na horizontal para caber em telas estreitas.
class DashboardNovoKpis extends StatelessWidget {
  const DashboardNovoKpis({super.key, required this.kpis});

  final List<DashboardKpi> kpis;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final k in kpis)
            Container(
              width: 140,
              margin: const EdgeInsets.only(right: 10, bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: k.destaque ? DashboardNovoPaleta.vermelho : DashboardNovoPaleta.branco,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: DashboardNovoPaleta.cinzaClaro.withValues(alpha: 0.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(k.rotulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: k.destaque ? Colors.white70 : DashboardNovoPaleta.cinza, fontSize: 11)),
                  const SizedBox(height: 6),
                  Text(k.valor,
                      style: TextStyle(
                          color: k.destaque ? Colors.white : DashboardNovoPaleta.preto,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Barras verticais simples. Cada valor vira uma barra; rotulos aparecem so no X inicial e final.
class DashboardNovoBarras extends StatelessWidget {
  const DashboardNovoBarras({super.key, required this.valores, this.rotulos, this.altura = 160});

  final List<double> valores;
  final List<String>? rotulos;
  final double altura;

  @override
  Widget build(BuildContext context) {
    if (valores.isEmpty) {
      return const Text('Sem dados no período.',
          style: TextStyle(color: DashboardNovoPaleta.cinza, fontSize: 12));
    }
    final maximo = valores.fold<double>(0, (a, b) => b > a ? b : a);
    final teto = maximo <= 0 ? 1.0 : maximo * 1.15;
    return Column(
      children: [
        SizedBox(
          height: altura,
          child: BarChart(
            BarChartData(
              maxY: teto,
              alignment: BarChartAlignment.spaceAround,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              barGroups: [
                for (var i = 0; i < valores.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: valores[i],
                      width: valores.length > 12 ? 6 : 14,
                      borderRadius: BorderRadius.circular(3),
                      color: valores[i] >= maximo && maximo > 0
                          ? DashboardNovoPaleta.vermelho
                          : DashboardNovoPaleta.preto,
                    ),
                  ]),
              ],
            ),
          ),
        ),
        if (rotulos != null && rotulos!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(rotulos!.first, style: const TextStyle(color: DashboardNovoPaleta.cinza, fontSize: 11)),
              Text(rotulos!.last, style: const TextStyle(color: DashboardNovoPaleta.cinza, fontSize: 11)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Rosca com o percentual principal no centro e legenda ao lado.
class DashboardNovoRosca extends StatelessWidget {
  const DashboardNovoRosca({super.key, required this.parte, required this.total, required this.rotuloParte, required this.rotuloTotal});

  final int parte;
  final int total;
  final String rotuloParte;
  final String rotuloTotal;

  @override
  Widget build(BuildContext context) {
    final pct = total <= 0 ? 0.0 : parte * 100 / total;
    final resto = (total - parte).clamp(0, total);
    return Row(
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(PieChartData(
                centerSpaceRadius: 42,
                sectionsSpace: 2,
                sections: [
                  PieChartSectionData(
                      value: parte.toDouble() == 0 && total == 0 ? 1 : parte.toDouble(),
                      color: DashboardNovoPaleta.vermelho,
                      radius: 18,
                      title: ''),
                  PieChartSectionData(
                      value: resto.toDouble() == 0 && total == 0 ? 1 : resto.toDouble(),
                      color: DashboardNovoPaleta.preto,
                      radius: 18,
                      title: ''),
                ],
              )),
              Text('${pct.toStringAsFixed(0)}%',
                  style: const TextStyle(
                      color: DashboardNovoPaleta.preto, fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legenda(DashboardNovoPaleta.vermelho, '$parte $rotuloParte'),
              const SizedBox(height: 6),
              _legenda(DashboardNovoPaleta.preto, '${total - parte} sem $rotuloParte'),
              const SizedBox(height: 10),
              Text('Total: $total $rotuloTotal',
                  style: const TextStyle(color: DashboardNovoPaleta.cinza, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legenda(Color cor, String texto) => Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 12, color: DashboardNovoPaleta.preto))),
        ],
      );
}

/// Linha de lista simples dentro de um cartao (nome + detalhe a direita).
class DashboardNovoLinha extends StatelessWidget {
  const DashboardNovoLinha({super.key, required this.titulo, this.detalhe, this.subtitulo});

  final String titulo;
  final String? detalhe;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: DashboardNovoPaleta.preto, fontSize: 13, fontWeight: FontWeight.w600)),
                if (subtitulo != null)
                  Text(subtitulo!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: DashboardNovoPaleta.cinza, fontSize: 11)),
              ],
            ),
          ),
          if (detalhe != null)
            Text(detalhe!, style: const TextStyle(color: DashboardNovoPaleta.vermelho, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Botao da barra superior para escolher o layout do dashboard (novo ou clássico).
class DashboardLayoutBotao extends StatelessWidget {
  const DashboardLayoutBotao({super.key, required this.atual, required this.onMudou});

  final DashboardLayout atual;
  final ValueChanged<DashboardLayout> onMudou;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DashboardLayout>(
      tooltip: 'Escolher layout do dashboard',
      icon: const Icon(Icons.dashboard_customize_outlined),
      initialValue: atual,
      onSelected: onMudou,
      itemBuilder: (_) => [
        for (final layout in DashboardLayout.values)
          PopupMenuItem(
            value: layout,
            child: Row(
              children: [
                Icon(layout == atual ? Icons.radio_button_checked : Icons.radio_button_off, size: 18),
                const SizedBox(width: 8),
                Text(layout.rotulo),
              ],
            ),
          ),
      ],
    );
  }
}

/// Mensagem quando um cartao nao tem dados.
class DashboardNovoVazio extends StatelessWidget {
  const DashboardNovoVazio(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => Text(texto,
      style: const TextStyle(color: DashboardNovoPaleta.cinza, fontSize: 12));
}
