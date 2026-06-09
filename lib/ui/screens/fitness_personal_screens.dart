import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';

class ExerciciosScreen extends StatelessWidget {
  const ExerciciosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FitnessMetricScreen(
      title: 'Treinos',
      subtitle: 'Plano do aluno e historico de execucao',
      icon: Icons.directions_run,
      heroValue: '32 min',
      heroLabel: 'treino registrado hoje',
      cards: [
        FitnessMetricCard('Forca', '18 min', Icons.fitness_center),
        FitnessMetricCard('Cardio', '14 min', Icons.monitor_heart_outlined),
        FitnessMetricCard('Alongamento', '8 min', Icons.self_improvement),
        FitnessMetricCard('Calorias', '286 kcal', Icons.local_fire_department),
      ],
    );
  }
}

class AtividadeScreen extends StatelessWidget {
  const AtividadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FitnessMetricScreen(
      title: 'Atividade',
      subtitle: 'Movimento diario para acompanhar a rotina',
      icon: Icons.directions_walk,
      heroValue: '7.842',
      heroLabel: 'passos hoje',
      cards: [
        FitnessMetricCard('Distancia', '5,6 km', Icons.route_outlined),
        FitnessMetricCard('Calorias', '421 kcal', Icons.local_fire_department),
        FitnessMetricCard('Tempo ativo', '64 min', Icons.timer_outlined),
        FitnessMetricCard('Meta diaria', '78%', Icons.flag_outlined),
      ],
    );
  }
}

class SonoScreen extends StatelessWidget {
  const SonoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FitnessMetricScreen(
      title: 'Sono',
      subtitle: 'Recuperacao do aluno entre os treinos',
      icon: Icons.bedtime_outlined,
      heroValue: '7h 18m',
      heroLabel: 'sono total',
      cards: [
        FitnessMetricCard('Sono profundo', '2h 04m', Icons.nightlight_round),
        FitnessMetricCard('Sono leve', '4h 32m', Icons.bed_outlined),
        FitnessMetricCard('Acordado', '42 min', Icons.wb_twilight_outlined),
        FitnessMetricCard('Qualidade', 'Boa', Icons.verified_outlined),
      ],
    );
  }
}

class BatimentosScreen extends StatelessWidget {
  const BatimentosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FitnessMetricScreen(
      title: 'Batimentos',
      subtitle: 'Frequencia cardiaca durante treino e repouso',
      icon: Icons.favorite,
      heroValue: '72 bpm',
      heroLabel: 'media em repouso',
      cards: [
        FitnessMetricCard('Minimo', '58 bpm', Icons.south_east),
        FitnessMetricCard('Maximo', '148 bpm', Icons.north_east),
        FitnessMetricCard('Zona cardio', '24 min', Icons.monitor_heart),
        FitnessMetricCard('Recuperacao', 'Normal', Icons.health_and_safety),
      ],
    );
  }
}

class CorpoScreen extends StatelessWidget {
  const CorpoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FitnessMetricScreen(
      title: 'Corpo',
      subtitle: 'Medidas para acompanhar a evolucao fisica',
      icon: Icons.scale_outlined,
      heroValue: '76,4 kg',
      heroLabel: 'peso atual',
      cards: [
        FitnessMetricCard('IMC', '23,8', Icons.analytics_outlined),
        FitnessMetricCard('Gordura', '18%', Icons.pie_chart_outline),
        FitnessMetricCard('Musculo', '34,2 kg', Icons.accessibility_new),
        FitnessMetricCard('Agua', '57%', Icons.water_drop_outlined),
      ],
    );
  }
}

class MetasScreen extends StatelessWidget {
  const MetasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FitnessMetricScreen(
      title: 'Metas',
      subtitle: 'Objetivos combinados entre aluno e personal',
      icon: Icons.flag_outlined,
      heroValue: '4/6',
      heroLabel: 'metas ativas',
      cards: [
        FitnessMetricCard('Passos', '10.000', Icons.directions_walk),
        FitnessMetricCard('Treino', '5x semana', Icons.fitness_center),
        FitnessMetricCard('Sono', '8h', Icons.bedtime_outlined),
        FitnessMetricCard('Peso alvo', '74 kg', Icons.scale_outlined),
      ],
    );
  }
}

class FitnessMetricScreen extends StatelessWidget {
  const FitnessMetricScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.heroValue,
    required this.heroLabel,
    required this.cards,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String heroValue;
  final String heroLabel;
  final List<FitnessMetricCard> cards;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.filterBackground,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: GridColors.filterBackground,
        foregroundColor: GridColors.textSecondary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
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
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFFEAE3FF),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        heroValue,
                        style: const TextStyle(
                          color: GridColors.textPrimary,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        heroLabel,
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
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.sizeOf(context).width >= 720 ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio:
                  MediaQuery.sizeOf(context).width >= 720 ? 1.45 : 1.18,
            ),
            itemBuilder: (context, index) {
              return cards[index];
            },
          ),
        ],
      ),
    );
  }
}

class FitnessMetricCard extends StatelessWidget {
  const FitnessMetricCard(
    this.label,
    this.value,
    this.icon, {
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GridColors.primary.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: GridColors.primary, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
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
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6D647A),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
