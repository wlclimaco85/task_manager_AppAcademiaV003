import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/services/fitness_360_local_store.dart';

class ExerciciosScreen extends StatelessWidget {
  const ExerciciosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FitnessRecordScreen(
      type: 'atividade',
      title: 'Treinos',
      subtitle: 'Treino ao vivo, historico e resumo da sessao',
      icon: Icons.directions_run,
      primaryActionLabel: 'Registrar treino',
      emptyLabel: 'Nenhum treino registrado ainda.',
      defaultTitle: 'Treino funcional',
      defaultValue: '35 min',
      defaultNote: 'Forca, cardio ou mobilidade',
      liveWorkout: true,
      metricCards: [
        FitnessMetricSpec('Calorias', '286 kcal', Icons.local_fire_department),
        FitnessMetricSpec('Distancia', '5,6 km', Icons.route_outlined),
        FitnessMetricSpec('Pace', '8:42/km', Icons.speed_outlined),
        FitnessMetricSpec('Zona cardio', '24 min', Icons.monitor_heart),
      ],
      tips: [
        'Acompanhe intensidade e descanso antes de repetir carga.',
        'Finalize a sessao para salvar o resumo no historico.',
      ],
    );
  }
}

class AtividadeScreen extends StatelessWidget {
  const AtividadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FitnessRecordScreen(
      type: 'atividade',
      title: 'Atividade',
      subtitle: 'Passos, tempo ativo, calorias e tendencia semanal',
      icon: Icons.directions_walk,
      primaryActionLabel: 'Registrar atividade',
      emptyLabel: 'Nenhuma atividade registrada ainda.',
      defaultTitle: 'Caminhada',
      defaultValue: '8000 passos',
      defaultNote: 'Movimento diario do aluno',
      metricCards: [
        FitnessMetricSpec('Meta diaria', '78%', Icons.flag_outlined),
        FitnessMetricSpec('Calorias', '421 kcal', Icons.local_fire_department),
        FitnessMetricSpec('Tempo ativo', '64 min', Icons.timer_outlined),
        FitnessMetricSpec('Distancia', '5,6 km', Icons.route_outlined),
      ],
      tips: [
        'Use a meta de passos para criar constancia sem sobrecarga.',
        'Dias abaixo da meta entram nos insights semanais.',
      ],
    );
  }
}

class SonoScreen extends StatelessWidget {
  const SonoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FitnessRecordScreen(
      type: 'sono',
      title: 'Sono e Habitos',
      subtitle: 'Score, fases do sono, check-in e agenda de recuperacao',
      icon: Icons.bedtime_outlined,
      primaryActionLabel: 'Registrar sono',
      emptyLabel: 'Nenhum registro de sono ainda.',
      defaultTitle: 'Sono principal',
      defaultValue: '7h 30m',
      defaultNote: 'Qualidade, despertares e recuperacao',
      metricCards: [
        FitnessMetricSpec('Score', '84/100', Icons.stars_outlined),
        FitnessMetricSpec('Profundo', '2h 04m', Icons.nightlight_round),
        FitnessMetricSpec('Leve', '4h 32m', Icons.bed_outlined),
        FitnessMetricSpec('Acordado', '42 min', Icons.wb_twilight_outlined),
      ],
      extraCards: [
        _SleepPhasesCard(),
        _HabitReminderCard(),
      ],
      tips: [
        'Manter horario regular tende a melhorar o score.',
        'Evite treino pesado perto do horario de dormir.',
      ],
    );
  }
}

class BatimentosScreen extends StatelessWidget {
  const BatimentosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FitnessRecordScreen(
      type: 'batimento',
      title: 'Sinais Vitais',
      subtitle: 'Frequencia cardiaca, zonas, SpO2, stress e integracoes',
      icon: Icons.favorite,
      primaryActionLabel: 'Registrar manualmente',
      emptyLabel: 'Nenhuma leitura cardiaca registrada.',
      defaultTitle: 'Frequencia em repouso',
      defaultValue: '72 bpm',
      defaultNote: 'Importacao manual ate aprovacao do spike',
      metricCards: [
        FitnessMetricSpec('Repouso', '72 bpm', Icons.favorite_border),
        FitnessMetricSpec('Maximo', '148 bpm', Icons.north_east),
        FitnessMetricSpec('SpO2', '97%', Icons.air_outlined),
        FitnessMetricSpec('Stress', '31 baixo', Icons.psychology_outlined),
      ],
      extraCards: [
        _HeartZonesCard(),
        _IntegrationConsentCard(),
      ],
      tips: [
        'Alertas sao informativos e nao substituem avaliacao medica.',
        'Dados de wearable so entram com consentimento explicito.',
      ],
    );
  }
}

