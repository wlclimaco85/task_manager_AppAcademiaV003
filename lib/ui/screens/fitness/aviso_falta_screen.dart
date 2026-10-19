import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/fitness/aviso_falta_model.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/utils/fitness_access.dart';
import 'package:task_manager_flutter/data/services/aviso_falta_repository.dart';

/// Tela de Aviso de Falta — Aluno avisa o personal e Personal avisa os alunos.
///
/// Visível apenas quando o aluno tiver um personal vinculado (exibir via guard
/// na chamada — ex: [vinculadoComPersonal] == true) ou quando for um personal.
class AvisoFaltaScreen extends StatefulWidget {
  const AvisoFaltaScreen({super.key});

  @override
  State<AvisoFaltaScreen> createState() => _AvisoFaltaScreenState();
}

class _AvisoFaltaScreenState extends State<AvisoFaltaScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _repo = AvisoFaltaRepository();
  bool _ocupado = false;

  // ── Formulário ────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  DateTime _dataAula = DateTime.now().add(const Duration(days: 1));
  TimeOfDay? _horario;
  final _motivoCtrl = TextEditingController();

  // ── Listas ────────────────────────────────────────────────────
  List<AvisoFaltaModel> _enviados = [];
  List<AvisoFaltaModel> _recebidos = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _carregar();
  }

  @override
  void dispose() {
    _tab.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final caixa = await _repo.carregar();
      if (mounted) {
        setState(() {
          _enviados = caixa.enviados;
          _recebidos = caixa.recebidos;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível atualizar os avisos: $e')),
        );
      }
    }
  }

  // ── Dados do usuário logado ───────────────────────────────────
  String get _meuId => AuthUtility.userInfo.login?.id?.toString() ?? 'eu';
  String get _meuNome => AuthUtility.userInfo.login?.nome ?? 'Eu';

  /// Verifica se o usuário é personal trainer
  bool get _souPersonal => podeGerenciarAlunos();

  // ── Envio ─────────────────────────────────────────────────────
  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _ocupado = true);
    try {
      final dataStr = DateFormat('yyyy-MM-dd').format(_dataAula);
      final horarioStr = _horario != null
          ? '${_horario!.hour.toString().padLeft(2, '0')}:${_horario!.minute.toString().padLeft(2, '0')}'
          : null;

      if (_souPersonal) {
        // Personal avisa todos os alunos — broadcast simplificado
        await _repo.enviar(
          remetenteTipo: 'personal',
          remetenteId: _meuId,
          remetenteNome: _meuNome,
          destinatarioId: 'todos_alunos',
          destinatarioNome: 'Seus alunos',
          dataAula: dataStr,
          horario: horarioStr,
          motivo: _motivoCtrl.text.trim(),
        );
      } else {
        // Aluno avisa o personal vinculado.
        // O personal do aluno pode vir via parceiro ou campo futuro da sessão.
        // Por ora usa o parceiro da sessão como identificador do personal.
        final parceiro = AuthUtility.userInfo.login?.parceiro;
        final personalId = parceiro?.id?.toString() ?? 'personal';
        final personalNome =
            parceiro?.nome ?? parceiro?.razaoSocial ?? 'Personal';
        await _repo.enviar(
          remetenteTipo: 'aluno',
          remetenteId: _meuId,
          remetenteNome: _meuNome,
          destinatarioId: personalId,
          destinatarioNome: personalNome,
          dataAula: dataStr,
          horario: horarioStr,
          motivo: _motivoCtrl.text.trim(),
        );
      }

      _motivoCtrl.clear();
      setState(() => _dataAula = DateTime.now().add(const Duration(days: 1)));
      await _carregar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Aviso enviado com sucesso!'),
            backgroundColor: CustomColors.primaryGreen,
          ),
        );
        _tab.animateTo(2); // vai para aba "Enviados"
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar aviso: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _marcarVisto(String id) async {
    try {
      await _repo.marcarComoVisto(id);
      await _carregar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Marcado como visto.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível confirmar: $e')),
        );
      }
    }
  }

  Future<void> _remover(String id) async {
    try {
      await _repo.removerEnviado(id);
      await _carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível remover: $e')),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        title: Text(
          'Aviso de Falta',
          style: TextStyle(
              color: context.appText,
              fontWeight: FontWeight.w700,
              fontSize: 18),
        ),
        bottom: TabBar(
          isScrollable: true,
          controller: _tab,
          labelColor: CustomColors.primaryGreen,
          unselectedLabelColor: context.appTextSecondary,
          indicatorColor: CustomColors.primaryGreen,
          tabs: [
            const Tab(text: 'Novo aviso'),
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Recebidos'),
                if (_recebidos.where((item) => !item.foiVisto).isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_recebidos.where((item) => !item.foiVisto).length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ]),
            ),
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Enviados'),
                if (_enviados.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: CustomColors.primaryGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${_enviados.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ]),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildFormulario(),
          _buildListaRecebidos(),
          _buildListaEnviados(),
        ],
      ),
    );
  }

  // ── Aba 1: Formulário ─────────────────────────────────────────
  Widget _buildFormulario() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Banner contextual
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CustomColors.primaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: CustomColors.primaryGreen.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline,
                  color: CustomColors.primaryGreen, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _souPersonal
                      ? 'Avise seus alunos sobre uma ausência. Eles receberão uma notificação e poderão confirmar a leitura.'
                      : 'Avise seu personal sobre uma ausência. Ele receberá uma notificação e poderá marcar como visto.',
                  style: TextStyle(
                      color: CustomColors.primaryGreen, fontSize: 13),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Data da aula
          Text('Data da aula que não ocorrerá',
              style: TextStyle(
                  color: context.appText,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          const SizedBox(height: 8),
          InkWell(
            onTap: _ocupado ? null : _selecionarData,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appBorder),
              ),
              child: Row(children: [
                Icon(Icons.calendar_today_outlined,
                    color: CustomColors.primaryGreen, size: 20),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd/MM/yyyy (EEEE)', 'pt_BR').format(_dataAula),
                  style: TextStyle(
                      color: context.appText,
                      fontSize: 15,
                      fontWeight: FontWeight.w500),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          // Horário (opcional)
          Text('Horário da aula (opcional)',
              style: TextStyle(
                  color: context.appText,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          const SizedBox(height: 8),
          InkWell(
            onTap: _ocupado ? null : _selecionarHorario,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appBorder),
              ),
              child: Row(children: [
                Icon(Icons.access_time_outlined,
                    color: CustomColors.primaryGreen, size: 20),
                const SizedBox(width: 12),
                Text(
                  _horario != null
                      ? '${_horario!.hour.toString().padLeft(2, '0')}:${_horario!.minute.toString().padLeft(2, '0')}'
                      : 'Toque para informar o horário',
                  style: TextStyle(
                      color: _horario != null
                          ? context.appText
                          : context.appTextSecondary,
                      fontSize: 15),
                ),
                if (_horario != null) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _horario = null),
                    child: Icon(Icons.close,
                        size: 18, color: GridColors.textSecondary),
                  ),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 14),

          // Motivo
          Text('Motivo (opcional)',
              style: TextStyle(
                  color: context.appText,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _motivoCtrl,
            enabled: !_ocupado,
            maxLines: 3,
            maxLength: 200,
            style: TextStyle(color: context.appText),
            decoration: InputDecoration(
              hintText: 'Ex: médico, compromisso profissional, viagem...',
              hintStyle:
                  TextStyle(color: context.appTextSecondary, fontSize: 13),
              filled: true,
              fillColor: context.appSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.appBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.appBorder),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Botão enviar
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: CustomColors.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _ocupado ? null : _enviar,
            icon: _ocupado
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_outlined),
            label: Text(_ocupado ? 'Enviando...' : 'Enviar aviso de falta',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ]),
      ),
    );
  }

  Future<void> _selecionarData() async {
    final pick = await showDatePicker(
      context: context,
      initialDate: _dataAula,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('pt', 'BR'),
    );
    if (pick != null && mounted) setState(() => _dataAula = pick);
  }

  Future<void> _selecionarHorario() async {
    final pick = await showTimePicker(
      context: context,
      initialTime: _horario ?? const TimeOfDay(hour: 7, minute: 0),
    );
    if (pick != null && mounted) setState(() => _horario = pick);
  }

  // ── Aba 2: Recebidos ──────────────────────────────────────────
  Widget _buildListaRecebidos() {
    if (_recebidos.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.mark_email_read_outlined,
              size: 56, color: context.appTextSecondary),
          const SizedBox(height: 12),
          Text('Nenhum aviso recebido.',
              style: TextStyle(color: context.appTextSecondary, fontSize: 15)),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _recebidos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _AvisoCard(
        aviso: _recebidos[i],
        recebido: true,
        onMarcarVisto: _marcarVisto,
      ),
    );
  }

  // ── Aba 3: Enviados ───────────────────────────────────────────
  Widget _buildListaEnviados() {
    if (_enviados.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.notifications_none_outlined,
              size: 56, color: context.appTextSecondary),
          const SizedBox(height: 12),
          Text('Nenhum aviso enviado ainda.',
              style: TextStyle(color: context.appTextSecondary, fontSize: 15)),
        ]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _enviados.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _AvisoCard(
        aviso: _enviados[i],
        recebido: false,
        onRemover: _remover,
      ),
    );
  }
}

