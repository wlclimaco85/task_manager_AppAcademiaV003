import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
import 'package:task_manager_flutter/data/services/fitness_push_notification_service.dart';
import 'package:task_manager_flutter/data/models/fitness/exercicio_model.dart' as task_manager_flutter_models;

/// Player de Treino Interativo ao Vivo (Padrão MyFitCoach / MFIT Aluno)
/// Interface escura esportiva, algoritmo de sobrecarga progressiva, cronômetro automático de descanso e card de compartilhamento Stories.
class PlayerTreinoAoVivoScreen extends StatefulWidget {
  final DivisaoTreinoModel divisao;
  final String planoId;
  final String alunoId;

  const PlayerTreinoAoVivoScreen({
    super.key,
    required this.divisao,
    required this.planoId,
    required this.alunoId,
  });

  @override
  State<PlayerTreinoAoVivoScreen> createState() =>
      _PlayerTreinoAoVivoScreenState();
}

class _PlayerTreinoAoVivoScreenState extends State<PlayerTreinoAoVivoScreen> {
  final _repository = FitnessOfflineRepository();
  final _pushService = FitnessPushNotificationService();
  final DateTime _inicioSessao = DateTime.now();

  int _exercicioIndexAtual = 0;
  final Map<int, List<SerieRegistroModel>> _seriesPorExercicio = {};

  // Sobrecarga inteligente (Algoritmo MyFitCoach)
  Map<String, dynamic>? _sugestaoSobrecargaAtual;
  bool _carregandoSugestao = false;

  // Cronômetro de descanso
  Timer? _descansoTimer;
  int _descansoRestanteSegundos = 0;
  int _descansoTotalSegundos = 60;
  bool _descansoAtivo = false;

  @override
  void initState() {
    super.initState();
    _inicializarSeries();
    _carregarSugestaoParaExercicioAtual();
  }

  void _inicializarSeries() {
    for (int i = 0; i < widget.divisao.exercicios.length; i++) {
      final ex = widget.divisao.exercicios[i];
      _seriesPorExercicio[i] = List.generate(
        ex.series,
        (serieIdx) => SerieRegistroModel(
          numero: serieIdx + 1,
          cargaRealKg: ex.cargaSugeridaKg,
          repeticoesRealizadas:
              int.tryParse(ex.repeticoes.split(RegExp(r'\D+')).first) ?? 10,
          concluida: false,
        ),
      );
    }
  }

