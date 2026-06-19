import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/exame_registro_model.dart';
import 'package:task_manager_flutter/data/models/gamificacao_model.dart';
import 'package:task_manager_flutter/data/models/hidratacao_model.dart';
import 'package:task_manager_flutter/data/models/lembrete_model.dart';
import 'package:task_manager_flutter/data/models/medida_corporal_model.dart';
import 'package:task_manager_flutter/data/models/mural_model.dart';
import 'package:task_manager_flutter/data/models/saude_diaria_model.dart';
import 'package:task_manager_flutter/data/services/exame_registro_caller.dart';
import 'package:task_manager_flutter/data/services/fitness_360_local_store.dart';
import 'package:task_manager_flutter/data/services/gamificacao_caller.dart';
import 'package:task_manager_flutter/data/services/hidratacao_caller.dart';
import 'package:task_manager_flutter/data/services/lembrete_caller.dart';
import 'package:task_manager_flutter/data/services/medida_corporal_caller.dart';
import 'package:task_manager_flutter/data/services/mural_caller.dart';
import 'package:task_manager_flutter/data/services/saude_diaria_caller.dart';

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

/// Tela "Sono e Habitos". Busca dados reais (resumo de saude para o sono e
/// lembretes ativos) ANTES de montar o [FitnessRecordScreen] generico, para
/// nao alterar a API publica do widget reutilizado por [MetasScreen] e
/// outras telas. Segue o mesmo padrao de [CorpoScreen].
class SonoScreen extends StatefulWidget {
  const SonoScreen({super.key});

  @override
  State<SonoScreen> createState() => _SonoScreenState();
}

class _SonoScreenData {
  const _SonoScreenData({
    required this.resumo,
    required this.lembretes,
  });

  final ResumoSaudeDiaria? resumo;
  final List<Lembrete> lembretes;
}

class _SonoScreenState extends State<SonoScreen> {
  late Future<_SonoScreenData> _future;

  @override
  void initState() {
    super.initState();
    _future = _carregar();
  }

  Future<_SonoScreenData> _carregar() async {
    final resumo = await SaudeDiariaCaller().fetchResumo();
    final lembretes = await LembreteCaller().fetchLembretes(ativo: true);
    return _SonoScreenData(
      resumo: resumo,
      // Fallback gracioso: sem lembrete real -> lista vazia (nao inventar
      // lembrete ficticio).
      lembretes: lembretes ?? const <Lembrete>[],
    );
  }

