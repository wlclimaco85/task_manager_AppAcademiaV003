import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/fitness/personal_gestao_model.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';
import 'package:task_manager_flutter/data/services/personal_gestao_offline_repository.dart';

class PersonalDesempenhoDialog extends StatefulWidget {
  final PersonalAlunoGestaoModel aluno;

  const PersonalDesempenhoDialog({super.key, required this.aluno});

  @override
  State<PersonalDesempenhoDialog> createState() =>
      _PersonalDesempenhoDialogState();
}

class _PersonalDesempenhoDialogState extends State<PersonalDesempenhoDialog> {
  late final Future<_DesempenhoDados> _dados = _carregar();

  Future<_DesempenhoDados> _carregar() async {
    final resposta = await PersonalGestaoOfflineRepository()
        .getDesempenhoAluno(widget.aluno.id);
    return _DesempenhoDados.fromMap(resposta);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: GridColors.dialogBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 760),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: GridColors.primarySubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.insights, color: GridColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Desempenho de ${widget.aluno.nome}',
                            style: TextStyle(
                                color: GridColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        Text('Peso, frequência e evolução de carga',
                            style: TextStyle(
                                color: GridColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: GridColors.textPrimary),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: GridColors.divider),
            Expanded(
              child: FutureBuilder<_DesempenhoDados>(
                future: _dados,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Center(
                        child: CircularProgressIndicator(
                            color: GridColors.primary));
                  }
                  if (snapshot.hasError) {
                    return _mensagem(Icons.cloud_off_outlined,
                        'Não foi possível carregar o desempenho agora.');
                  }
                  final dados = snapshot.data!;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _resumo(
                                'Variação de peso',
                                dados.variacaoPeso,
                                Icons.monitor_weight_outlined,
                                GridColors.primary),
                            _resumo(
                                'Média semanal',
                                dados.mediaSemanal,
                                Icons.calendar_month_outlined,
                                GridColors.secondaryDark),
                            _resumo('Evolução da carga', dados.variacaoCarga,
                                Icons.fitness_center, GridColors.info),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (dados.pesoPermitido)
                          _grafico(
                            titulo: 'Perda ou ganho de peso',
                            subtitulo: 'Histórico dos últimos 12 meses',
                            unidade: 'kg',
                            pontos: dados.pesos,
                            cor: GridColors.primary,
                          )
                        else
                          _bloqueado(),
                        const SizedBox(height: 14),
                        _grafico(
                          titulo: 'Frequência de treinos',
                          subtitulo: 'Treinos concluídos por semana',
                          unidade: 'treinos',
                          pontos: dados.frequencia,
                          cor: GridColors.secondaryDark,
                          inteiro: true,
                        ),
                        const SizedBox(height: 14),
                        _grafico(
                          titulo: 'Evolução de carga',
                          subtitulo:
                              'Maior carga registrada em cada treino concluído',
                          unidade: 'kg',
                          pontos: dados.cargas,
                          cor: GridColors.info,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumo(String titulo, String valor, IconData icone, Color cor) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GridColors.filterBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GridColors.divider),
      ),
      child: Row(children: [
        Icon(icone, color: cor, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(valor,
                style: TextStyle(
                    color: GridColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            Text(titulo,
                style:
                    TextStyle(color: GridColors.textSecondary, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  Widget _grafico({
    required String titulo,
    required String subtitulo,
    required String unidade,
    required List<_Ponto> pontos,
    required Color cor,
    bool inteiro = false,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GridColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo,
            style: TextStyle(
                color: GridColors.textPrimary, fontWeight: FontWeight.w800)),
        Text(subtitulo,
            style: TextStyle(color: GridColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 14),
        if (pontos.isEmpty)
          SizedBox(
              height: 120,
              child: _mensagem(Icons.show_chart,
                  'Ainda não há registros suficientes para este gráfico.'))
        else
          SizedBox(
            height: 190,
            child: LineChart(LineChartData(
              minX: 0,
              maxX: math.max(1, pontos.length - 1).toDouble(),
              minY: _minimo(pontos),
              maxY: _maximo(pontos),
              gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: GridColors.divider, strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (value, _) => Text(
                      inteiro
                          ? value.round().toString()
                          : value.toStringAsFixed(1),
                      style: TextStyle(
                          color: GridColors.textSecondary, fontSize: 9),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval:
                        math.max(1, (pontos.length / 4).ceil()).toDouble(),
                    getTitlesWidget: (value, _) {
                      final i = value.round();
                      if (i < 0 || i >= pontos.length) return const SizedBox();
                      final d = pontos[i].data;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('${d.day}/${d.month}',
                            style: TextStyle(
                                color: GridColors.textSecondary, fontSize: 9)),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => GridColors.filterBackground,
                  getTooltipItems: (spots) => spots
                      .map((spot) => LineTooltipItem(
                          '${pontos[spot.x.round()].rotulo}\n${spot.y.toStringAsFixed(inteiro ? 0 : 1)} $unidade',
                          TextStyle(
                              color: GridColors.textPrimary,
                              fontWeight: FontWeight.w700)))
                      .toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < pontos.length; i++)
                      FlSpot(i.toDouble(), pontos[i].valor)
                  ],
                  isCurved: pontos.length > 2,
                  color: cor,
                  barWidth: 3,
                  dotData: FlDotData(show: pontos.length <= 14),
                  belowBarData: BarAreaData(
                      show: true, color: cor.withValues(alpha: 0.10)),
                ),
              ],
            )),
          ),
      ]),
    );
  }

  Widget _bloqueado() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GridColors.filterBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GridColors.divider),
        ),
        child: Row(children: [
          Icon(Icons.lock_outline, color: GridColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'O aluno ainda não liberou “Metas e evolução do corpo”. O gráfico de peso respeita essa permissão.',
              style: TextStyle(color: GridColors.textSecondary),
            ),
          ),
        ]),
      );

