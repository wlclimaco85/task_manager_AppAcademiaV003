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
  int _series = 4, _descanso = 60;
  String _reps = '8 a 12', _observacao = '';
  double _carga = 10;
  final List<String?> _alternativas = [null, null];
  bool _fazerBiset = false;
  String? _bisetId;
  String _bisetReps = '8 a 12';
  double _bisetCarga = 0;
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
          _campo('Séries', '4', (v) => _series = int.tryParse(v) ?? 4, numero: true),
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
        const Divider(height: 28),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Fazer biset'),
          subtitle: const Text('Dois exercícios seguidos. Descanso após o segundo.'),
          value: _fazerBiset,
          onChanged: (v) => setState(() {
            _fazerBiset = v;
            if (!v) {
              _bisetId = null;
              _bisetCarga = 0;
              _bisetReps = '8 a 12';
            }
          }),
        ),
        if (_fazerBiset) ...[
          DropdownButtonFormField<String>(
            isExpanded: true,
            menuMaxHeight: 320,
            decoration: const InputDecoration(labelText: 'Exercício do biset'),
            items: [
              for (final ex in widget.catalogo.where((e) => e.id != widget.exercicio.id))
                DropdownMenuItem(value: ex.id,
                  child: Text('${ex.nome} • ${ex.grupoMuscular}',
                    overflow: TextOverflow.ellipsis)),
            ],
            validator: (v) => v == null || v.isEmpty
                ? 'Escolha o segundo exercício' : null,
            onChanged: (v) => _bisetId = v,
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _campo('Repetições do biset', _bisetReps, (v) => _bisetReps = v),
            _campo('Carga do biset (kg)', '0', (v) =>
              _bisetCarga = double.tryParse(v.replaceAll(',', '.')) ?? 0,
              numero: true),
          ]),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(icon: const Icon(Icons.add), label: const Text('Adicionar ao treino'),
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            final parceiro = _fazerBiset
                ? widget.catalogo.firstWhere((e) => e.id == _bisetId) : null;
            widget.onAdicionar(ItemTreinoModel(
              id: 'it_${DateTime.now().microsecondsSinceEpoch}',
              exercicioId: widget.exercicio.id, exercicioNome: widget.exercicio.nome,
              grupoMuscular: widget.exercicio.grupoMuscular, videoUrl: widget.exercicio.videoUrl,
              series: _series, repeticoes: _reps.trim(), cargaSugeridaKg: _carga,
              descansoSegundos: _descanso, observacoes: _observacao.trim(),
              tecnica: parceiro == null ? 'Normal' : 'Bi-set',
              exercicioBiset: parceiro == null ? null : ItemTreinoModel(
                id: 'biset_${DateTime.now().microsecondsSinceEpoch}',
                exercicioId: parceiro.id, exercicioNome: parceiro.nome,
                grupoMuscular: parceiro.grupoMuscular, videoUrl: parceiro.videoUrl,
                series: _series, repeticoes: _bisetReps.trim(),
                cargaSugeridaKg: _bisetCarga, descansoSegundos: _descanso,
                tecnica: 'Bi-set',
              ),
              exerciciosAlternativos: _alternativas.whereType<String>()
                  .where((id) => id.isNotEmpty)
                  .map((id) => widget.catalogo.firstWhere((e) => e.id == id).nome).toList(),
            ));
          }),
      ],
    ),
  ));
}