class CorpoScreen extends StatelessWidget {
  const CorpoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FitnessRecordScreen(
      type: 'corpo',
      title: 'Corpo e Exames',
      subtitle: 'Peso, IMC, composicao corporal, medidas e exames',
      icon: Icons.scale_outlined,
      primaryActionLabel: 'Registrar medida',
      emptyLabel: 'Nenhuma medida corporal registrada.',
      defaultTitle: 'Peso',
      defaultValue: '76,4 kg',
      defaultNote: 'IMC, gordura, musculo ou observacao de exame',
      metricCards: [
        FitnessMetricSpec('IMC', '23,8', Icons.analytics_outlined),
        FitnessMetricSpec('Gordura', '18%', Icons.pie_chart_outline),
        FitnessMetricSpec('Musculo', '34,2 kg', Icons.accessibility_new),
        FitnessMetricSpec('Agua', '57%', Icons.water_drop_outlined),
      ],
      extraCards: [
        _BodyCompositionCard(),
      ],
      tips: [
        'Acompanhe tendencia, nao apenas uma medida isolada.',
        'Exames podem ser ligados ao historico de evolucao do aluno.',
      ],
    );
  }
}

class MetasScreen extends StatelessWidget {
  const MetasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FitnessRecordScreen(
      type: 'meta',
      title: 'Metas e Conquistas',
      subtitle: 'Metas, lembretes, streaks, badges e ranking opcional',
      icon: Icons.emoji_events_outlined,
      primaryActionLabel: 'Criar meta',
      emptyLabel: 'Nenhuma meta criada ainda.',
      defaultTitle: 'Treinar 5x na semana',
      defaultValue: '0/5',
      defaultNote: 'Ranking sempre opcional e com privacidade por aluno.',
      metricCards: [
        FitnessMetricSpec('Pontos', '180', Icons.bolt_outlined),
        FitnessMetricSpec('Streak', '5 dias', Icons.local_fire_department),
        FitnessMetricSpec('Badges', '3', Icons.workspace_premium_outlined),
        FitnessMetricSpec('Ranking', 'Opt-in', Icons.privacy_tip_outlined),
      ],
      extraCards: [
        _GamificationCard(),
        _CommunityPrivacyCard(),
      ],
      tips: [
        'Ranking deve ficar desligado ate o aluno aceitar participar.',
        'Conquistas valorizam constancia, nao exposicao de dados sensiveis.',
      ],
    );
  }
}

class ComunidadeScreen extends StatelessWidget {
  const ComunidadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FitnessRecordScreen(
      type: 'comunidade',
      title: 'Comunidade',
      subtitle: 'Desafios, mural da academia e ranking opcional',
      icon: Icons.groups_outlined,
      primaryActionLabel: 'Criar desafio',
      emptyLabel: 'Nenhum desafio ou post criado ainda.',
      defaultTitle: 'Desafio da semana',
      defaultValue: 'Opt-in',
      defaultNote: 'Participacao voluntaria por aluno.',
      metricCards: [
        FitnessMetricSpec('Desafios', '2 ativos', Icons.flag_circle_outlined),
        FitnessMetricSpec('Ranking', 'Privado', Icons.privacy_tip_outlined),
        FitnessMetricSpec('Turma', '12 alunos', Icons.groups_outlined),
        FitnessMetricSpec('Badges', '3', Icons.workspace_premium_outlined),
      ],
      extraCards: [
        _CommunityPrivacyCard(),
        _GamificationCard(),
      ],
      tips: [
        'Dados de saude nao aparecem no mural sem permissao.',
        'Desafios devem premiar constancia e participacao segura.',
      ],
    );
  }
}