  Widget _mensagem(IconData icone, String texto) => Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icone, color: GridColors.textSecondary),
            const SizedBox(height: 8),
            Text(texto,
                textAlign: TextAlign.center,
                style: TextStyle(color: GridColors.textSecondary)),
          ]),
        ),
      );

  double _minimo(List<_Ponto> pontos) {
    final menor = pontos.map((p) => p.valor).reduce(math.min);
    if (menor == 0) return 0;
    return math.max(0, menor - math.max(1, menor.abs() * .08));
  }

  double _maximo(List<_Ponto> pontos) {
    final maior = pontos.map((p) => p.valor).reduce(math.max);
    final minimo = _minimo(pontos);
    return math.max(minimo + 1, maior + math.max(1, maior.abs() * .08));
  }
}

class _Ponto {
  final DateTime data;
  final double valor;
  final String rotulo;
  const _Ponto(this.data, this.valor, this.rotulo);
}

class _DesempenhoDados {
  final bool pesoPermitido;
  final List<_Ponto> pesos;
  final List<_Ponto> frequencia;
  final List<_Ponto> cargas;

  const _DesempenhoDados({
    required this.pesoPermitido,
    required this.pesos,
    required this.frequencia,
    required this.cargas,
  });

  factory _DesempenhoDados.fromMap(Map<String, dynamic> map) {
    final pesosPorDia = <DateTime, _Ponto>{};
    for (final bruto in map['pesos'] as List? ?? const []) {
      if (bruto is! Map) continue;
      final data = DateTime.tryParse(bruto['data']?.toString() ?? '');
      final valor = _numero(bruto['peso']);
      if (data != null && valor != null && valor > 0) {
        final dia = DateTime(data.year, data.month, data.day);
        pesosPorDia[dia] = _Ponto(dia, valor, _data(dia));
      }
    }
    final pesos = pesosPorDia.values.toList()
      ..sort((a, b) => a.data.compareTo(b.data));

    final sessoes = <SessaoTreinoRegistroModel>[];
    for (final bruto in map['sessoes'] as List? ?? const []) {
      if (bruto is Map) {
        final sessao =
            SessaoTreinoRegistroModel.fromMap(Map<String, dynamic>.from(bruto));
        if (sessao.dataHoraFim.isNotEmpty) {
          sessoes.add(sessao);
        }
      }
    }
    sessoes.sort((a, b) => a.dataHoraInicio.compareTo(b.dataHoraInicio));

    final hoje = DateTime.now();
    final inicioSemana = DateTime(hoje.year, hoje.month, hoje.day)
        .subtract(Duration(days: hoje.weekday - 1));
    final frequencia = <_Ponto>[];
    for (var semana = 7; semana >= 0; semana--) {
      final inicio = inicioSemana.subtract(Duration(days: semana * 7));
      final fim = inicio.add(const Duration(days: 7));
      final total = sessoes.where((s) {
        final data = DateTime.tryParse(s.dataHoraInicio);
        return data != null && !data.isBefore(inicio) && data.isBefore(fim);
      }).length;
      frequencia.add(_Ponto(inicio, total.toDouble(), _data(inicio)));
    }

    final cargas = <_Ponto>[];
    for (final sessao in sessoes.reversed.take(12).toList().reversed) {
      final data = DateTime.tryParse(sessao.dataHoraInicio);
      if (data == null) continue;
      var maiorCarga = 0.0;
      for (final exercicio in sessao.exerciciosExecutados) {
        for (final serie in exercicio.series.where((s) => s.concluida)) {
          maiorCarga = math.max(maiorCarga, serie.cargaRealKg);
        }
      }
      if (maiorCarga > 0) {
        cargas.add(_Ponto(data, maiorCarga,
            '${_data(data)} • ${sessao.divisaoNome.isEmpty ? 'Treino' : sessao.divisaoNome}'));
      }
    }
    return _DesempenhoDados(
      pesoPermitido: map['pesoPermitido'] == true,
      pesos: pesos,
      frequencia: frequencia,
      cargas: cargas,
    );
  }

  String get variacaoPeso {
    if (!pesoPermitido) return 'Sem permissão';
    if (pesos.length < 2) {
      return pesos.isEmpty
          ? 'Sem registros'
          : '${pesos.last.valor.toStringAsFixed(1)} kg';
    }
    final diferenca = pesos.last.valor - pesos.first.valor;
    return '${diferenca > 0 ? '+' : ''}${diferenca.toStringAsFixed(1)} kg';
  }

  String get mediaSemanal {
    final media = frequencia.isEmpty
        ? 0
        : frequencia.fold<double>(0, (soma, p) => soma + p.valor) /
            frequencia.length;
    return '${media.toStringAsFixed(1)} treinos';
  }

  String get variacaoCarga {
    if (cargas.length < 2) {
      return cargas.isEmpty
          ? 'Sem registros'
          : '${cargas.last.valor.toStringAsFixed(1)} kg';
    }
    final diferenca = cargas.last.valor - cargas.first.valor;
    return '${diferenca > 0 ? '+' : ''}${diferenca.toStringAsFixed(1)} kg';
  }

  static double? _numero(Object? valor) => valor is num
      ? valor.toDouble()
      : double.tryParse(valor?.toString().replaceAll(',', '.') ?? '');

  static String _data(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
}