  void _reload() {
    setState(() {
      _future = _carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SonoScreenData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: GridColors.filterBackground,
            appBar: AppBar(
              title: const Text('Sono e Habitos'),
              backgroundColor: GridColors.filterBackground,
              foregroundColor: GridColors.textSecondary,
              elevation: 0,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data ??
            const _SonoScreenData(resumo: null, lembretes: <Lembrete>[]);

        final sonoMinutos = data.resumo?.sonoMinutos;
        // Fallback gracioso para o mock se a API falhar ou sonoMinutos
        // vier 0/null.
        final sonoLabel = (sonoMinutos != null && sonoMinutos > 0)
            ? _formatarMinutos(sonoMinutos)
            : '7h 30m';

        final lembretesOrdenados = [...data.lembretes]
          ..sort((a, b) => (a.horario ?? '99:99').compareTo(
                b.horario ?? '99:99',
              ));

        return FitnessRecordScreen(
          type: 'sono',
          title: 'Sono e Habitos',
          subtitle: 'Score, fases do sono, check-in e agenda de recuperacao',
          icon: Icons.bedtime_outlined,
          primaryActionLabel: 'Registrar sono',
          emptyLabel: 'Nenhum registro de sono ainda.',
          defaultTitle: 'Sono principal',
          defaultValue: sonoLabel,
          defaultNote: 'Qualidade, despertares e recuperacao',
          metricCards: const [
            FitnessMetricSpec('Score', '84/100', Icons.stars_outlined),
            FitnessMetricSpec('Profundo', '2h 04m', Icons.nightlight_round),
            FitnessMetricSpec('Leve', '4h 32m', Icons.bed_outlined),
            FitnessMetricSpec('Acordado', '42 min', Icons.wb_twilight_outlined),
          ],
          extraCards: [
            _SleepPhasesCard(sonoMinutosTotal: sonoMinutos),
            _HabitReminderCard(
              lembretes: lembretesOrdenados,
              onLembreteConcluido: _reload,
            ),
            const _HidratacaoCard(),
          ],
          tips: const [
            'Manter horario regular tende a melhorar o score.',
            'Evite treino pesado perto do horario de dormir.',
          ],
        );
      },
    );
  }
}

/// Formata minutos totais como "Xh Ym" (ex: 450 -> "7h 30m").
String _formatarMinutos(int minutos) {
  final horas = minutos ~/ 60;
  final restoMinutos = minutos % 60;
  return '${horas}h ${restoMinutos.toString().padLeft(2, '0')}m';
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

/// Tela "Corpo e Exames". Busca dados reais (resumo de saude, medidas
/// corporais e exames) ANTES de montar o [FitnessRecordScreen] generico, para
/// nao alterar a API publica do widget reutilizado por [MetasScreen] e
/// outras telas.
class CorpoScreen extends StatefulWidget {
  const CorpoScreen({super.key});

  @override
  State<CorpoScreen> createState() => _CorpoScreenState();
}

class _CorpoScreenData {
  const _CorpoScreenData({
    required this.resumo,
    required this.medidas,
    required this.exames,
  });

  final ResumoSaudeDiaria? resumo;
  final List<MedidaCorporal> medidas;
  final List<ExameRegistro> exames;
}

class _CorpoScreenState extends State<CorpoScreen> {
  late Future<_CorpoScreenData> _future;

  @override
  void initState() {
    super.initState();
    _future = _carregar();
  }

  Future<_CorpoScreenData> _carregar() async {
    final resumo = await SaudeDiariaCaller().fetchResumo();
    final medidas = await MedidaCorporalCaller().fetchMedidas();
    final exames = await ExameRegistroCaller().fetchExames();
    return _CorpoScreenData(
      resumo: resumo,
      // Fallback gracioso: sem mock previo para medida/exame -> lista vazia
      // (nao inventar dado clinico ficticio).
      medidas: medidas ?? const <MedidaCorporal>[],
      exames: exames ?? const <ExameRegistro>[],
    );
  }

  void _reload() {
    setState(() {
      _future = _carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CorpoScreenData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: GridColors.filterBackground,
            appBar: AppBar(
              title: const Text('Corpo e Exames'),
              backgroundColor: GridColors.filterBackground,
              foregroundColor: GridColors.textSecondary,
              elevation: 0,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data ??
            const _CorpoScreenData(
              resumo: null,
              medidas: <MedidaCorporal>[],
              exames: <ExameRegistro>[],
            );

        final pesoKg = data.resumo?.pesoKg;
        final alturaCm = data.resumo?.alturaCm;
        final imc = _calcularImc(pesoKg, alturaCm);
        final ultimaMedida = data.medidas.isEmpty ? null : data.medidas.first;

        return FitnessRecordScreen(
          type: 'corpo',
          title: 'Corpo e Exames',
          subtitle: 'Peso, IMC, composicao corporal, medidas e exames',
          icon: Icons.scale_outlined,
          primaryActionLabel: 'Registrar medida',
          emptyLabel: 'Nenhuma medida corporal registrada.',
          defaultTitle: 'Peso',
          defaultValue:
              pesoKg != null ? '${_formatarNumero(pesoKg)} kg' : '--',
          defaultNote: 'IMC, gordura, musculo ou observacao de exame',
          metricCards: [
            FitnessMetricSpec(
              'IMC',
              imc != null ? _formatarNumero(imc) : '--',
              Icons.analytics_outlined,
            ),
            FitnessMetricSpec(
              'Gordura',
              ultimaMedida?.percentualGordura != null
                  ? '${_formatarNumero(ultimaMedida!.percentualGordura!)}%'
                  : '--',
              Icons.pie_chart_outline,
            ),
            FitnessMetricSpec(
              'Musculo',
              ultimaMedida?.percentualMassaMuscular != null
                  ? '${_formatarNumero(ultimaMedida!.percentualMassaMuscular!)}%'
                  : '--',
              Icons.accessibility_new,
            ),
            FitnessMetricSpec(
              'Agua',
              ultimaMedida?.percentualAgua != null
                  ? '${_formatarNumero(ultimaMedida!.percentualAgua!)}%'
                  : '--',
              Icons.water_drop_outlined,
            ),
          ],
          extraCards: [
            _BodyCompositionCard(medida: ultimaMedida, pesoKg: pesoKg),
            _CorpoEvolutionChartCard(
              historico: data.resumo?.historicoSemanal ?? const [],
              medidas: data.medidas,
            ),
            _CorpoActionsCard(
              resumo: data.resumo,
              onAlturaSalva: _reload,
              onMedidaRegistrada: _reload,
              onExameRegistrado: _reload,
            ),
            _CorpoTimelineCard(
              historico: data.resumo?.historicoSemanal ?? const [],
              medidas: data.medidas,
              exames: data.exames,
            ),
          ],
          tips: const [
            'Acompanhe tendencia, nao apenas uma medida isolada.',
            'Exames podem ser ligados ao historico de evolucao do aluno.',
          ],
        );
      },
    );
  }
}

/// Calcula o IMC no client: peso / (altura_m)^2. Retorna null se peso ou
/// altura nao estiverem disponiveis (nunca um valor ficticio).
double? _calcularImc(double? pesoKg, int? alturaCm) {
  if (pesoKg == null || alturaCm == null || alturaCm <= 0) return null;
  final alturaM = alturaCm / 100;
  return pesoKg / (alturaM * alturaM);
}

String _formatarNumero(double value) {
  return value.toStringAsFixed(1).replaceAll('.', ',');
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
        _RankingCard(),
        _MuralCard(),
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
  const _SleepPhasesCard({this.sonoMinutosTotal});

  /// Total real de minutos de sono (GET /api/fitness/resumo). Pode ser null
  /// se a API falhar ou nao houver registro do dia.
  final int? sonoMinutosTotal;

  @override
  Widget build(BuildContext context) {
    // Fases do sono sao estimativa proporcional - backend so expoe total.
    // Os percentuais abaixo sao os mesmos do mock anterior, aplicados sobre
    // o total real quando disponivel.
    const percentualProfundo = 0.28;
    const percentualLeve = 0.62;
    const percentualAcordado = 0.10;

    final temDadoReal = sonoMinutosTotal != null && sonoMinutosTotal! > 0;
    final trailing = temDadoReal
        ? _formatarMinutos(sonoMinutosTotal!)
        : 'Score 84';

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Fases do sono', trailing: trailing),
          const SizedBox(height: 12),
          const _SegmentBar(
            segments: [
              _SegmentSpec(percentualProfundo, Color(0xFF32117A), 'Profundo'),
              _SegmentSpec(percentualLeve, GridColors.primary, 'Leve'),
              _SegmentSpec(
                percentualAcordado,
                GridColors.secondary,
                'Acordado',
              ),
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
  const _BodyCompositionCard({this.medida, this.pesoKg});

  final MedidaCorporal? medida;
  final double? pesoKg;

  @override
  Widget build(BuildContext context) {
    final gordura = medida?.percentualGordura;
    final massaMuscular = medida?.percentualMassaMuscular;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Composicao corporal', trailing: ''),
          const SizedBox(height: 12),
          _ProgressRow(
            label: 'Peso',
            value: pesoKg != null ? '${_formatarNumero(pesoKg!)} kg' : '--',
            progress: pesoKg != null ? (pesoKg! / 120).clamp(0.0, 1.0) : 0,
          ),
          _ProgressRow(
            label: 'Gordura',
            value: gordura != null ? '${_formatarNumero(gordura)}%' : '--',
            progress: gordura != null ? (gordura / 100).clamp(0.0, 1.0) : 0,
          ),
          _ProgressRow(
            label: 'Musculo',
            value: massaMuscular != null
                ? '${_formatarNumero(massaMuscular)}%'
                : '--',
            progress: massaMuscular != null
                ? (massaMuscular / 100).clamp(0.0, 1.0)
                : 0,
          ),
        ],
      ),
    );
  }
}

/// Card de acoes do CorpoScreen: input de altura (uma vez/pre-populado),
/// registrar medida corporal e registrar exame.
class _CorpoActionsCard extends StatefulWidget {
  const _CorpoActionsCard({
    required this.resumo,
    required this.onAlturaSalva,
    required this.onMedidaRegistrada,
    required this.onExameRegistrado,
  });

  final ResumoSaudeDiaria? resumo;
  final VoidCallback onAlturaSalva;
  final VoidCallback onMedidaRegistrada;
  final VoidCallback onExameRegistrado;

  @override
  State<_CorpoActionsCard> createState() => _CorpoActionsCardState();
}

class _CorpoActionsCardState extends State<_CorpoActionsCard> {
  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Registros', trailing: ''),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _showAlturaSheet,
                icon: const Icon(Icons.height),
                label: Text(
                  widget.resumo?.alturaCm != null
                      ? 'Altura: ${widget.resumo!.alturaCm} cm'
                      : 'Informar altura',
                ),
              ),
              OutlinedButton.icon(
                onPressed: _showMedidaSheet,
                icon: const Icon(Icons.straighten),
                label: const Text('Registrar medida'),
              ),
              OutlinedButton.icon(
                onPressed: _showExameSheet,
                icon: const Icon(Icons.assignment_outlined),
                label: const Text('Registrar exame'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAlturaSheet() async {
    final controller = TextEditingController(
      text: widget.resumo?.alturaCm?.toString() ?? '',
    );

    final saved = await _showBottomSheet(
      context: context,
      title: 'Informar altura',
      child: _TextField(controller: controller, label: 'Altura (cm)'),
      onSave: () async {
        final alturaCm = int.tryParse(controller.text.trim());
        if (alturaCm == null) return false;
        final base = widget.resumo ??
            ResumoSaudeDiaria(
              data: DateTime.now(),
              passos: 0,
              treinoMinutos: 0,
              batimentos: null,
              sonoMinutos: 0,
              pesoKg: null,
              pesoMetaKg: null,
              historicoSemanal: const [],
            );
        final atualizado = base.copyWith(alturaCm: alturaCm);
        final resultado =
            await SaudeDiariaCaller().salvarResumo(atualizado);
        return resultado != null;
      },
    );

    controller.dispose();
    if (saved == true) widget.onAlturaSalva();
  }

  Future<void> _showMedidaSheet() async {
    final gordura = TextEditingController();
    final massaMuscular = TextEditingController();
    final agua = TextEditingController();
    final braco = TextEditingController();
    final cintura = TextEditingController();
    final quadril = TextEditingController();

    final saved = await _showBottomSheet(
      context: context,
      title: 'Registrar medida corporal',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TextField(controller: gordura, label: '% Gordura'),
          const SizedBox(height: 12),
          _TextField(controller: massaMuscular, label: '% Massa muscular'),
          const SizedBox(height: 12),
          _TextField(controller: agua, label: '% Agua'),
          const SizedBox(height: 12),
          _TextField(controller: braco, label: 'Braco (cm)'),
          const SizedBox(height: 12),
          _TextField(controller: cintura, label: 'Cintura (cm)'),
          const SizedBox(height: 12),
          _TextField(controller: quadril, label: 'Quadril (cm)'),
        ],
      ),
      onSave: () async {
        final circunferencias = <String, double>{};
        final bracoVal = _parseDouble(braco.text);
        final cinturaVal = _parseDouble(cintura.text);
        final quadrilVal = _parseDouble(quadril.text);
        if (bracoVal != null) circunferencias['braco'] = bracoVal;
        if (cinturaVal != null) circunferencias['cintura'] = cinturaVal;
        if (quadrilVal != null) circunferencias['quadril'] = quadrilVal;

        final medida = MedidaCorporal(
          data: DateTime.now(),
          percentualGordura: _parseDouble(gordura.text),
          percentualMassaMuscular: _parseDouble(massaMuscular.text),
          percentualAgua: _parseDouble(agua.text),
          circunferencias: circunferencias,
        );
        final resultado =
            await MedidaCorporalCaller().registrarMedida(medida);
        return resultado != null;
      },
    );

    gordura.dispose();
    massaMuscular.dispose();
    agua.dispose();
    braco.dispose();
    cintura.dispose();
    quadril.dispose();

    if (saved == true) widget.onMedidaRegistrada();
  }

  Future<void> _showExameSheet() async {
    final nomeExame = TextEditingController();
    final observacao = TextEditingController();

    final saved = await _showBottomSheet(
      context: context,
      title: 'Registrar exame',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TextField(controller: nomeExame, label: 'Nome do exame'),
          const SizedBox(height: 12),
          _TextField(controller: observacao, label: 'Observacao (opcional)'),
        ],
      ),
      onSave: () async {
        final nome = nomeExame.text.trim();
        if (nome.isEmpty) return false;
        final exame = ExameRegistro(
          data: DateTime.now(),
          nomeExame: nome,
          observacao:
              observacao.text.trim().isEmpty ? null : observacao.text.trim(),
        );
        final resultado = await ExameRegistroCaller().registrarExame(exame);
        return resultado != null;
      },
    );

    nomeExame.dispose();
    observacao.dispose();

    if (saved == true) widget.onExameRegistrado();
  }

