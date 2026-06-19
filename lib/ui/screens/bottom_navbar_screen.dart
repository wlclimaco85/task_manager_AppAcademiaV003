import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/customization/dynamic_grid_dynamic_screen.dart';
import 'package:task_manager_flutter/data/services/fitness_360_local_store.dart';
import 'package:task_manager_flutter/data/services/saude_diaria_caller.dart';
import 'package:task_manager_flutter/data/utils/security_matrix.dart';
import 'package:task_manager_flutter/ui/screens/fitness_personal_screens.dart';
import 'package:task_manager_flutter/ui/screens/personal_workspace_screen.dart';
import 'package:task_manager_flutter/ui/screens/sem_acesso_screen.dart';
import 'package:task_manager_flutter/ui/screens/alimento_grid_screen_dynamic.dart';
import 'package:task_manager_flutter/ui/screens/objetivo_grid_screen_dynamic.dart';
import 'package:task_manager_flutter/ui/screens/avaliacao_fisica_grid_screen_dynamic.dart';
import 'package:task_manager_flutter/ui/screens/grupo_muscular_grid_screen_dynamic.dart';
import 'package:task_manager_flutter/ui/screens/modalidade_grid_screen_dynamic.dart';

class BottomNavBarScreen extends StatefulWidget {
  const BottomNavBarScreen({super.key});

  @override
  State<BottomNavBarScreen> createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
  int selectedIndex = 0;

  List<_FitnessNavItem> _navItems(SecurityMatrix sec) {
    return [
      _FitnessNavItem(
        label: 'Inicio',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        screen: _EnhancedFitnessHubScreen(
          modules: _allFitnessActions(sec),
          onOpenModule: (action) => _openFitnessAction(action, sec),
        ),
      ),
      if (sec.canView(AppScreen.exercicios))
        const _FitnessNavItem(
          label: 'Treinos',
          icon: Icons.directions_run_outlined,
          selectedIcon: Icons.directions_run,
          screen: ExerciciosScreen(),
        ),
      if (sec.canView(AppScreen.treinos))
        const _FitnessNavItem(
          label: 'Alunos',
          icon: Icons.groups_outlined,
          selectedIcon: Icons.groups,
          screen: PersonalWorkspaceScreen(),
        ),
      if (sec.canView(AppScreen.atividades))
        const _FitnessNavItem(
          label: 'Atividade',
          icon: Icons.insights_outlined,
          selectedIcon: Icons.insights,
          screen: AtividadeScreen(),
        ),
      if (sec.canView(AppScreen.metas))
        const _FitnessNavItem(
          label: 'Metas',
          icon: Icons.flag_outlined,
          selectedIcon: Icons.flag,
          screen: MetasScreen(),
        ),
      const _FitnessNavItem(
        label: 'Mais',
        icon: Icons.grid_view_outlined,
        selectedIcon: Icons.grid_view_rounded,
        screen: SizedBox.shrink(),
        opensMenu: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sec = SecurityMatrix.current();
    final navItems = _navItems(sec);

    if (!sec.canView(AppScreen.fitness) || navItems.length < 2) {
      return const SemAcessoScreen();
    }

    final safeIndex = selectedIndex.clamp(0, navItems.length - 1);
    final activeItem = navItems[safeIndex];

    return Scaffold(
      body: activeItem.opensMenu ? navItems.first.screen : activeItem.screen,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: GridColors.card,
            boxShadow: [
              BoxShadow(
                color: GridColors.shadow,
                blurRadius: 18,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: safeIndex,
            height: 72,
            backgroundColor: GridColors.card,
            indicatorColor: GridColors.primary.withValues(alpha: 0.13),
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            destinations: [
              for (final item in navItems)
                NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: item.label,
                ),
            ],
            onDestinationSelected: (index) {
              if (navItems[index].opensMenu) {
                _showMenuOptions(context, sec);
                return;
              }
              setState(() => selectedIndex = index);
            },
          ),
        ),
      ),
    );
  }

