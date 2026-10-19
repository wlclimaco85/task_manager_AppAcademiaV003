import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/personal_aluno_sheet.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/data/utils/fitness_access.dart';
import 'package:task_manager_flutter/ui/screens/sem_acesso_screen.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/fitness/personal_gestao_model.dart';
import 'package:task_manager_flutter/data/models/fitness/personal_conta_pagar_model.dart';
import 'package:task_manager_flutter/data/models/fitness/personal_pix_cobranca_model.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
import 'package:task_manager_flutter/data/services/personal_gestao_offline_repository.dart';
import 'package:task_manager_flutter/ui/screens/fitness/montador_treino_screen.dart';
import 'package:task_manager_flutter/data/services/avaliacao_agendada_service.dart';
import 'package:task_manager_flutter/ui/screens/fitness/nutricao_protocolos_hub_screen.dart';
import 'package:task_manager_flutter/ui/widgets/avatar_com_indicador.dart';
import 'package:task_manager_flutter/ui/screens/fitness/avaliacao_fisica_pro_screen.dart';
import 'package:task_manager_flutter/ui/screens/fitness/agenda_compartilhada_screen.dart';
import 'package:task_manager_flutter/ui/widgets/personal_qr_code_pix_dialog.dart';
import 'package:task_manager_flutter/ui/screens/fitness/meu_perfil_screen.dart';

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
  Map<String, DateTime> _avaliacoesAgendadas = {};
  List<PersonalContaPagarModel> _contasPagar = [];
  PersonalPixCobrancaModel _pixConfig = PersonalPixCobrancaModel();
  int _secaoFinanceira = 0; // 0 = A Receber, 1 = A Pagar, 2 = Balanço

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (podeGerenciarAlunos()) _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => _loading = true);
    final alunos = await _repo.getAlunos();
    final avaliacoes = await AvaliacaoAgendadaService.listar();
    final contas = await _repo.getContasPagar();
    final pix = await _repo.getPixCobranca();
    if (mounted) {
      setState(() {
        _alunos = alunos;
        _avaliacoesAgendadas = avaliacoes;
        _contasPagar = contas;
        _pixConfig = pix;
        _loading = false;
      });
    }
  }

  /// Agenda a proxima avaliacao fisica do aluno (com data e alerta no card).
  Future<void> _agendarAvaliacao(PersonalAlunoGestaoModel aluno) async {
    final hoje = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: _avaliacoesAgendadas[aluno.id] ?? hoje,
      firstDate: DateTime(hoje.year, hoje.month, hoje.day),
      lastDate: hoje.add(const Duration(days: 730)),
      helpText: 'Data da nova avaliação de ${aluno.nome}',
    );
    if (data == null || !mounted) return;
    await AvaliacaoAgendadaService.agendar(aluno.id, data);
    if (!mounted) return;
    _snack('Avaliação de ${aluno.nome} agendada para ${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}.');
    await _carregarDados();
  }

  /// Texto e cor do alerta de avaliacao agendada (null = sem alerta).
  ({String texto, Color cor})? _alertaAvaliacao(String alunoId) {
    final data = _avaliacoesAgendadas[alunoId];
    if (data == null) return null;
    final situacao = AvaliacaoAgendadaService.situacao(data, DateTime.now());
    final dataBr = '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';
    return switch (situacao) {
      SituacaoAvaliacao.vencida => (texto: 'Avaliação vencida ($dataBr)', cor: GridColors.error),
      SituacaoAvaliacao.proxima => (texto: 'Avaliação agendada: $dataBr', cor: GridColors.secondaryDark),
      SituacaoAvaliacao.distante => (texto: 'Avaliação agendada: $dataBr', cor: GridColors.textSecondary),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!podeGerenciarAlunos()) return const SemAcessoScreen();
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        backgroundColor: GridColors.card,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CustomColors.primaryGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.sports,
                  color: CustomColors.primaryGreen, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workspace Personal Pro',
                  style: TextStyle(
                    color: GridColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Gestão de Alunos, Agenda e Financeiro',
                  style: TextStyle(
                    color: GridColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: GridColors.textSecondary),
            onPressed: _carregarDados,
            tooltip: 'Atualizar Dados',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: CustomColors.primaryGreen,
          labelColor: CustomColors.primaryGreen,
          unselectedLabelColor: GridColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.people_alt_outlined), text: 'Alunos'),
            Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Agenda'),
            Tab(icon: Icon(Icons.attach_money_outlined), text: 'Financeiro'),
            Tab(icon: Icon(Icons.notifications_active_outlined), text: 'Alertas'),
          ],
        ),
      ),
      body: _loading
          ? Center(
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
              style: TextStyle(
                color: GridColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _modalNovoAluno(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomColors.primaryGreen,
                foregroundColor: GridColors.textOnPrimary,
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
        color: GridColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: treinoVenceu
              ? GridColors.error.withOpacity(0.6)
              : alertaVencendo
                  ? GridColors.secondaryDark.withOpacity(0.6)
                  : GridColors.divider,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarComIndicador(
                mostrarAlerta: !aluno.cadastroInicialCompleto,
                rotulo: 'Cadastro inicial de ${aluno.nome} incompleto',
                titulo: 'Cadastro inicial pendente',
                corpo: '${aluno.nome} ainda não preencheu a foto ou as medidas. Peça para completar no app.',
                avatar: CircleAvatar(
                  radius: 24,
                  backgroundColor: CustomColors.primaryGreen.withOpacity(0.2),
                  child: Text(
                    aluno.nome.isNotEmpty ? aluno.nome[0].toUpperCase() : 'A',
                    style: TextStyle(
                      color: CustomColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
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
                      style: TextStyle(
                        color: GridColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [aluno.objetivo, aluno.nivel].where((v)=>v.isNotEmpty).join(' • '),
                      style: TextStyle(
                        color: GridColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    if (_alertaAvaliacao(aluno.id) case final alerta?)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(children: [
                          Icon(Icons.event_available, size: 14, color: alerta.cor),
                          const SizedBox(width: 4),
                          Text(alerta.texto,
                              style: TextStyle(
                                  color: alerta.cor, fontSize: 12, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: GridColors.textSecondary),
                color: GridColors.card,
                onSelected: (val) {
                  if (val == 'historico_treinos') {
                    _modalHistoricoTreinosAluno(context, aluno);
                  } else if (val == 'alterar_validade') {
                    _modalDefinirValidadeTreino(context, aluno);
                  } else if (val == 'montar_treino') {
                    _montarTreino(aluno);
                  } else if (val == 'clonar_treino') {
                    _clonarTreinoDeOutroAluno(aluno);
                  } else if (val == 'agendar_avaliacao') {
                    _agendarAvaliacao(aluno);
                  } else if (val == 'dieta_suplementos') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NutricaoProtocolosHubScreen(
                            alunoId: aluno.id, nomeAluno: aluno.nome),
                      ),
                    );
                  } else if (val == 'editar_aluno') {
                    _modalNovoAluno(context, aluno:aluno);
                  } else if (val == 'avaliacao') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AvaliacaoFisicaProScreen(alunoNome: aluno.nome, alunoId: aluno.id)),
                    );
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(value:'editar_aluno',child:Text('Editar frequência e cobrança',style:TextStyle(color:GridColors.textPrimary))),
                  PopupMenuItem(
                    value: 'historico_treinos',
                    child: Row(
                      children: [
                        Icon(Icons.history, color: CustomColors.primaryGreen, size: 18),
                        SizedBox(width: 8),
                        Text('Histórico de Treinos e Cargas',
                            style: TextStyle(color: GridColors.textPrimary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'montar_treino',
                    child: Text('Montar / Atualizar Treino',
                        style: TextStyle(color: GridColors.textPrimary)),
                  ),
                  PopupMenuItem(
                    value: 'dieta_suplementos',
                    child: Text('Ver dieta e suplementação',
                        style: TextStyle(color: GridColors.textPrimary)),
                  ),
                  PopupMenuItem(
                    value: 'clonar_treino',
                    child: Text('Clonar treino de outro aluno',
                        style: TextStyle(color: GridColors.textPrimary)),
                  ),
                  PopupMenuItem(
                    value: 'alterar_validade',
                    child: Text('Definir Validade da Ficha',
                        style: TextStyle(color: GridColors.textPrimary)),
                  ),
                  PopupMenuItem(
                    value: 'agendar_avaliacao',
                    child: Text('Agendar nova avaliação física',
                        style: TextStyle(color: GridColors.textPrimary)),
                  ),
                  PopupMenuItem(
                    value: 'avaliacao',
                    child: Text('Abrir avaliação física',
                        style: TextStyle(color: GridColors.textPrimary)),
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
              color: GridColors.background,
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
                      ? GridColors.error
                      : alertaVencendo
                          ? GridColors.secondaryDark
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
                        style: TextStyle(
                          color: GridColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        aluno.treinoAtualNome == null ? 'Monte a primeira ficha para este aluno.' : treinoVenceu
                            ? 'Ficha VENCIDA há ${aluno.diasParaVencerTreino.abs()} dias (Trocar treino!)'
                            : 'Vence em ${aluno.diasParaVencerTreino} dias (${aluno.validadeTreinoDias} dias de ciclo)',
                        style: TextStyle(
                          color: treinoVenceu
                              ? GridColors.error
                              : alertaVencendo
                                  ? GridColors.secondaryDark
                                  : GridColors.textSecondary,
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
                  child: Text('Ajustar',
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
              Expanded(child:InkWell(onTap:()=>_modalNovoAluno(context,aluno:aluno),
                child:Column(children:[Text(aluno.resumoAulasContratadas,style:TextStyle(color:GridColors.secondaryDark,fontWeight:FontWeight.bold)),
                  Text('Contratada • editar',style:TextStyle(color:GridColors.textSecondary,fontSize:11))]))),
              const SizedBox(width: 8),
              _buildMiniMetrica(
                  'Tonelagem',
                  '${(aluno.volumeTotalKg / 1000).toStringAsFixed(1)}k kg',
                  Icons.fitness_center,
                  CustomColors.primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _modalHistoricoTreinosAluno(context, aluno),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    decoration: BoxDecoration(
                      color: GridColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GridColors.info.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 14, color: GridColors.info),
                            const SizedBox(width: 4),
                            Text(
                              '${aluno.totalTreinosConcluidos}',
                              style: const TextStyle(
                                color: GridColors.info,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Concluídos (Ver)',
                          style: TextStyle(
                            color: GridColors.info,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (aluno.feedbacks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Último Feedback do Aluno no Treino:',
              style: TextStyle(
                color: GridColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: GridColors.filterBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GridColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        aluno.feedbacks.first.divisaoNome,
                        style: TextStyle(
                          color: CustomColors.primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'RPE ${aluno.feedbacks.first.rpe}/10 • ${aluno.feedbacks.first.data}',
                        style: TextStyle(
                          color: GridColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${aluno.feedbacks.first.comentario}"',
                    style: TextStyle(
                      color: GridColors.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Align(alignment:Alignment.centerRight, child:Wrap(spacing:8,children:[
            OutlinedButton.icon(onPressed:()=>_modalNovoAluno(context,aluno:aluno),icon:const Icon(Icons.edit_outlined),label:const Text('Frequência e cobrança')),
            FilledButton.icon(onPressed:()=>_montarTreino(aluno),icon:const Icon(Icons.fitness_center),label:const Text('Montar treino')),
          ])),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _modalHistoricoTreinosAluno(context, aluno),
              icon: Icon(Icons.history_edu, size: 16, color: CustomColors.primaryGreen),
              label: Text('Ver Histórico de Treinos e Cargas',
                  style: TextStyle(color: CustomColors.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
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
          color: GridColors.background,
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
              style: TextStyle(
                color: GridColors.textSecondary,
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

  Widget _buildAbaAgenda() =>
      const AgendaCompartilhadaScreen(embedded: true);

  Widget _buildAbaFinanceiro() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card de destaque da Cobrança Pix & Mensalidade
        _buildCardPixDestaque(),
        const SizedBox(height: 16),

        // Seletor de Seções Financeiras (A Receber | A Pagar | Balanço)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: GridColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GridColors.divider),
          ),
          child: Row(
            children: [
              _buildBotaoAbaFinanceira(
                indice: 0,
                titulo: 'A Receber (Alunos)',
                icone: Icons.arrow_downward,
                cor: CustomColors.primaryGreen,
              ),
              _buildBotaoAbaFinanceira(
                indice: 1,
                titulo: 'A Pagar (Despesas)',
                icone: Icons.arrow_upward,
                cor: GridColors.error,
              ),
              _buildBotaoAbaFinanceira(
                indice: 2,
                titulo: 'Balanço',
                icone: Icons.pie_chart_outline,
                cor: GridColors.info,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_secaoFinanceira == 0) ...[
          _buildSecaoContasReceber(),
        ] else if (_secaoFinanceira == 1) ...[
          _buildSecaoContasPagar(),
        ] else ...[
          _buildSecaoBalancoGeral(),
        ],
      ],
    );
  }

  Widget _buildCardPixDestaque() {
    final bool temPix = _pixConfig.configurado;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CustomColors.primaryGreen.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CustomColors.primaryGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.qr_code_2,
              color: CustomColors.primaryGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Meu Pix & QR Code',
                      style: TextStyle(
                        color: GridColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: CustomColors.primaryGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        temPix ? 'CONFIGURADO' : 'PENDENTE',
                        style: TextStyle(
                          color: CustomColors.primaryGreen,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  temPix
                      ? 'Mensalidade Padrão: R\$ ${_pixConfig.valorMensalidadePadrao.toStringAsFixed(2)} • ${_pixConfig.tipoChavePix}'
                      : 'Configure sua chave Pix e mensalidade no perfil',
                  style: TextStyle(
                    color: GridColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              PersonalQrCodePixDialog.show(
                context,
                pixConfig: _pixConfig,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CustomColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.qr_code, size: 18),
            label: const Text(
              'Abrir QR Code',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoAbaFinanceira({
    required int indice,
    required String titulo,
    required IconData icone,
    required Color cor,
  }) {
    final bool ativo = _secaoFinanceira == indice;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _secaoFinanceira = indice),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: ativo ? cor.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: ativo ? Border.all(color: cor.withOpacity(0.5)) : null,
          ),
          child: Column(
            children: [
              Icon(
                icone,
                size: 18,
                color: ativo ? cor : GridColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ativo ? GridColors.textPrimary : GridColors.textSecondary,
                  fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SEÇÃO 1: CONTAS A RECEBER (ALUNOS)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildSecaoContasReceber() {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Métricas de Recebimento
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
              GridColors.info,
            ),
            const SizedBox(width: 8),
            _buildCardMetricaFinanceira(
              'Em Atraso',
              'R\$ ${totalAtrasado.toStringAsFixed(0)}',
              Icons.warning_amber_rounded,
              GridColors.error,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cobranças dos Alunos (${_alunos.length})',
              style: TextStyle(
                color: GridColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Total: R\$ ${(totalRecebido + totalPendente + totalAtrasado).toStringAsFixed(2)}',
              style: TextStyle(
                color: GridColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_alunos.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: GridColors.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                'Nenhum aluno vinculado ainda.',
                style: TextStyle(color: GridColors.textSecondary),
              ),
            ),
          )
        else
          ..._alunos.map((aluno) => _buildCardFinanceiroAluno(aluno)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SEÇÃO 2: CONTAS A PAGAR (DESPESAS DO PERSONAL)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildSecaoContasPagar() {
    double totalPago = 0;
    double totalPendente = 0;
    double totalAtrasado = 0;

    for (var c in _contasPagar) {
      if (c.pago) {
        totalPago += c.valor;
      } else if (c.atrasado) {
        totalAtrasado += c.valor;
      } else {
        totalPendente += c.valor;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Métricas de Pagamento
        Row(
          children: [
            _buildCardMetricaFinanceira(
              'Total Pago',
              'R\$ ${totalPago.toStringAsFixed(0)}',
              Icons.task_alt,
              CustomColors.primaryGreen,
            ),
            const SizedBox(width: 8),
            _buildCardMetricaFinanceira(
              'A Vencer',
              'R\$ ${totalPendente.toStringAsFixed(0)}',
              Icons.schedule,
              GridColors.info,
            ),
            const SizedBox(width: 8),
            _buildCardMetricaFinanceira(
              'Em Atraso',
              'R\$ ${totalAtrasado.toStringAsFixed(0)}',
              Icons.error_outline,
              GridColors.error,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Barra de ação: Título + Botão Nova Conta
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Despesas do Personal (${_contasPagar.length})',
              style: TextStyle(
                color: GridColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _abrirModalNovaContaPagar,
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Nova Despesa',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_contasPagar.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: GridColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GridColors.divider),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 40, color: GridColors.textSecondary),
                const SizedBox(height: 8),
                Text(
                  'Nenhuma conta a pagar cadastrada.',
                  style: TextStyle(
                    color: GridColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cadastre seu aluguel de academia, CREF, equipamentos, etc.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: GridColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          )
        else
          ..._contasPagar.map((conta) => _buildCardContaPagar(conta)),
      ],
    );
  }

  Widget _buildCardContaPagar(PersonalContaPagarModel conta) {
    final bool isPago = conta.pago;
    final bool isAtrasado = conta.atrasado;

    Color corStatus = GridColors.info;
    String statusTexto = 'PENDENTE';
    if (isPago) {
      corStatus = CustomColors.primaryGreen;
      statusTexto = 'PAGO';
    } else if (isAtrasado) {
      corStatus = GridColors.error;
      statusTexto = 'EM ATRASO';
    }

    final dataVencFormatada =
        '${conta.dataVencimento.day.toString().padLeft(2, '0')}/${conta.dataVencimento.month.toString().padLeft(2, '0')}/${conta.dataVencimento.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAtrasado
              ? GridColors.error.withOpacity(0.5)
              : GridColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conta.descricao,
                      style: TextStyle(
                        color: GridColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Categoria: ${conta.categoria} • Vencimento: $dataVencFormatada',
                      style: TextStyle(
                        color: GridColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'R\$ ${conta.valor.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isPago ? CustomColors.primaryGreen : GridColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (conta.observacao != null && conta.observacao!.isNotEmpty) ...[
            Text(
              'Obs: ${conta.observacao}',
              style: TextStyle(
                color: GridColors.textSecondary,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: corStatus.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusTexto,
                  style: TextStyle(
                    color: corStatus,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: GridColors.textSecondary),
                    tooltip: 'Excluir conta',
                    onPressed: () async {
                      final confirma = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Excluir Despesa'),
                          content: Text('Deseja excluir a conta "${conta.descricao}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: FilledButton.styleFrom(backgroundColor: GridColors.error),
                              child: const Text('Excluir'),
                            ),
                          ],
                        ),
                      );
                      if (confirma == true) {
                        await _repo.excluirContaPagar(conta.id);
                        _carregarDados();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await _repo.registrarPagamentoConta(conta.id, pago: !isPago);
                      _carregarDados();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              !isPago
                                  ? 'Despesa "${conta.descricao}" marcada como paga!'
                                  : 'Pagamento de "${conta.descricao}" estornado para pendente.',
                            ),
                            backgroundColor: !isPago
                                ? CustomColors.primaryGreen
                                : GridColors.secondaryDark,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPago
                          ? GridColors.divider
                          : CustomColors.primaryGreen,
                      foregroundColor: isPago
                          ? GridColors.textSecondary
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isPago ? 'Paga (Desfazer)' : 'Marcar Paga',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SEÇÃO 3: BALANÇO GERAL (RECEITAS X DESPESAS)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildSecaoBalancoGeral() {
    double totalReceitas = 0;
    double totalReceitasRecebidas = 0;
    for (var a in _alunos) {
      totalReceitas += a.valorMensalidade;
      if (a.statusMensalidade == StatusMensalidadeAluno.pago) {
        totalReceitasRecebidas += a.valorMensalidade;
      }
    }

    double totalDespesas = 0;
    double totalDespesasPagas = 0;
    for (var c in _contasPagar) {
      totalDespesas += c.valor;
      if (c.pago) {
        totalDespesasPagas += c.valor;
      }
    }

    final double saldoProjetado = totalReceitas - totalDespesas;
    final double saldoEfetivo = totalReceitasRecebidas - totalDespesasPagas;
    final bool positivo = saldoProjetado >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card Principal de Lucro Líquido / Saldo
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: GridColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: positivo
                  ? CustomColors.primaryGreen.withOpacity(0.4)
                  : GridColors.error.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                'LUCRO LÍQUIDO PROJETADO (MÊS)',
                style: TextStyle(
                  color: GridColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'R\$ ${saldoProjetado.toStringAsFixed(2)}',
                style: TextStyle(
                  color: positivo ? CustomColors.primaryGreen : GridColors.error,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Saldo em Caixa Atual: R\$ ${saldoEfetivo.toStringAsFixed(2)}',
                style: TextStyle(
                  color: GridColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Comparativo em Cards
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GridColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: CustomColors.primaryGreen.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.arrow_downward, color: CustomColors.primaryGreen, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Receitas',
                          style: TextStyle(
                            color: CustomColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'R\$ ${totalReceitas.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: GridColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_alunos.length} alunos cadastrados',
                      style: TextStyle(color: GridColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GridColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: GridColors.error.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.arrow_upward, color: GridColors.error, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Despesas',
                          style: TextStyle(
                            color: GridColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'R\$ ${totalDespesas.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: GridColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_contasPagar.length} despesas cadastradas',
                      style: TextStyle(color: GridColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Detalhamento de Despesas por Categoria
        Text(
          'Despesas por Categoria',
          style: TextStyle(
            color: GridColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._buildListaCategoriasDespesas(totalDespesas),
      ],
    );
  }

  List<Widget> _buildListaCategoriasDespesas(double totalDespesas) {
    final Map<String, double> categorias = {};
    for (var c in _contasPagar) {
      categorias[c.categoria] = (categorias[c.categoria] ?? 0) + c.valor;
    }

    if (categorias.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: GridColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'Nenhuma despesa para detalhar.',
              style: TextStyle(color: GridColors.textSecondary),
            ),
          ),
        ),
      ];
    }

    return categorias.entries.map((e) {
      final double percentual = totalDespesas > 0 ? (e.value / totalDespesas) * 100 : 0;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: GridColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GridColors.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.key,
                  style: TextStyle(
                    color: GridColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${percentual.toStringAsFixed(1)}% do total de custos',
                  style: TextStyle(
                    color: GridColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            Text(
              'R\$ ${e.value.toStringAsFixed(2)}',
              style: TextStyle(
                color: GridColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MODAL NOVA CONTA A PAGAR
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _abrirModalNovaContaPagar() async {
    final descCtrl = TextEditingController();
    final valorCtrl = TextEditingController();
    final obsCtrl = TextEditingController();
    String categoria = CategoriaContaPagar.espacoAcademia;
    DateTime dataVenc = DateTime.now().add(const Duration(days: 7));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GridColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final dataFormatada =
              '${dataVenc.day.toString().padLeft(2, '0')}/${dataVenc.month.toString().padLeft(2, '0')}/${dataVenc.year}';

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nova Despesa / Conta a Pagar',
                        style: TextStyle(
                          color: GridColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descrição da despesa',
                      hintText: 'Ex: Aluguel Academia, Anuidade CREF, etc.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: categoria,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: CategoriaContaPagar.todas.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => categoria = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: valorCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Valor (R\$)',
                      prefixText: 'R\$ ',
                      hintText: '150,00',
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () async {
                      final escolhida = await showDatePicker(
                        context: context,
                        initialDate: dataVenc,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (escolhida != null) {
                        setModalState(() => dataVenc = escolhida);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data de Vencimento',
                        suffixIcon: Icon(Icons.calendar_today, size: 20),
                      ),
                      child: Text(dataFormatada),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: obsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Observações (opcional)',
                      hintText: 'Detalhes adicionais, parcelamento, etc.',
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () async {
                      final desc = descCtrl.text.trim();
                      if (desc.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Informe a descrição da despesa.')),
                        );
                        return;
                      }
                      final valor = double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 0;
                      if (valor <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Informe um valor válido maior que zero.')),
                        );
                        return;
                      }

                      final novaConta = PersonalContaPagarModel(
                        id: 'pagar_${DateTime.now().millisecondsSinceEpoch}',
                        descricao: desc,
                        categoria: categoria,
                        valor: valor,
                        dataVencimento: dataVenc,
                        observacao: obsCtrl.text.trim().isNotEmpty ? obsCtrl.text.trim() : null,
                      );

                      await _repo.salvarContaPagar(novaConta);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _carregarDados();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Despesa cadastrada com sucesso!'),
                          backgroundColor: CustomColors.primaryGreen,
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: CustomColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text(
                      'Salvar Despesa',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Card de metrica do resumo financeiro (Recebido, A Vencer, Em Atraso...).
  Widget _buildCardMetricaFinanceira(
      String titulo, String valor, IconData icone, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: GridColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: cor, size: 20),
            const SizedBox(height: 6),
            Text(
              titulo,
              style: TextStyle(color: GridColors.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              valor,
              style: TextStyle(
                color: GridColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
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
        color: GridColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAtrasado
              ? GridColors.error.withOpacity(0.5)
              : GridColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aluno.nome,
                      style: TextStyle(
                        color: GridColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vencimento: Dia ${aluno.diaVencimento} • Valor: R\$ ${aluno.valorMensalidade.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: GridColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'R\$ ${aluno.valorMensalidade.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isPago ? CustomColors.primaryGreen : GridColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPago
                      ? CustomColors.primaryGreen.withOpacity(0.2)
                      : isAtrasado
                          ? GridColors.error.withOpacity(0.2)
                          : GridColors.secondaryDark.withOpacity(0.2),
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
                            ? GridColors.error
                            : GridColors.secondaryDark,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isPago && aluno.dataUltimoPagamento != null) ...[
                const SizedBox(width: 8),
                Text(
                  'Pago em: ${aluno.dataUltimoPagamento}',
                  style: TextStyle(
                    color: GridColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Botão Cobrar com Pix
              OutlinedButton.icon(
                onPressed: () {
                  PersonalQrCodePixDialog.show(
                    context,
                    pixConfig: _pixConfig,
                    valorCobrado: aluno.valorMensalidade,
                    alunoNome: aluno.nome,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: CustomColors.primaryGreen,
                  side: BorderSide(color: CustomColors.primaryGreen),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.qr_code, size: 16),
                label: const Text(
                  'Cobrar Pix',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isPago
                    ? null
                    : () async {
                        await _repo.registrarRecebimentoMensalidade(
                          alunoId: aluno.id,
                          mesReferencia: '${DateTime.now().month.toString().padLeft(2,'0')}/${DateTime.now().year}',
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
                      ? GridColors.divider
                      : CustomColors.primaryGreen,
                  foregroundColor: isPago
                      ? GridColors.textSecondary
                      : GridColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isPago ? 'Recebido' : 'Dar Baixa',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              'Ocultar ficha de treino do aluno',
              style: TextStyle(color: GridColors.textPrimary, fontSize: 13),
            ),
            value: aluno.fichaOcultaParaAluno,
            activeColor: CustomColors.primaryGreen,
            onChanged: (oculta) async {
              await _repo.definirFichaOculta(alunoId: aluno.id, oculta: oculta);
              _carregarDados();
            },
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
    final contasEmAtraso =
        _contasPagar.where((c) => c.atrasado).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Seção: Contas a Pagar em Atraso (se houver)
        if (contasEmAtraso.isNotEmpty) ...[
          _buildTituloSecaoAlerta('Contas a Pagar em Atraso (${contasEmAtraso.length})',
              Icons.receipt_long, GridColors.error),
          ...contasEmAtraso.map((c) => _buildCardAlertaItem(
                titulo: c.descricao,
                subtitulo:
                    'Despesa de R\$ ${c.valor.toStringAsFixed(2)} (${c.categoria}) vencida em ${c.dataVencimento.day.toString().padLeft(2, '0')}/${c.dataVencimento.month.toString().padLeft(2, '0')}/${c.dataVencimento.year}.',
                botaoTexto: 'Marcar Paga',
                icone: Icons.error_outline,
                cor: GridColors.error,
                onAcao: () async {
                  await _repo.registrarPagamentoConta(c.id, pago: true);
                  _carregarDados();
                },
              )),
          const SizedBox(height: 20),
        ],

        // Seção: Fichas de Treino Vencendo ou Vencidas
        _buildTituloSecaoAlerta('Fichas de Treino a Vencer / Vencidas',
            Icons.fitness_center, GridColors.secondaryDark),
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
                cor: a.treinoVencido ? GridColors.error : GridColors.secondaryDark,
                onAcao: () => _modalDefinirValidadeTreino(context, a),
              )),
        const SizedBox(height: 20),

        // Seção: Cobranças & Alunos Devendo
        _buildTituloSecaoAlerta('Alunos em Débito (Inadimplentes)',
            Icons.money_off, GridColors.error),
        if (alunosEmDebito.isEmpty)
          _buildCardVazioAlerta('Nenhum aluno em débito este mês.')
        else
          ...alunosEmDebito.map((a) => _buildCardAlertaItem(
                titulo: a.nome,
                subtitulo:
                    'Mensalidade de R\$ ${a.valorMensalidade.toStringAsFixed(2)} vencida no dia ${a.diaVencimento}.',
                botaoTexto: 'Dar Baixa',
                icone: Icons.error_outline,
                cor: GridColors.error,
                onAcao: () async {
                  await _repo.registrarRecebimentoMensalidade(
                    alunoId: a.id,
                    mesReferencia: '${DateTime.now().month.toString().padLeft(2,'0')}/${DateTime.now().year}',
                  );
                  _carregarDados();
                },
              )),
        const SizedBox(height: 20),

        // Seção: Alunos Ausentes (Sem Treinar há 3+ dias)
        _buildTituloSecaoAlerta('Assiduidade & Alunos Ausentes',
            Icons.person_off, GridColors.secondaryDark),
        if (alunosAusentes.isEmpty)
          _buildCardVazioAlerta('Todos os alunos estão frequentes!')
        else
          ...alunosAusentes.map((a) => _buildCardAlertaItem(
                titulo: a.nome,
                subtitulo:
                    'Não registra treinos há ${a.diasSemTreinar} dias. Envie uma mensagem de incentivo!',
                botaoTexto: 'Notificar Aluno',
                icone: Icons.message,
                cor: GridColors.secondaryDark,
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
        color: GridColors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        msg,
        style: TextStyle(color: GridColors.textSecondary, fontSize: 13),
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
        color: GridColors.card,
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
                  style: TextStyle(
                    color: GridColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: TextStyle(
                    color: GridColors.textSecondary,
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
      backgroundColor: GridColors.card,
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
                style: TextStyle(
                  color: GridColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: treinoController,
                style: TextStyle(color: GridColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nome da Ficha / Treino',
                  labelStyle: TextStyle(color: GridColors.textSecondary),
                  filled: true,
                  fillColor: GridColors.inputBackground,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tempo para Alerta de Mudança de Treino:',
                style: TextStyle(
                  color: GridColors.textSecondary,
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
                    backgroundColor: GridColors.background,
                    labelStyle: TextStyle(
                      color: isSelected ? GridColors.textOnPrimary : GridColors.textPrimary,
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
                    foregroundColor: GridColors.textOnPrimary,
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

  void _modalHistoricoTreinosAluno(
      BuildContext context, PersonalAlunoGestaoModel aluno) async {
    List<SessaoTreinoRegistroModel> sessoes =
        await _repo.getHistoricoAluno(aluno.id);


    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: GridColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => SizedBox(
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
                      color: GridColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: CustomColors.primaryGreen.withOpacity(0.2),
                      foregroundColor: CustomColors.primaryGreen,
                      child: const Icon(Icons.history),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Histórico de Treinos: ${aluno.nome}',
                            style: TextStyle(
                              color: GridColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${sessoes.length} sessões • Toque no treino para ver os exercícios e cargas',
                            style: TextStyle(
                              color: GridColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: GridColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Divider(color: GridColors.divider, height: 24),
                Expanded(
                  child: sessoes.isEmpty ? Center(child:Text('Nenhum treino concluído por este aluno.',style:TextStyle(color:GridColors.textSecondary))) : ListView.separated(
                    itemCount: sessoes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final sessao = sessoes[idx];
                      final minutos = sessao.duracaoSegundos ~/ 60;

                      return Container(
                        decoration: BoxDecoration(
                          color: GridColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: idx == 0
                                ? CustomColors.primaryGreen.withOpacity(0.5)
                                : GridColors.divider,
                          ),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            initiallyExpanded: idx == 0,
                            iconColor: CustomColors.primaryGreen,
                            collapsedIconColor: GridColors.textSecondary,
                            tilePadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            title: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: CustomColors.primaryGreen,
                                  foregroundColor: GridColors.textOnPrimary,
                                  child: Text(
                                    sessao.divisaoLetra,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    sessao.divisaoNome,
                                    style: TextStyle(
                                      color: GridColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: GridColors.secondaryDark.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'RPE ${sessao.rpe}/10',
                                    style: TextStyle(
                                      color: GridColors.secondaryDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 12, color: GridColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    sessao.dataHoraInicio,
                                    style: TextStyle(
                                      color: GridColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(Icons.timer_outlined,
                                      size: 12, color: GridColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$minutos min',
                                    style: TextStyle(
                                      color: GridColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${sessao.exerciciosExecutados.length} exercícios',
                                    style: TextStyle(
                                      color: CustomColors.primaryGreen,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            children: [
                              if (sessao.feedbackAluno != null &&
                                  sessao.feedbackAluno!.isNotEmpty) ...[
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: GridColors.card,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: GridColors.divider),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.chat_bubble_outline,
                                          size: 14, color: GridColors.info),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '"${sessao.feedbackAluno}"',
                                          style: TextStyle(
                                            color: GridColors.textSecondary,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(14, 4, 14, 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Exercícios Realizados e Cargas:',
                                      style: TextStyle(
                                        color: GridColors.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...sessao.exerciciosExecutados
                                        .map((ex) => _buildItemExercicioExecutado(ex)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemExercicioExecutado(ExercicioExecutadoRegistroModel ex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GridColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ex.exercicioNome,
                  style: TextStyle(
                    color: GridColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CustomColors.primaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ex.grupoMuscular,
                  style: TextStyle(
                    color: CustomColors.primaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Lista horizontal ou wrap de séries com repetições e carga
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: ex.series.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: GridColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: CustomColors.primaryGreen.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'S${s.numero}: ',
                      style: TextStyle(
                          color: GridColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${s.repeticoesRealizadas} reps',
                      style: TextStyle(
                          color: GridColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '@ ${s.cargaRealKg.toStringAsFixed(0)} kg',
                      style: TextStyle(
                        color: CustomColors.primaryGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (ex.observacaoAluno != null && ex.observacaoAluno!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Obs: ${ex.observacaoAluno}',
              style: TextStyle(
                color: GridColors.textSecondary,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _modalNovoAluno(BuildContext context, {PersonalAlunoGestaoModel? aluno}) async {
    final salvo = await showModalBottomSheet<PersonalAlunoGestaoModel>(
      context: context, backgroundColor: GridColors.card, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => PersonalAlunoSheet(aluno: aluno));
    if (salvo != null && context.mounted) {
      await _carregarDados();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor:CustomColors.primaryGreen,content:Text('Aluno salvo. Alterações offline ficam pendentes para sincronizar.',style:TextStyle(color:GridColors.textOnPrimary))));
    }
  }

  /// Clona o treino ativo de outro aluno para [destino]. O original nao muda.
  Future<void> _clonarTreinoDeOutroAluno(PersonalAlunoGestaoModel destino) async {
    final outros = _alunos.where((a) => a.id != destino.id).toList();
    if (outros.isEmpty) {
      _snack('Não há outro aluno para copiar o treino.');
      return;
    }
    final origem = await showDialog<PersonalAlunoGestaoModel>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: GridColors.card,
        title: Text('Copiar treino de qual aluno?',
            style: TextStyle(color: GridColors.textPrimary)),
        children: [
          for (final a in outros)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, a),
              child: Text(a.nome, style: TextStyle(color: GridColors.textPrimary)),
            ),
        ],
      ),
    );
    if (origem == null || !mounted) return;

    final planos = await FitnessOfflineRepository().getPlanosTreino(alunoId: origem.id);
    final ativo = planos.where((p) => !p.isTemplate && p.ativo).firstOrNull;
    if (ativo == null) {
      _snack('${origem.nome} não tem treino ativo para copiar.');
      return;
    }

    final hoje = DateTime.now().toIso8601String().split('T').first;
    final clone = ativo.clonarParaAluno(
      novoId: 'plano_${DateTime.now().millisecondsSinceEpoch}',
      alunoId: destino.id,
      alunoNome: destino.nome,
      dataInicio: hoje,
    );
    final repo = FitnessOfflineRepository();
    await repo.salvarPlanoTreino(clone);
    await PersonalGestaoOfflineRepository().publicarTreino(destino.id, clone);
    await _repo.salvarAluno(destino.copyWith(treinoAtualNome: clone.titulo, dataInicioTreino: hoje));
    if (!mounted) return;
    _snack('Treino de ${origem.nome} copiado para ${destino.nome}.');
    await _carregarDados();
  }

  void _snack(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: CustomColors.primaryGreen,
      content: Text(mensagem, style: TextStyle(color: GridColors.textOnPrimary)),
    ));
  }

  Future<void> _montarTreino(PersonalAlunoGestaoModel aluno) async {
    final planos = await FitnessOfflineRepository().getPlanosTreino(alunoId:aluno.id);
    if (!mounted) return;
    final retorno = await Navigator.push<PlanoTreinoModel>(context,MaterialPageRoute(
      builder:(_) => MontadorTreinoScreen(alunoId:aluno.id,alunoNome:aluno.nome,
        planoParaEditar:planos.where((p)=>!p.isTemplate && p.ativo).firstOrNull)));
    if (retorno!=null) {
      await _repo.salvarAluno(aluno.copyWith(treinoAtualNome:retorno.titulo,dataInicioTreino:retorno.dataInicio));
      if (mounted) await _carregarDados();
    }
  }
}