class FitnessMetricSpec {
  const FitnessMetricSpec(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class FitnessRecordScreen extends StatefulWidget {
  const FitnessRecordScreen({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryActionLabel,
    required this.emptyLabel,
    required this.defaultTitle,
    required this.defaultValue,
    required this.defaultNote,
    this.metricCards = const [],
    this.extraCards = const [],
    this.tips = const [],
    this.liveWorkout = false,
  });

  final String type;
  final String title;
  final String subtitle;
  final IconData icon;
  final String primaryActionLabel;
  final String emptyLabel;
  final String defaultTitle;
  final String defaultValue;
  final String defaultNote;
  final List<FitnessMetricSpec> metricCards;
  final List<Widget> extraCards;
  final List<String> tips;
  final bool liveWorkout;

  @override
  State<FitnessRecordScreen> createState() => _FitnessRecordScreenState();
}

class _FitnessRecordScreenState extends State<FitnessRecordScreen> {
  late Future<List<Fitness360Record>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = Fitness360LocalStore.records(type: widget.type);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.filterBackground,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: GridColors.filterBackground,
        foregroundColor: GridColors.textSecondary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: GridColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(widget.primaryActionLabel),
        onPressed: _showRecordSheet,
      ),
      body: FutureBuilder<List<Fitness360Record>>(
        future: _future,
        builder: (context, snapshot) {
          final records = snapshot.data ?? const <Fitness360Record>[];
          return RefreshIndicator(
            onRefresh: () async {
              await Fitness360LocalStore.markSynced();
              setState(_reload);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              children: [
                _HeroCard(
                  title: widget.subtitle,
                  value: records.isEmpty ? '--' : records.first.value,
                  label:
                      records.isEmpty ? widget.emptyLabel : records.first.title,
                  icon: widget.icon,
                ),
                if (widget.liveWorkout) ...[
                  const SizedBox(height: 14),
                  _LiveWorkoutCard(onFinished: () => setState(_reload)),
                ],
                const SizedBox(height: 14),
                if (widget.metricCards.isNotEmpty)
                  _MetricGrid(metrics: widget.metricCards),
                const SizedBox(height: 14),
                _WeeklyInsightCard(type: widget.type),
                const SizedBox(height: 14),
                ...widget.extraCards,
                if (widget.extraCards.isNotEmpty) const SizedBox(height: 4),
                if (widget.tips.isNotEmpty) _TipsCard(tips: widget.tips),
                const SizedBox(height: 14),
                _SectionTitle(
                  title: 'Historico',
                  trailing: '${records.length} registro(s)',
                ),
                const SizedBox(height: 10),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (records.isEmpty)
                  _EmptyState(label: widget.emptyLabel)
                else
                  for (final record in records) _RecordTile(record: record),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showRecordSheet() async {
    final title = TextEditingController(text: widget.defaultTitle);
    final value = TextEditingController(text: widget.defaultValue);
    final note = TextEditingController(text: widget.defaultNote);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: GridColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.primaryActionLabel,
                      style: const TextStyle(
                        color: GridColors.textSecondary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _TextField(controller: title, label: 'Titulo'),
                    const SizedBox(height: 12),
                    _TextField(controller: value, label: 'Valor'),
                    const SizedBox(height: 12),
                    _TextField(controller: note, label: 'Observacao'),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GridColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          await Fitness360LocalStore.addRecord(
                            type: widget.type,
                            title: title.text.trim(),
                            value: value.text.trim(),
                            note: note.text.trim(),
                          );
                          if (context.mounted) Navigator.pop(context, true);
                        },
                        child: const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    title.dispose();
    value.dispose();
    note.dispose();

    if (saved == true && mounted) {
      setState(_reload);
    }
  }
}

class _LiveWorkoutCard extends StatefulWidget {
  const _LiveWorkoutCard({required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<_LiveWorkoutCard> createState() => _LiveWorkoutCardState();
}

class _LiveWorkoutCardState extends State<_LiveWorkoutCard> {
  Timer? _timer;
  var _seconds = 0;
  var _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
    setState(() => _running = true);
  }

  Future<void> _finish() async {
    _timer?.cancel();
    final minutes = (_seconds / 60).ceil().clamp(1, 999);
    await Fitness360LocalStore.addRecord(
      type: 'atividade',
      title: 'Treino ao vivo',
      value: '$minutes min',
      note: 'Sessao concluida pelo cronometro',
    );
    setState(() {
      _seconds = 0;
      _running = false;
    });
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final mm = (_seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (_seconds % 60).toString().padLeft(2, '0');
    return _Panel(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Treino ao vivo',
                  style: TextStyle(
                    color: GridColors.textSecondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$mm:$ss',
                  style: const TextStyle(
                    color: GridColors.primary,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: GridColors.primary),
            onPressed: _toggle,
            icon: Icon(_running ? Icons.pause : Icons.play_arrow),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            onPressed: _seconds == 0 ? null : _finish,
            icon: const Icon(Icons.stop),
          ),
        ],
      ),
    );
  }
}

class _WeeklyInsightCard extends StatefulWidget {
  const _WeeklyInsightCard({required this.type});

  final String type;

  @override
  State<_WeeklyInsightCard> createState() => _WeeklyInsightCardState();
}

class _WeeklyInsightCardState extends State<_WeeklyInsightCard> {
  var _range = 'Semana';
  static const _ranges = ['Dia', 'Semana', 'Mes'];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: Fitness360LocalStore.insightSeries(widget.type, _range),
      builder: (context, snapshot) {
        final values = snapshot.data ?? const [1, 2, 3, 4, 5, 6, 7];
        final max = values.reduce((a, b) => a > b ? a : b).toDouble();
        final labels = _chartLabels(values.length);
        return _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                title: 'Insights',
                trailing: _range,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final range in _ranges)
                    ChoiceChip(
                      label: Text(range),
                      selected: _range == range,
                      onSelected: (_) => setState(() => _range = range),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _rangeSubtitle,
                style: const TextStyle(
                  color: Color(0xFF6D647A),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 92,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final value in values)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: FractionallySizedBox(
                            heightFactor: (value / max).clamp(0.08, 1.0),
                            alignment: Alignment.bottomCenter,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: GridColors.primary,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final label in labels)
                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF8A8196),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _insightText,
                style: const TextStyle(color: Color(0xFF6D647A), fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  String get _insightText {
    return switch (_range) {
      'Dia' =>
        'Hoje esta consistente. Use os picos do dia para ajustar lembretes e treinos.',
      'Mes' =>
        'No mes, mantenha a meta progressiva e revise quedas antes de virar rotina.',
      _ =>
        'Tendencia positiva: mantenha a rotina e ajuste a meta se ficar facil por muitos dias.',
    };
  }

  String get _rangeSubtitle {
    return switch (_range) {
      'Dia' => 'Visao em blocos do dia para atacar picos e quedas no horario certo.',
      'Mes' => 'Visao mensal por semana para enxergar consistencia e regressao.',
      _ => 'Visao semanal para comparar constancia, volume e recuperacao.',
    };
  }

  List<String> _chartLabels(int count) {
    return switch (_range) {
      'Dia' => const ['00h', '04h', '08h', '12h', '16h', '20h'],
      'Mes' => const ['S1', 'S2', 'S3', 'S4'],
      _ => const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'],
    }.take(count).toList();
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<FitnessMetricSpec> metrics;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width >= 720 ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: MediaQuery.sizeOf(context).width >= 720 ? 1.55 : 1.22,
      ),
      itemBuilder: (context, index) => _MetricTile(spec: metrics[index]),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.spec});

  final FitnessMetricSpec spec;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(spec.icon, color: GridColors.primary, size: 26),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                spec.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GridColors.textSecondary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                spec.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF6D647A), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.value,
    required this.label,
    required this.icon,
  });

  final String title;
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: GridColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: GridColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFEAE3FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  value,
                  style: const TextStyle(
                    color: GridColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFEAE3FF),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: GridColors.secondary.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});

