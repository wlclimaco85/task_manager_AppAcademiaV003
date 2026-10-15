import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/fitness/personal_gestao_model.dart';
import 'package:task_manager_flutter/data/services/personal_gestao_offline_repository.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';

/// Cadastro e contrato do aluno, com controllers vivos até o sheet desmontar.
class PersonalAlunoSheet extends StatefulWidget {
  final PersonalAlunoGestaoModel? aluno;
  const PersonalAlunoSheet({super.key, this.aluno});
  @override
  State<PersonalAlunoSheet> createState() => _PersonalAlunoSheetState();
}

class _PersonalAlunoSheetState extends State<PersonalAlunoSheet> {
  final _repo = PersonalGestaoOfflineRepository();
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();
  final _busca = TextEditingController();
  final _valor = TextEditingController();
  final _frequencia = TextEditingController();
  final _vencimento = TextEditingController();
  bool? _temConta;
  bool _ocupado = false;
  String? _erro;
  String _tipo = 'mensal';
  String? _plano;
  Map<String, dynamic>? _selecionado;
  List<Map<String, dynamic>> _resultados = [];
  List<Map<String, dynamic>> _planos = [];

  @override
  void initState() {
    super.initState();
    final a = widget.aluno;
    if (a != null) {
      _nome.text = a.nome;
      _telefone.text = a.telefone;
      _email.text = a.email;
      _valor.text = a.valorMensalidade.toStringAsFixed(2);
      _tipo = a.tipoCobranca;
      _plano = a.planoId;
      _frequencia.text = a.frequenciaContratada.toString();
      _vencimento.text = a.diaVencimento.toString();
    }
    _carregarPlanos();
  }

  Future<void> _carregarPlanos() async {
    final planos = await _repo.getPlanosCobranca();
    if (mounted) setState(() => _planos = planos);
  }