  double? _parseDouble(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }
}

/// Bottom sheet generico de registro, usado pelos 3 fluxos do
/// [_CorpoActionsCard] (altura, medida, exame), reaproveitando o mesmo
/// padrao visual do `_showRecordSheet` do [FitnessRecordScreen].
Future<bool?> _showBottomSheet({
  required BuildContext context,
  required String title,
  required Widget child,
  required Future<bool> Function() onSave,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      var salvando = false;
      return StatefulBuilder(
        builder: (context, setState) {
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
                        title,
                        style: const TextStyle(
                          color: GridColors.textSecondary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      child,
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GridColors.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: salvando
                              ? null
                              : () async {
                                  setState(() => salvando = true);
                                  final ok = await onSave();
                                  if (context.mounted) {
                                    Navigator.pop(context, ok);
                                  }
                                },
                          child: salvando
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Salvar'),
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
    },
  );
}

/// Evento generico da linha do tempo do CorpoScreen (peso/medida/exame).
class _TimelineEvent {
  const _TimelineEvent({
    required this.data,
    required this.tipo,
    required this.titulo,
    required this.detalhe,
    required this.icon,
  });

  final DateTime data;
  final String tipo;
  final String titulo;
  final String detalhe;
  final IconData icon;
}

/// Periodo de filtro para o grafico de evolucao (client-side, sobre dados
/// ja carregados pela CorpoScreen - sem novo parametro de API).
enum _PeriodoEvolucao { umMes, tresMeses, seisMeses, umAno }

extension on _PeriodoEvolucao {
  String get label => switch (this) {
        _PeriodoEvolucao.umMes => '1 mes',
        _PeriodoEvolucao.tresMeses => '3 meses',
        _PeriodoEvolucao.seisMeses => '6 meses',
        _PeriodoEvolucao.umAno => '1 ano',
      };

  int get dias => switch (this) {
        _PeriodoEvolucao.umMes => 30,
        _PeriodoEvolucao.tresMeses => 90,
        _PeriodoEvolucao.seisMeses => 180,
        _PeriodoEvolucao.umAno => 365,
      };
}

/// Metrica selecionavel no grafico de evolucao corporal.
enum _MetricaEvolucao { peso, gordura, musculo, agua }

extension on _MetricaEvolucao {
  String get label => switch (this) {
        _MetricaEvolucao.peso => 'Peso (kg)',
        _MetricaEvolucao.gordura => 'Gordura (%)',
        _MetricaEvolucao.musculo => 'Musculo (%)',
        _MetricaEvolucao.agua => 'Agua (%)',
      };
}

/// Grafico de linha de evolucao de peso e medidas corporais, com seletor de
/// metrica e filtro de periodo. Reaproveita os mesmos dados (historico e
/// medidas) ja carregados pela CorpoScreen - nao duplica chamada de API.
///
/// Nota de escopo: evolucao de carga maxima por exercicio NAO esta incluida
/// aqui porque "carga" (peso levantado em exercicio) ainda nao existe no
/// backend - depende do card "[FITNESS] Registro de carga por exercicio"
/// (nao iniciado). Quando esse card for implementado, adicionar uma aba ou
/// selector adicional aqui reaproveitando este mesmo widget de grafico.
class _CorpoEvolutionChartCard extends StatefulWidget {
  const _CorpoEvolutionChartCard({
    required this.historico,
    required this.medidas,
  });

  final List<DiaResumoSaude> historico;
  final List<MedidaCorporal> medidas;

  @override
  State<_CorpoEvolutionChartCard> createState() =>
      _CorpoEvolutionChartCardState();
}

class _CorpoEvolutionChartCardState extends State<_CorpoEvolutionChartCard> {
  _MetricaEvolucao _metrica = _MetricaEvolucao.peso;
  _PeriodoEvolucao _periodo = _PeriodoEvolucao.tresMeses;

  List<_PontoSerie> _serieFiltrada() {
    final limite = DateTime.now().subtract(Duration(days: _periodo.dias));
    final pontos = <_PontoSerie>[];

    if (_metrica == _MetricaEvolucao.peso) {
      for (final dia in widget.historico) {
        if (dia.pesoKg != null && !dia.data.isBefore(limite)) {
          pontos.add(_PontoSerie(dia.data, dia.pesoKg!));
        }
      }
    } else {
      for (final medida in widget.medidas) {
        if (medida.data.isBefore(limite)) continue;
        final valor = switch (_metrica) {
          _MetricaEvolucao.gordura => medida.percentualGordura,
          _MetricaEvolucao.musculo => medida.percentualMassaMuscular,
          _MetricaEvolucao.agua => medida.percentualAgua,
          _MetricaEvolucao.peso => null,
        };
        if (valor != null) {
          pontos.add(_PontoSerie(medida.data, valor));
        }
      }
    }

    pontos.sort((a, b) => a.data.compareTo(b.data));
    return pontos;
  }

  @override
  Widget build(BuildContext context) {
    final serie = _serieFiltrada();

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Evolucao',
            trailing: 'Peso e medidas',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final metrica in _MetricaEvolucao.values)
                ChoiceChip(
                  label: Text(metrica.label),
                  selected: _metrica == metrica,
                  onSelected: (_) => setState(() => _metrica = metrica),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final periodo in _PeriodoEvolucao.values)
                ChoiceChip(
                  label: Text(periodo.label),
                  selected: _periodo == periodo,
                  onSelected: (_) => setState(() => _periodo = periodo),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (serie.length < 2)
            const _EmptyState(
              label: 'Dados insuficientes para grafico neste periodo.',
            )
          else
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 36),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= serie.length) {
                            return const SizedBox.shrink();
                          }
                          final d = serie[i].data;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
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
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: GridColors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      spots: [
                        for (var i = 0; i < serie.length; i++)
                          FlSpot(i.toDouble(), serie[i].valor),
                      ],
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            GridColors.primary.withValues(alpha: 0.25),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PontoSerie {
  const _PontoSerie(this.data, this.valor);

  final DateTime data;
  final double valor;
}

/// Linha do tempo unificada: combina historico de peso/altura, medidas
/// corporais e exames numa lista ordenada por data desc.
class _CorpoTimelineCard extends StatelessWidget {
  const _CorpoTimelineCard({
    required this.historico,
    required this.medidas,
    required this.exames,
  });

  final List<DiaResumoSaude> historico;
  final List<MedidaCorporal> medidas;
  final List<ExameRegistro> exames;

  @override
  Widget build(BuildContext context) {
    final eventos = <_TimelineEvent>[
      for (final dia in historico)
        if (dia.pesoKg != null)
          _TimelineEvent(
            data: dia.data,
            tipo: 'peso',
            titulo: 'Peso',
            detalhe: '${_formatarNumero(dia.pesoKg!)} kg',
            icon: Icons.scale_outlined,
          ),
      for (final medida in medidas)
        _TimelineEvent(
          data: medida.data,
          tipo: 'medida',
          titulo: 'Medida corporal',
          detalhe: _detalheMedida(medida),
          icon: Icons.straighten,
        ),
      for (final exame in exames)
        _TimelineEvent(
          data: exame.data,
          tipo: 'exame',
          titulo: exame.nomeExame,
          detalhe: exame.observacao ?? 'Exame registrado',
          icon: Icons.assignment_outlined,
        ),
    ]..sort((a, b) => b.data.compareTo(a.data));

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Linha do tempo',
            trailing: '${eventos.length} evento(s)',
          ),
          const SizedBox(height: 10),
          if (eventos.isEmpty)
            const _EmptyState(label: 'Nenhum evento registrado ainda.')
          else
            for (final evento in eventos) _TimelineTile(evento: evento),
        ],
      ),
    );
  }

  String _detalheMedida(MedidaCorporal medida) {
    final partes = <String>[];
    if (medida.percentualGordura != null) {
      partes.add('Gordura ${_formatarNumero(medida.percentualGordura!)}%');
    }
    if (medida.percentualMassaMuscular != null) {
      partes.add(
        'Musculo ${_formatarNumero(medida.percentualMassaMuscular!)}%',
      );
    }
    if (medida.percentualAgua != null) {
      partes.add('Agua ${_formatarNumero(medida.percentualAgua!)}%');
    }
    if (partes.isEmpty) return 'Medida registrada';
    return partes.join(' - ');
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.evento});

  final _TimelineEvent evento;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy').format(evento.data);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: GridColors.filterBackground,
            child: Icon(evento.icon, color: GridColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evento.titulo,
                  style: const TextStyle(
                    color: GridColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  evento.detalhe,
                  style: const TextStyle(color: Color(0xFF6D647A)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            date,
            style: const TextStyle(color: Color(0xFF6D647A), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _HabitReminderCard extends StatelessWidget {
  const _HabitReminderCard({
    this.lembretes = const <Lembrete>[],
    this.onLembreteConcluido,
  });

  /// Lembretes reais (GET /api/fitness/lembretes?ativo=true), ja ordenados
  /// por horario pelo chamador.
  final List<Lembrete> lembretes;
  final VoidCallback? onLembreteConcluido;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Agenda de habitos', trailing: 'Opt-in'),
          const SizedBox(height: 10),
          if (lembretes.isEmpty)
            const _EmptyState(label: 'Nenhum lembrete cadastrado')
          else
            for (final lembrete in lembretes)
              _ReminderLine(
                icon: _iconeLembrete(lembrete.tipo),
                label: lembrete.nome,
                time: lembrete.horario ?? lembrete.frequencia ?? '--',
                concluido: lembrete.concluidoHoje,
                onTap: lembrete.id == null
                    ? null
                    : () async {
                        await LembreteCaller().concluirLembrete(lembrete.id!);
                        onLembreteConcluido?.call();
                      },
              ),
        ],
      ),
    );
  }

  IconData _iconeLembrete(String tipo) {
    return switch (tipo) {
      'MEDICAMENTO' => Icons.medication_outlined,
      'SUPLEMENTO' => Icons.local_pharmacy_outlined,
      'HABITO' => Icons.fitness_center,
      _ => Icons.notifications_outlined,
    };
  }
}

