import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/utils/fitness_access.dart';
import 'package:task_manager_flutter/ui/widgets/detalhes_sessao_treino.dart';
import 'package:task_manager_flutter/ui/widgets/midias_sessao_treino.dart';
import 'package:task_manager_flutter/ui/widgets/imprimir_pdf.dart';
import 'package:task_manager_flutter/data/services/pdf/ficha_dieta_pdf.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
import 'package:task_manager_flutter/data/services/fitness_push_notification_service.dart';
import 'package:task_manager_flutter/ui/screens/fitness/biblioteca_exercicios_screen.dart';
import 'package:task_manager_flutter/ui/screens/fitness/montador_treino_screen.dart';
import 'package:task_manager_flutter/ui/screens/fitness/player_treino_ao_vivo_screen.dart';
import 'package:task_manager_flutter/data/services/personal_gestao_offline_repository.dart';

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
  bool _fichaOcultaPeloPersonal = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregarDados();
  }

  Future<void> _carregarDados({bool manual = false}) async {
    setState(() => _loading = true);
    final isPersonal = podeGerenciarAlunos(AuthUtility.session.value);
    // Personal ve so os treinos dele; os dos alunos ficam nos perfis deles.
    final planos = await _repository.getPlanosTreino(
        alunoId: isPersonal
            ? AuthUtility.userInfo.login?.id?.toString()
            : null);
    final sessoes = await _repository.getSessoesConcluidas();

    bool fichaOculta = false;
    if (!isPersonal) {
      fichaOculta = await PersonalGestaoOfflineRepository().isFichaOcultaParaAlunoAtual();
    }
    
    // Dispara verificações inteligentes de lembretes e inatividade em background
    FitnessPushNotificationService().inicializarVerificacoesAutomaticas();

    if (mounted) {
      setState(() {
        _planos = planos;
        _sessoes = sessoes;
        _fichaOcultaPeloPersonal = fichaOculta;
        _loading = false;
      });
      if (manual) {
        final sincronizados = sessoes.where((s) => s.sincronizado).length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: GridColors.success,
            content: Text('Sincronização concluída! ${planos.length} ficha(s) e $sincronizados treino(s) na nuvem.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
            icon: Icon(Icons.fitness_center, color: GridColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BibliotecaExerciciosScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Atualizar e sincronizar',
            icon: const Icon(Icons.refresh),
            onPressed: () => _carregarDados(manual: true),
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
              ? Center(child: CircularProgressIndicator(color: GridColors.primary))
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
    if (!apenasTemplates && _fichaOcultaPeloPersonal) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.visibility_off_outlined, size: 48, color: Colors.amber),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ficha de Treino Oculta',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Seu Personal Trainer configurou sua rotina de treino para ficar temporariamente oculta.\nFale com seu personal para dúvidas ou solicitar a liberação.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: GridColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

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
              Text(
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
        side: BorderSide(color: GridColors.divider),
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
                        style: TextStyle(color: GridColors.textSecondary, fontSize: 13),
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
                    style: TextStyle(
                      color: GridColors.primaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 24, color: GridColors.divider),

            // Divisões da Ficha (Treino A, Treino B, Treino C)
            Text(
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
                      child: InkWell(
                        onTap: () => _modalVisualizarFichaDivisao(context, div, plano),
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(div.nome, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            Wrap(
                              spacing: 6, runSpacing: 2,
                              children: [
                                Text('${div.exercicios.length} exercícios', style: TextStyle(fontSize: 11, color: GridColors.textSecondary)),
                                Text('• Toque p/ ver ficha', style: TextStyle(fontSize: 11, color: GridColors.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GridColors.primary,
                        side: BorderSide(color: GridColors.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('Ver Ficha'),
                      onPressed: () => _modalVisualizarFichaDivisao(context, div, plano),
                    ),
                    const SizedBox(width: 8),
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
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              children: [
                TextButton.icon(
                  key: const Key('btn_imprimir_ficha'),
                  icon: const Icon(Icons.print_outlined, size: 16),
                  label: const Text('Imprimir PDF'),
                  onPressed: () => imprimirPdf(
                    context,
                    nomeArquivo: nomeArquivoPdf('Ficha', plano.titulo),
                    gerar: () async {
                      final catalogo = {
                        for (final e in await FitnessOfflineRepository().getExercicios()) e.id: e,
                      };
                      return FichaDietaPdf.fichaTreino(plano, catalogo: catalogo);
                    },
                  ),
                ),
                TextButton.icon(
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
              ],
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
              Text(
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
            side: BorderSide(color: GridColors.divider),
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
                TextButton.icon(
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Ver detalhes'),
                  onPressed: () async {
                    await showDialog(context: context,
                      builder: (_) => DetalhesSessaoTreino(sessao: sessao));
                    if (mounted) await _carregarDados();
                  },
                ),
                Text('${sessao.fotosDoTreino.length} fotos • ${sessao.videosDoTreino.length} vídeos'),
                if (sessao.fotosDoTreino.isNotEmpty)
                  MidiasSessaoTreinoGaleria(fotosBase64: sessao.fotosDoTreino,
                    videosUrls: const [], compacta: true),
                TextButton.icon(
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Fotos e vídeos'),
                  onPressed: () async {
                    final atualizada = await editarMidiasSessaoTreino(context, sessao);
                    if (atualizada != null && mounted) await _carregarDados();
                  },
                ),
                if (sessao.feedbackAluno != null)
                  Text(
                    '"${sessao.feedbackAluno}"',
                    style: TextStyle(fontStyle: FontStyle.italic, color: GridColors.primaryDark),
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

  void _modalVisualizarFichaDivisao(
      BuildContext context, DivisaoTreinoModel div, PlanoTreinoModel plano) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GridColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: GridColors.primary,
                    foregroundColor: Colors.white,
                    child: Text(
                      div.letra,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          div.nome,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                        Text(
                          '${plano.titulo} • Aluno: ${plano.alunoNome}',
                          style: TextStyle(color: GridColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Resumo didático da divisão
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: GridColors.primarySubtle.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GridColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.fitness_center, size: 16, color: GridColors.primaryDark),
                        const SizedBox(width: 6),
                        Text(
                          '${div.exercicios.length} exercícios',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: GridColors.primaryDark),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: GridColors.primaryDark),
                        const SizedBox(width: 6),
                        Text(
                          '~45-60 min',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: GridColors.primaryDark),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.flag_outlined, size: 16, color: GridColors.primaryDark),
                        const SizedBox(width: 6),
                        Text(
                          plano.objetivo,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: GridColors.primaryDark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Ficha Completa de Exercícios:',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: GridColors.textSecondary),
              ),
              const SizedBox(height: 10),
              // Lista didática e autoexplicativa dos exercícios
              Expanded(
                child: div.exercicios.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum exercício cadastrado nesta divisão.',
                          style: TextStyle(color: GridColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        itemCount: div.exercicios.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final ex = div.exercicios[idx];

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: GridColors.filterBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: GridColors.divider),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: GridColors.primarySubtle,
                                      foregroundColor: GridColors.primaryDark,
                                      child: Text(
                                        '${idx + 1}',
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        ex.exercicioNome,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: GridColors.primarySubtle,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        ex.grupoMuscular,
                                        style: TextStyle(
                                          color: GridColors.primaryDark,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Informações técnicas: Séries, Reps, Carga e Descanso
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _buildTagPrescricao(
                                      Icons.format_list_numbered,
                                      '${ex.series} séries',
                                      Colors.blue.shade800,
                                      Colors.blue.shade50,
                                    ),
                                    _buildTagPrescricao(
                                      Icons.repeat,
                                      '${ex.repeticoes} reps',
                                      Colors.purple.shade800,
                                      Colors.purple.shade50,
                                    ),
                                    if (ex.cargaSugeridaKg > 0)
                                      _buildTagPrescricao(
                                        Icons.fitness_center,
                                        '${ex.cargaSugeridaKg.toStringAsFixed(0)} kg alvo',
                                        GridColors.primaryDark,
                                        GridColors.primarySubtle,
                                      ),
                                    _buildTagPrescricao(
                                      Icons.timer_outlined,
                                      '${ex.descansoSegundos}s descanso',
                                      Colors.amber.shade900,
                                      Colors.amber.shade50,
                                    ),
                                    if (ex.tecnica != 'Normal')
                                      _buildTagPrescricao(
                                        Icons.bolt,
                                        ex.tecnica,
                                        Colors.deepOrange.shade900,
                                        Colors.deepOrange.shade50,
                                      ),
                                  ],
                                ),
                                if (ex.observacoes != null && ex.observacoes!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.tips_and_updates_outlined, size: 14, color: Colors.amber),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            ex.observacoes!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                              color: GridColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (ex.exercicioBiset != null)
                                  Text('Biset com ${ex.exercicioBiset!.exercicioNome} • '
                                    '${ex.exercicioBiset!.repeticoes} reps • '
                                    '${ex.exercicioBiset!.cargaSugeridaKg} kg',
                                    style: TextStyle(color: GridColors.primaryDark,
                                      fontWeight: FontWeight.w600)),
                                if (ex.exerciciosAlternativos.isNotEmpty)
                                  Text('Máquina ocupada? ${ex.exerciciosAlternativos.join(' ou ')}',
                                    style: TextStyle(color: GridColors.textSecondary)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 14),
              // Botão de Iniciar Treino Ao Vivo
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: const Text(
                    'Iniciar Este Treino Agora (Modo Ao Vivo)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagPrescricao(IconData icon, String texto, Color corTexto, Color corFundo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: corTexto),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(color: corTexto, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