  @override
  void dispose() {
    for (final c in [
      _nome,
      _telefone,
      _email,
      _busca,
      _valor,
      _frequencia,
      _vencimento
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _buscar() async {
    if (_busca.text.trim().length < 3) {
      setState(() => _erro = 'Informe pelo menos 3 caracteres para buscar.');
      return;
    }
    setState(() {
      _ocupado = true;
      _erro = null;
      _selecionado = null;
    });
    try {
      final r = await _repo.buscarAlunos(_busca.text);
      if (mounted)
        setState(() {
          _resultados = r;
          if (r.isEmpty) _erro = 'Nenhum aluno encontrado.';
        });
    } catch (e) {
      if (mounted)
        setState(() => _erro = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    if (widget.aluno == null && _temConta == true && _selecionado == null) {
      setState(() => _erro = 'Selecione o aluno encontrado antes de vincular.');
      return;
    }
    if (_tipo == 'plano' &&
        (_plano == null || !_planos.any((p) => p['id'].toString() == _plano))) {
      setState(() => _erro = 'Selecione um plano cadastrado.');
      return;
    }
    setState(() {
      _ocupado = true;
      _erro = null;
    });
    try {
      final base = widget.aluno ??
          (_temConta == true
              ? await _repo.vincularAluno(_selecionado!['id'].toString())
              : PersonalAlunoGestaoModel(
                  id: 'aluno-${DateTime.now().microsecondsSinceEpoch}',
                  nome: _nome.text.trim(),
                  email: _email.text.trim(),
                  telefone: _telefone.text.trim()));
      final plano =
          _planos.where((p) => p['id'].toString() == _plano).firstOrNull;
      final agora = DateTime.now();
      final aluno = base.copyWith(
        nome: widget.aluno != null || _temConta == false
            ? _nome.text.trim()
            : base.nome,
        telefone: widget.aluno != null || _temConta == false
            ? _telefone.text.trim()
            : base.telefone,
        email: widget.aluno != null || _temConta == false
            ? _email.text.trim()
            : base.email,
        tipoCobranca: _tipo,
        planoId: _tipo == 'plano' ? _plano : '',
        planoNome: _tipo == 'plano' ? (plano?['nome']?.toString()) : '',
        valorMensalidade: double.parse(_valor.text.trim().replaceAll(',', '.')),
        frequenciaContratada: int.parse(_frequencia.text),
        diaVencimento: int.parse(_vencimento.text),
        mesReferencia: widget.aluno?.mesReferencia.isNotEmpty == true
            ? base.mesReferencia
            : '${agora.month.toString().padLeft(2, '0')}/${agora.year}',
      );
      await _repo.salvarAluno(aluno);
      if (mounted) Navigator.pop(context, aluno);
    } catch (e) {
      if (mounted)
        setState(() => _erro = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Widget _campo(TextEditingController c, String label,
          {bool numero = false,
          bool readOnly = false,
          bool obrigatorio = true,
          String? Function(String?)? validar}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
              controller: c,
              readOnly: readOnly,
              keyboardType: numero
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              style: const TextStyle(color: GridColors.textPrimary),
              decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(color: GridColors.textSecondary),
                  filled: true,
                  fillColor: GridColors.inputBackground),
              validator: validar ??
                  (v) => obrigatorio && (v?.trim().isEmpty ?? true)
                      ? 'Informe este campo.'
                      : null));

  @override
  Widget build(BuildContext context) {
    final edicao = widget.aluno != null;
    return Theme(
        data: Theme.of(context).copyWith(
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(
                primary: CustomColors.primaryGreen,
                surface: GridColors.card)),
        child: SafeArea(
            child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
                child: Form(
                    key: _form,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                              edicao
                                  ? 'Editar aluno e cobrança'
                                  : 'Adicionar aluno',
                              style: const TextStyle(
                                  color: GridColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          if (!edicao) ...[
                            const Text('O aluno já tem usuário no app?',
                                style: TextStyle(color: GridColors.textPrimary)),
                            Wrap(spacing: 12, children: [
                              for (final tem in [true, false])
                                ChoiceChip(
                                    label: Text(tem
                                        ? 'Sim, buscar e vincular'
                                        : 'Não, cadastrar aluno'),
                                    selected: _temConta == tem,
                                    onSelected: _ocupado
                                        ? null
                                        : (_) => setState(() {
                                              _temConta = tem;
                                              _erro = null;
                                            }))
                            ]),
                            const SizedBox(height: 12),
                          ],
                          if (!edicao && _temConta == true) ...[
                            _campo(_busca, 'Nome, CPF ou telefone',
                                obrigatorio: false),
                            OutlinedButton.icon(
                                onPressed: _ocupado ? null : _buscar,
                                icon: const Icon(Icons.search),
                                label: const Text('Buscar aluno')),
                            for (final r in _resultados)
                              ListTile(
                                  title: Text(r['nome']?.toString() ?? '',
                                      style:
                                          const TextStyle(color: GridColors.textPrimary)),
                                  subtitle: Text(
                                      r['telefone']?.toString() ?? '',
                                      style: const TextStyle(
                                          color: GridColors.textSecondary)),
                                  trailing: Icon(
                                      _selecionado?['id'] == r['id']
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: CustomColors.primaryGreen),
                                  onTap: () =>
                                      setState(() => _selecionado = r)),
                          ],
                          if (edicao || _temConta == false) ...[
                            _campo(_nome, 'Nome completo', readOnly: edicao),
                            _campo(_telefone, 'WhatsApp / Telefone',
                                readOnly: edicao, obrigatorio: !edicao),
                            _campo(_email, 'E-mail (opcional)',
                                obrigatorio: false, readOnly: edicao),
                          ],
                          if (edicao || _temConta != null) ...[
                            DropdownButtonFormField<String>(
                                initialValue: _tipo,
                                decoration: const InputDecoration(
                                    labelText: 'Forma de cobrança'),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'plano',
                                      child: Text('Plano cadastrado')),
                                  DropdownMenuItem(
                                      value: 'mensal',
                                      child: Text('Valor mensal à parte')),
                                  DropdownMenuItem(
                                      value: 'aula_avulsa',
                                      child:
                                          Text('Aula avulsa / fora do plano'))
                                ],
                                onChanged: _ocupado
                                    ? null
                                    : (v) => setState(() => _tipo = v!)),
                            const SizedBox(height: 12),
                            if (_tipo == 'plano') ...[
                              DropdownButtonFormField<String>(
                                  initialValue: _planos.any(
                                          (p) => p['id'].toString() == _plano)
                                      ? _plano
                                      : null,
                                  decoration:
                                      const InputDecoration(labelText: 'Plano'),
                                  items: [
                                    for (final p in _planos)
                                      DropdownMenuItem(
                                          value: p['id'].toString(),
                                          child:
                                              Text(p['nome']?.toString() ?? ''))
                                  ],
                                  onChanged: _ocupado
                                      ? null
                                      : (v) => setState(() {
                                            _plano = v;
                                            final p = _planos.firstWhere(
                                                (p) => p['id'].toString() == v);
                                            _valor.text = p['valor'].toString();
                                          })),
                              if (_planos.isEmpty)
                                const Text(
                                    'Nenhum plano cadastrado disponível. Use valor à parte.',
                                    style: TextStyle(color: GridColors.secondaryDark)),
                              const SizedBox(height: 12),
                            ],
                            _campo(
                                _valor,
                                _tipo == 'aula_avulsa'
                                    ? 'Valor por aula (R\$)'
                                    : 'Valor do mês (R\$)',
                                numero: true,
                                readOnly: _tipo == 'plano', validar: (v) {
                              final n = double.tryParse(
                                  (v ?? '').replaceAll(',', '.'));
                              return n == null || !n.isFinite || n < 0
                                  ? 'Informe um valor válido.'
                                  : null;
                            }),
                            _campo(_frequencia,
                                'Frequência contratada (aulas por semana)',
                                numero: true, validar: (v) {
                              final n = int.tryParse(v ?? '');
                              return n == null || n < 0 || n > 7
                                  ? 'Informe de 0 a 7 aulas.'
                                  : null;
                            }),
                            _campo(_vencimento, 'Dia de vencimento',
                                numero: true, validar: (v) {
                              final n = int.tryParse(v ?? '');
                              return n == null || n < 1 || n > 31
                                  ? 'Informe um dia de 1 a 31.'
                                  : null;
                            }),
                            const Text(
                                'A frequência contratada é independente da frequência real de treinos.',
                                style: TextStyle(color: GridColors.textSecondary)),
                            const SizedBox(height: 12),
                          ],
                          if (_erro != null)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(_erro!,
                                    style: const TextStyle(
                                        color: GridColors.error))),
                          if (edicao || _temConta != null)
                            FilledButton(
                                onPressed: _ocupado ? null : _salvar,
                                child: Text(_ocupado
                                    ? 'Aguarde...'
                                    : edicao
                                        ? 'Salvar alterações'
                                        : _temConta == true
                                            ? 'Vincular e salvar'
                                            : 'Cadastrar aluno')),
                        ])))));
  }
}
