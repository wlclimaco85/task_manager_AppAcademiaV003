import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/services/tipos_medida_store.dart';
import 'package:task_manager_flutter/data/services/fitness_360_local_store.dart';
import 'package:task_manager_flutter/data/services/medida_corporal_caller.dart';
import 'package:task_manager_flutter/data/services/saude_diaria_caller.dart';
import 'package:task_manager_flutter/data/models/medida_corporal_model.dart';
import 'package:task_manager_flutter/data/models/saude_diaria_model.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

class RegistroMedidaSheet extends StatefulWidget {
  const RegistroMedidaSheet({super.key, this.tipoInicial});
  final String? tipoInicial;
  @override
  State<RegistroMedidaSheet> createState() => _RegistroMedidaSheetState();
}
class _RegistroMedidaSheetState extends State<RegistroMedidaSheet> {
  final _form = GlobalKey<FormState>();
  final _valor = TextEditingController(), _nota = TextEditingController();
  Map<String, String> _tipos = Map.from(TiposMedidaStore.padrao);
  String _tipo = 'Peso';
  DateTime _data = DateUtils.dateOnly(DateTime.now());
  bool _salvando = false;
  @override
  void initState() {
    super.initState();
    _tipo = widget.tipoInicial ?? _tipo;
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
        CircleAvatar(radius: 26, child: Icon(Icons.emoji_events_outlined, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 8),
        const Text('Registrar evolução', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Cada registro adiciona um ponto na sua jornada.'),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _salvando ? null : _escolherData,
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text('Data: ${_formatarData(_data)}'),
        ),
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
            final valor = double.parse(_valor.text.replaceAll(',', '.'));
            final sincronizado = await _sincronizarCorpo(valor, _data);
            await Fitness360LocalStore.addRecord(type: 'corpo', title: _tipo,
              value: '$valor ${_tipos[_tipo]}', note: _nota.text.trim(), dataRegistro: _data);
            if (!sincronizado) {
              AppLogger.i.warn('Medida $_tipo salva localmente; sincronizacao corporal pendente.');
            }
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

  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (escolhida != null && mounted) setState(() => _data = DateUtils.dateOnly(escolhida));
  }

  String _formatarData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

  Future<bool> _sincronizarCorpo(double valor, DateTime data) async {
    if (_tipo == 'Peso' || _tipo == 'Altura') {
      // Uma data hist\u00f3rica deve complementar apenas o resumo daquele dia;
      // reutilizar o resumo de hoje aqui levaria passos e sono para o gr\u00e1fico antigo.
      final atual = await SaudeDiariaCaller().fetchResumo(data: data);
      final base = atual ?? ResumoSaudeDiaria(
        data: data, passos: 0, treinoMinutos: 0, batimentos: null,
        sonoMinutos: 0, pesoKg: null, pesoMetaKg: null, historicoSemanal: const [],
      );
      final salvo = await SaudeDiariaCaller().salvarResumo(ResumoSaudeDiaria(
        data: data, passos: base.passos, treinoMinutos: base.treinoMinutos,
        batimentos: base.batimentos, sonoMinutos: base.sonoMinutos,
        pesoKg: _tipo == 'Peso' ? valor : base.pesoKg,
        pesoMetaKg: base.pesoMetaKg,
        alturaCm: _tipo == 'Altura' ? valor.round() : base.alturaCm,
        distanciaKm: base.distanciaKm, caloriasAtivas: base.caloriasAtivas,
        historicoSemanal: base.historicoSemanal,
      ));
      return salvo != null;
    }

    final composicao = _chaveComposicao(_tipo);
    if (composicao != null) {
      final salvo = await MedidaCorporalCaller().registrarMedida(
        MedidaCorporal(
          data: data,
          percentualGordura:
              composicao == _Composicao.gordura ? valor : null,
          percentualMassaMuscular:
              composicao == _Composicao.massaMuscular ? valor : null,
          percentualAgua: composicao == _Composicao.agua ? valor : null,
        ),
      );
      return salvo != null;
    }

    final chave = _chaveCircunferencia(_tipo);
    if (chave == null) return true;
    final salvo = await MedidaCorporalCaller().registrarMedida(
      MedidaCorporal(data: data, circunferencias: {chave: valor}),
    );
    return salvo != null;
  }

  String? _chaveCircunferencia(String tipo) => switch (tipo) {
        'Cintura' => 'cintura',
        'Quadril' => 'quadril',
        'Braço direito relaxado' || 'Braço direito flexionado' => 'braco_direito',
        'Braço esquerdo relaxado' || 'Braço esquerdo flexionado' => 'braco_esquerdo',
        'Coxa direita' => 'coxa_direita',
        'Coxa esquerda' => 'coxa_esquerda',
        'Panturrilha direita' => 'panturrilha_direita',
        'Panturrilha esquerda' => 'panturrilha_esquerda',
        'Pescoço' => 'pescoco',
        'Ombros' => 'ombros',
        'Tórax' => 'torax',
        'Abdômen' => 'abdomen',
        'Antebraço direito' => 'antebraco_direito',
        'Antebraço esquerdo' => 'antebraco_esquerdo',
        _ => null,
      };

  _Composicao? _chaveComposicao(String tipo) => switch (tipo) {
        'Gordura corporal' => _Composicao.gordura,
        'Massa muscular' => _Composicao.massaMuscular,
        'Água corporal' => _Composicao.agua,
        _ => null,
      };
}

enum _Composicao { gordura, massaMuscular, agua }
