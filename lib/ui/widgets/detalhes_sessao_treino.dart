import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/compartilhar_treino_sheet.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';
import 'package:task_manager_flutter/ui/widgets/exercicio_midia.dart';

class DetalhesSessaoTreino extends StatelessWidget {
  final SessaoTreinoRegistroModel sessao;
  const DetalhesSessaoTreino({super.key, required this.sessao});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Treino ${sessao.divisaoLetra} • ${sessao.divisaoNome}'),
    content: SizedBox(width: 600, child: SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
          Text('Data: ${sessao.dataHoraInicio.split('T').first}'),
          Text('Duração: ${(sessao.duracaoSegundos / 60).round()} min • RPE ${sessao.rpe}/10'),
          if (sessao.feedbackAluno?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Text('Observação: ${sessao.feedbackAluno}'),
          ],
          if (sessao.exerciciosExecutados.isEmpty)
            const Padding(padding: EdgeInsets.only(top: 16),
              child: Text('Esta sessão não possui exercícios registrados.')),
          for (final ex in sessao.exerciciosExecutados) ...[
            const Divider(height: 24),
            Text(ex.exercicioNome, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(ex.grupoMuscular),
            if (ex.observacaoAluno?.isNotEmpty ?? false)
              Text('Observação: ${ex.observacaoAluno}'),
            if (ex.series.isEmpty) const Text('Sem séries registradas.'),
            for (final serie in ex.series) Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Série ${serie.numero}: ${serie.cargaRealKg.toStringAsFixed(1)} kg • '
                '${serie.repeticoesRealizadas} repetições • '
                '${serie.concluida ? 'Concluída' : 'Não concluída'}'
                '${serie.descansoUtilizadoSegundos == null ? '' : ' • Descanso: ${serie.descansoUtilizadoSegundos}s'}'),
            ),
          ],
          if (sessao.videoUrl?.isNotEmpty ?? false) ...[
            const Divider(height: 24),
            const Text('Vídeo do meu treino'),
            ExercicioMidia(url: sessao.videoUrl!),
          ],
        ],
      ),
    )),
    actions: [
      TextButton.icon(icon: const Icon(Icons.share), label: const Text('Compartilhar treino'),
        onPressed: () {
          final series = sessao.exerciciosExecutados.expand((e) => e.series).where((s) => s.concluida).toList();
          final volume = series.fold<double>(0, (v, s) => v + s.cargaRealKg * s.repeticoesRealizadas);
          showModalBottomSheet(context: context, isScrollControlled: true,
            builder: (sheetContext) => SizedBox(height: MediaQuery.sizeOf(sheetContext).height * 0.9,
              child: CompartilharTreinoSheet(treino: 'Treino ${sessao.divisaoLetra} - ${sessao.divisaoNome}',
                minutos: (sessao.duracaoSegundos / 60).round(), series: series.length,
                tonelagemKg: volume, rpe: sessao.rpe, onFechar: () => Navigator.pop(sheetContext))));
        }),
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
    ],
  );
}
