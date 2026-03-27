import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/controller/ponto_controller.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';

import 'pdf_preview_dialog.dart';

class PontoScreen extends ConsumerStatefulWidget {
  const PontoScreen({super.key});

  @override
  ConsumerState<PontoScreen> createState() => _PontoScreenState();
}

class _PontoScreenState extends ConsumerState<PontoScreen> {
  late DateTime now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    now = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _mostrarSnack(String msg) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final login = AuthUtility.userInfo?.login;
    if (login == null || login.id == null) {
      return const Scaffold(
        body: Center(
          child: Text('Login não encontrado na sessão'),
        ),
      );
    }

    final loginId = login.id!;

    final pontoState = ref.watch(pontoControllerProvider(loginId));
    final controller = ref.read(pontoControllerProvider(loginId).notifier);

    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        backgroundColor: GridColors.primary,
        title: const Text(
          'Registro de Ponto',
          style: TextStyle(
            color: GridColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.carregarDiaAtual(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildClockCard(
                registering: pontoState.registering,
                onRegistrar: () async {
                  final ok = await controller.registrarPontoAutomatico(context);
                  if (ok) {
                    await _mostrarSnack('Ponto registrado com sucesso!');
                  } else {
                    await _mostrarSnack(
                      pontoState.error ?? 'Erro ao registrar ponto',
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              _buildMarcacoesCard(
                marcacoes: controller.marcacoesAgrupadas,
                horasTrabalhadas: controller.horasTrabalhadasFormatada,
                intervalo: controller.intervaloFormatado,
                loading: pontoState.loading,
              ),
              const SizedBox(height: 20),
              _buildActionButtons(
                context,
                onPdf: () async {
                  final bytes = await controller.gerarRelatorioPdf();
                  if (bytes == null) {
                    await _mostrarSnack(
                        'Não foi possível gerar o PDF de batidas');
                    return;
                  }

                  if (!mounted) return;
                  showDialog(
                    context: context,
                    builder: (_) => PdfPreviewDialog(bytes: bytes),
                  );
                },
                onBancoHoras: () async {
                  final valor = await controller.carregarBancoHorasMesAtual();
                  if (valor == null) {
                    await _mostrarSnack(
                      pontoState.error ?? 'Erro ao carregar banco de horas',
                    );
                    return;
                  }

                  if (!mounted) return;
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Banco de Horas'),
                      content: Text(
                        'Saldo: ${valor.toStringAsFixed(2)} horas',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              _buildHumorSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClockCard({
    required bool registering,
    required VoidCallback onRegistrar,
  }) {
    return Card(
      color: GridColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Text(
              DateFormat.Hms().format(now),
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: GridColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat("EEEE, dd 'de' MMMM 'de' yyyy", 'pt_BR').format(now),
              style: const TextStyle(
                fontSize: 15,
                color: GridColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              onPressed: registering ? null : onRegistrar,
              icon: const Icon(Icons.fingerprint, color: Colors.white),
              label: Text(
                registering ? 'Registrando...' : 'Registrar Ponto',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Clique para registrar sua entrada/saída automaticamente',
              style: TextStyle(
                fontSize: 13,
                color: GridColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarcacoesCard({
    required List<Map<String, String>> marcacoes,
    required String horasTrabalhadas,
    required String intervalo,
    required bool loading,
  }) {
    return Card(
      color: GridColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.schedule, color: GridColors.primary),
                SizedBox(width: 8),
                Text(
                  'Marcações de Hoje',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: GridColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (marcacoes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Nenhuma marcação registrada hoje.',
                  style: TextStyle(color: GridColors.textSecondary),
                ),
              )
            else
              Column(
                children: marcacoes
                    .map(
                      (m) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTimeBadge(
                              Icons.login,
                              m['entrada'] ?? '--:--',
                              true,
                            ),
                            const Icon(
                              Icons.swap_horiz,
                              color: GridColors.textSecondary,
                            ),
                            _buildTimeBadge(
                              Icons.logout,
                              m['saida'] ?? '--:--',
                              false,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 16),
            _buildInfoRow('Horas trabalhadas hoje', horasTrabalhadas),
            _buildInfoRow('Intervalos', intervalo),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBadge(IconData icon, String time, bool start) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: start
            ? GridColors.success.withOpacity(0.15)
            : GridColors.error.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: start ? GridColors.success : GridColors.error,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            time,
            style: TextStyle(
              color: start ? GridColors.success : GridColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: GridColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              color: GridColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context, {
    required VoidCallback onPdf,
    required VoidCallback onBancoHoras,
  }) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.edit_calendar, color: Colors.white),
          label: const Text(
            'Solicitar Ajuste de Ponto',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: GridColors.primary,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: onPdf,
          icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
          label: const Text(
            'Gerar PDF',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: GridColors.buttonBackground,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: onBancoHoras,
          icon: const Icon(Icons.timelapse, color: Colors.white),
          label: const Text(
            'Saldo do Banco de Horas',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: GridColors.success,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHumorSection() {
    final icons = [
      Icons.sentiment_very_satisfied,
      Icons.sentiment_satisfied,
      Icons.sentiment_neutral,
      Icons.sentiment_dissatisfied,
      Icons.sentiment_very_dissatisfied,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Como está seu humor hoje?',
          style: TextStyle(
            color: GridColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: icons
              .map(
                (icon) => IconButton(
                  icon: Icon(icon, size: 34, color: GridColors.primary),
                  onPressed: () {},
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
