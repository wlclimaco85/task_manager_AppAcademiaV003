import 'package:task_manager_flutter/ui/screens/fitness/meu_perfil_screen.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/fitness_graficos_hub.dart';
import 'package:task_manager_flutter/ui/widgets/versao_app_label.dart';
import 'package:task_manager_flutter/ui/widgets/fitness_menu_page.dart';
import 'package:task_manager_flutter/ui/screens/fitness/selecionar_aluno_avaliacao_screen.dart';
import 'package:task_manager_flutter/ui/widgets/cadastro_inicial_banner.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/utils/fitness_access.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/customization/dynamic_grid_dynamic_screen.dart';
import 'package:task_manager_flutter/data/services/fitness_360_local_store.dart';
import 'package:task_manager_flutter/data/services/fitness_resumo_hoje_service.dart';
import 'package:task_manager_flutter/data/services/checkin_diario_caller.dart';
import 'package:task_manager_flutter/data/services/hidratacao_caller.dart';
import 'package:task_manager_flutter/data/services/saude_diaria_caller.dart';
import 'package:task_manager_flutter/data/services/aviso_falta_repository.dart';
import 'package:task_manager_flutter/data/utils/security_matrix.dart';
import 'package:task_manager_flutter/ui/screens/fitness_personal_screens.dart';
import 'package:task_manager_flutter/ui/screens/personal_workspace_screen.dart';
import 'package:task_manager_flutter/ui/screens/sem_acesso_screen.dart';
import 'package:task_manager_flutter/ui/screens/alimento_grid_screen_dynamic.dart';
import 'package:task_manager_flutter/ui/screens/objetivo_grid_screen_dynamic.dart';
import 'package:task_manager_flutter/ui/screens/grupo_muscular_grid_screen_dynamic.dart';
import 'package:task_manager_flutter/ui/screens/modalidade_grid_screen_dynamic.dart';
import 'package:task_manager_flutter/ui/screens/fitness/treinos_hub_screen.dart';
import 'package:task_manager_flutter/ui/screens/fitness/avaliacao_fisica_pro_screen.dart';
import 'package:task_manager_flutter/ui/screens/fitness/nutricao_protocolos_hub_screen.dart';
import 'package:task_manager_flutter/ui/screens/fitness/contratar_profissional_screen.dart';
import 'package:task_manager_flutter/ui/screens/fitness/exames_clinicos_hub_screen.dart';
import 'package:task_manager_flutter/ui/screens/fitness/aviso_falta_screen.dart';
import 'package:task_manager_flutter/ui/screens/fitness/agenda_compartilhada_screen.dart';
import 'package:task_manager_flutter/ui/screens/fitness/financeiro_academia_screen.dart';

class BottomNavBarScreen extends StatefulWidget {
  const BottomNavBarScreen({super.key});

  @override
  State<BottomNavBarScreen> createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
  int selectedIndex = 0;
  bool _alunoTemPersonal = false;

  @override
  void initState() {
    super.initState();
    _carregarVinculoPersonal();
  }

