import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';

class PersonalWorkspaceScreen extends StatefulWidget {
  const PersonalWorkspaceScreen({super.key});

  @override
  State<PersonalWorkspaceScreen> createState() =>
      _PersonalWorkspaceScreenState();
}

enum _WorkspaceStatus { loading, error, empty, success }

enum _WorkspacePhase {
  alunos,
  convite,
  treino,
  execucao,
  avaliacao,
  agenda,
  planos,
  conteudo,
}

class _PersonalWorkspaceScreenState extends State<PersonalWorkspaceScreen> {
  _WorkspacePhase _selectedPhase = _WorkspacePhase.alunos;
  _WorkspaceStatus _status = _WorkspaceStatus.success;

  Future<void> _simulateLoading(
      [_WorkspaceStatus nextStatus = _WorkspaceStatus.success]) async {
    setState(() => _status = _WorkspaceStatus.loading);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (mounted) {
      setState(() => _status = nextStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 900;

    return Scaffold(
      backgroundColor: GridColors.filterBackground,
      appBar: AppBar(
        backgroundColor: GridColors.filterBackground,
        foregroundColor: GridColors.textSecondary,
        elevation: 0,
        title: const Text('Workspace Personal'),
        actions: [
          Tooltip(
            message: 'Simular carregamento',
            child: IconButton(
              onPressed: () => _simulateLoading(),
              icon: const Icon(Icons.refresh),
            ),
          ),
          PopupMenuButton<_WorkspaceStatus>(
            tooltip: 'Simular estado da tela',
            icon: const Icon(Icons.tune),
            onSelected: (status) => _simulateLoading(status),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _WorkspaceStatus.success,
                child: Text('Sucesso'),
              ),
              PopupMenuItem(
                value: _WorkspaceStatus.empty,
                child: Text('Vazio'),
              ),
              PopupMenuItem(
                value: _WorkspaceStatus.error,
                child: Text('Erro'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (useRail)
              _WorkspaceRail(
                selectedPhase: _selectedPhase,
                onSelected: (phase) => setState(() => _selectedPhase = phase),
              ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        useRail ? 18 : 16,
                        10,
                        16,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _WorkspaceHero(),
                          if (!useRail) ...[
                            const SizedBox(height: 16),
                            _PhaseSelector(
                              selectedPhase: _selectedPhase,
                              onSelected: (phase) =>
                                  setState(() => _selectedPhase = phase),
                            ),
                          ],
                          const SizedBox(height: 16),
                          _StatusSummary(status: _status),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      useRail ? 18 : 16,
                      0,
                      16,
                      28,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _WorkspaceStage(
                        phase: _selectedPhase,
                        status: _status,
                        onRetry: _simulateLoading,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceHero extends StatelessWidget {
  const _WorkspaceHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GridColors.primary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: GridColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final metrics = [
            const _HeroMetric('24', 'alunos ativos'),
            const _HeroMetric('86%', 'adesao semanal'),
            const _HeroMetric('R\$ 7,8k', 'receita prevista'),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: GridColors.secondary.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.sports,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jornada personal/aluno',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: GridColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            height: 1.08,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'MVP navegavel com funil, prescricao, acompanhamento, agenda, monetizacao e conteudo.',
                          style: TextStyle(
                            color: Color(0xFFEAE3FF),
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (compact)
                Column(
                  children: [
                    for (final metric in metrics) ...[
                      metric,
                      if (metric != metrics.last) const SizedBox(height: 10),
                    ],
                  ],
                )
              else
                Row(
                  children: [
                    for (final metric in metrics)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: metric,
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: GridColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFEAE3FF), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceRail extends StatelessWidget {
  const _WorkspaceRail({
    required this.selectedPhase,
    required this.onSelected,
  });

  final _WorkspacePhase selectedPhase;
  final ValueChanged<_WorkspacePhase> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 236,
      margin: const EdgeInsets.fromLTRB(16, 10, 0, 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GridColors.primary.withValues(alpha: 0.08)),
      ),
      child: ListView.separated(
        itemCount: _WorkspacePhase.values.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final phase = _WorkspacePhase.values[index];
          return _PhaseNavigationTile(
            phase: phase,
            selected: phase == selectedPhase,
            onTap: () => onSelected(phase),
          );
        },
      ),
    );
  }
}

class _PhaseSelector extends StatelessWidget {
  const _PhaseSelector({
    required this.selectedPhase,
    required this.onSelected,
  });

  final _WorkspacePhase selectedPhase;
  final ValueChanged<_WorkspacePhase> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _WorkspacePhase.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final phase = _WorkspacePhase.values[index];
          final selected = phase == selectedPhase;
          return Semantics(
            button: true,
            selected: selected,
            label: phase.title,
            child: ChoiceChip(
              selected: selected,
              avatar: Icon(
                phase.icon,
                size: 18,
                color: selected ? GridColors.buttonText : GridColors.primary,
              ),
              label: Text(phase.shortTitle),
              labelStyle: TextStyle(
                color: selected ? GridColors.buttonText : GridColors.primary,
                fontWeight: FontWeight.w800,
              ),
              selectedColor: GridColors.primary,
              backgroundColor: GridColors.card,
              side: BorderSide(
                color: selected
                    ? GridColors.primary
                    : GridColors.primary.withValues(alpha: 0.16),
              ),
              onSelected: (_) => onSelected(phase),
            ),
          );
        },
      ),
    );
  }
}

class _PhaseNavigationTile extends StatelessWidget {
  const _PhaseNavigationTile({
    required this.phase,
    required this.selected,
    required this.onTap,
  });

  final _WorkspacePhase phase;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: phase.title,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? GridColors.primary.withValues(alpha: 0.11)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? GridColors.primary.withValues(alpha: 0.22)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                phase.icon,
                color: selected ? GridColors.primary : const Color(0xFF6D647A),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  phase.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? GridColors.textSecondary
                        : const Color(0xFF6D647A),
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusSummary extends StatelessWidget {
  const _StatusSummary({required this.status});

  final _WorkspaceStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      _WorkspaceStatus.loading => GridColors.info,
      _WorkspaceStatus.error => GridColors.error,
      _WorkspaceStatus.empty => GridColors.warning,
      _WorkspaceStatus.success => GridColors.success,
    };
    final label = switch (status) {
      _WorkspaceStatus.loading => 'Carregando dados mockados',
      _WorkspaceStatus.error => 'Erro simulado',
      _WorkspaceStatus.empty => 'Sem registros simulados',
      _WorkspaceStatus.success => 'Jornada pronta para exploracao',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 12),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: GridColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceStage extends StatelessWidget {
  const _WorkspaceStage({
    required this.phase,
    required this.status,
    required this.onRetry,
  });

  final _WorkspacePhase phase;
  final _WorkspaceStatus status;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: switch (status) {
        _WorkspaceStatus.loading => const _LoadingState(),
        _WorkspaceStatus.error => _ErrorState(onRetry: onRetry),
        _WorkspaceStatus.empty => _EmptyState(phase: phase),
        _WorkspaceStatus.success => _SuccessPhase(phase: phase),
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const _StatePanel(
      icon: Icons.hourglass_top,
      title: 'Carregando workspace',
      message: 'Preparando os dados de exemplo para a jornada selecionada.',
      child: Padding(
        padding: EdgeInsets.only(top: 18),
        child: LinearProgressIndicator(minHeight: 6),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _StatePanel(
      icon: Icons.error_outline,
      title: 'Nao foi possivel carregar',
      message:
          'Confira a origem dos dados quando a API for conectada. Neste MVP, toque em tentar novamente para voltar ao mock.',
      child: Padding(
        padding: const EdgeInsets.only(top: 18),
        child: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.phase});

  final _WorkspacePhase phase;

  @override
  Widget build(BuildContext context) {
    return _StatePanel(
      icon: phase.icon,
      title: 'Nenhum registro nesta fase',
      message:
          'Use este estado para validar listas vazias, primeira configuracao e convites ainda nao aceitos.',
      child: Padding(
        padding: const EdgeInsets.only(top: 18),
        child: OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: Text('Criar ${phase.shortTitle.toLowerCase()}'),
        ),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(title),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GridColors.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: GridColors.primary, size: 34),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: GridColors.textSecondary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF6D647A),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _SuccessPhase extends StatelessWidget {
  const _SuccessPhase({required this.phase});

  final _WorkspacePhase phase;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final data = _PhaseData.forPhase(phase);

        return Column(
          key: ValueKey(phase),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PhaseHeader(data: data),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.metrics.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: wide ? 4 : 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: wide ? 1.9 : 1.28,
              ),
              itemBuilder: (context, index) {
                return _MetricCard(metric: data.metrics[index]);
              },
            ),
            const SizedBox(height: 14),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: _PrimaryPanel(data: data)),
                  const SizedBox(width: 14),
                  Expanded(flex: 4, child: _NextActionsPanel(data: data)),
                ],
              )
            else ...[
              _PrimaryPanel(data: data),
              const SizedBox(height: 14),
              _NextActionsPanel(data: data),
            ],
          ],
        );
      },
    );
  }
}

class _PhaseHeader extends StatelessWidget {
  const _PhaseHeader({required this.data});

  final _PhaseData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GridColors.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: GridColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(data.phase.icon, color: GridColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.phase.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GridColors.textSecondary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.description,
                  style: const TextStyle(
                    color: Color(0xFF6D647A),
                    fontSize: 13,
                    height: 1.35,
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GridColors.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(metric.icon, color: GridColors.primary, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GridColors.textSecondary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                metric.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6D647A),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryPanel extends StatelessWidget {
  const _PrimaryPanel({required this.data});

  final _PhaseData data;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: data.primaryTitle,
      icon: data.phase.icon,
      child: Column(
        children: [
          for (final item in data.items)
            _TimelineRow(
              item: item,
              last: item == data.items.last,
            ),
        ],
      ),
    );
  }
}

class _NextActionsPanel extends StatelessWidget {
  const _NextActionsPanel({required this.data});

  final _PhaseData data;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Proximas acoes',
      icon: Icons.task_alt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final action in data.actions) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                minimumSize: const Size.fromHeight(46),
                foregroundColor: GridColors.primary,
                side: BorderSide(
                  color: GridColors.primary.withValues(alpha: 0.18),
                ),
              ),
              onPressed: () {},
              icon: Icon(action.icon, size: 20),
              label: Text(
                action.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (action != data.actions.last) const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
          const _MockNotice(),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GridColors.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: GridColors.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GridColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.item,
    required this.last,
  });

  final _TimelineItem item;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: item.done
                    ? GridColors.success.withValues(alpha: 0.12)
                    : GridColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                item.done ? Icons.check : Icons.schedule,
                color: item.done ? GridColors.success : GridColors.warning,
                size: 18,
              ),
            ),
            if (!last)
              Container(
                width: 2,
                height: 44,
                color: GridColors.primary.withValues(alpha: 0.12),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: GridColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6D647A),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MockNotice extends StatelessWidget {
  const _MockNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GridColors.secondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'Dados mockados: nenhuma chamada HTTP ou alteracao no backend.',
        style: TextStyle(
          color: GridColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    );
  }
}