  void _openFitnessAction(_FitnessAction action, SecurityMatrix sec) {
    switch (action.title) {
      case 'Academias':
        _openDynamicGrid('academia', sec, AppScreen.academias);
        break;
      case 'Personal':
        _openDynamicGrid('personal', sec, AppScreen.personais);
        break;
      case 'Alunos do personal':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PersonalWorkspaceScreen()),
        );
        break;
      case 'Dieta':
        _openDynamicGrid('Dietas', sec, AppScreen.dieta);
        break;
      case 'Suplementos':
        _openDynamicGrid('suplemento', sec, AppScreen.suplementos);
        break;
      case 'Medicamentos':
        _openDynamicGrid('Medicamentos', sec, AppScreen.medicamentos);
        break;
      case 'Exames':
        _openDynamicGrid('exame', sec, AppScreen.exames);
        break;
      case 'Treinos':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExerciciosScreen()),
        );
        break;
      case 'Atividade':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AtividadeScreen()),
        );
        break;
      case 'Sono':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SonoScreen()),
        );
        break;
      case 'Batimentos':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BatimentosScreen()),
        );
        break;
      case 'Corpo':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CorpoScreen()),
        );
        break;
      case 'Metas':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MetasScreen()),
        );
        break;
      case 'Alimentos':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AlimentoScreenDynamic()),
        );
        break;
      case 'Objetivos':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ObjetivoScreenDynamic()),
        );
        break;
      case 'Avaliacao fisica':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AvaliacaoFisicaScreenDynamic()),
        );
        break;
      case 'Grupo muscular':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GrupoMuscularScreenDynamic()),
        );
        break;
      case 'Modalidades':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ModalidadeScreenDynamic()),
        );
        break;
      case 'Sair':
        Navigator.pop(context);
        break;
    }
  }

  void _openDynamicGrid(String telaNome, SecurityMatrix sec, AppScreen screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DynamicGridDynamicScreen(
          key: ValueKey('fitness_dynamic_$telaNome'),
          telaNome: telaNome,
          hasPermission: (permission) =>
              _hasPermissionFor(sec, screen, permission),
          storageKey: 'fitness_dynamic_$telaNome',
        ),
      ),
    );
  }

  bool _hasPermissionFor(
    SecurityMatrix sec,
    AppScreen screen,
    String permission,
  ) {
    switch (permission.toLowerCase()) {
      case 'insert':
      case 'create':
        return sec.canInsert(screen);
      case 'edit':
      case 'update':
        return sec.canUpdate(screen);
      case 'delete':
      case 'remove':
        return sec.canDelete(screen);
      case 'view':
      case 'read':
      default:
        return sec.canView(screen);
    }
  }

  void _showMenuOptions(BuildContext context, SecurityMatrix sec) {
    final sections = [
      _FitnessMenuSection(
        title: 'Treino do aluno',
        actions: [
          if (sec.canView(AppScreen.treinos))
            const _FitnessAction(Icons.groups, 'Alunos do personal'),
          if (sec.canView(AppScreen.exercicios))
            const _FitnessAction(Icons.directions_run, 'Treinos'),
          if (sec.canView(AppScreen.academias))
            const _FitnessAction(Icons.fitness_center, 'Academias'),
          if (sec.canView(AppScreen.personais))
            const _FitnessAction(Icons.person_search, 'Personal'),
        ],
      ),
      _FitnessMenuSection(
        title: 'Saude e cuidado',
        actions: [
          if (sec.canView(AppScreen.dieta))
            const _FitnessAction(Icons.restaurant_menu, 'Dieta'),
          if (sec.canView(AppScreen.alimentos))
            const _FitnessAction(Icons.set_meal_outlined, 'Alimentos'),
          if (sec.canView(AppScreen.objetivos))
            const _FitnessAction(Icons.track_changes_outlined, 'Objetivos'),
          if (sec.canView(AppScreen.suplementos))
            const _FitnessAction(Icons.medication_liquid, 'Suplementos'),
          if (sec.canView(AppScreen.medicamentos))
            const _FitnessAction(
                Icons.medical_services_outlined, 'Medicamentos'),
          if (sec.canView(AppScreen.exames))
            const _FitnessAction(Icons.biotech_outlined, 'Exames'),
        ],
      ),
      _FitnessMenuSection(
        title: 'Evolucao',
        actions: [
          if (sec.canView(AppScreen.atividades))
            const _FitnessAction(Icons.directions_walk, 'Atividade'),
          if (sec.canView(AppScreen.sono))
            const _FitnessAction(Icons.bedtime_outlined, 'Sono'),
          if (sec.canView(AppScreen.batimentos))
            const _FitnessAction(Icons.favorite_border, 'Batimentos'),
          if (sec.canView(AppScreen.corpo))
            const _FitnessAction(Icons.scale_outlined, 'Corpo'),
          if (sec.canView(AppScreen.avaliacaoFisica))
            const _FitnessAction(Icons.assignment_outlined, 'Avaliacao fisica'),
          if (sec.canView(AppScreen.metas))
            const _FitnessAction(Icons.flag_outlined, 'Metas'),
        ],
      ),
      _FitnessMenuSection(
        title: 'Cadastros',
        actions: [
          if (sec.canView(AppScreen.grupoMuscular))
            const _FitnessAction(
                Icons.accessibility_new_outlined, 'Grupo muscular'),
          if (sec.canView(AppScreen.modalidades))
            const _FitnessAction(Icons.sports_outlined, 'Modalidades'),
        ],
      ),
      const _FitnessMenuSection(
        title: 'Conta',
        actions: [
          _FitnessAction(Icons.logout, 'Sair', danger: true),
        ],
      ),
    ].where((section) => section.actions.isNotEmpty).toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.42,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return DecoratedBox(
              decoration: const BoxDecoration(
                color: GridColors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: GridColors.divider,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Hub Fitness',
                    style: TextStyle(
                      color: GridColors.textSecondary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Treinos, saude e evolucao do aluno',
                    style: TextStyle(color: Color(0xFF6D647A), fontSize: 13),
                  ),
                  const SizedBox(height: 22),
                  for (final section in sections) ...[
                    _FitnessSectionView(
                      section: section,
                      onTap: (action) {
                        Navigator.pop(context);
                        _openFitnessAction(action, sec);
                      },
                    ),
                    const SizedBox(height: 18),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<_FitnessAction> _allFitnessActions(SecurityMatrix sec) {
    return [
      if (sec.canView(AppScreen.treinos))
        const _FitnessAction(Icons.groups, 'Alunos do personal'),
      if (sec.canView(AppScreen.exercicios))
        const _FitnessAction(Icons.directions_run, 'Treinos'),
      if (sec.canView(AppScreen.atividades))
        const _FitnessAction(Icons.directions_walk, 'Atividade'),
      if (sec.canView(AppScreen.sono))
        const _FitnessAction(Icons.bedtime_outlined, 'Sono'),
      if (sec.canView(AppScreen.batimentos))
        const _FitnessAction(Icons.favorite_border, 'Batimentos'),
      if (sec.canView(AppScreen.corpo))
        const _FitnessAction(Icons.scale_outlined, 'Corpo'),
      if (sec.canView(AppScreen.metas))
        const _FitnessAction(Icons.flag_outlined, 'Metas'),
      if (sec.canView(AppScreen.academias))
        const _FitnessAction(Icons.fitness_center, 'Academias'),
      if (sec.canView(AppScreen.personais))
        const _FitnessAction(Icons.person_search, 'Personal'),
      if (sec.canView(AppScreen.dieta))
        const _FitnessAction(Icons.restaurant_menu, 'Dieta'),
      if (sec.canView(AppScreen.suplementos))
        const _FitnessAction(Icons.medication_liquid, 'Suplementos'),
      if (sec.canView(AppScreen.medicamentos))
        const _FitnessAction(Icons.medical_services_outlined, 'Medicamentos'),
      if (sec.canView(AppScreen.exames))
        const _FitnessAction(Icons.biotech_outlined, 'Exames'),
      if (sec.canView(AppScreen.alimentos))
        const _FitnessAction(Icons.set_meal_outlined, 'Alimentos'),
      if (sec.canView(AppScreen.objetivos))
        const _FitnessAction(Icons.track_changes_outlined, 'Objetivos'),
      if (sec.canView(AppScreen.avaliacaoFisica))
        const _FitnessAction(Icons.assignment_outlined, 'Avaliacao fisica'),
      if (sec.canView(AppScreen.grupoMuscular))
        const _FitnessAction(
            Icons.accessibility_new_outlined, 'Grupo muscular'),
      if (sec.canView(AppScreen.modalidades))
        const _FitnessAction(Icons.sports_outlined, 'Modalidades'),
    ];
  }
}

// ignore: unused_element
class _FitnessHubScreen extends StatelessWidget {
  const _FitnessHubScreen({
    required this.modules,
    required this.onOpenModule,
  });

  final List<_FitnessAction> modules;
  final ValueChanged<_FitnessAction> onOpenModule;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.filterBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hub Fitness',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: GridColors.textSecondary,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Resumo do aluno, treinos e evolucao',
                      style: TextStyle(color: Color(0xFF6D647A), fontSize: 13),
                    ),
                    SizedBox(height: 18),
                    _TodaySummaryCard(),
                    SizedBox(height: 22),
                    Text(
                      'Atalhos do aluno',
                      style: TextStyle(
                        color: GridColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverGrid.builder(
                itemCount: modules.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.sizeOf(context).width >= 720 ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio:
                      MediaQuery.sizeOf(context).width >= 720 ? 1.55 : 1.12,
                ),
                itemBuilder: (context, index) {
                  final module = modules[index];
                  return _FitnessModuleTile(
                    action: module,
                    onTap: () => onOpenModule(module),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Fitness360Summary>(
      future: Fitness360LocalStore.summary(),
      builder: (context, snapshot) {
        final summary = snapshot.data;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saude do aluno hoje',
                style: TextStyle(
                  color: Color(0xFFEAE3FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryMetric(
                      value: summary == null ? '--' : '${summary.steps}',
                      label: 'passos',
                    ),
                  ),
                  Expanded(
                    child: _SummaryMetric(
                      value: summary == null
                          ? '--'
                          : '${summary.trainingMinutes}m',
                      label: 'treino',
                    ),
                  ),
                  Expanded(
                    child: _SummaryMetric(
                      value:
                          summary == null ? '--' : '${summary.heartRate} bpm',
                      label: 'batimentos',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: summary?.weeklyProgress ?? 0,
                  minHeight: 9,
                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                  valueColor:
                      const AlwaysStoppedAnimation(GridColors.secondary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                summary == null
                    ? 'Carregando metas e habitos...'
                    : 'Sono ${summary.sleepLabel} • Habitos ${summary.habitsDone}/${summary.habitsTotal} • ${summary.points} pontos',
                style: const TextStyle(color: Color(0xFFEAE3FF), fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: GridColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFFEAE3FF), fontSize: 12),
        ),
      ],
    );
  }
}

class _FitnessModuleTile extends StatelessWidget {
  const _FitnessModuleTile({
    required this.action,
    required this.onTap,
  });

  final _FitnessAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = action.danger ? GridColors.error : GridColors.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: GridColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: color, size: 23),
              ),
              Text(
                action.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GridColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FitnessSectionView extends StatelessWidget {
  const _FitnessSectionView({
    required this.section,
    required this.onTap,
  });

  final _FitnessMenuSection section;
  final ValueChanged<_FitnessAction> onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 720 ? 3 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: const TextStyle(
            color: GridColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: section.actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: width >= 720 ? 3.2 : 2.45,
          ),
          itemBuilder: (context, index) {
            return _FitnessMenuButton(
              action: section.actions[index],
              onTap: () => onTap(section.actions[index]),
            );
          },
        ),
      ],
    );
  }
}

class _FitnessMenuButton extends StatelessWidget {
  const _FitnessMenuButton({
    required this.action,
    required this.onTap,
  });

  final _FitnessAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = action.danger ? GridColors.error : GridColors.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: action.danger
              ? GridColors.error.withValues(alpha: 0.07)
              : GridColors.filterBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(action.icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GridColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

class _EnhancedFitnessHubScreen extends StatefulWidget {
  const _EnhancedFitnessHubScreen({
    required this.modules,
    required this.onOpenModule,
  });

  final List<_FitnessAction> modules;
  final ValueChanged<_FitnessAction> onOpenModule;

  @override
  State<_EnhancedFitnessHubScreen> createState() =>
      _EnhancedFitnessHubScreenState();
}

class _EnhancedFitnessHubScreenState extends State<_EnhancedFitnessHubScreen> {
  late Future<_EnhancedHubState> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _EnhancedHubState.load();
  }

  Future<void> _sync() async {
    await Fitness360LocalStore.markSynced();
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.filterBackground,
      body: SafeArea(
        child: FutureBuilder<_EnhancedHubState>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  const Text(
                    'Hub Fitness',
                    style: TextStyle(
                      color: GridColors.textSecondary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: GridColors.card,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nao foi possivel carregar o resumo.',
                          style: TextStyle(
                            color: GridColors.textSecondary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tente sincronizar novamente.',
                          style: TextStyle(color: Color(0xFF6D647A)),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => setState(_reload),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Recarregar'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            final state = snapshot.data;
            if (state == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final visibleCards = state.cardOrder
                .where((id) => !state.hiddenCards.contains(id))
                .toList();

            return RefreshIndicator(
              onRefresh: _sync,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hub Fitness',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: GridColors.textSecondary,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Resumo do aluno, treinos e evolucao',
                              style: TextStyle(
                                color: Color(0xFF6D647A),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sincronizar',
                        onPressed: _sync,
                        icon: const Icon(Icons.sync),
                      ),
                      IconButton(
                        tooltip: 'Editar cards',
                        onPressed: () => _showCardSettings(state),
                        icon: const Icon(Icons.tune),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _EnhancedSyncStatusCard(summary: state.summary),
                  const SizedBox(height: 12),
                  _CommunityParticipationBanner(
                    enabled: state.communityOptIn,
                    onChanged: (value) async {
                      await Fitness360LocalStore.setCommunityOptIn(value);
                      if (mounted) setState(_reload);
                    },
                    onOpenCommunity: () => _openCard('community'),
                  ),
                  const SizedBox(height: 12),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visibleCards.length,
                    onReorder: (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) newIndex--;
                      final reordered = [...visibleCards];
                      final moved = reordered.removeAt(oldIndex);
                      reordered.insert(newIndex, moved);
                      final hidden = state.cardOrder
                          .where(state.hiddenCards.contains)
                          .toList();
                      await Fitness360LocalStore.saveHomeCardOrder(
                        [...reordered, ...hidden],
                      );
                      setState(_reload);
                    },
                    itemBuilder: (context, index) {
                      final cardId = visibleCards[index];
                      return Padding(
                        key: ValueKey(cardId),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _HomeHealthCard(
                          cardId: cardId,
                          summary: state.summary,
                          onOpen: _openCard,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Atalhos do aluno',
                    style: TextStyle(
                      color: GridColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.modules.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.sizeOf(context).width >= 720 ? 4 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio:
                          MediaQuery.sizeOf(context).width >= 720 ? 1.55 : 1.12,
                    ),
                    itemBuilder: (context, index) {
                      final module = widget.modules[index];
                      return _FitnessModuleTile(
                        action: module,
                        onTap: () => widget.onOpenModule(module),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openCard(String cardId) {
    final title = switch (cardId) {
      'sleep' => 'Sono',
      'workout' => 'Treinos',
      'heart' => 'Batimentos',
      'body' => 'Corpo',
      'goals' => 'Metas',
      'community' => 'Comunidade',
      _ => 'Atividade',
    };
    if (cardId == 'community') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ComunidadeScreen()),
      );
      return;
    }
    final matches = widget.modules.where((module) => module.title == title);
    if (matches.isNotEmpty) {
      widget.onOpenModule(matches.first);
    }
  }

  Future<void> _showCardSettings(_EnhancedHubState state) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        var hiddenCards = {...state.hiddenCards};
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DecoratedBox(
              decoration: const BoxDecoration(
                color: GridColors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  const Text(
                    'Cards da home',
                    style: TextStyle(
                      color: GridColors.textSecondary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Arraste os cards na home e oculte o que nao fizer sentido para o aluno.',
                    style: TextStyle(color: Color(0xFF6D647A)),
                  ),
                  const SizedBox(height: 12),
                  for (final cardId in state.cardOrder)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: !hiddenCards.contains(cardId),
                      title: Text(_homeCardTitle(cardId)),
                      onChanged: (value) async {
                        await Fitness360LocalStore.setHomeCardHidden(
                          cardId,
                          !value,
                        );
                        setSheetState(() {
                          if (value) {
                            hiddenCards.remove(cardId);
                          } else {
                            hiddenCards.add(cardId);
                          }
                        });
                        if (mounted) setState(_reload);
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EnhancedHubState {
  const _EnhancedHubState({
    required this.summary,
    required this.communityOptIn,
    required this.cardOrder,
    required this.hiddenCards,
  });

  final Fitness360Summary summary;
  final bool communityOptIn;
  final List<String> cardOrder;
  final Set<String> hiddenCards;

  static Future<_EnhancedHubState> load() async {
    // Tenta a API REAL primeiro; em caso de null (offline/erro) cai no store local.
    final resumoApi = await SaudeDiariaCaller().fetchResumo();
    final summary = resumoApi != null
        ? Fitness360Summary.fromApi(resumoApi)
        : await Fitness360LocalStore.summary();

    return _EnhancedHubState(
      summary: summary,
      communityOptIn: await Fitness360LocalStore.communityOptIn(),
      cardOrder: await Fitness360LocalStore.homeCardOrder(),
      hiddenCards: await Fitness360LocalStore.hiddenHomeCards(),
    );
  }
}

class _CommunityParticipationBanner extends StatelessWidget {
  const _CommunityParticipationBanner({
    required this.enabled,
    required this.onChanged,
    required this.onOpenCommunity,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenCommunity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GridColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_outlined, color: GridColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  enabled
                      ? 'Participando da comunidade local'
                      : 'Participacao comunitaria desligada',
                  style: const TextStyle(
                    color: GridColors.textSecondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Chip(
                label: Text(enabled ? 'Opt-in ativo' : 'Opt-in off'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            enabled
                ? 'Desafios, ranking e conquistas ficam visiveis para o aluno na comunidade local.'
                : 'Desligado por padrao. Ative o opt-in para liberar desafios e ranking local.',
            style: const TextStyle(color: Color(0xFF6D647A)),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: enabled,
            title: const Text('Permitir participacao local'),
            subtitle: const Text('Controle de privacidade por aluno.'),
            onChanged: onChanged,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onOpenCommunity,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir comunidade local'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedSyncStatusCard extends StatelessWidget {
  const _EnhancedSyncStatusCard({required this.summary});

  final Fitness360Summary summary;

  @override
  Widget build(BuildContext context) {
    final minutes = DateTime.now().difference(summary.lastSyncAt).inMinutes;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Saude do aluno hoje',
                  style: TextStyle(
                    color: Color(0xFFEAE3FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Chip(
                label: Text('${minutes}m'),
                avatar: const Icon(Icons.sync, size: 16),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  value: '${summary.steps}',
                  label: 'passos',
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  value: '${summary.trainingMinutes}m',
                  label: 'treino',
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  value: '${summary.heartRate} bpm',
                  label: 'batimentos',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: summary.weeklyProgress,
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              valueColor: const AlwaysStoppedAnimation(GridColors.secondary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sono ${summary.sleepLabel} | Habitos ${summary.habitsDone}/${summary.habitsTotal} | ${summary.points} pontos | ${summary.syncSource}',
            style: const TextStyle(color: Color(0xFFEAE3FF), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _HomeHealthCard extends StatelessWidget {
  const _HomeHealthCard({
    required this.cardId,
    required this.summary,
    required this.onOpen,
  });

  final String cardId;
  final Fitness360Summary summary;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final data = _homeCardData(cardId, summary);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => onOpen(cardId),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GridColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: data.color.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: data.color.withValues(alpha: 0.12),
              child: Icon(data.icon, color: data.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      color: GridColors.textSecondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6D647A),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.drag_handle, color: Color(0xFF6D647A)),
          ],
        ),
      ),
    );
  }
}

class _HomeCardData {
  const _HomeCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

_HomeCardData _homeCardData(String cardId, Fitness360Summary summary) {
  return switch (cardId) {
    'sleep' => _HomeCardData(
        title: 'Sono ${summary.sleepScore}/100',
        subtitle: '${summary.sleepLabel} com sugestoes de recuperacao',
        icon: Icons.bedtime_outlined,
        color: const Color(0xFF32117A),
      ),
    'workout' => _HomeCardData(
        title: 'Treino ${summary.trainingMinutes}m',
        subtitle:
            '${summary.activeCalories} kcal | ${summary.distanceKm.toStringAsFixed(1)} km',
        icon: Icons.directions_run,
        color: GridColors.secondary,
      ),
    'heart' => _HomeCardData(
        title: 'Cardio ${summary.cardioScore}/100',
        subtitle:
            '${summary.heartRate} bpm | SpO2 ${summary.spo2}% | stress ${summary.stress}',
        icon: Icons.favorite_border,
        color: GridColors.error,
      ),
    'body' => _HomeCardData(
        title: 'Corpo ${summary.weightKg.toStringAsFixed(1)} kg',
        subtitle:
            'Meta ${summary.weightGoalKg.toStringAsFixed(1)} kg | score ${summary.bodyScore}',
        icon: Icons.scale_outlined,
        color: GridColors.info,
      ),
    'goals' => _HomeCardData(
        title: 'Metas e habitos',
        subtitle:
            '${summary.habitsDone}/${summary.habitsTotal} feitos | ${summary.points} pontos',
        icon: Icons.flag_outlined,
        color: GridColors.success,
      ),
    'community' => const _HomeCardData(
        title: 'Comunidade',
        subtitle: 'Ranking opcional, desafios e conquistas',
        icon: Icons.groups_outlined,
        color: GridColors.primary,
      ),
    _ => _HomeCardData(
        title: 'Passos ${summary.steps}',
        subtitle: 'Readiness ${summary.readiness}/100 | progresso semanal',
        icon: Icons.directions_walk,
        color: GridColors.primary,
      ),
  };
}

String _homeCardTitle(String cardId) => switch (cardId) {
      'sleep' => 'Sono',
      'workout' => 'Treino',
      'heart' => 'Sinais vitais',
      'body' => 'Corpo e balanca',
      'goals' => 'Metas e habitos',
      'community' => 'Comunidade',
      _ => 'Passos e atividade',
    };

class _FitnessNavItem {
  const _FitnessNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
    this.opensMenu = false,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
  final bool opensMenu;
}

class _FitnessMenuSection {
  const _FitnessMenuSection({
    required this.title,
    required this.actions,
  });

  final String title;
  final List<_FitnessAction> actions;
}

class _FitnessAction {
  const _FitnessAction(
    this.icon,
    this.title, {
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final bool danger;
}