  Future<void> _carregarVinculoPersonal() async {
    if (podeGerenciarAlunos() || AuthUtility.userInfo.login == null) return;
    final vinculado = await AvisoFaltaRepository().temVinculo();
    if (mounted && vinculado != _alunoTemPersonal) {
      setState(() => _alunoTemPersonal = vinculado);
    }
  }

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
      if (podeGerenciarAlunos() && sec.canView(AppScreen.treinos))
        const _FitnessNavItem(
          label: 'Alunos',
          icon: Icons.groups_outlined,
          selectedIcon: Icons.groups,
          screen: PersonalWorkspaceScreen(),
        ),
      if (sec.canView(AppScreen.exercicios))
        const _FitnessNavItem(
          label: 'Treinos',
          icon: Icons.fitness_center_outlined,
          selectedIcon: Icons.fitness_center,
          screen: TreinosHubScreen(),
        ),
      if (sec.canView(AppScreen.atividades))
        const _FitnessNavItem(
          label: 'Atividade',
          icon: Icons.insights_outlined,
          selectedIcon: Icons.insights,
          screen: AtividadeScreen(),
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
    final width = MediaQuery.sizeOf(context).width;
    final isDesktopOrWeb = width >= 800;

    if (isDesktopOrWeb) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: safeIndex,
              onDestinationSelected: (index) {
                if (navItems[index].opensMenu) {
                  _showMenuOptions(context, sec);
                  return;
                }
                setState(() => selectedIndex = index);
              },
              backgroundColor: context.appSurface,
              indicatorColor: GridColors.primarySubtle,
              selectedIconTheme: IconThemeData(color: GridColors.primary),
              unselectedIconTheme:
                  IconThemeData(color: context.appTextSecondary),
              selectedLabelTextStyle: TextStyle(
                color: GridColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: context.appTextSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/logo_eu_atleta.png',
                        width: 44,
                        height: 44,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Eu Atleta',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: GridColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: [
                for (final item in navItems)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  ),
              ],
            ),
            VerticalDivider(
                thickness: 1, width: 1, color: context.appBorder),
            Expanded(
              child: activeItem.opensMenu
                  ? navItems.first.screen
                  : activeItem.screen,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: activeItem.opensMenu ? navItems.first.screen : activeItem.screen,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: context.appSurface,
            boxShadow: [
              BoxShadow(
                color: GridColors.shadow,
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: safeIndex,
            height: 68,
            backgroundColor: context.appSurface,
            indicatorColor: GridColors.primarySubtle,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              for (final item in navItems)
                NavigationDestination(
                  icon: Icon(item.icon, color: context.appTextSecondary),
                  selectedIcon:
                      Icon(item.selectedIcon, color: GridColors.primary),
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
      case 'Meu perfil':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FitnessMenuPage(child: MeuPerfilScreen())));
        break;
      case 'Academias':
        _openDynamicGrid('academia', sec, AppScreen.academias);
        break;
      case 'Personal':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const FitnessMenuPage(child: ContratarProfissionalScreen())),
        );
        break;
      case 'Alunos do personal':
        if (!podeGerenciarAlunos()) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FitnessMenuPage(child: PersonalWorkspaceScreen())),
        );
        break;
      case 'Aviso de falta':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FitnessMenuPage(child: AvisoFaltaScreen())),
        );
        break;
      case 'Agenda':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const FitnessMenuPage(
                  child: AgendaCompartilhadaScreen())),
        );
        break;
      case 'Financeiro':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const FitnessMenuPage(
                  child: FinanceiroAcademiaScreen())),
        );
        break;
      case 'Dieta':
      case 'Suplementos':
      case 'Medicamentos':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const FitnessMenuPage(child: NutricaoProtocolosHubScreen())),
        );
        break;

      case 'Exames':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const FitnessMenuPage(child: ExamesClinicosHubScreen())),
        );
        break;
      case 'Treinos':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FitnessMenuPage(child: TreinosHubScreen())),
        );
        break;
      case 'Atividade':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FitnessMenuPage(child: AtividadeScreen())),
        );
        break;
      case 'Sono':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FitnessMenuPage(child: SonoScreen())),
        );
        break;
      case 'Batimentos':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FitnessMenuPage(child: BatimentosScreen())),
        );
        break;
      case 'Corpo':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FitnessMenuPage(child: CorpoScreen())),
        );
        break;
      case 'Metas':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FitnessMenuPage(child: MetasScreen())),
        );
        break;
      case 'Alimentos':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FitnessMenuPage(child: AlimentoScreenDynamic())),
        );
        break;
      case 'Objetivos':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FitnessMenuPage(child: ObjetivoScreenDynamic())),
        );
        break;
      case 'Avaliacao fisica':
        // Personal escolhe de quem e a avaliacao (dele ou de um aluno).
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => podeGerenciarAlunos(AuthUtility.session.value)
                  ? const FitnessMenuPage(child: SelecionarAlunoAvaliacaoScreen())
                  : const FitnessMenuPage(child: AvaliacaoFisicaProScreen())),
        );
        break;
      case 'Grupo muscular':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FitnessMenuPage(child: GrupoMuscularScreenDynamic())),
        );
        break;
      case 'Modalidades':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FitnessMenuPage(child: ModalidadeScreenDynamic())),
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
        builder: (_) => FitnessMenuPage(child: DynamicGridDynamicScreen(
          key: ValueKey('fitness_dynamic_$telaNome'),
          telaNome: telaNome,
          hasPermission: (permission) =>
              _hasPermissionFor(sec, screen, permission),
          storageKey: 'fitness_dynamic_$telaNome',
        )),
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

  bool _temPersonalVinculado() {
    return true;
  }

  void _showMenuOptions(BuildContext context, SecurityMatrix sec) {
    final sections = [
      _FitnessMenuSection(
        title: 'Treino do aluno',
        actions: [
          if (podeGerenciarAlunos() && sec.canView(AppScreen.treinos))
            const _FitnessAction(Icons.groups, 'Alunos do personal'),
          if (sec.canView(AppScreen.exercicios))
            const _FitnessAction(Icons.directions_run, 'Treinos'),
          const _FitnessAction(Icons.calendar_month_outlined, 'Agenda'),
          const _FitnessAction(Icons.event_busy_outlined, 'Aviso de falta'),
          if (ehAcademia())
            const _FitnessAction(Icons.payments_outlined, 'Financeiro'),
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
            const _FitnessAction(Icons.directions_run, 'Atividade'),
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
          _FitnessAction(Icons.manage_accounts_outlined, 'Meu perfil'),
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
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                        color: context.appBorder,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Hub Fitness',
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Treinos, saude e evolucao do aluno',
                    style: TextStyle(color: context.appTextSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 22),
                  const CadastroInicialBanner(),
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
                  const SizedBox(height: 8),
                  const Center(child: VersaoAppLabel()),
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
      const _FitnessAction(Icons.manage_accounts_outlined, 'Meu perfil'),
      if (podeGerenciarAlunos() && sec.canView(AppScreen.treinos))
        const _FitnessAction(Icons.groups, 'Alunos do personal'),
      if (sec.canView(AppScreen.exercicios))
        const _FitnessAction(Icons.directions_run, 'Treinos'),
      const _FitnessAction(Icons.calendar_month_outlined, 'Agenda'),
      const _FitnessAction(Icons.event_busy_outlined, 'Aviso de falta'),
      if (ehAcademia())
        const _FitnessAction(Icons.payments_outlined, 'Financeiro'),
      if (sec.canView(AppScreen.atividades))
        const _FitnessAction(Icons.directions_run, 'Atividade'),
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
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hub Fitness',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Resumo do aluno, treinos e evolucao',
                      style: TextStyle(color: context.appTextSecondary, fontSize: 13),
                    ),
                    SizedBox(height: 18),
                    _TodaySummaryCard(),
                    SizedBox(height: 22),
                    Text(
                      'Atalhos do aluno',
                      style: TextStyle(
                        color: context.appText,
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
      future: FitnessResumoHojeService.carregar(),
      builder: (context, snapshot) {
        final summary = snapshot.data;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: GridColors.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
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
                      value: summary == null
                          ? '--'
                          : '${summary.distanceKm.toStringAsFixed(1)} km',
                      label: 'distancia',
                    ),
                  ),
                  Expanded(
                    child: _SummaryMetric(
                      value: summary == null
                          ? '--'
                          : '${summary.trainingMinutes}m',
                      label: 'tempo ativo',
                    ),
                  ),
                  Expanded(
                    child: _SummaryMetric(
                      value: summary == null
                          ? '--'
                          : '${summary.activeCalories} kcal',
                      label: 'calorias',
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
                      AlwaysStoppedAnimation(GridColors.secondary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                summary == null
                    ? 'Carregando metas e habitos...'
                    : 'Atividade hoje ${summary.distanceKm.toStringAsFixed(1)} km • Musculação ${summary.strengthTrainingMinutes}m • Habitos ${summary.habitsDone}/${summary.habitsTotal}',
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
          style: TextStyle(
            color: context.appText,
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
    final visual = _ShortcutVisual.forAction(action);
    final color = visual.accent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.10 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -22,
              top: -26,
              child: Container(
                width: 122,
                height: 122,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: isDark ? 0.13 : 0.08),
                ),
              ),
            ),
            Positioned(
              right: 18,
              top: 17,
              child: Icon(
                visual.motif,
                color: color.withValues(alpha: isDark ? 0.34 : 0.22),
                size: 58,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: isDark ? 0.92 : 0.18),
                          visual.secondary.withValues(
                            alpha: isDark ? 0.70 : 0.11,
                          ),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: color.withValues(alpha: isDark ? 0.42 : 0.25),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          visual.icon,
                          color: isDark ? Colors.white : color,
                          size: 30,
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: visual.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: context.appSurface,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    action.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
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

class _ShortcutVisual {
  const _ShortcutVisual({
    required this.icon,
    required this.motif,
    required this.accent,
    required this.secondary,
  });

  final IconData icon;
  final IconData motif;
  final Color accent;
  final Color secondary;

  factory _ShortcutVisual.forAction(_FitnessAction action) {
    if (action.danger) {
      return const _ShortcutVisual(
        icon: Icons.logout_rounded,
        motif: Icons.waving_hand_outlined,
        accent: Color(0xFFE05263),
        secondary: Color(0xFFFFB74D),
      );
    }

    return switch (action.title) {
      'Meu perfil' => const _ShortcutVisual(
          icon: Icons.account_circle_rounded,
          motif: Icons.badge_outlined,
          accent: Color(0xFF7C4DFF),
          secondary: Color(0xFFB388FF),
        ),
      'Alunos do personal' => const _ShortcutVisual(
          icon: Icons.diversity_1_rounded,
          motif: Icons.groups_2_outlined,
          accent: Color(0xFF00897B),
          secondary: Color(0xFF4DB6AC),
        ),
      'Treinos' => const _ShortcutVisual(
          icon: Icons.fitness_center_rounded,
          motif: Icons.bolt_rounded,
          accent: Color(0xFFE65100),
          secondary: Color(0xFFFFB300),
        ),
      'Agenda' => const _ShortcutVisual(
          icon: Icons.calendar_month_rounded,
          motif: Icons.access_time_filled_rounded,
          accent: Color(0xFF1565C0),
          secondary: Color(0xFF42A5F5),
        ),
      'Aviso de falta' => const _ShortcutVisual(
          icon: Icons.event_busy_rounded,
          motif: Icons.notifications_paused_outlined,
          accent: Color(0xFFE53935),
          secondary: Color(0xFFFF8A80),
        ),
      'Atividade' => const _ShortcutVisual(
          icon: Icons.directions_run_rounded,
          motif: Icons.insights_rounded,
          accent: Color(0xFF00A77A),
          secondary: Color(0xFF80CBC4),
        ),
      'Corpo' => const _ShortcutVisual(
          icon: Icons.monitor_heart_rounded,
          motif: Icons.favorite_border_rounded,
          accent: Color(0xFFD81B60),
          secondary: Color(0xFFF48FB1),
        ),
      'Metas' => const _ShortcutVisual(
          icon: Icons.flag_circle_rounded,
          motif: Icons.emoji_events_outlined,
          accent: Color(0xFFFF8F00),
          secondary: Color(0xFFFFD54F),
        ),
      'Dieta' => const _ShortcutVisual(
          icon: Icons.restaurant_menu_rounded,
          motif: Icons.eco_outlined,
          accent: Color(0xFF43A047),
          secondary: Color(0xFFAED581),
        ),
      'Alimentos' => const _ShortcutVisual(
          icon: Icons.set_meal_rounded,
          motif: Icons.spa_outlined,
          accent: Color(0xFF689F38),
          secondary: Color(0xFFCDDC39),
        ),
      'Objetivos' => const _ShortcutVisual(
          icon: Icons.track_changes_rounded,
          motif: Icons.ads_click_rounded,
          accent: Color(0xFF5E35B1),
          secondary: Color(0xFFB39DDB),
        ),
      'Suplementos' => const _ShortcutVisual(
          icon: Icons.medication_liquid_rounded,
          motif: Icons.water_drop_outlined,
          accent: Color(0xFF00ACC1),
          secondary: Color(0xFF80DEEA),
        ),
      'Medicamentos' => const _ShortcutVisual(
          icon: Icons.medical_services_rounded,
          motif: Icons.health_and_safety_outlined,
          accent: Color(0xFFEF6C00),
          secondary: Color(0xFFFFCC80),
        ),
      'Exames' => const _ShortcutVisual(
          icon: Icons.biotech_rounded,
          motif: Icons.science_outlined,
          accent: Color(0xFF00838F),
          secondary: Color(0xFF80CBC4),
        ),
      'Avaliacao fisica' => const _ShortcutVisual(
          icon: Icons.fact_check_rounded,
          motif: Icons.query_stats_rounded,
          accent: Color(0xFF3949AB),
          secondary: Color(0xFF9FA8DA),
        ),
      'Grupo muscular' => const _ShortcutVisual(
          icon: Icons.accessibility_new_rounded,
          motif: Icons.fitness_center_outlined,
          accent: Color(0xFF00897B),
          secondary: Color(0xFF80CBC4),
        ),
      'Modalidades' => const _ShortcutVisual(
          icon: Icons.sports_handball_rounded,
          motif: Icons.sports_score_outlined,
          accent: Color(0xFF6D4C41),
          secondary: Color(0xFFFFCC80),
        ),
      'Academias' => const _ShortcutVisual(
          icon: Icons.apartment_rounded,
          motif: Icons.location_city_outlined,
          accent: Color(0xFF455A64),
          secondary: Color(0xFF90A4AE),
        ),
      'Personal' => const _ShortcutVisual(
          icon: Icons.person_search_rounded,
          motif: Icons.stars_rounded,
          accent: Color(0xFF8E24AA),
          secondary: Color(0xFFE1BEE7),
        ),
      'Financeiro' => const _ShortcutVisual(
          icon: Icons.account_balance_wallet_rounded,
          motif: Icons.payments_outlined,
          accent: Color(0xFF2E7D32),
          secondary: Color(0xFFA5D6A7),
        ),
      _ => _ShortcutVisual(
          icon: action.icon,
          motif: Icons.auto_awesome_outlined,
          accent: GridColors.primary,
          secondary: const Color(0xFF80CBC4),
        ),
    };
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
          style: TextStyle(
            color: context.appText,
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
              : context.appSurfaceAlt,
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
                  style: TextStyle(
                    color: context.appText,
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
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: FutureBuilder<_EnhancedHubState>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  Text(
                    'Hub Fitness',
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nao foi possivel carregar o resumo.',
                          style: TextStyle(
                            color: context.appText,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tente sincronizar novamente.',
                          style: TextStyle(color: context.appTextSecondary),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hub Fitness',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.appText,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Resumo do aluno, treinos e evolucao',
                              style: TextStyle(
                                color: context.appTextSecondary,
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
                  FitnessGraficosHub(key: ObjectKey(state)),
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
                  Text(
                    'Atalhos do aluno',
                    style: TextStyle(
                      color: context.appText,
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
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  Text(
                    'Cards da home',
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Arraste os cards na home e oculte o que nao fizer sentido para o aluno.',
                    style: TextStyle(color: context.appTextSecondary),
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
    final Fitness360Summary baseSummary;
    if (resumoApi != null) {
      // Hidratação e check-in completam os hábitos reais do dia.
      final hidratacaoFuture = HidratacaoCaller().fetchResumo();
      final checkinFuture = CheckinDiarioCaller().fetchResumo();
      final hidratacao = await hidratacaoFuture;
      final checkin = await checkinFuture;
      baseSummary = Fitness360Summary.fromApi(
        resumoApi,
        hidratacaoMetaAtingida: hidratacaoMetaAtingida(hidratacao),
        checkinFeito: (checkin?.humor ?? '').trim().isNotEmpty,
      );
    } else {
      baseSummary = await Fitness360LocalStore.summary();
    }
    final summary =
        await FitnessResumoHojeService.carregar(remoto: baseSummary);

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
        color: context.appSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GridColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_outlined, color: GridColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  enabled
                      ? 'Participando da comunidade local'
                      : 'Participacao comunitaria desligada',
                  style: TextStyle(
                    color: context.appText,
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
            style: TextStyle(color: context.appTextSecondary),
          ),
          const SizedBox(height: 12),
          // Material proprio: o cartao usa BoxDecoration, e o ListTile precisa de Material por perto.
          Material(
            color: Colors.transparent,
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: enabled,
              title: const Text('Permitir participacao local'),
              subtitle: const Text('Controle de privacidade por aluno.'),
              onChanged: onChanged,
            ),
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
        boxShadow: [
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
                  value: '${summary.distanceKm.toStringAsFixed(1)} km',
                  label: 'distancia',
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  value: '${summary.trainingMinutes}m',
                  label: 'tempo ativo',
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  value: '${summary.activeCalories} kcal',
                  label: 'calorias',
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
              valueColor: AlwaysStoppedAnimation(GridColors.secondary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Atividade hoje ${summary.distanceKm.toStringAsFixed(1)} km | Musculação ${summary.strengthTrainingMinutes}m (${summary.strengthCalories} kcal) | Habitos ${summary.habitsDone}/${summary.habitsTotal}',
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
          color: context.appSurface,
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
                    style: TextStyle(
                      color: context.appText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      color: context.appTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.drag_handle, color: context.appTextSecondary),
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
        title: summary.sonoTitulo,
        subtitle: summary.sonoSubtitulo,
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
        title: summary.cardioTitulo,
        subtitle: summary.cardioSubtitulo,
        icon: Icons.favorite_border,
        color: GridColors.error,
      ),
    'body' => _HomeCardData(
        title: summary.pesoTitulo,
        subtitle: '${summary.metaPesoTexto} | ${summary.imcTexto}',
        icon: Icons.scale_outlined,
        color: GridColors.info,
      ),
    'goals' => _HomeCardData(
        title: 'Metas e habitos',
        subtitle:
            '${summary.habitsDone}/${summary.habitsTotal} feitos | ${summary.diasAtivosTexto}',
        icon: Icons.flag_outlined,
        color: GridColors.success,
      ),
    'community' => _HomeCardData(
        title: 'Comunidade',
        subtitle: 'Ranking opcional, desafios e conquistas',
        icon: Icons.groups_outlined,
        color: GridColors.primary,
      ),
    _ => _HomeCardData(
        title: 'Passos ${summary.steps}',
        subtitle: '${summary.diasAtivosTexto} | progresso semanal',
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