extension _WorkspacePhaseDetails on _WorkspacePhase {
  String get title {
    return switch (this) {
      _WorkspacePhase.alunos => 'Lista de alunos',
      _WorkspacePhase.convite => 'Convite e link',
      _WorkspacePhase.treino => 'Treino prescrito',
      _WorkspacePhase.execucao => 'Execucao e historico',
      _WorkspacePhase.avaliacao => 'Avaliacao e progresso',
      _WorkspacePhase.agenda => 'Agenda e comunicacao',
      _WorkspacePhase.planos => 'Planos e monetizacao',
      _WorkspacePhase.conteudo => 'Conteudo',
    };
  }

  String get shortTitle {
    return switch (this) {
      _WorkspacePhase.alunos => 'Alunos',
      _WorkspacePhase.convite => 'Convite',
      _WorkspacePhase.treino => 'Treino',
      _WorkspacePhase.execucao => 'Historico',
      _WorkspacePhase.avaliacao => 'Progresso',
      _WorkspacePhase.agenda => 'Agenda',
      _WorkspacePhase.planos => 'Planos',
      _WorkspacePhase.conteudo => 'Conteudo',
    };
  }

  IconData get icon {
    return switch (this) {
      _WorkspacePhase.alunos => Icons.groups_outlined,
      _WorkspacePhase.convite => Icons.link,
      _WorkspacePhase.treino => Icons.assignment_outlined,
      _WorkspacePhase.execucao => Icons.play_circle_outline,
      _WorkspacePhase.avaliacao => Icons.trending_up,
      _WorkspacePhase.agenda => Icons.event_available_outlined,
      _WorkspacePhase.planos => Icons.payments_outlined,
      _WorkspacePhase.conteudo => Icons.video_library_outlined,
    };
  }
}

