import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/services/tipos_medida_store.dart';
import 'package:task_manager_flutter/data/services/fitness_360_local_store.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

class RegistroMedidaSheet extends StatefulWidget {
  const RegistroMedidaSheet({super.key});
  @override
  State<RegistroMedidaSheet> createState() => _RegistroMedidaSheetState();
}
class _RegistroMedidaSheetState extends State<RegistroMedidaSheet> {
  final _form = GlobalKey<FormState>();
  final _valor = TextEditingController(), _nota = TextEditingController();
  Map<String, String> _tipos = Map.from(TiposMedidaStore.padrao);
  String _tipo = 'Peso';
  bool _salvando = false;
  @override
  void initState() {
    super.initState();
    TiposMedidaStore.carregar().then((tipos) {
      if (mounted) setState(() { _tipos = tipos; if (!_tipos.containsKey(_tipo)) _tipo = _tipos.keys.first; });
    }).catchError((Object error, StackTrace stack) { AppLogger.i.error('Falha ao carregar tipos de medida.', stack); });
  }
  @override
  void dispose() { _valor.dispose(); _nota.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
    child: SingleChildScrollView(child: Form(key: _form, child: Column(
      mainAxisSize: MainAxisSize.min, children: [
        const Text('Registrar medida', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(initialValue: _tipo, isExpanded: true,
          decoration: const InputDecoration(labelText: 'Tipo de medida'),
          items: [for (final tipo in _tipos.keys) DropdownMenuItem(value: tipo, child: Text(tipo))],
          onChanged: _salvando ? null : (v) => setState(() => _tipo = v!),
        ),
        const SizedBox(height: 12),
        TextFormField(controller: _valor,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'Valor', suffixText: _tipos[_tipo]),
          validator: (v) {
            final numero = double.tryParse((v ?? '').replaceAll(',', '.'));
            if (numero == null || !numero.isFinite || numero <= 0) return 'Informe um valor positivo';
            if (_tipo == 'Peso' && (numero < 20 || numero > 400)) return 'Peso deve ficar entre 20 e 400 kg';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(controller: _nota, maxLines: 3, minLines: 1,
          decoration: const InputDecoration(labelText: 'Observação (opcional)')),
        const SizedBox(height: 16),
        FilledButton(onPressed: _salvando ? null : () async {
          if (!_form.currentState!.validate()) return;
          setState(() => _salvando = true);
          try {
            await Fitness360LocalStore.addRecord(type: 'corpo', title: _tipo,
              value: '${double.parse(_valor.text.replaceAll(',', '.'))} ${_tipos[_tipo]}', note: _nota.text.trim());
            if (context.mounted) Navigator.pop(context, true);
          } catch (error, stack) {
            AppLogger.i.error('Falha ao registrar medida.', stack);
            if (context.mounted) { setState(() => _salvando = false);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível salvar. Tente novamente.'))); }
          }
        }, child: Text(_salvando ? 'Salvando...' : 'Salvar')),
      ],
    ))),
  );
}
