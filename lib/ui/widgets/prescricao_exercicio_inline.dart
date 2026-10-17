import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/fitness/exercicio_model.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';

class PrescricaoExercicioInline extends StatefulWidget {
  final ExercicioModel exercicio;
  final List<ExercicioModel> catalogo;
  final String? grupoAlternativas;
  final ValueChanged<ItemTreinoModel> onAdicionar;
  const PrescricaoExercicioInline(
      {super.key,
      required this.exercicio,
      required this.catalogo,
      this.grupoAlternativas,
      required this.onAdicionar});
  @override
  State<PrescricaoExercicioInline> createState() =>
      _PrescricaoExercicioInlineState();
}

class _PrescricaoExercicioInlineState extends State<PrescricaoExercicioInline> {
  final _form = GlobalKey<FormState>();
  int _series = 4, _descanso = 60;
  String _reps = '8 a 12', _observacao = '';
  double _carga = 10;
  final List<String?> _alternativas = [null, null];
  bool _fazerBiset = false, _usarAlternativas = false;
  late String _grupoBiset;
  @override
  void initState() {
    super.initState();
    _grupoBiset = widget.grupoAlternativas ?? widget.exercicio.grupoMuscular;
  }

  Widget _numero(String label, num valor, ValueChanged<num> alterar,
      {num passo = 1, num minimo = 0, bool inteiro = false}) {
    String formatar(num v) =>
        v == v.roundToDouble() ? v.toInt().toString() : v.toString();
    num atual = valor;
    void ajustar(num delta) {
      final proximo = (atual + delta).clamp(minimo, 99999);
      setState(() => alterar(proximo));
    }

    return SizedBox(
        width: 140,
        child: Row(children: [
          IconButton(
              tooltip: 'Diminuir $label',
              onPressed: () => ajustar(-passo),
              icon: const Icon(Icons.remove_circle_outline),
              iconSize: 20,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 48)),
          Expanded(
              child: TextFormField(
            key: ValueKey('$label-${formatar(valor)}'),
            initialValue: formatar(valor),
            decoration: InputDecoration(labelText: label),
            keyboardType: TextInputType.numberWithOptions(decimal: !inteiro),
            validator: (v) {
              final n = num.tryParse((v ?? '').replaceAll(',', '.'));
              if (n == null ||
                  !n.isFinite ||
                  n < minimo ||
                  (inteiro && n != n.round())) {
                return inteiro ? 'Inteiro ≥ $minimo' : 'Valor ≥ $minimo';
              }
              return null;
            },
            onChanged: (v) {
              final n = num.tryParse(v.replaceAll(',', '.'));
              if (n != null &&
                  n.isFinite &&
                  n >= minimo &&
                  (!inteiro || n == n.round())) {
                atual = n;
                alterar(n);
              }
            },
          )),
          IconButton(
              tooltip: 'Aumentar $label',
              onPressed: () => ajustar(passo),
              icon: const Icon(Icons.add_circle_outline),
              iconSize: 20,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 48)),
        ]));
  }

  String? _bisetId;
  String _bisetReps = '8 a 12';
  double _bisetCarga = 0;
  Widget _campo(String label, String initial, ValueChanged<String> change) =>
      SizedBox(
          width: 140,
          child: TextFormField(
            initialValue: initial,
            decoration: InputDecoration(labelText: label),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Informe o valor' : null,
            onChanged: change,
          ));
  @override
  Widget build(BuildContext context) => Form(
      key: _form,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 12, runSpacing: 12, children: [
              _numero('Séries', _series, (v) => _series = v.toInt(),
                  minimo: 1, inteiro: true),
              _campo('Repetições', _reps, (v) => _reps = v),
              _numero('Carga (kg)', _carga, (v) => _carga = v.toDouble()),
              _numero('Descanso (s)', _descanso, (v) => _descanso = v.toInt(),
                  passo: 5, minimo: 1, inteiro: true),
            ]),
            const SizedBox(height: 12),
            TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Observação para o aluno'),
                minLines: 1,
                maxLines: 3,
                onChanged: (v) => _observacao = v),
            const SizedBox(height: 12),
            // Toggle compacto: uma linha, como os demais ajustes da prescricao.
            Row(children: [
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _usarAlternativas,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (v) => setState(() => _usarAlternativas = v),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: InkWell(
                  // Tocar no texto tambem liga/desliga, como o SwitchListTile fazia.
                  onTap: () => setState(() => _usarAlternativas = !_usarAlternativas),
                  child: Text('Se a máquina estiver ocupada',
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ),
            ]),
            if (_usarAlternativas)
              for (int i = 0; i < 2; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _alternativas[i],
                    decoration:
                        InputDecoration(labelText: 'Alternativa ${i + 1}'),
                    items: [
                      const DropdownMenuItem<String>(
                          value: '', child: Text('Nenhuma')),
                      for (final ex in widget.catalogo.where((e) =>
                          e.id != widget.exercicio.id &&
                          e.grupoMuscular ==
                              (widget.grupoAlternativas ??
                                  widget.exercicio.grupoMuscular)))
                        DropdownMenuItem(
                            value: ex.id,
                            child:
                                Text(ex.nome, overflow: TextOverflow.ellipsis)),
                    ],
                    validator: (v) =>
                        v != null && v.isNotEmpty && v == _alternativas[1 - i]
                            ? 'Escolha exercícios diferentes'
                            : null,
                    onChanged: (v) => _alternativas[i] = v,
                  ),
                ),
            const Divider(height: 28),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fazer biset'),
              subtitle: const Text(
                  'Dois exercícios seguidos. Descanso após o segundo.'),
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
                initialValue: _grupoBiset,
                isExpanded: true,
                decoration:
                    const InputDecoration(labelText: 'Grupo muscular do biset'),
                items: [
                  for (final grupo
                      in ({
                    _grupoBiset,
                    ...widget.catalogo.map((e) => e.grupoMuscular)
                  }.toList()
                        ..sort()))
                    DropdownMenuItem(value: grupo, child: Text(grupo)),
                ],
                onChanged: (grupo) {
                  if (grupo == null) return;
                  setState(() {
                    _grupoBiset = grupo;
                    _bisetId = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('biset-$_grupoBiset'),
                initialValue: _bisetId,
                isExpanded: true,
                menuMaxHeight: 320,
                decoration:
                    const InputDecoration(labelText: 'Exercício do biset'),
                items: [
                  for (final ex in widget.catalogo.where((e) =>
                      e.id != widget.exercicio.id &&
                      e.grupoMuscular == _grupoBiset))
                    DropdownMenuItem(
                        value: ex.id,
                        child: Text('${ex.nome} • ${ex.grupoMuscular}',
                            overflow: TextOverflow.ellipsis)),
                ],
                validator: (v) => v == null || v.isEmpty
                    ? 'Escolha o segundo exercício'
                    : null,
                onChanged: (v) => _bisetId = v,
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 12, runSpacing: 12, children: [
                _campo(
                    'Repetições do biset', _bisetReps, (v) => _bisetReps = v),
                _numero('Carga do biset (kg)', _bisetCarga,
                    (v) => _bisetCarga = v.toDouble()),
              ]),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Adicionar ao treino'),
                onPressed: () {
                  if (!_form.currentState!.validate()) return;
                  final parceiro = _fazerBiset
                      ? widget.catalogo.firstWhere((e) => e.id == _bisetId)
                      : null;
                  widget.onAdicionar(ItemTreinoModel(
                    id: 'it_${DateTime.now().microsecondsSinceEpoch}',
                    exercicioId: widget.exercicio.id,
                    exercicioNome: widget.exercicio.nome,
                    grupoMuscular: widget.exercicio.grupoMuscular,
                    videoUrl: widget.exercicio.videoUrl,
                    series: _series,
                    repeticoes: _reps.trim(),
                    cargaSugeridaKg: _carga,
                    descansoSegundos: _descanso,
                    observacoes: _observacao.trim(),
                    tecnica: parceiro == null ? 'Normal' : 'Bi-set',
                    exercicioBiset: parceiro == null
                        ? null
                        : ItemTreinoModel(
                            id: 'biset_${DateTime.now().microsecondsSinceEpoch}',
                            exercicioId: parceiro.id,
                            exercicioNome: parceiro.nome,
                            grupoMuscular: parceiro.grupoMuscular,
                            videoUrl: parceiro.videoUrl,
                            series: _series,
                            repeticoes: _bisetReps.trim(),
                            cargaSugeridaKg: _bisetCarga,
                            descansoSegundos: _descanso,
                            tecnica: 'Bi-set',
                          ),
                    exerciciosAlternativos: (_usarAlternativas
                            ? _alternativas
                            : <String?>[])
                        .whereType<String>()
                        .where((id) => id.isNotEmpty)
                        .map((id) =>
                            widget.catalogo.firstWhere((e) => e.id == id).nome)
                        .toList(),
                  ));
                }),
          ],
        ),
      ));
}