class _PhaseData {
  const _PhaseData({
    required this.phase,
    required this.description,
    required this.primaryTitle,
    required this.metrics,
    required this.items,
    required this.actions,
  });

  final _WorkspacePhase phase;
  final String description;
  final String primaryTitle;
  final List<_MetricData> metrics;
  final List<_TimelineItem> items;
  final List<_ActionData> actions;

  static _PhaseData forPhase(_WorkspacePhase phase) {
    return switch (phase) {
      _WorkspacePhase.alunos => _PhaseData(
          phase: phase,
          description:
              'Carteira operacional do personal para acompanhar alunos ativos, risco de abandono e pendencias.',
          primaryTitle: 'Alunos em acompanhamento',
          metrics: const [
            _MetricData(Icons.person_add_alt, '6', 'novos convites'),
            _MetricData(Icons.warning_amber, '3', 'alunos em risco'),
            _MetricData(Icons.fitness_center, '18', 'com treino ativo'),
            _MetricData(Icons.chat_bubble_outline, '9', 'mensagens abertas'),
          ],
          items: const [
            _TimelineItem(
                'Ana Souza', 'Hipertrofia, treino A/B atualizado hoje', true),
            _TimelineItem('Bruno Lima',
                'Sem check-in ha 5 dias, revisar aderencia', false),
            _TimelineItem(
                'Carla Mendes', 'Avaliacao fisica vence nesta semana', false),
          ],
          actions: const [
            _ActionData(Icons.search, 'Filtrar alunos por objetivo'),
            _ActionData(Icons.person_add_alt, 'Adicionar aluno manual'),
            _ActionData(Icons.notifications_active, 'Ver alertas de adesao'),
          ],
        ),
      _WorkspacePhase.convite => _PhaseData(
          phase: phase,
          description:
              'Fluxo de entrada do aluno com link compartilhavel, status de aceite e onboarding inicial.',
          primaryTitle: 'Funil de convite',
          metrics: const [
            _MetricData(Icons.link, '12', 'links gerados'),
            _MetricData(Icons.mark_email_read, '8', 'convites aceitos'),
            _MetricData(Icons.pending_actions, '4', 'pendentes'),
            _MetricData(Icons.percent, '67%', 'conversao'),
          ],
          items: const [
            _TimelineItem(
                'Link criado', 'Plano mensal com anamnese inicial', true),
            _TimelineItem(
                'Aluno aceitou', 'Cadastro e termo preenchidos', true),
            _TimelineItem('Onboarding pendente',
                'Responder PAR-Q e objetivo principal', false),
          ],
          actions: const [
            _ActionData(Icons.copy, 'Copiar link de convite'),
            _ActionData(Icons.qr_code_2, 'Exibir QR Code'),
            _ActionData(Icons.send, 'Enviar por WhatsApp'),
          ],
        ),
      _WorkspacePhase.treino => _PhaseData(
          phase: phase,
          description:
              'Prescricao de treinos por blocos, dias da semana, exercicios, series, carga e observacoes.',
          primaryTitle: 'Semana prescrita',
          metrics: const [
            _MetricData(Icons.assignment_turned_in, '21', 'treinos ativos'),
            _MetricData(Icons.timer_outlined, '52 min', 'duracao media'),
            _MetricData(Icons.repeat, '4x', 'frequencia semanal'),
            _MetricData(Icons.edit_note, '7', 'ajustes pendentes'),
          ],
          items: const [
            _TimelineItem('Treino A - inferiores',
                'Agachamento, leg press, stiff e panturrilha', true),
            _TimelineItem('Treino B - superiores',
                'Supino, remada, desenvolvimento e core', true),
            _TimelineItem('Deload programado',
                'Reduzir volume na semana de reavaliacao', false),
          ],
          actions: const [
            _ActionData(Icons.add_task, 'Prescrever novo bloco'),
            _ActionData(Icons.copy_all, 'Duplicar semana anterior'),
            _ActionData(Icons.rule, 'Validar volume por grupo muscular'),
          ],
        ),
      _WorkspacePhase.execucao => _PhaseData(
          phase: phase,
          description:
              'Acompanhamento do aluno durante a execucao, check-ins, cargas realizadas e historico por treino.',
          primaryTitle: 'Historico recente',
          metrics: const [
            _MetricData(Icons.play_circle, '34', 'sessoes registradas'),
            _MetricData(Icons.done_all, '86%', 'aderencia'),
            _MetricData(Icons.local_fire_department, '18k', 'kcal estimadas'),
            _MetricData(Icons.speed, '+12%', 'evolucao de carga'),
          ],
          items: const [
            _TimelineItem(
                'Check-in concluido', 'Treino A registrado com RPE 8', true),
            _TimelineItem('Carga atualizada',
                'Supino reto passou de 42kg para 46kg', true),
            _TimelineItem('Feedback pendente',
                'Aluno marcou dor leve no joelho esquerdo', false),
          ],
          actions: const [
            _ActionData(Icons.history, 'Abrir historico completo'),
            _ActionData(Icons.feedback_outlined, 'Responder feedback'),
            _ActionData(Icons.compare_arrows, 'Comparar cargas'),
          ],
        ),
      _WorkspacePhase.avaliacao => _PhaseData(
          phase: phase,
          description:
              'Evolucao fisica com medidas, fotos, metas, marcadores de saude e progresso por periodo.',
          primaryTitle: 'Progresso do ciclo',
          metrics: const [
            _MetricData(Icons.scale_outlined, '-2,4kg', 'peso no ciclo'),
            _MetricData(Icons.straighten, '-5cm', 'cintura'),
            _MetricData(Icons.show_chart, '+9%', 'forca relativa'),
            _MetricData(Icons.flag, '5/7', 'metas batidas'),
          ],
          items: const [
            _TimelineItem(
                'Avaliacao inicial', 'Fotos, medidas e peso base', true),
            _TimelineItem('Reavaliacao 30 dias',
                'Comparativo positivo em cintura e carga', true),
            _TimelineItem('Nova meta',
                'Definir meta de performance para proximo ciclo', false),
          ],
          actions: const [
            _ActionData(Icons.add_chart, 'Registrar avaliacao'),
            _ActionData(Icons.photo_camera, 'Comparar fotos'),
            _ActionData(Icons.insights, 'Gerar resumo de progresso'),
          ],
        ),
      _WorkspacePhase.agenda => _PhaseData(
          phase: phase,
          description:
              'Agenda de aulas, lembretes, sessoes online, comunicados e mensagens entre personal e aluno.',
          primaryTitle: 'Agenda da semana',
          metrics: const [
            _MetricData(Icons.event_available, '14', 'aulas marcadas'),
            _MetricData(Icons.video_call, '3', 'sessoes online'),
            _MetricData(Icons.chat, '11', 'conversas ativas'),
            _MetricData(Icons.alarm, '5', 'lembretes'),
          ],
          items: const [
            _TimelineItem('Segunda 07:30', 'Ana - treino presencial', true),
            _TimelineItem('Quarta 19:00', 'Bruno - consultoria online', false),
            _TimelineItem('Sexta 08:00', 'Carla - reavaliacao fisica', false),
          ],
          actions: const [
            _ActionData(Icons.calendar_month, 'Abrir calendario'),
            _ActionData(Icons.campaign, 'Enviar comunicado'),
            _ActionData(Icons.message, 'Responder mensagens'),
          ],
        ),
      _WorkspacePhase.planos => _PhaseData(
          phase: phase,
          description:
              'Produtos, planos recorrentes, recebimentos, upgrade, vencimentos e monetizacao do personal.',
          primaryTitle: 'Receita e planos',
          metrics: const [
            _MetricData(Icons.attach_money, 'R\$ 7,8k', 'MRR previsto'),
            _MetricData(Icons.workspace_premium, '5', 'planos premium'),
            _MetricData(Icons.sync_problem, '2', 'pagamentos em atraso'),
            _MetricData(Icons.trending_up, '+18%', 'crescimento mensal'),
          ],
          items: const [
            _TimelineItem(
                'Plano consultoria', '12 alunos ativos a R\$ 199', true),
            _TimelineItem(
                'Plano presencial', '8 alunos ativos a R\$ 449', true),
            _TimelineItem('Renovacao pendente',
                '2 contratos vencem nos proximos 7 dias', false),
          ],
          actions: const [
            _ActionData(Icons.add_card, 'Criar plano'),
            _ActionData(Icons.receipt_long, 'Ver vencimentos'),
            _ActionData(Icons.upgrade, 'Sugerir upgrade'),
          ],
        ),
      _WorkspacePhase.conteudo => _PhaseData(
          phase: phase,
          description:
              'Biblioteca de videos, orientacoes, aulas gravadas, materiais ricos e conteudo enviado ao aluno.',
          primaryTitle: 'Biblioteca ativa',
          metrics: const [
            _MetricData(Icons.video_library, '28', 'videos'),
            _MetricData(Icons.menu_book, '9', 'materiais'),
            _MetricData(Icons.visibility, '74%', 'visualizacao'),
            _MetricData(Icons.bookmark_added, '16', 'salvos por alunos'),
          ],
          items: const [
            _TimelineItem('Tecnica de agachamento',
                'Video anexado ao treino de inferiores', true),
            _TimelineItem(
                'Guia de aquecimento', 'PDF enviado para novos alunos', true),
            _TimelineItem('Modulo mobilidade',
                'Publicar sequencia para dores lombares', false),
          ],
          actions: const [
            _ActionData(Icons.upload_file, 'Enviar conteudo'),
            _ActionData(Icons.playlist_add, 'Criar trilha'),
            _ActionData(Icons.analytics_outlined, 'Ver engajamento'),
          ],
        ),
    };
  }
}

class _MetricData {
  const _MetricData(this.icon, this.value, this.label);

  final IconData icon;
  final String value;
  final String label;
}

class _TimelineItem {
  const _TimelineItem(this.title, this.subtitle, this.done);

  final String title;
  final String subtitle;
  final bool done;
}

class _ActionData {
  const _ActionData(this.icon, this.label);

  final IconData icon;
  final String label;
}
