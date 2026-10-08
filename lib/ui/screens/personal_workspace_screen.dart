import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/fitness/personal_gestao_model.dart';
import 'package:task_manager_flutter/data/services/personal_gestao_offline_repository.dart';
import 'package:task_manager_flutter/ui/screens/fitness/montador_treino_screen.dart';
import 'package:task_manager_flutter/ui/screens/fitness/avaliacao_fisica_pro_screen.dart';

/// Workspace Completo do Personal Trainer (MFIT Pro Standard)
/// 4 Abas Especializadas:
/// 1. 👥 Alunos & Fichas (Vigência de Treino, Frequência, Tonelagem e Feedbacks)
/// 2. 📅 Agenda & Academias (Agendamentos por Unidade com Remarcação)
/// 3. 💰 Financeiro & Mensalidades (Baixa com 1 toque, Inadimplentes e Cobrança)
/// 4. 🔔 Central de Alertas (Fichas a Vencer + Inadimplência)
class PersonalWorkspaceScreen extends StatefulWidget {
  const PersonalWorkspaceScreen({super.key});

  @override
  State<PersonalWorkspaceScreen> createState() =>
      _PersonalWorkspaceScreenState();
}

class _PersonalWorkspaceScreenState extends State<PersonalWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PersonalGestaoOfflineRepository _repo =
      PersonalGestaoOfflineRepository();

  bool _loading = true;
  List<PersonalAlunoGestaoModel> _alunos = [];
  List<PersonalAgendamentoAulaModel> _agendamentos = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => _loading = true);
    final alunos = await _repo.getAlunos();
    final agendamentos = await _repo.getAgendamentos();
    if (mounted) {
      setState(() {
        _alunos = alunos;
        _agendamentos = agendamentos;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D131A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141C24),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CustomColors.primaryGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.sports,
                  color: CustomColors.primaryGreen, size: 22),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workspace Personal Pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Gestão de Alunos, Agenda e Financeiro',
                  style: TextStyle(
                    color: Color(0xFF8E9BAE),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF8E9BAE)),
            onPressed: _carregarDados,
            tooltip: 'Atualizar Dados',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: CustomColors.primaryGreen,
          labelColor: CustomColors.primaryGreen,
          unselectedLabelColor: const Color(0xFF8E9BAE),
          tabs: const [
            Tab(icon: Icon(Icons.people_alt_outlined), text: 'Alunos'),
            Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Agenda'),
            Tab(icon: Icon(Icons.attach_money_outlined), text: 'Financeiro'),
            Tab(icon: Icon(Icons.notifications_active_outlined), text: 'Alertas'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: CustomColors.primaryGreen),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAbaAlunos(),
                _buildAbaAgenda(),
                _buildAbaFinanceiro(),
                _buildAbaAlertas(),
              ],
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ABA 1: ALUNOS & FICHAS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildAbaAlunos() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total de Alunos (${_alunos.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _modalNovoAluno(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomColors.primaryGreen,
                foregroundColor: const Color(0xFF0D131A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Novo Aluno',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._alunos.map((aluno) => _buildCardAluno(aluno)),
      ],
    );
  }

  Widget _buildCardAluno(PersonalAlunoGestaoModel aluno) {
    final bool treinoVenceu = aluno.treinoVencido;
    final bool alertaVencendo = aluno.alertaTreinoVencendo;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16202A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: treinoVenceu
              ? Colors.redAccent.withOpacity(0.6)
              : alertaVencendo
                  ? Colors.amber.withOpacity(0.6)
                  : const Color(0xFF223140),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: CustomColors.primaryGreen.withOpacity(0.2),
                child: Text(
                  aluno.nome.isNotEmpty ? aluno.nome[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    color: CustomColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aluno.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${aluno.objetivo} • ${aluno.nivel}',
                      style: const TextStyle(
                        color: Color(0xFF8E9BAE),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xFF8E9BAE)),
                color: const Color(0xFF1E2B38),
                onSelected: (val) {
                  if (val == 'alterar_validade') {
                    _modalDefinirValidadeTreino(context, aluno);
                  } else if (val == 'montar_treino') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MontadorTreinoScreen()),
                    );
                  } else if (val == 'avaliacao') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AvaliacaoFisicaProScreen()),
                    );
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'montar_treino',
                    child: Text('Montar / Atualizar Treino',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: 'alterar_validade',
                    child: Text('Definir Validade da Ficha',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: 'avaliacao',
                    child: Text('Nova Avaliação Física',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Status da Ficha e Validade
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D131A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  treinoVenceu
                      ? Icons.error_outline
                      : alertaVencendo
                          ? Icons.warning_amber_rounded
                          : Icons.fitness_center,
                  color: treinoVenceu
                      ? Colors.redAccent
                      : alertaVencendo
                          ? Colors.amber
                          : CustomColors.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aluno.treinoAtualNome ?? 'Sem ficha ativa',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        treinoVenceu
                            ? 'Ficha VENCIDA há ${aluno.diasParaVencerTreino.abs()} dias (Trocar treino!)'
                            : 'Vence em ${aluno.diasParaVencerTreino} dias (${aluno.validadeTreinoDias} dias de ciclo)',
                        style: TextStyle(
                          color: treinoVenceu
                              ? Colors.redAccent
                              : alertaVencendo
                                  ? Colors.amber
                                  : const Color(0xFF8E9BAE),
                          fontSize: 11,
                          fontWeight: alertaVencendo
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _modalDefinirValidadeTreino(context, aluno),
                  child: const Text('Ajustar',
                      style: TextStyle(
                          color: CustomColors.primaryGreen, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Métricas de Desempenho (Frequência, Tonelagem, Treinos)
          Row(
            children: [
              _buildMiniMetrica('Frequência',
                  '${aluno.frequenciaSemanalMedia}x/sem', Icons.bolt, Colors.amber),
              const SizedBox(width: 8),
              _buildMiniMetrica(
                  'Tonelagem',
                  '${(aluno.volumeTotalKg / 1000).toStringAsFixed(1)}k kg',
                  Icons.fitness_center,
                  CustomColors.primaryGreen),
              const SizedBox(width: 8),
              _buildMiniMetrica('Concluídos', '${aluno.totalTreinosConcluidos}',
                  Icons.check_circle_outline, Colors.cyanAccent),
            ],
          ),
          if (aluno.feedbacks.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Último Feedback do Aluno no Treino:',
              style: TextStyle(
                color: Color(0xFF8E9BAE),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2733),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2A3B4D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        aluno.feedbacks.first.divisaoNome,
                        style: const TextStyle(
                          color: CustomColors.primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'RPE ${aluno.feedbacks.first.rpe}/10 • ${aluno.feedbacks.first.data}',
                        style: const TextStyle(
                          color: Color(0xFF8E9BAE),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${aluno.feedbacks.first.comentario}"',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniMetrica(
      String label, String valor, IconData icon, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0D131A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: cor),
                const SizedBox(width: 4),
                Text(
                  valor,
                  style: TextStyle(
                    color: cor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8E9BAE),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ABA 2: AGENDA DE AULAS & ACADEMIAS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildAbaAgenda() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Aulas e Consultorias',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _modalAgendarAula(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomColors.primaryGreen,
                foregroundColor: const Color(0xFF0D131A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agendar Aula',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._agendamentos.map((agenda) => _buildCardAgenda(agenda)),
      ],
    );
  }

  Widget _buildCardAgenda(PersonalAgendamentoAulaModel agenda) {
    final bool isRemarcada =
        agenda.status == StatusAgendamentoAula.remarcada;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16202A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRemarcada
              ? Colors.amber.withOpacity(0.5)
              : const Color(0xFF223140),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: CustomColors.primaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${agenda.horarioInicio} - ${agenda.horarioFim}',
                  style: const TextStyle(
                    color: CustomColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  agenda.alunoNome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isRemarcada)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'REMARCADA',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: Color(0xFF8E9BAE)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Academia: ${agenda.academiaNome}',
                  style: const TextStyle(
                    color: Color(0xFFB0BEC5),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.fitness_center_outlined,
                  size: 16, color: Color(0xFF8E9BAE)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tipo: ${agenda.tipoAula}',
                  style: const TextStyle(
                    color: Color(0xFF8E9BAE),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (agenda.motivoRemarcacao != null &&
              agenda.motivoRemarcacao!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Motivo Remarcação: ${agenda.motivoRemarcacao}',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 11,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _modalRemarcarAula(context, agenda),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber,
                  side: const BorderSide(color: Colors.amber),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.edit_calendar, size: 16),
                label: const Text('Remarcar Horário',
                    style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ABA 3: CONTROLE FINANCEIRO SIMPLES
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildAbaFinanceiro() {
    double totalRecebido = 0;
    double totalPendente = 0;
    double totalAtrasado = 0;

    for (var a in _alunos) {
      if (a.statusMensalidade == StatusMensalidadeAluno.pago) {
        totalRecebido += a.valorMensalidade;
      } else if (a.statusMensalidade == StatusMensalidadeAluno.pendente) {
        totalPendente += a.valorMensalidade;
      } else if (a.statusMensalidade == StatusMensalidadeAluno.atrasado) {
        totalAtrasado += a.valorMensalidade;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Cards Resumo Financeiro
        Row(
          children: [
            _buildCardMetricaFinanceira(
              'Recebido',
              'R\$ ${totalRecebido.toStringAsFixed(0)}',
              Icons.check_circle,
              CustomColors.primaryGreen,
            ),
            const SizedBox(width: 8),
            _buildCardMetricaFinanceira(
              'A Vencer',
              'R\$ ${totalPendente.toStringAsFixed(0)}',
              Icons.schedule,
              Colors.cyanAccent,
            ),
            const SizedBox(width: 8),
            _buildCardMetricaFinanceira(
              'Em Atraso',
              'R\$ ${totalAtrasado.toStringAsFixed(0)}',
              Icons.warning_amber_rounded,
              Colors.redAccent,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Mensalidades dos Alunos (Mês 10/2026)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._alunos.map((aluno) => _buildCardFinanceiroAluno(aluno)),
      ],
    );
  }

  Widget _buildCardMetricaFinanceira(
      String label, String valor, IconData icon, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF16202A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: cor, size: 22),
            const SizedBox(height: 6),
            Text(
              valor,
              style: TextStyle(
                color: cor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8E9BAE),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFinanceiroAluno(PersonalAlunoGestaoModel aluno) {
    final bool isPago = aluno.statusMensalidade == StatusMensalidadeAluno.pago;
    final bool isAtrasado =
        aluno.statusMensalidade == StatusMensalidadeAluno.atrasado;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16202A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAtrasado
              ? Colors.redAccent.withOpacity(0.5)
              : const Color(0xFF223140),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aluno.nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vencimento: Dia ${aluno.diaVencimento} • Valor: R\$ ${aluno.valorMensalidade.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF8E9BAE),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPago
                            ? CustomColors.primaryGreen.withOpacity(0.2)
                            : isAtrasado
                                ? Colors.redAccent.withOpacity(0.2)
                                : Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPago
                            ? 'PAGO'
                            : isAtrasado
                                ? 'ATRASADO / DEVENDO'
                                : 'PENDENTE',
                        style: TextStyle(
                          color: isPago
                              ? CustomColors.primaryGreen
                              : isAtrasado
                                  ? Colors.redAccent
                                  : Colors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isPago && aluno.dataUltimoPagamento != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Pago em: ${aluno.dataUltimoPagamento}',
                        style: const TextStyle(
                          color: Color(0xFF8E9BAE),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isPago
                ? null
                : () async {
                    await _repo.registrarRecebimentoMensalidade(
                      alunoId: aluno.id,
                      mesReferencia: '10/2026',
                    );
                    _carregarDados();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Mensalidade de ${aluno.nome} recebida com sucesso!'),
                          backgroundColor: CustomColors.primaryGreen,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isPago
                  ? const Color(0xFF223140)
                  : CustomColors.primaryGreen,
              foregroundColor: isPago
                  ? const Color(0xFF8E9BAE)
                  : const Color(0xFF0D131A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isPago ? 'Recebido' : 'Dar Baixa',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ABA 4: CENTRAL DE ALERTAS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildAbaAlertas() {
    final alunosComTreinoVencendo =
        _alunos.where((a) => a.alertaTreinoVencendo).toList();
    final alunosEmDebito =
        _alunos.where((a) => a.alertaInadimplente).toList();
    final alunosAusentes =
        _alunos.where((a) => a.diasSemTreinar >= 3).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Seção: Fichas de Treino Vencendo ou Vencidas
        _buildTituloSecaoAlerta('Fichas de Treino a Vencer / Vencidas',
            Icons.fitness_center, Colors.amber),
        if (alunosComTreinoVencendo.isEmpty)
          _buildCardVazioAlerta('Nenhuma ficha com prazo a vencer.')
        else
          ...alunosComTreinoVencendo.map((a) => _buildCardAlertaItem(
                titulo: a.nome,
                subtitulo: a.treinoVencido
                    ? 'Ficha "${a.treinoAtualNome}" VENCIDA há ${a.diasParaVencerTreino.abs()} dias.'
                    : 'Ficha "${a.treinoAtualNome}" vence em ${a.diasParaVencerTreino} dias.',
                botaoTexto: 'Atualizar Treino',
                icone: Icons.warning_amber_rounded,
                cor: a.treinoVencido ? Colors.redAccent : Colors.amber,
                onAcao: () => _modalDefinirValidadeTreino(context, a),
              )),
        const SizedBox(height: 20),

        // Seção: Cobranças & Alunos Devendo
        _buildTituloSecaoAlerta('Alunos em Débito (Inadimplentes)',
            Icons.money_off, Colors.redAccent),
        if (alunosEmDebito.isEmpty)
          _buildCardVazioAlerta('Nenhum aluno em débito este mês.')
        else
          ...alunosEmDebito.map((a) => _buildCardAlertaItem(
                titulo: a.nome,
                subtitulo:
                    'Mensalidade de R\$ ${a.valorMensalidade.toStringAsFixed(2)} vencida no dia ${a.diaVencimento}.',
                botaoTexto: 'Dar Baixa',
                icone: Icons.error_outline,
                cor: Colors.redAccent,
                onAcao: () async {
                  await _repo.registrarRecebimentoMensalidade(
                    alunoId: a.id,
                    mesReferencia: '10/2026',
                  );
                  _carregarDados();
                },
              )),
        const SizedBox(height: 20),

        // Seção: Alunos Ausentes (Sem Treinar há 3+ dias)
        _buildTituloSecaoAlerta('Assiduidade & Alunos Ausentes',
            Icons.person_off, Colors.orangeAccent),
        if (alunosAusentes.isEmpty)
          _buildCardVazioAlerta('Todos os alunos estão frequentes!')
        else
          ...alunosAusentes.map((a) => _buildCardAlertaItem(
                titulo: a.nome,
                subtitulo:
                    'Não registra treinos há ${a.diasSemTreinar} dias. Envie uma mensagem de incentivo!',
                botaoTexto: 'Notificar Aluno',
                icone: Icons.message,
                cor: Colors.orangeAccent,
                onAcao: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lembrete push enviado para ${a.nome}!'),
                      backgroundColor: CustomColors.primaryGreen,
                    ),
                  );
                },
              )),
      ],
    );
  }

  Widget _buildTituloSecaoAlerta(String titulo, IconData icon, Color cor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: cor, size: 20),
          const SizedBox(width: 8),
          Text(
            titulo,
            style: TextStyle(
              color: cor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardVazioAlerta(String msg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16202A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        msg,
        style: const TextStyle(color: Color(0xFF8E9BAE), fontSize: 13),
      ),
    );
  }

  Widget _buildCardAlertaItem({
    required String titulo,
    required String subtitulo,
    required String botaoTexto,
    required IconData icone,
    required Color cor,
    required VoidCallback onAcao,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16202A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icone, color: cor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    color: Color(0xFF8E9BAE),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onAcao,
            style: ElevatedButton.styleFrom(
              backgroundColor: cor.withOpacity(0.2),
              foregroundColor: cor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(botaoTexto,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MODAIS E AÇÕES
  // ─────────────────────────────────────────────────────────────────────────────

  void _modalDefinirValidadeTreino(
      BuildContext context, PersonalAlunoGestaoModel aluno) {
    int diasSelecionados = aluno.validadeTreinoDias;
    final treinoController =
        TextEditingController(text: aluno.treinoAtualNome ?? 'Nova Ficha');

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16202A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Definir Vigência do Treino: ${aluno.nome}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: treinoController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nome da Ficha / Treino',
                  labelStyle: TextStyle(color: Color(0xFF8E9BAE)),
                  filled: true,
                  fillColor: Color(0xFF0D131A),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tempo para Alerta de Mudança de Treino:',
                style: TextStyle(
                  color: Color(0xFF8E9BAE),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [30, 45, 60, 90].map((dias) {
                  final isSelected = diasSelecionados == dias;
                  return ChoiceChip(
                    label: Text('$dias dias'),
                    selected: isSelected,
                    selectedColor: CustomColors.primaryGreen,
                    backgroundColor: const Color(0xFF0D131A),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF0D131A) : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) setModalState(() => diasSelecionados = dias);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _repo.definirValidadeTreino(
                      alunoId: aluno.id,
                      validadeDias: diasSelecionados,
                      treinoNome: treinoController.text,
                    );
                    Navigator.pop(ctx);
                    _carregarDados();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomColors.primaryGreen,
                    foregroundColor: const Color(0xFF0D131A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Salvar Vigência & Ativar Alerta',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _modalRemarcarAula(
      BuildContext context, PersonalAgendamentoAulaModel agenda) {
    final horarioController =
        TextEditingController(text: agenda.horarioInicio);
    final academiaController =
        TextEditingController(text: agenda.academiaNome);
    final motivoController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16202A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remarcar Aula: ${agenda.alunoNome}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: horarioController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Novo Horário (HH:MM)',
                labelStyle: TextStyle(color: Color(0xFF8E9BAE)),
                filled: true,
                fillColor: Color(0xFF0D131A),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: academiaController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Academia / Local',
                labelStyle: TextStyle(color: Color(0xFF8E9BAE)),
                filled: true,
                fillColor: Color(0xFF0D131A),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motivoController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Motivo da Remarcação',
                labelStyle: TextStyle(color: Color(0xFF8E9BAE)),
                filled: true,
                fillColor: Color(0xFF0D131A),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _repo.remarcarAula(
                    aulaId: agenda.id,
                    novaData: agenda.data,
                    novoHorarioInicio: horarioController.text,
                    novoHorarioFim: '09:00',
                    novaAcademia: academiaController.text,
                    motivo: motivoController.text,
                  );
                  Navigator.pop(ctx);
                  _carregarDados();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: const Color(0xFF0D131A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Confirmar Remarcação',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _modalAgendarAula(BuildContext context) {
    String alunoSelecionado = _alunos.isNotEmpty ? _alunos.first.id : '';
    final academiaController =
        TextEditingController(text: 'SmartFit Jardins');
    final horarioController = TextEditingController(text: '10:00');
    final tipoController =
        TextEditingController(text: 'Musculação Acompanhada');

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16202A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Agendar Nova Aula / Consultoria',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: alunoSelecionado,
                dropdownColor: const Color(0xFF16202A),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Aluno',
                  labelStyle: TextStyle(color: Color(0xFF8E9BAE)),
                  filled: true,
                  fillColor: Color(0xFF0D131A),
                ),
                items: _alunos
                    .map((a) =>
                        DropdownMenuItem(value: a.id, child: Text(a.nome)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => alunoSelecionado = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: academiaController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Academia / Local',
                  labelStyle: TextStyle(color: Color(0xFF8E9BAE)),
                  filled: true,
                  fillColor: Color(0xFF0D131A),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: horarioController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Horário de Início (HH:MM)',
                  labelStyle: TextStyle(color: Color(0xFF8E9BAE)),
                  filled: true,
                  fillColor: Color(0xFF0D131A),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final aluno = _alunos.firstWhere(
                        (a) => a.id == alunoSelecionado,
                        orElse: () => _alunos.first);
                    final novaAula = PersonalAgendamentoAulaModel(
                      id: 'agenda-${DateTime.now().millisecondsSinceEpoch}',
                      alunoId: aluno.id,
                      alunoNome: aluno.nome,
                      academiaNome: academiaController.text,
                      data: DateTime.now().toIso8601String().substring(0, 10),
                      horarioInicio: horarioController.text,
                      horarioFim: '11:00',
                      tipoAula: tipoController.text,
                    );
                    await _repo.agendarAula(novaAula);
                    Navigator.pop(ctx);
                    _carregarDados();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomColors.primaryGreen,
                    foregroundColor: const Color(0xFF0D131A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Salvar Agendamento',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _modalNovoAluno(BuildContext context) {
    final nomeController = TextEditingController();
    final telController = TextEditingController();
    final valorController = TextEditingController(text: '250');

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16202A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cadastrar Novo Aluno',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nomeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nome Completo',
                labelStyle: TextStyle(color: Color(0xFF8E9BAE)),
                filled: true,
                fillColor: Color(0xFF0D131A),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: telController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'WhatsApp / Telefone',
                labelStyle: TextStyle(color: Color(0xFF8E9BAE)),
                filled: true,
                fillColor: Color(0xFF0D131A),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valorController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Valor da Mensalidade (R\$)',
                labelStyle: TextStyle(color: Color(0xFF8E9BAE)),
                filled: true,
                fillColor: Color(0xFF0D131A),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final novo = PersonalAlunoGestaoModel(
                    id: 'aluno-${DateTime.now().millisecondsSinceEpoch}',
                    nome: nomeController.text.isNotEmpty
                        ? nomeController.text
                        : 'Novo Aluno',
                    email: 'aluno@email.com',
                    telefone: telController.text,
                    valorMensalidade:
                        double.tryParse(valorController.text) ?? 250.0,
                  );
                  await _repo.salvarAluno(novo);
                  Navigator.pop(ctx);
                  _carregarDados();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.primaryGreen,
                  foregroundColor: const Color(0xFF0D131A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Cadastrar Aluno',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
