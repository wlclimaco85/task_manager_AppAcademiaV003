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
      subtitle: 'Registro de atividade, treino e historico do aluno',
      icon: Icons.directions_run,
      primaryActionLabel: 'Registrar treino',
      emptyLabel: 'Nenhum treino registrado ainda.',
      defaultTitle: 'Treino funcional',
      defaultValue: '35 min',
      defaultNote: 'Forca, cardio ou mobilidade',
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
      subtitle: 'Passos, tempo ativo e historico diario',
      icon: Icons.directions_walk,
      primaryActionLabel: 'Registrar atividade',
      emptyLabel: 'Nenhuma atividade registrada ainda.',
      defaultTitle: 'Caminhada',
      defaultValue: '8000 passos',
      defaultNote: 'Movimento diario do aluno',
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
      subtitle: 'Sono, check-in diario e agenda de recuperacao',
      icon: Icons.bedtime_outlined,
      primaryActionLabel: 'Registrar sono',
      emptyLabel: 'Nenhum registro de sono ainda.',
      defaultTitle: 'Sono principal',
      defaultValue: '7h 30m',
      defaultNote: 'Qualidade, despertares e recuperacao',
      extraCards: [
        _InfoCard(
          icon: Icons.water_drop_outlined,
          title: 'Agua',
          description: 'Use Habitos para registrar hidratacao diaria.',
        ),
        _InfoCard(
          icon: Icons.medication_outlined,
          title: 'Medicamentos',
          description: 'Lembretes devem respeitar prescricao e horario.',
        ),
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
      title: 'Integracoes de Saude',
      subtitle: 'Spike Health Connect, Apple Health e importacao manual',
      icon: Icons.favorite,
      primaryActionLabel: 'Registrar manualmente',
      emptyLabel: 'Nenhuma leitura cardiaca registrada.',
      defaultTitle: 'Frequencia em repouso',
      defaultValue: '72 bpm',
      defaultNote: 'Importacao manual ate aprovacao do spike',
      extraCards: [
        _InfoCard(
          icon: Icons.health_and_safety_outlined,
          title: 'Consentimento',
          description: 'Integracoes exigem opt-in claro e revogacao simples.',
        ),
        _InfoCard(
          icon: Icons.sync_outlined,
          title: 'Health Connect / Apple Health',
          description:
              'Fase tecnica antes de salvar dados sensiveis no backend.',
        ),
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
      subtitle: 'Peso, IMC, medidas, composicao corporal e exames',
      icon: Icons.scale_outlined,
      primaryActionLabel: 'Registrar medida',
      emptyLabel: 'Nenhuma medida corporal registrada.',
      defaultTitle: 'Peso',
      defaultValue: '76,4 kg',
      defaultNote: 'IMC, gordura, musculo ou observacao de exame',
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
      subtitle: 'Gamificacao, ranking opcional e comunidade',
      icon: Icons.emoji_events_outlined,
      primaryActionLabel: 'Criar meta',
      emptyLabel: 'Nenhuma meta criada ainda.',
      defaultTitle: 'Treinar 5x na semana',
      defaultValue: '0/5',
      defaultNote: 'Ranking sempre opcional e com privacidade por aluno.',
      extraCards: [
        _InfoCard(
          icon: Icons.lock_outline,
          title: 'Privacidade',
          description: 'Ranking deve ser opt-in, nunca expor saude por padrao.',
        ),
        _InfoCard(
          icon: Icons.groups_outlined,
          title: 'Comunidade',
          description:
              'Mural por academia/aluno, moderado por perfil autorizado.',
        ),
      ],
    );
  }
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
    this.extraCards = const [],
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
  final List<Widget> extraCards;

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
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
            children: [
              _HeroCard(
                title: widget.subtitle,
                value: records.isEmpty ? '--' : records.first.value,
                label:
                    records.isEmpty ? widget.emptyLabel : records.first.title,
                icon: widget.icon,
              ),
              const SizedBox(height: 18),
              ...widget.extraCards,
              if (widget.extraCards.isNotEmpty) const SizedBox(height: 6),
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GridColors.secondary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: GridColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: GridColors.textSecondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Color(0xFF6D647A)),
                ),
              ],
            ),
          ),
        ],
      ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
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
