import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/fitness/agenda_evento_model.dart';
import 'package:task_manager_flutter/data/models/fitness/personal_gestao_model.dart';
import 'package:task_manager_flutter/data/repository/cadastro_repository.dart';
import 'package:task_manager_flutter/data/services/agenda_repository.dart';
import 'package:task_manager_flutter/data/services/personal_gestao_offline_repository.dart';
import 'package:task_manager_flutter/data/utils/fitness_access.dart';

class AgendaCompartilhadaScreen extends StatefulWidget {
  final bool embedded;
  const AgendaCompartilhadaScreen({super.key, this.embedded = false});

  @override
  State<AgendaCompartilhadaScreen> createState() =>
      _AgendaCompartilhadaScreenState();
}

class _AgendaCompartilhadaScreenState extends State<AgendaCompartilhadaScreen> {
  static const List<String> _academiasPadrao = [
    'Smart Fit',
    'Bluefit',
    'Bodytech',
    'Selfit',
    'Bio Ritmo',
    'Panobianco',
    'Academia Central',
  ];

  static const String _opcaoResidencia = 'Residência';
  static const String _opcaoOutro = 'Outro local (especificar)';

  final _repo = AgendaRepository();
  DateTime _focado = DateTime.now();
  DateTime _selecionado = DateTime.now();
  List<AgendaEventoModel> _eventos = [];
  List<PersonalAlunoGestaoModel> _alunos = [];
  List<String> _academias = List.from(_academiasPadrao);
  bool _carregando = true;

