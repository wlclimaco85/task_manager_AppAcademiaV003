import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/fitness/exercicio_model.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';

class PrescricaoExercicioInline extends StatefulWidget {
  final ExercicioModel exercicio;
  final List<ExercicioModel> catalogo;
  final String? grupoAlternativas;
  final ValueChanged<ItemTreinoModel> onAdicionar;
  const PrescricaoExercicioInline({super.key, required this.exercicio,
    required this.catalogo, this.grupoAlternativas, required this.onAdicionar});
  @override
  State<PrescricaoExercicioInline> createState() => _PrescricaoExercicioInlineState();
}

class _PrescricaoExercicioInlineState extends State<PrescricaoExercicioInline> {
  final _form = GlobalKey<FormState>();
  int _series = 3, _descanso = 60;
  String _reps = '10 a 12', _observacao = '';
  double _carga = 10;
  final List<String?> _alternativas = [null, null];
  Widget _campo(String label, String initial, ValueChanged<String> change,
      {bool numero = false}) => SizedBox(width: 140, child: TextFormField(
    initialValue: initial, decoration: InputDecoration(labelText: label),
    keyboardType: numero ? const TextInputType.numberWithOptions(decimal: true) : null,
    validator: (v) {
      if (v == null || v.trim().isEmpty) return 'Informe o valor';
      if (numero && (double.tryParse(v.replaceAll(',', '.')) == null ||
          double.parse(v.replaceAll(',', '.')) < 0)) return 'Valor inválido';
      if ((label == 'Séries' || label == 'Descanso (s)') &&
          (int.tryParse(v) == null || int.parse(v) < 1)) return 'Use inteiro positivo';
      return null;
    }, onChanged: change,
  ));
  @override
  Widget build(BuildContext context) => Form(key: _form, child: Padding(
    padding: const EdgeInsets.all(14), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 12, runSpacing: 12, children: [
          _campo('Séries', '3', (v) => _series = int.tryParse(v) ?? 3, numero: true),
          _campo('Repetições', _reps, (v) => _reps = v),
          _campo('Carga (kg)', '10', (v) => _carga = double.tryParse(v.replaceAll(',', '.')) ?? 10, numero: true),
          _campo('Descanso (s)', '60', (v) => _descanso = int.tryParse(v) ?? 60, numero: true),
        ]),
        const SizedBox(height: 12),
        TextFormField(decoration: const InputDecoration(labelText: 'Observação para o aluno'),
          minLines: 1, maxLines: 3, onChanged: (v) => _observacao = v),
        const SizedBox(height: 12),
        const Text('Se a máquina estiver ocupada (opcional)'),
        for (int i = 0; i < 2; i++) Padding(
          padding: const EdgeInsets.only(top: 8),
          child: DropdownButtonFormField<String>(
            isExpanded: true, initialValue: _alternativas[i],
            decoration: InputDecoration(labelText: 'Alternativa ${i + 1}'),
            items: [const DropdownMenuItem<String>(value: '', child: Text('Nenhuma')),
              for (final ex in widget.catalogo.where((e) => e.id != widget.exercicio.id &&
                  e.grupoMuscular == (widget.grupoAlternativas ?? widget.exercicio.grupoMuscular)))
                DropdownMenuItem(value: ex.id, child: Text(ex.nome, overflow: TextOverflow.ellipsis)),
            ],
            validator: (v) => v != null && v.isNotEmpty && v == _alternativas[1 - i]
                ? 'Escolha exercícios diferentes' : null,
            onChanged: (v) => _alternativas[i] = v,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(icon: const Icon(Icons.add), label: const Text('Adicionar ao treino'),
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            widget.onAdicionar(ItemTreinoModel(
              id: 'it_${DateTime.now().microsecondsSinceEpoch}',
              exercicioId: widget.exercicio.id, exercicioNome: widget.exercicio.nome,
              grupoMuscular: widget.exercicio.grupoMuscular, videoUrl: widget.exercicio.videoUrl,
              series: _series, repeticoes: _reps.trim(), cargaSugeridaKg: _carga,
              descansoSegundos: _descanso, observacoes: _observacao.trim(),
              exerciciosAlternativos: _alternativas.whereType<String>()
                  .where((id) => id.isNotEmpty)
                  .map((id) => widget.catalogo.firstWhere((e) => e.id == id).nome).toList(),
            ));
          }),
      ],
    ),
  ));
}