// ── Card de Aviso ─────────────────────────────────────────────

class _AvisoCard extends StatelessWidget {
  final AvisoFaltaModel aviso;
  final bool recebido;
  final ValueChanged<String>? onMarcarVisto;
  final ValueChanged<String>? onRemover;

  const _AvisoCard({
    required this.aviso,
    required this.recebido,
    this.onMarcarVisto,
    this.onRemover,
  });

  String _formatarData(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('dd/MM/yyyy (EEE)', 'pt_BR').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final isPendente = !aviso.foiVisto;
    final isPersonalEnviando = aviso.remetenteTipo == 'personal';

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPendente
              ? CustomColors.primaryGreen.withValues(alpha: 0.35)
              : context.appBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header: ícone + título + badge status
          Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: (isPersonalEnviando
                      ? const Color(0xFF7C3AED)
                      : CustomColors.primaryGreen)
                  .withValues(alpha: 0.12),
              child: Icon(
                isPersonalEnviando
                    ? Icons.sports_outlined
                    : Icons.person_outlined,
                size: 20,
                color: isPersonalEnviando
                    ? const Color(0xFF7C3AED)
                    : CustomColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recebido
                          ? 'De: ${aviso.remetenteNome}'
                          : 'Para: ${aviso.destinatarioNome}',
                      style: TextStyle(
                          color: context.appText,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    Text(
                      'Aula: ${_formatarData(aviso.dataAula)}'
                      '${aviso.horario != null ? " às ${aviso.horario}" : ""}',
                      style: TextStyle(
                          color: context.appTextSecondary, fontSize: 12),
                    ),
                  ]),
            ),
            // Badge status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: aviso.foiVisto
                    ? Colors.green.withValues(alpha: 0.12)
                    : Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  aviso.foiVisto ? Icons.done_all : Icons.schedule_outlined,
                  size: 13,
                  color: aviso.foiVisto ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  aviso.foiVisto ? 'Visto ✓' : 'Aguardando',
                  style: TextStyle(
                    color: aviso.foiVisto ? Colors.green : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            ),
          ]),

          // Motivo
          if (aviso.motivo.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.notes_outlined,
                  size: 14, color: context.appTextSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(aviso.motivo,
                    style: TextStyle(
                        color: context.appTextSecondary, fontSize: 13)),
              ),
            ]),
          ],

          // Data/hora visto
          if (aviso.foiVisto && aviso.vistoEm != null) ...[
            const SizedBox(height: 6),
            Text(
              'Visto em: ${DateFormat('dd/MM/yyyy HH:mm').format(aviso.vistoEm!)}',
              style: const TextStyle(color: Colors.green, fontSize: 11),
            ),
          ],

          // Ações
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            if (recebido && isPendente && onMarcarVisto != null)
              TextButton.icon(
                style: TextButton.styleFrom(
                    foregroundColor: CustomColors.primaryGreen),
                onPressed: () => onMarcarVisto!(aviso.id),
                icon: const Icon(Icons.done_all, size: 16),
                label:
                    const Text('Marcar visto', style: TextStyle(fontSize: 12)),
              ),
            if (!recebido && onRemover != null) ...[
              const SizedBox(width: 4),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: GridColors.error),
                onPressed: () => onRemover!(aviso.id),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Remover', style: TextStyle(fontSize: 12)),
              ),
            ],
          ]),
        ]),
      ),
    );
  }
}