  bool get _personal => podeGerenciarAlunos();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    if (mounted) setState(() => _carregando = true);
    try {
      final inicio = DateTime(_focado.year, _focado.month - 1, 1);
      final fim = DateTime(_focado.year, _focado.month + 2, 1);
      final resultados = await Future.wait<dynamic>([
        _repo.listar(inicio, fim),
        if (_personal) PersonalGestaoOfflineRepository().getAlunos(),
        CadastroRepository()
            .listarAcademiasDisponiveis()
            .catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (!mounted) return;
      final eventos = resultados[0] as List<AgendaEventoModel>;
      final alunos = _personal && resultados.length > 1
          ? resultados[1] as List<PersonalAlunoGestaoModel>
          : <PersonalAlunoGestaoModel>[];

      final dynamic rawAcademias = _personal && resultados.length > 2
          ? resultados[2]
          : (!_personal && resultados.length > 1 ? resultados[1] : null);

      final novasAcademias = <String>{..._academiasPadrao};
      if (rawAcademias is List) {
        for (final item in rawAcademias) {
          if (item is Map && item['nome'] != null) {
            final nome = item['nome'].toString().trim();
            if (nome.isNotEmpty) novasAcademias.add(nome);
          }
        }
      }

      setState(() {
        _eventos = eventos;
        _alunos = alunos;
        _academias = novasAcademias.toList();
      });
    } catch (e) {
      if (mounted) _erro('$e');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<String> _locaisDisponiveis() {
    final list = <String>[];
    for (final ac in _academias) {
      final t = ac.trim();
      if (t.isNotEmpty &&
          t.toLowerCase() != 'residência' &&
          t.toLowerCase() != 'residencia' &&
          !list.contains(t)) {
        list.add(t);
      }
    }
    // "coloque as academias e por ultimo residencia"
    list.add(_opcaoResidencia);
    return list;
  }

  @visibleForTesting
  List<String> locaisDisponiveisTest() => _locaisDisponiveis();

  List<AgendaEventoModel> _doDia(DateTime dia) =>
      _eventos.where((item) => isSameDay(item.inicio, dia)).toList()
        ..sort((a, b) => a.inicio.compareTo(b.inicio));

  @override
  Widget build(BuildContext context) {
    final conteudo = Column(children: [
      _cabecalhoResumo(),
      TableCalendar<AgendaEventoModel>(
        locale: 'pt_BR',
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 730)),
        focusedDay: _focado,
        selectedDayPredicate: (dia) => isSameDay(dia, _selecionado),
        eventLoader: _doDia,
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {CalendarFormat.month: 'Mês'},
        onDaySelected: (dia, foco) => setState(() {
          _selecionado = dia;
          _focado = foco;
        }),
        onPageChanged: (foco) {
          _focado = foco;
          _carregar();
        },
        calendarStyle: CalendarStyle(
          selectedDecoration:
              BoxDecoration(color: GridColors.primary, shape: BoxShape.circle),
          todayDecoration: BoxDecoration(
              color: GridColors.primary.withValues(alpha: .18),
              shape: BoxShape.circle),
          markerDecoration: BoxDecoration(
              color: GridColors.secondary, shape: BoxShape.circle),
          defaultTextStyle: TextStyle(color: context.appText),
          weekendTextStyle: TextStyle(color: context.appTextSecondary),
          outsideTextStyle:
              TextStyle(color: context.appTextSecondary.withValues(alpha: .55)),
        ),
        headerStyle: HeaderStyle(
          titleCentered: true,
          titleTextStyle:
              TextStyle(color: context.appText, fontWeight: FontWeight.w700),
          leftChevronIcon: Icon(Icons.chevron_left, color: context.appText),
          rightChevronIcon: Icon(Icons.chevron_right, color: context.appText),
        ),
      ),
      Divider(color: context.appBorder, height: 1),
      Expanded(child: _listaDia()),
    ]);

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: context.appBackground,
        body: conteudo,
        floatingActionButton: _botaoNovo(),
      );
    }
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(title: const Text('Minha agenda')),
      body: conteudo,
      floatingActionButton: _botaoNovo(),
    );
  }

  Widget _cabecalhoResumo() {
    final futuras = _eventos
        .where((item) => !item.cancelado && item.inicio.isAfter(DateTime.now()))
        .length;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GridColors.primarySubtle,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Icon(Icons.calendar_month_outlined, color: GridColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _personal
                ? '$futuras compromissos futuros • aulas aparecem para o aluno'
                : '$futuras compromissos futuros • aulas do personal são compartilhadas',
            style: TextStyle(color: context.appText, fontSize: 12),
          ),
        ),
      ]),
    );
  }

  Widget _listaDia() {
    if (_carregando) {
      return Center(
          child: CircularProgressIndicator(color: GridColors.primary));
    }
    final itens = _doDia(_selecionado);
    if (itens.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.event_available_outlined,
              size: 52, color: context.appTextSecondary.withValues(alpha: .7)),
          const SizedBox(height: 10),
          Text('Nenhum evento neste dia.',
              style: TextStyle(color: context.appTextSecondary)),
          const SizedBox(height: 4),
          Text('Toque em “Novo evento” para organizar sua agenda.',
              style: TextStyle(
                  color: context.appTextSecondary.withValues(alpha: .75),
                  fontSize: 12)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        itemCount: itens.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) => _card(itens[index]),
      ),
    );
  }

  Widget _card(AgendaEventoModel evento) {
    final cor = _corTipo(evento.tipo);
    return Opacity(
      opacity: evento.cancelado ? .55 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: evento.compartilhado ? cor : context.appBorder),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 5,
            height: 62,
            decoration: BoxDecoration(
                color: cor, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(evento.titulo,
                      style: TextStyle(
                          color: context.appText,
                          fontWeight: FontWeight.w700,
                          decoration: evento.cancelado
                              ? TextDecoration.lineThrough
                              : null)),
                ),
                if (evento.compartilhado)
                  Icon(Icons.people_outline,
                      size: 17, color: GridColors.primary),
              ]),
              Text(
                '${DateFormat('HH:mm').format(evento.inicio)}–${DateFormat('HH:mm').format(evento.fim)}'
                '${evento.local.isEmpty ? '' : ' • ${evento.local}'}',
                style: TextStyle(color: context.appTextSecondary, fontSize: 12),
              ),
              if (evento.alunoNome?.isNotEmpty == true)
                Text('Aluno: ${evento.alunoNome}',
                    style: TextStyle(color: GridColors.primary, fontSize: 12)),
              if (!_personal && evento.personalNome?.isNotEmpty == true)
                Text('Personal: ${evento.personalNome}',
                    style: TextStyle(color: GridColors.primary, fontSize: 12)),
              if (evento.observacao.isNotEmpty)
                Text(evento.observacao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: context.appTextSecondary.withValues(alpha: .8),
                        fontSize: 11)),
            ]),
          ),
          if (evento.podeEditar && !evento.cancelado)
            PopupMenuButton<String>(
              color: context.appSurface,
              onSelected: (acao) => acao == 'editar'
                  ? _abrirFormulario(evento: evento)
                  : _cancelar(evento),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'editar', child: Text('Editar')),
                PopupMenuItem(value: 'cancelar', child: Text('Cancelar')),
              ],
            ),
        ]),
      ),
    );
  }

  Widget _botaoNovo() => FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo evento'),
      );

  Future<void> _cancelar(AgendaEventoModel evento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar evento?'),
        content: Text(evento.compartilhado
            ? 'O aluno e o personal serão notificados.'
            : 'O evento continuará no histórico como cancelado.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancelar evento')),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await _repo.cancelar(evento.id);
      await _carregar();
    } catch (e) {
      if (mounted) _erro('$e');
    }
  }

  Future<void> _abrirFormulario({AgendaEventoModel? evento}) async {
    final titulo = TextEditingController(text: evento?.titulo ?? '');
    final observacao = TextEditingController(text: evento?.observacao ?? '');
    var tipo = evento?.tipo ?? 'AULA';
    var dia = evento?.inicio ?? _selecionado;
    var hora = TimeOfDay.fromDateTime(
        evento?.inicio ?? DateTime.now().add(const Duration(hours: 1)));
    var duracao =
        evento == null ? 60 : evento.fim.difference(evento.inicio).inMinutes;
    var lembrete = evento?.lembreteMinutos ?? 60;
    var alunoId =
        evento?.alunoId ?? (_alunos.isEmpty ? null : _alunos.first.id);
    var semanas = 1;

    final locais = _locaisDisponiveis();
    String? localSelecionado;
    final localInicial = evento?.local.trim() ?? '';
    if (localInicial.isNotEmpty) {
      if (locais.contains(localInicial)) {
        localSelecionado = localInicial;
      } else {
        localSelecionado = _opcaoOutro;
      }
    }
    final localOutroController = TextEditingController(
      text: localSelecionado == _opcaoOutro ? localInicial : '',
    );

    final salvo = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.appSurface,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                20, 4, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(evento == null ? 'Novo evento' : 'Editar evento',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: _tiposPermitidos()
                        .map((item) => DropdownMenuItem(
                            value: item.key, child: Text(item.value)))
                        .toList(),
                    onChanged: evento == null
                        ? (value) => setSheetState(() => tipo = value ?? tipo)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                      controller: titulo,
                      decoration: InputDecoration(
                        labelText: 'Título',
                        hintText: tipo == 'AULA'
                            ? (_personal
                                ? 'Ex: Aula de musculação'
                                : 'Ex: Treino com personal')
                            : 'Ex: Consulta de rotina',
                      )),
                  if (_personal && tipo == 'AULA') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: alunoId,
                      decoration:
                          const InputDecoration(labelText: 'Aluno vinculado'),
                      items: _alunos
                          .map((item) => DropdownMenuItem(
                              value: item.id, child: Text(item.nome)))
                          .toList(),
                      onChanged: evento == null
                          ? (value) => setSheetState(() => alunoId = value)
                          : null,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final escolha = await showDatePicker(
                            context: context,
                            initialDate: dia,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 30)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 730)),
                          );
                          if (escolha != null) {
                            setSheetState(() => dia = escolha);
                          }
                        },
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(DateFormat('dd/MM/yyyy').format(dia)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final escolha = await showTimePicker(
                              context: context, initialTime: hora);
                          if (escolha != null) {
                            setSheetState(() => hora = escolha);
                          }
                        },
                        icon: const Icon(Icons.schedule),
                        label: Text(hora.format(context)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: duracao,
                    decoration: const InputDecoration(labelText: 'Duração'),
                    items: const [30, 45, 60, 90, 120]
                        .map((m) => DropdownMenuItem(
                            value: m, child: Text('$m minutos')))
                        .toList(),
                    onChanged: (value) =>
                        setSheetState(() => duracao = value ?? 60),
                  ),
                  const SizedBox(height: 14),
                  // ─── Local: Academias e por último Residência ───
                  DropdownButtonFormField<String>(
                    initialValue: localSelecionado,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Local',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                    hint: const Text('Selecione uma academia ou residência'),
                    items: [
                      ...locais.map((loc) {
                        final isResidencia = loc == _opcaoResidencia;
                        return DropdownMenuItem<String>(
                          value: loc,
                          child: Row(
                            children: [
                              Icon(
                                isResidencia
                                    ? Icons.home_outlined
                                    : Icons.fitness_center,
                                size: 18,
                                color: isResidencia
                                    ? Colors.amber[700]
                                    : GridColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  loc,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: isResidencia
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const DropdownMenuItem<String>(
                        value: _opcaoOutro,
                        child: Row(
                          children: [
                            Icon(Icons.edit_location_alt_outlined,
                                size: 18, color: Colors.blueGrey),
                            SizedBox(width: 8),
                            Text(_opcaoOutro),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setSheetState(() {
                        localSelecionado = value;
                      });
                    },
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: locais.map((loc) {
                        final isResidencia = loc == _opcaoResidencia;
                        final isSelected = localSelecionado == loc;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(loc),
                            avatar: Icon(
                              isResidencia
                                  ? Icons.home_outlined
                                  : Icons.fitness_center,
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : (isResidencia
                                      ? Colors.amber[700]
                                      : GridColors.primary),
                            ),
                            selected: isSelected,
                            selectedColor: isResidencia
                                ? Colors.amber[800]
                                : GridColors.primary,
                            labelStyle: TextStyle(
                              color:
                                  isSelected ? Colors.white : context.appText,
                              fontSize: 11,
                              fontWeight: isResidencia
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setSheetState(() {
                                  localSelecionado = loc;
                                  localOutroController.clear();
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (localSelecionado == _opcaoOutro) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: localOutroController,
                      decoration: const InputDecoration(
                        labelText: 'Digite o endereço ou nome do local',
                        prefixIcon: Icon(Icons.edit_location_outlined),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                      controller: observacao,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'Observação (opcional)')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: lembrete,
                    decoration:
                        const InputDecoration(labelText: 'Notificar antes'),
                    items: const {
                      0: 'Sem lembrete',
                      15: '15 minutos',
                      30: '30 minutos',
                      60: '1 hora',
                      120: '2 horas',
                      1440: '1 dia'
                    }
                        .entries
                        .map((e) => DropdownMenuItem(
                            value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (value) =>
                        setSheetState(() => lembrete = value ?? 60),
                  ),
                  if (evento == null && _personal && tipo == 'AULA') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: semanas,
                      decoration:
                          const InputDecoration(labelText: 'Repetição semanal'),
                      items: const {
                        1: 'Somente esta aula',
                        4: '4 semanas',
                        8: '8 semanas',
                        12: '12 semanas',
                        24: '24 semanas'
                      }
                          .entries
                          .map((e) => DropdownMenuItem(
                              value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (value) =>
                          setSheetState(() => semanas = value ?? 1),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () async {
                      if (titulo.text.trim().isEmpty) {
                        if (tipo == 'AULA') {
                          titulo.text = _personal
                              ? 'Aula com aluno'
                              : 'Aula com personal';
                        } else if (tipo == 'TREINO') {
                          titulo.text = 'Treino individual';
                        } else if (tipo == 'AVALIACAO') {
                          titulo.text = 'Avaliação física';
                        } else if (tipo == 'CONSULTA') {
                          titulo.text = 'Consulta';
                        } else {
                          _erro('Preencha o título do evento.');
                          return;
                        }
                      }
                      if (_personal &&
                          tipo == 'AULA' &&
                          alunoId == null &&
                          _alunos.isNotEmpty) {
                        _erro('Selecione o aluno vinculado para a aula.');
                        return;
                      }

                      final localFinal = localSelecionado == _opcaoOutro
                          ? localOutroController.text.trim()
                          : (localSelecionado ?? '');

                      final inicio = DateTime(
                          dia.year, dia.month, dia.day, hora.hour, hora.minute);
                      final dados = <String, dynamic>{
                        'titulo': titulo.text.trim(),
                        'tipo': tipo,
                        'inicio': _iso(inicio),
                        'fim': _iso(inicio.add(Duration(minutes: duracao))),
                        'local': localFinal,
                        'observacao': observacao.text.trim(),
                        'lembreteMinutos': lembrete,
                        'repetirSemanas': semanas,
                        if (alunoId != null && tipo == 'AULA')
                          'alunoId': int.tryParse(alunoId!),
                      };
                      try {
                        if (evento == null) {
                          await _repo.criar(dados);
                        } else {
                          await _repo.atualizar(evento.id, dados);
                        }
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext, true);
                        }
                      } catch (e) {
                        if (mounted) _erro('$e');
                      }
                    },
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: Text(evento == null
                        ? 'Salvar e notificar'
                        : 'Atualizar e notificar'),
                  ),
                ]),
          ),
        ),
      ),
    );
    titulo.dispose();
    observacao.dispose();
    localOutroController.dispose();
    if (salvo == true) await _carregar();
  }

  List<MapEntry<String, String>> _tiposPermitidos() => [
        if (_personal)
          const MapEntry('AULA', 'Aula com aluno')
        else ...[
          const MapEntry('AULA', 'Aula com personal'),
          const MapEntry('TREINO', 'Treino individual'),
        ],
        const MapEntry('CONSULTA', 'Consulta'),
        const MapEntry('MEDICAMENTO', 'Medicamento'),
        const MapEntry('AVALIACAO', 'Avaliação física'),
        const MapEntry('COMPROMISSO', 'Compromisso'),
        const MapEntry('OUTRO', 'Outro'),
      ];

  Color _corTipo(String tipo) => switch (tipo) {
        'AULA' => GridColors.primary,
        'TREINO' => Colors.teal,
        'MEDICAMENTO' => Colors.red,
        'CONSULTA' => Colors.blue,
        'AVALIACAO' => Colors.purple,
        _ => Colors.orange,
      };

  String _iso(DateTime value) => value.toIso8601String().split('.').first;
  void _erro(String mensagem) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(mensagem)));
}