/// Card simples de hidratacao na SonoScreen: mostra total consumido/meta do
/// dia e um botao "+1 copo". Modulo de hidratacao ja existe 100% no backend
/// (nao desta fase), contrato confirmado em HidratacaoController.java.
class _HidratacaoCard extends StatefulWidget {
  const _HidratacaoCard();

  @override
  State<_HidratacaoCard> createState() => _HidratacaoCardState();
}

class _HidratacaoCardState extends State<_HidratacaoCard> {
  late Future<ResumoHidratacao?> _future;
  var _registrando = false;

  @override
  void initState() {
    super.initState();
    _future = HidratacaoCaller().fetchResumo();
  }

  void _reload() {
    setState(() {
      _future = HidratacaoCaller().fetchResumo();
    });
  }

  Future<void> _adicionarCopo(int volumeCopoMl) async {
    setState(() => _registrando = true);
    await HidratacaoCaller().registrarConsumo(volumeCopoMl);
    if (mounted) {
      setState(() => _registrando = false);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ResumoHidratacao?>(
      future: _future,
      builder: (context, snapshot) {
        final resumo = snapshot.data;
        final totalMl = resumo?.totalMl;
        final metaMl = resumo?.metaDiariaMl;
        final volumeCopoMl = resumo?.volumeCopoMl ?? 250;

        final resumoLabel = (totalMl != null && metaMl != null)
            ? '$totalMl ml / $metaMl ml'
            : '-- ml / -- ml';

        return _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(title: 'Hidratacao', trailing: 'Hoje'),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.water_drop_outlined,
                    color: GridColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      resumoLabel,
                      style: const TextStyle(
                        color: GridColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _registrando
                        ? null
                        : () => _adicionarCopo(volumeCopoMl),
                    icon: _registrando
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add, size: 18),
                    label: const Text('+1 copo'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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

/// Especificacao simples de badge (label + icone), usada para gerar tanto o
/// fallback mockado quanto os badges reais vindos da API de conquistas.
class _BadgeSpec {
  const _BadgeSpec(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Badges mockados usados como fallback quando a API de conquistas falha ou
/// retorna lista vazia (nao quebrar a UX que ja existia).
const _badgesFallback = [
  _BadgeSpec('5 dias', Icons.local_fire_department),
  _BadgeSpec('10k passos', Icons.directions_walk),
  _BadgeSpec('Sono bom', Icons.bedtime_outlined),
];

/// Mapa simples de icone por codigo/nome de conquista. Usa um icone generico
/// quando o codigo nao e reconhecido (o backend pode evoluir a lista).
IconData _iconeConquista(String codigo) {
  final chave = codigo.toLowerCase();
  if (chave.contains('passo') || chave.contains('caminhada')) {
    return Icons.directions_walk;
  }
  if (chave.contains('sono') || chave.contains('dormir')) {
    return Icons.bedtime_outlined;
  }
  if (chave.contains('streak') || chave.contains('dias') ||
      chave.contains('sequencia')) {
    return Icons.local_fire_department;
  }
  if (chave.contains('treino') || chave.contains('exercicio')) {
    return Icons.fitness_center;
  }
  return Icons.workspace_premium_outlined;
}

class _GamificationCard extends StatefulWidget {
  const _GamificationCard();

  @override
  State<_GamificationCard> createState() => _GamificationCardState();
}

class _GamificationCardState extends State<_GamificationCard> {
  late Future<List<ConquistaItem>?> _future;

  @override
  void initState() {
    super.initState();
    _future = GamificacaoCaller().fetchConquistas();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ConquistaItem>?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Panel(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        final conquistas = snapshot.data;
        final obtidas =
            (conquistas ?? const <ConquistaItem>[])
                .where((item) => item.obtida)
                .toList();

        // Fallback gracioso: chamada falhou (null) ou lista vazia -> badges
        // mockados, mesma UX anterior a integracao.
        final usaFallback = conquistas == null || obtidas.isEmpty;
        final badgeSpecs = usaFallback
            ? _badgesFallback
            : [
                for (final item in obtidas)
                  _BadgeSpec(
                    item.nome.isNotEmpty ? item.nome : item.codigo,
                    _iconeConquista(
                      item.codigo.isNotEmpty ? item.codigo : item.nome,
                    ),
                  ),
              ];

        final contagem = badgeSpecs.length;

        return _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                title: 'Conquistas',
                trailing: '$contagem badge${contagem == 1 ? '' : 's'}',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 4,
                runSpacing: 8,
                children: [
                  for (final spec in badgeSpecs)
                    SizedBox(
                      width: 84,
                      child: Row(
                        children: [
                          _Badge(label: spec.label, icon: spec.icon),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
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
  var _salvando = false;

  @override
  void initState() {
    super.initState();
    // Le preferencialmente do backend (GET perfil); cai no valor local salvo
    // se a chamada de rede falhar (mesmo padrao de _atividadeSeriesFromBackend
    // em fitness_360_local_store.dart).
    _future = Fitness360LocalStore.communityOptInFromBackend();
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
                secondary: _salvando
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
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
                onChanged: _salvando
                    ? null
                    : (value) async {
                        setState(() => _salvando = true);
                        // Tenta salvar no backend primeiro; o helper ja cai
                        // no SharedPreferences local como fallback/cache em
                        // qualquer cenario (sucesso ou falha de rede).
                        await Fitness360LocalStore.setCommunityOptInBackend(
                          value,
                        );
                        if (!mounted) return;
                        setState(() {
                          _salvando = false;
                          _future =
                              Fitness360LocalStore.communityOptInFromBackend();
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

/// Card de ranking opcional: mostra "Posicao X de Y" e a lista (top 20 +
/// posicao do usuario, se fora do top). Sem nomes de aluno -- so "Voce" ou
/// "Usuario #<id>", pois o backend nao expoe nome. Trata loading/erro/vazio.
class _RankingCard extends StatefulWidget {
  const _RankingCard();

  @override
  State<_RankingCard> createState() => _RankingCardState();
}

class _RankingCardState extends State<_RankingCard> {
  late Future<List<RankingItem>?> _future;

  @override
  void initState() {
    super.initState();
    _future = GamificacaoCaller().fetchRanking();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RankingItem>?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Panel(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        final ranking = snapshot.data;

        // Erro de rede (null) ou lista vazia: estado vazio, sem quebrar a
        // tela.
        if (ranking == null) {
          return const _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: 'Ranking', trailing: 'Opt-in'),
                SizedBox(height: 10),
                _EmptyState(label: 'Ranking indisponivel no momento.'),
              ],
            ),
          );
        }

        if (ranking.isEmpty) {
          return const _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: 'Ranking', trailing: 'Opt-in'),
                SizedBox(height: 10),
                _EmptyState(label: 'Nenhum participante ainda.'),
              ],
            ),
          );
        }

        final ordenado = [...ranking]
          ..sort((a, b) => a.posicao.compareTo(b.posicao));
        RankingItem? voce;
        for (final item in ordenado) {
          if (item.voce) {
            voce = item;
            break;
          }
        }
        final top20 = ordenado.take(20).toList();

        return _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                title: 'Ranking',
                trailing: voce != null
                    ? 'Posicao ${voce.posicao} de ${ordenado.length}'
                    : 'Opt-in',
              ),
              const SizedBox(height: 10),
              for (final item in top20)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${item.posicao}.',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: GridColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.voce ? 'Voce' : 'Usuario #${item.usuarioId}',
                          style: TextStyle(
                            fontWeight:
                                item.voce ? FontWeight.w900 : FontWeight.w500,
                            color: item.voce
                                ? GridColors.primary
                                : GridColors.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        '${item.pontuacao} pontos',
                        style: const TextStyle(color: Color(0xFF6D647A)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Mural simples da comunidade: lista de posts (texto + autor "Voce"/
/// "Usuario #<id>" + data) e um campo de texto com botao "Postar" (max 280
/// caracteres, contador). Se o usuario nao tiver opt-in de comunidade, o
/// campo de postar fica desabilitado com mensagem explicativa.
class _MuralCard extends StatefulWidget {
  const _MuralCard();

  @override
  State<_MuralCard> createState() => _MuralCardState();
}

class _MuralCardState extends State<_MuralCard> {
  static const _maxChars = 280;

  late Future<_MuralCardData> _future;
  final _controller = TextEditingController();
  var _postando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _future = _carregar();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<_MuralCardData> _carregar() async {
    final optIn = await Fitness360LocalStore.communityOptInFromBackend();
    final posts = await MuralCaller().fetchPosts();
    return _MuralCardData(
      comunidadeOptIn: optIn,
      posts: posts,
    );
  }

  void _reload() {
    setState(() {
      _future = _carregar();
    });
  }

  Future<void> _postar() async {
    final conteudo = _controller.text.trim();
    if (conteudo.isEmpty || conteudo.length > _maxChars) return;

    setState(() {
      _postando = true;
      _erro = null;
    });

    final criado = await MuralCaller().criarPost(conteudo);

    if (!mounted) return;
    setState(() => _postando = false);

    if (criado != null) {
      _controller.clear();
      _reload();
    } else {
      setState(() => _erro = 'Nao foi possivel publicar agora. Tente novamente.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MuralCardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Panel(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        final data = snapshot.data ??
            const _MuralCardData(comunidadeOptIn: false, posts: null);
        final posts = data.posts;
        final podePostar = data.comunidadeOptIn;
        final caracteresRestantes = _maxChars - _controller.text.length;

        return _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(title: 'Mural da comunidade', trailing: 'Opt-in'),
              const SizedBox(height: 10),
              if (posts == null)
                const _EmptyState(label: 'Mural indisponivel no momento.')
              else if (posts.isEmpty)
                const _EmptyState(label: 'Nenhum post ainda. Seja o primeiro!')
              else
                for (final post in posts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.voce ? 'Voce' : 'Usuario #${post.usuarioId}',
                              style: TextStyle(
                                fontWeight: post.voce
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                color: post.voce
                                    ? GridColors.primary
                                    : GridColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatarDataHora(post.criadoEm),
                              style: const TextStyle(
                                color: Color(0xFF6D647A),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(post.conteudo),
                      ],
                    ),
                  ),
              const Divider(height: 20),
              if (!podePostar)
                const Text(
                  'Ative a participacao na comunidade para poder postar no mural.',
                  style: TextStyle(color: Color(0xFF6D647A), fontSize: 12),
                )
              else ...[
                TextField(
                  controller: _controller,
                  enabled: !_postando,
                  maxLength: _maxChars,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Compartilhe algo com a comunidade...',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_erro != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _erro!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '$caracteresRestantes caracteres restantes',
                      style: const TextStyle(
                        color: Color(0xFF6D647A),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: (_postando || _controller.text.trim().isEmpty)
                          ? null
                          : _postar,
                      icon: _postando
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined, size: 18),
                      label: const Text('Postar'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MuralCardData {
  const _MuralCardData({
    required this.comunidadeOptIn,
    required this.posts,
  });

  final bool comunidadeOptIn;
  final List<MuralPost>? posts;
}

/// Formata data+hora como DD/MM HH:MM.
String _formatarDataHora(DateTime d) {
  final dia = d.day.toString().padLeft(2, '0');
  final mes = d.month.toString().padLeft(2, '0');
  final hora = d.hour.toString().padLeft(2, '0');
  final minuto = d.minute.toString().padLeft(2, '0');
  return '$dia/$mes $hora:$minuto';
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
    this.concluido = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String time;
  final bool concluido;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Icon(
              concluido ? Icons.check_circle : icon,
              color: concluido ? GridColors.success : GridColors.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: concluido
                    ? const TextStyle(
                        color: Color(0xFF6D647A),
                        decoration: TextDecoration.lineThrough,
                      )
                    : null,
              ),
            ),
            Text(time, style: const TextStyle(color: Color(0xFF6D647A))),
          ],
        ),
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
