import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
import 'package:task_manager_flutter/data/services/fitness_push_notification_service.dart';
import 'package:task_manager_flutter/ui/screens/fitness/biblioteca_exercicios_screen.dart';
import 'package:task_manager_flutter/ui/screens/fitness/montador_treino_screen.dart';
import 'package:task_manager_flutter/ui/screens/fitness/player_treino_ao_vivo_screen.dart';

/// Central de Treinos do MFIT Personal (Fichas Ativas, Modelos, Biblioteca e Histórico)
class TreinosHubScreen extends StatefulWidget {
  const TreinosHubScreen({super.key});

  @override
  State<TreinosHubScreen> createState() => _TreinosHubScreenState();
}

class _TreinosHubScreenState extends State<TreinosHubScreen>
    with SingleTickerProviderStateMixin {
  final _repository = FitnessOfflineRepository();
  late TabController _tabController;

  List<PlanoTreinoModel> _planos = [];
  List<SessaoTreinoRegistroModel> _sessoes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _loading = true);
    final planos = await _repository.getPlanosTreino();
    final sessoes = await _repository.getSessoesConcluidas();
    
    // Dispara verificações inteligentes de lembretes e inatividade em background
    FitnessPushNotificationService().inicializarVerificacoesAutomaticas();

    if (mounted) {
      setState(() {
        _planos = planos;
        _sessoes = sessoes;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktopOrWeb = width >= 800;

    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        title: const Text('Treinos & Prescrição', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Biblioteca de Exercícios',
            icon: const Icon(Icons.fitness_center, color: GridColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BibliotecaExerciciosScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: GridColors.primary,
          labelColor: GridColors.primary,
          unselectedLabelColor: GridColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Fichas Ativas'),
            Tab(text: 'Modelos / Templates'),
            Tab(text: 'Histórico Offline'),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktopOrWeb ? 1100 : double.infinity),
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: GridColors.primary))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildListaFichas(apenasTemplates: false),
                    _buildListaFichas(apenasTemplates: true),
                    _buildHistoricoOffline(),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: GridColors.buttonBackground,
        foregroundColor: GridColors.buttonText,
        icon: const Icon(Icons.add),
        label: const Text('Prescrever Treino', style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MontadorTreinoScreen()),
          );
          if (res != null) _carregarDados();
        },
      ),
    );
  }

  Widget _buildListaFichas({required bool apenasTemplates}) {
    final filtrados = _planos.where((p) => p.isTemplate == apenasTemplates).toList();

    if (filtrados.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, size: 54, color: GridColors.textMuted),
              const SizedBox(height: 14),
              Text(
                apenasTemplates ? 'Nenhum template salvo' : 'Nenhuma ficha de treino ativa',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Toque em "Prescrever Treino" para criar uma nova rotina.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: GridColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: filtrados.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final plano = filtrados[index];
        return _buildCardFicha(plano);
      },
    );
  }

  Widget _buildCardFicha(PlanoTreinoModel plano) {
    return Card(
      elevation: 0,
      color: GridColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: GridColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho da ficha
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plano.titulo,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Aluno: ${plano.alunoNome} • Objetivo: ${plano.objetivo}',
                        style: const TextStyle(color: GridColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: GridColors.primarySubtle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${plano.divisoes.length} divisões',
                    style: const TextStyle(
                      color: GridColors.primaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: GridColors.divider),

            // Divisões da Ficha (Treino A, Treino B, Treino C)
            const Text(
              'Divisões de Treino:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: GridColors.textSecondary),
            ),
            const SizedBox(height: 8),
            for (final div in plano.divisoes)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: GridColors.filterBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: GridColors.primary,
                      foregroundColor: Colors.white,
                      child: Text(div.letra, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(div.nome, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text('${div.exercicios.length} exercícios', style: const TextStyle(fontSize: 11, color: GridColors.textSecondary)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GridColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Treinar'),
                      onPressed: () async {
                        final concluiu = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlayerTreinoAoVivoScreen(
                              divisao: div,
                              planoId: plano.id,
                              alunoId: plano.alunoId,
                            ),
                          ),
                        );
                        if (concluiu == true) _carregarDados();
                      },
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Editar Prescrição'),
                onPressed: () async {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MontadorTreinoScreen(planoParaEditar: plano),
                    ),
                  );
                  if (res != null) _carregarDados();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricoOffline() {
    if (_sessoes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off, size: 54, color: GridColors.textMuted),
              const SizedBox(height: 14),
              const Text(
                'Nenhum treino concluído ainda',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Inicie um treino ao vivo. Todas as repetições e cargas serão salvas localmente mesmo sem internet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: GridColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _sessoes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sessao = _sessoes[index];
        final duracaoMin = (sessao.duracaoSegundos / 60).round();
        final data = sessao.dataHoraInicio.split('T').first;

        return Card(
          elevation: 0,
          color: GridColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: GridColors.divider),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: CircleAvatar(
              backgroundColor: GridColors.primarySubtle,
              foregroundColor: GridColors.primary,
              child: const Icon(Icons.check_circle),
            ),
            title: Text(
              'Treino ${sessao.divisaoLetra} • ${sessao.divisaoNome}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Data: $data • Duração: $duracaoMin min • RPE ${sessao.rpe}/10'),
                if (sessao.feedbackAluno != null)
                  Text(
                    '"${sessao.feedbackAluno}"',
                    style: const TextStyle(fontStyle: FontStyle.italic, color: GridColors.primaryDark),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      sessao.sincronizado ? Icons.cloud_done : Icons.cloud_queue,
                      size: 14,
                      color: sessao.sincronizado ? GridColors.success : GridColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      sessao.sincronizado ? 'Sincronizado na Nuvem' : 'Salvo no Celular (Offline)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: sessao.sincronizado ? GridColors.success : GridColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