  final Fitness360Record record;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM HH:mm').format(record.createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GridColors.primary.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: GridColors.filterBackground,
            child: Icon(Icons.check_circle_outline, color: GridColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: const TextStyle(
                    color: GridColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (record.note.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    record.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF6D647A)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                record.value,
                style: const TextStyle(
                  color: GridColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                date,
                style: const TextStyle(color: Color(0xFF6D647A), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SleepPhasesCard extends StatelessWidget {
  const _SleepPhasesCard();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Fases do sono', trailing: 'Score 84'),
          SizedBox(height: 12),
          _SegmentBar(
            segments: [
              _SegmentSpec(0.28, Color(0xFF32117A), 'Profundo'),
              _SegmentSpec(0.62, GridColors.primary, 'Leve'),
              _SegmentSpec(0.10, GridColors.secondary, 'Acordado'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeartZonesCard extends StatelessWidget {
  const _HeartZonesCard();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Zonas cardiacas', trailing: 'Hoje'),
          SizedBox(height: 12),
          _SegmentBar(
            segments: [
              _SegmentSpec(0.36, Color(0xFF2E7D32), 'Leve'),
              _SegmentSpec(0.42, GridColors.warning, 'Cardio'),
              _SegmentSpec(0.22, GridColors.error, 'Pico'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BodyCompositionCard extends StatelessWidget {
  const _BodyCompositionCard();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Composicao corporal', trailing: 'Meta 74 kg'),
          SizedBox(height: 12),
          _ProgressRow(label: 'Peso', value: '76,4 kg', progress: 0.72),
          _ProgressRow(label: 'Gordura', value: '18%', progress: 0.42),
          _ProgressRow(label: 'Musculo', value: '34,2 kg', progress: 0.68),
        ],
      ),
    );
  }
}

class _HabitReminderCard extends StatelessWidget {
  const _HabitReminderCard();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Agenda de habitos', trailing: 'Opt-in'),
          SizedBox(height: 10),
          _ReminderLine(
              icon: Icons.water_drop_outlined,
              label: 'Agua',
              time: '10:00, 14:00, 18:00'),
          _ReminderLine(
              icon: Icons.medication_outlined,
              label: 'Medicamento',
              time: '08:00'),
          _ReminderLine(
              icon: Icons.fitness_center,
              label: 'Treino',
              time: 'Seg, Qua, Sex'),
        ],
      ),
    );
  }
}

class _IntegrationConsentCard extends StatefulWidget {
  const _IntegrationConsentCard();

  @override
  State<_IntegrationConsentCard> createState() =>
      _IntegrationConsentCardState();
}

class _IntegrationConsentCardState extends State<_IntegrationConsentCard> {
  late Future<bool> _future;

  @override
  void initState() {
    super.initState();
    _future = Fitness360LocalStore.integrationConsent();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _future,
      builder: (context, snapshot) {
        final enabled = snapshot.data ?? false;
        return _Panel(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: enabled,
            title: const Text(
              'Integracoes de saude',
              style: TextStyle(
                color: GridColors.textSecondary,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: const Text(
              'Health Connect, Apple Health e importacao manual com consentimento.',
            ),
            onChanged: (value) async {
              await Fitness360LocalStore.setIntegrationConsent(value);
              setState(() {
                _future = Fitness360LocalStore.integrationConsent();
              });
            },
          ),
        );
      },
    );
  }
}

class _GamificationCard extends StatelessWidget {
  const _GamificationCard();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Conquistas', trailing: '3 badges'),
          SizedBox(height: 12),
          Row(
            children: [
              _Badge(label: '5 dias', icon: Icons.local_fire_department),
              _Badge(label: '10k passos', icon: Icons.directions_walk),
              _Badge(label: 'Sono bom', icon: Icons.bedtime_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommunityPrivacyCard extends StatefulWidget {
  const _CommunityPrivacyCard();

  @override
  State<_CommunityPrivacyCard> createState() => _CommunityPrivacyCardState();
}

class _CommunityPrivacyCardState extends State<_CommunityPrivacyCard> {
  late Future<bool> _future;

  @override
  void initState() {
    super.initState();
    _future = Fitness360LocalStore.communityOptIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _future,
      builder: (context, snapshot) {
        final enabled = snapshot.data ?? false;
        return _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(
                  Icons.privacy_tip_outlined,
                  color: GridColors.primary,
                ),
                value: enabled,
                title: Text(
                  enabled
                      ? 'Participando da comunidade local'
                      : 'Participar da comunidade local',
                  style: const TextStyle(
                    color: GridColors.textSecondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  enabled
                      ? 'Ranking e desafios ficam visiveis para o aluno.'
                      : 'Desligado por padrao. Ative para liberar desafios e ranking local.',
                ),
                onChanged: (value) async {
                  await Fitness360LocalStore.setCommunityOptIn(value);
                  setState(() {
                    _future = Fitness360LocalStore.communityOptIn();
                  });
                },
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ComunidadeScreen()),
                  );
                },
                icon: const Icon(Icons.groups_outlined),
                label: const Text('Abrir comunidade local'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.tips});

  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Sugestoes', trailing: 'Personalizadas'),
          const SizedBox(height: 8),
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: GridColors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(color: Color(0xFF6D647A)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: padding,
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GridColors.primary.withValues(alpha: 0.10)),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.trailing,
  });

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: GridColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(color: Color(0xFF6D647A), fontSize: 12),
        ),
      ],
    );
  }
}

class _SegmentSpec {
  const _SegmentSpec(this.value, this.color, this.label);

  final double value;
  final Color color;
  final String label;
}

class _SegmentBar extends StatelessWidget {
  const _SegmentBar({required this.segments});

  final List<_SegmentSpec> segments;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Row(
            children: [
              for (final segment in segments)
                Expanded(
                  flex: (segment.value * 100).round(),
                  child: Container(height: 12, color: segment.color),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            for (final segment in segments)
              Text(
                segment.label,
                style: TextStyle(color: segment.color, fontSize: 12),
              ),
          ],
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.progress,
  });

  final String label;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: GridColors.filterBackground,
            valueColor: const AlwaysStoppedAnimation(GridColors.primary),
          ),
        ],
      ),
    );
  }
}

class _ReminderLine extends StatelessWidget {
  const _ReminderLine({
    required this.icon,
    required this.label,
    required this.time,
  });

  final IconData icon;
  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, color: GridColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(time, style: const TextStyle(color: Color(0xFF6D647A))),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: GridColors.secondary.withValues(alpha: 0.14),
            child: Icon(icon, color: GridColors.secondary),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Text(label, style: const TextStyle(color: Color(0xFF6D647A))),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: GridColors.filterBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