  Future<void> _carregarSugestaoParaExercicioAtual() async {
    if (widget.divisao.exercicios.isEmpty) return;
    final exAtual = widget.divisao.exercicios[_exercicioIndexAtual];
    final repsPrescritas =
        int.tryParse(exAtual.repeticoes.split(RegExp(r'\D+')).first) ?? 10;

    setState(() => _carregandoSugestao = true);
    try {
      final sugestao = await _repository.calcularSugestaoSobrecarga(
        exercicioId: exAtual.exercicioId,
        cargaAtualKg: exAtual.cargaSugeridaKg,
        repsPrescritas: repsPrescritas,
        alunoId: widget.alunoId,
      );
      if (mounted) {
        setState(() {
          _sugestaoSobrecargaAtual = sugestao;
          _carregandoSugestao = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _carregandoSugestao = false);
    }
  }

  void _aplicarSugestaoSobrecarga() {
    if (_sugestaoSobrecargaAtual == null) return;
    final novaCarga =
        (_sugestaoSobrecargaAtual!['cargaSugeridaKg'] as num?)?.toDouble() ??
            0.0;
    if (novaCarga <= 0) return;

    HapticFeedback.lightImpact();
    setState(() {
      final series = _seriesPorExercicio[_exercicioIndexAtual] ?? [];
      _seriesPorExercicio[_exercicioIndexAtual] = series
          .map((s) => SerieRegistroModel(
                numero: s.numero,
                cargaRealKg: novaCarga,
                repeticoesRealizadas: s.repeticoesRealizadas,
                concluida: s.concluida,
              ))
          .toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '⚡ Sobrecarga aplicada: ${novaCarga.toStringAsFixed(1)}kg em todas as séries!'),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _iniciarCronometroDescanso(int segundos) {
    _descansoTimer?.cancel();
    HapticFeedback.mediumImpact();

    setState(() {
      _descansoTotalSegundos = segundos;
      _descansoRestanteSegundos = segundos;
      _descansoAtivo = true;
    });

    _descansoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_descansoRestanteSegundos > 1) {
        setState(() => _descansoRestanteSegundos--);
      } else {
        timer.cancel();
        HapticFeedback.heavyImpact();
        setState(() {
          _descansoRestanteSegundos = 0;
          _descansoAtivo = false;
        });
      }
    });
  }

  void _pularDescanso() {
    _descansoTimer?.cancel();
    setState(() {
      _descansoRestanteSegundos = 0;
      _descansoAtivo = false;
    });
  }

  void _adicionarTempoDescanso(int segundos) {
    setState(() {
      _descansoRestanteSegundos += segundos;
      _descansoTotalSegundos += segundos;
    });
  }

  @override
  void dispose() {
    _descansoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktopOrWeb = width >= 800;

    if (widget.divisao.exercicios.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          title: Text('Treino ${widget.divisao.letra}'),
        ),
        body: const Center(
          child: Text(
            'Esta divisão ainda não possui exercícios cadastrados.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final exAtual = widget.divisao.exercicios[_exercicioIndexAtual];
    final seriesAtuais = _seriesPorExercicio[_exercicioIndexAtual] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120), // Deep Slate Obsidian
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Treino ${widget.divisao.letra} • ${widget.divisao.nome}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            Text(
              'Exercício ${_exercicioIndexAtual + 1} de ${widget.divisao.exercicios.length}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFF10B981)),
            icon: const Icon(Icons.check_circle, size: 20),
            label: const Text('Concluir',
                style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: _confirmarFinalizarTreino,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: isDesktopOrWeb ? 800 : double.infinity),
          child: Column(
            children: [
              // 1. Barra de Progresso Geral do Treino
              LinearProgressIndicator(
                value: (_exercicioIndexAtual + 1) /
                    widget.divisao.exercicios.length,
                backgroundColor: const Color(0xFF1E293B),
                color: const Color(0xFF10B981),
                minHeight: 4,
              ),

              // 2. Banner do Exercício Atual
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.fitness_center,
                          color: Color(0xFF10B981), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exAtual.exercicioNome,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${exAtual.grupoMuscular} • ${exAtual.series} séries • ${exAtual.repeticoes} reps',
                            style: const TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _mostrarDemonstracao(exAtual.exercicioId),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_circle_fill, color: Color(0xFF3B82F6), size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Ver Demonstração e Instruções',
                                    style: TextStyle(
                                      color: Color(0xFF3B82F6),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Banner de Sobrecarga Inteligente (MyFitCoach Overload Engine)
              if (_sugestaoSobrecargaAtual != null)
                _buildBannerSobrecargaInteligente(),

              // 4. Tabela de Séries com Checkbox e Ajustes Rápidos
              Expanded(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: seriesAtuais.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final serie = seriesAtuais[idx];
                    return _buildCardSerieAoVivo(
                        serie, idx, exAtual.descansoSegundos);
                  },
                ),
              ),

              // 5. Barra Inferior do Cronômetro de Descanso
              if (_descansoAtivo) _buildBarraDescanso(),

              // 6. Botões de Navegação Entre Exercícios
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    if (_exercicioIndexAtual > 0)
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Color(0xFF475569)),
                          ),
                          onPressed: () {
                            setState(() => _exercicioIndexAtual--);
                            _carregarSugestaoParaExercicioAtual();
                          },
                          child: const Text('Anterior'),
                        ),
                      ),
                    if (_exercicioIndexAtual > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          if (_exercicioIndexAtual <
                              widget.divisao.exercicios.length - 1) {
                            setState(() => _exercicioIndexAtual++);
                            _carregarSugestaoParaExercicioAtual();
                          } else {
                            _confirmarFinalizarTreino();
                          }
                        },
                        child: Text(
                          _exercicioIndexAtual <
                                  widget.divisao.exercicios.length - 1
                              ? 'Próximo Exercício'
                              : 'Concluir Treino',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarDemonstracao(String exercicioId) async {
    final todosExercicios = await _repository.getExercicios();
    final exercicio = todosExercicios.firstWhere(
      (e) => e.id == exercicioId,
      orElse: () => const task_manager_flutter_models.ExercicioModel(
        id: '', nome: 'Não encontrado', grupoMuscular: '', instrucoes: 'Sem instruções disponíveis.',
      ),
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 40),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          exercicio.nome,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (exercicio.videoUrl != null && exercicio.videoUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        exercicio.videoUrl!,
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) {
                          return Container(
                            height: 200,
                            color: const Color(0xFF0F172A),
                            alignment: Alignment.center,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, color: Color(0xFF475569), size: 48),
                                SizedBox(height: 8),
                                Text('Animação indisponível', style: TextStyle(color: Color(0xFF94A3B8))),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.ondemand_video, color: Color(0xFF475569), size: 48),
                          SizedBox(height: 8),
                          Text('Nenhuma demonstração visual', style: TextStyle(color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text('Instruções de Execução', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    exercicio.instrucoes.isNotEmpty ? exercicio.instrucoes : 'Não há instruções para este exercício.',
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                  if (exercicio.errosComuns != null && exercicio.errosComuns!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Erros Comuns', style: TextStyle(color: Color(0xFFEF4444), fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      exercicio.errosComuns!,
                      style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Banner de Sobrecarga Inteligente (MyFitCoach)
  Widget _buildBannerSobrecargaInteligente() {
    final sugestao = _sugestaoSobrecargaAtual!;
    final temSugestao = sugestao['temSugestao'] == true;
    final motivo = sugestao['motivo']?.toString() ?? '';
    final cargaSugerida = (sugestao['cargaSugeridaKg'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: temSugestao
            ? const Color(0xFF064E3B).withValues(alpha: 0.6)
            : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: temSugestao
              ? const Color(0xFF10B981)
              : const Color(0xFF334155),
        ),
      ),
      child: Row(
        children: [
          Icon(
            temSugestao ? Icons.bolt : Icons.insights,
            color: temSugestao ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  temSugestao
                      ? '⚡ Sobrecarga Recomendada (MyFitCoach)'
                      : 'Histórico & Carga',
                  style: TextStyle(
                    color: temSugestao
                        ? const Color(0xFF34D399)
                        : const Color(0xFFCBD5E1),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  motivo,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            ),
          ),
          if (temSugestao && cargaSugerida > 0)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: _aplicarSugestaoSobrecarga,
              child: Text(
                'Aplicar ${cargaSugerida.toStringAsFixed(1)}kg',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardSerieAoVivo(
      SerieRegistroModel serie, int serieIdx, int descansoPadrao) {
    final concluida = serie.concluida;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: concluida
            ? const Color(0xFF064E3B).withValues(alpha: 0.4)
            : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: concluida ? const Color(0xFF10B981) : const Color(0xFF334155),
        ),
      ),
      child: Row(
        children: [
          // Número da série
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: concluida
                  ? const Color(0xFF10B981)
                  : const Color(0xFF334155),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${serie.numero}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Carga (kg)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Carga (kg)',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                Row(
                  children: [
                    Text(
                      '${serie.cargaRealKg.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _ajustarCargaSerie(serieIdx, -1.0),
                      child: const Icon(Icons.remove_circle_outline,
                          color: Color(0xFF94A3B8), size: 18),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _ajustarCargaSerie(serieIdx, 1.0),
                      child: const Icon(Icons.add_circle_outline,
                          color: Color(0xFF10B981), size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Repetições
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reps',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                Row(
                  children: [
                    Text(
                      '${serie.repeticoesRealizadas}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _ajustarRepsSerie(serieIdx, -1),
                      child: const Icon(Icons.remove_circle_outline,
                          color: Color(0xFF94A3B8), size: 18),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _ajustarRepsSerie(serieIdx, 1),
                      child: const Icon(Icons.add_circle_outline,
                          color: Color(0xFF10B981), size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Botão de Check da Série
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              final novoEstado = !concluida;
              setState(() {
                _seriesPorExercicio[_exercicioIndexAtual]![serieIdx] =
                    SerieRegistroModel(
                  numero: serie.numero,
                  cargaRealKg: serie.cargaRealKg,
                  repeticoesRealizadas: serie.repeticoesRealizadas,
                  concluida: novoEstado,
                );
              });

              if (novoEstado) {
                _iniciarCronometroDescanso(descansoPadrao);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    concluida ? const Color(0xFF10B981) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: concluida
                      ? const Color(0xFF10B981)
                      : const Color(0xFF64748B),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.check,
                color: concluida ? Colors.white : Colors.transparent,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraDescanso() {
    final progress = _descansoTotalSegundos > 0
        ? _descansoRestanteSegundos / _descansoTotalSegundos
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F766E), // Teal Dark
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                ),
                Text(
                  '$_descansoRestanteSegundos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Intervalo de descanso...',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => _adicionarTempoDescanso(15),
            child: const Text('+15s', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: _pularDescanso,
            child: const Text('Pular', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _ajustarCargaSerie(int serieIdx, double delta) {
    final serie = _seriesPorExercicio[_exercicioIndexAtual]![serieIdx];
    final novaCarga = (serie.cargaRealKg + delta).clamp(0.0, 500.0);
    setState(() {
      _seriesPorExercicio[_exercicioIndexAtual]![serieIdx] =
          SerieRegistroModel(
        numero: serie.numero,
        cargaRealKg: novaCarga,
        repeticoesRealizadas: serie.repeticoesRealizadas,
        concluida: serie.concluida,
      );
    });
  }

  void _ajustarRepsSerie(int serieIdx, int delta) {
    final serie = _seriesPorExercicio[_exercicioIndexAtual]![serieIdx];
    final novasReps = (serie.repeticoesRealizadas + delta).clamp(1, 100);
    setState(() {
      _seriesPorExercicio[_exercicioIndexAtual]![serieIdx] =
          SerieRegistroModel(
        numero: serie.numero,
        cargaRealKg: serie.cargaRealKg,
        repeticoesRealizadas: novasReps,
        concluida: serie.concluida,
      );
    });
  }

  void _confirmarFinalizarTreino() {
    int rpeSelecionado = 7;
    final feedbackCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final fimSessao = DateTime.now();
            final duracaoMinutos =
                fimSessao.difference(_inicioSessao).inMinutes.clamp(1, 300);

            // Calcula tonelagem total levantada (Volume Load)
            double tonelagemKg = 0;
            int totalSeriesConcluidas = 0;
            _seriesPorExercicio.forEach((_, series) {
              for (final s in series) {
                if (s.concluida) {
                  tonelagemKg += (s.cargaRealKg * s.repeticoesRealizadas);
                  totalSeriesConcluidas++;
                }
              }
            });

            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.emoji_events,
                      color: Color(0xFFF59E0B), size: 28),
                  SizedBox(width: 10),
                  Text('Treino Finalizado!',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Excelente sessão! Duração: $duracaoMinutos min • $totalSeriesConcluidas séries concluídas.',
                      style: const TextStyle(
                          color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                    const SizedBox(height: 12),

                    // Card de Métricas de Alta Performance
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniStat(
                              'Tonelagem',
                              '${(tonelagemKg / 1000).toStringAsFixed(1)} ton',
                              Icons.fitness_center),
                          _buildMiniStat('Duração', '$duracaoMinutos min',
                              Icons.timer_outlined),
                          _buildMiniStat('Séries', '$totalSeriesConcluidas',
                              Icons.check_circle_outline),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Percepção de Esforço (RPE 1 a 10):',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                    Slider(
                      value: rpeSelecionado.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: const Color(0xFF10B981),
                      inactiveColor: const Color(0xFF334155),
                      label: '$rpeSelecionado',
                      onChanged: (val) {
                        setDialogState(() => rpeSelecionado = val.toInt());
                      },
                    ),
                    Center(
                      child: Text(
                        'RPE $rpeSelecionado (${_descricaoRpe(rpeSelecionado)})',
                        style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: feedbackCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Recado para o Personal (Opcional)',
                        labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                        hintText:
                            'Ex: Treino muito bom, apliquei sobrecarga!',
                        hintStyle: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Continuar',
                      style: TextStyle(color: Color(0xFF94A3B8))),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Salvar & Compartilhar'),
                  onPressed: () async {
                    // 1. Gravar sessão no repositório offline
                    final sessao = SessaoTreinoRegistroModel(
                      id: 'sessao_${DateTime.now().millisecondsSinceEpoch}',
                      treinoId: widget.planoId,
                      divisaoLetra: widget.divisao.letra,
                      divisaoNome: widget.divisao.nome,
                      alunoId: widget.alunoId,
                      dataHoraInicio: _inicioSessao.toIso8601String(),
                      dataHoraFim: DateTime.now().toIso8601String(),
                      duracaoSegundos:
                          DateTime.now().difference(_inicioSessao).inSeconds,
                      rpe: rpeSelecionado,
                      feedbackAluno: feedbackCtrl.text.trim().isNotEmpty
                          ? feedbackCtrl.text.trim()
                          : null,
                      sincronizado: false,
                      exerciciosExecutados: [
                        for (int i = 0;
                            i < widget.divisao.exercicios.length;
                            i++)
                          ExercicioExecutadoRegistroModel(
                            exercicioId:
                                widget.divisao.exercicios[i].exercicioId,
                            exercicioNome:
                                widget.divisao.exercicios[i].exercicioNome,
                            grupoMuscular:
                                widget.divisao.exercicios[i].grupoMuscular,
                            series: _seriesPorExercicio[i] ?? [],
                          ),
                      ],
                    );

                    await _repository.registrarSessaoConcluida(sessao);
                    final streak =
                        await _repository.calcularStreakDias(alunoId: widget.alunoId);

                    // 2. Disparar notificação de meta batida
                    await _pushService.notificarMetaBatida(
                      streakDias: streak,
                      tonelagemKg: tonelagemKg,
                    );

                    Navigator.pop(context); // Fecha dialog
                    if (!context.mounted) return;

                    // 3. Exibir Card Visual Stories / Strava para compartilhamento
                    _exibirModalStoriesCompartilhamento(
                      duracaoMinutos: duracaoMinutos,
                      tonelagemKg: tonelagemKg,
                      totalSeries: totalSeriesConcluidas,
                      streakDias: streak,
                      rpe: rpeSelecionado,
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF10B981), size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13)),
        Text(label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
      ],
    );
  }

  /// Exibe Modal Estilo Stories / Strava com Layout Premium 9:16
  void _exibirModalStoriesCompartilhamento({
    required int duracaoMinutos,
    required double tonelagemKg,
    required int totalSeries,
    required int streakDias,
    required int rpe,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),

              // Card Visual Estilo Instagram Stories
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF064E3B), Color(0xFF022C22), Color(0xFF0B1120)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3310B981),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bolt, color: Color(0xFF34D399), size: 24),
                            SizedBox(width: 6),
                            Text('APPACADEMIA PRO',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    fontSize: 13)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '🔥 $streakDias Dias Seguidos',
                            style: const TextStyle(
                                color: Color(0xFF34D399),
                                fontWeight: FontWeight.w800,
                                fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'TREINO CONCLUÍDO!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.divisao.letra} • ${widget.divisao.nome}',
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Grid de Conquistas
                    Row(
                      children: [
                        Expanded(
                          child: _buildStoriesStat(
                            'TONELAGEM TOTAL',
                            '${(tonelagemKg / 1000).toStringAsFixed(1)} ton',
                            Icons.fitness_center,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStoriesStat(
                            'DURAÇÃO',
                            '$duracaoMinutos min',
                            Icons.timer_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStoriesStat(
                            'SÉRIES FEITAS',
                            '$totalSeries',
                            Icons.checklist,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStoriesStat(
                            'INTENSIDADE',
                            'RPE $rpe',
                            Icons.local_fire_department,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      '#NoExcuses #AppAcademia #ProgressoReal',
                      style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Ações de Compartilhamento
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF475569)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // fecha modal
                        Navigator.pop(context, true); // volta tela treinos
                      },
                      child: const Text('Fechar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.share, size: 20),
                      label: const Text('Compartilhar Stories',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      onPressed: () {
                        final shareText = '''🔥 Treino Batido com Sucesso no AppAcademia Pro!

🏋️ Treino: ${widget.divisao.letra} - ${widget.divisao.nome}
⏱ Tempo: $duracaoMinutos min
💪 Tonelagem Total: ${(tonelagemKg / 1000).toStringAsFixed(1)} toneladas levantadas
🎯 Séries Concluídas: $totalSeries
🔥 Sequência: $streakDias dias consecutivos!

#Foco #Treino #AppAcademia #MyFitCoach #SobrecargaProgressiva''';

                        Share.share(shareText);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStoriesStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF34D399), size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 9,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _descricaoRpe(int rpe) {
    if (rpe <= 3) return 'Muito Leve';
    if (rpe <= 5) return 'Moderado';
    if (rpe <= 7) return 'Desafiador / Ideal';
    if (rpe <= 9) return 'Muito Difícil';
    return 'Esforço Máximo / Falha Total';
  }
}
