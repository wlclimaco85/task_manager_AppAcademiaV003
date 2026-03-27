import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_flutter/data/models/documento_model.dart';
import 'package:task_manager_flutter/data/services/documentoService.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';
import 'package:task_manager_flutter/data/utils/grid_colors.dart'; // ★ adicionado para aplicar o tema

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime.now();
  final DocumentoService _documentoService = DocumentoService();
  List<DateTime> _datesWithNewDocs = [];
  List<DateTime> _datesWithReadDocs = [];
  List<Documento> _selectedDayDocuments = [];
  DateTime? _selectedDay;
  final int _usuarioId = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month);
    _loadDatesWithDocuments();
  }

  Future<void> _loadDatesWithDocuments() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final newDates = await _documentoService.getDatasComDocumentosNovos(
        _currentMonth.month,
        _currentMonth.year,
        _usuarioId,
      );

      final readDates = await _documentoService.getDatasComDocumentosLidos(
        _currentMonth.month,
        _currentMonth.year,
        _usuarioId,
      );

      setState(() {
        _datesWithNewDocs = newDates;
        _datesWithReadDocs = readDates;
      });
    } catch (e) {
      print('Erro ao carregar datas: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDayDocuments(DateTime day) async {
    try {
      final documentos = await _documentoService.getDocumentosPorData(day);

      for (var doc in documentos) {
        final isRead = await _documentoService.verificarSeLido(
          doc.id,
          _usuarioId,
        );
        doc.lido = isRead;
      }

      setState(() {
        _selectedDay = day;
        _selectedDayDocuments = documentos;
      });
    } catch (e) {
      print('Erro ao carregar documentos: $e');
    }
  }

  Future<void> _marcarDocumentoComoLido(int documentoId) async {
    try {
      await _documentoService.marcarComoLido(documentoId, _usuarioId);
      setState(() {
        _selectedDayDocuments = _selectedDayDocuments.map((doc) {
          if (doc.id == documentoId) {
            return Documento(
              id: doc.id,
              dataDocumento: doc.dataDocumento,
              descricao: doc.descricao,
              valor: doc.valor,
              status: doc.status,
              lido: true,
            );
          }
          return doc;
        }).toList();
      });
      _loadDatesWithDocuments();
    } catch (e) {
      print('Erro ao marcar documento como lido: $e');
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _loadDatesWithDocuments();
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _loadDatesWithDocuments();
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Color _getDayColor(DateTime date) {
    if (_datesWithNewDocs.any((d) => _isSameDay(d, date))) {
      return GridColors.primary.withOpacity(0.15); // ★ vermelho suave
    } else if (_datesWithReadDocs.any((d) => _isSameDay(d, date))) {
      return GridColors.secondary.withOpacity(0.10); // ★ verde suave
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.filterBackground, // ★ fundo da tela
      appBar: UserBannerAppBar(
        screenTitle: 'Calendário Financeiro',
        onRefresh: _loadDatesWithDocuments,
        isLoading: _isLoading,
        showFilterButton: false,
      ),
      body: Column(
        children: [
          _buildMonthNavigation(),
          _buildLegend(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [_buildCalendarGrid(), _buildDailyDocuments()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: GridColors.card, // ★ fundo branco do topo
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: GridColors.secondary), // ★
              onPressed: _previousMonth),
          Text(
            DateFormat('MMMM de yyyy', 'pt_BR').format(_currentMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: GridColors.primary, // ★
            ),
          ),
          IconButton(
              icon: const Icon(Icons.arrow_forward,
                  color: GridColors.secondary), // ★
              onPressed: _nextMonth),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Text('Legenda:',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: GridColors.secondary)), // ★
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: GridColors.primary.withOpacity(0.15), // ★
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text('Novos documentos',
                style: TextStyle(fontSize: 12, color: GridColors.primary)), // ★
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: GridColors.secondary.withOpacity(0.10), // ★
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text(
              'Documentos lidos',
              style: TextStyle(fontSize: 12, color: GridColors.secondary), // ★
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final int daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;

    final DateTime firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );

    final int firstWeekday = firstDayOfMonth.weekday;
    final int startingDay = firstWeekday % 7;
    List<String> weekdays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'];

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: weekdays.map((day) {
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: GridColors.secondary), // ★
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayOffset = index - startingDay;
              final currentDay = DateTime(
                _currentMonth.year,
                _currentMonth.month,
                1 + dayOffset,
              );

              final bool isCurrentMonth =
                  currentDay.month == _currentMonth.month;

              if (!isCurrentMonth ||
                  dayOffset < 0 ||
                  dayOffset >= daysInMonth) {
                return Container(
                  margin: const EdgeInsets.all(2),
                  child: const Center(child: Text('')),
                );
              }

              final int dayNumber = currentDay.day;

              return GestureDetector(
                onTap: () => _loadDayDocuments(currentDay),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _getDayColor(currentDay),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedDay != null &&
                              _isSameDay(_selectedDay!, currentDay)
                          ? GridColors.primary // ★ dia selecionado vermelho
                          : GridColors.divider, // ★ borda padrão cinza
                      width: _selectedDay != null &&
                              _isSameDay(_selectedDay!, currentDay)
                          ? 2
                          : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: GridColors.textSecondary, // ★ preto
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDailyDocuments() {
    if (_selectedDay == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Selecione um dia para ver os documentos',
          style: TextStyle(fontSize: 16, color: GridColors.secondary), // ★
        ),
      );
    }

    if (_selectedDayDocuments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documentos do dia ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: GridColors.primary), // ★
            ),
            const SizedBox(height: 10),
            const Text(
              'Nenhum documento encontrado para este dia',
              style: TextStyle(color: GridColors.secondary), // ★
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documentos do dia ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: GridColors.primary), // ★
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedDayDocuments.length,
            itemBuilder: (context, index) {
              final doc = _selectedDayDocuments[index];
              return Card(
                color: GridColors.card, // ★
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(doc.descricao,
                                style: const TextStyle(
                                    color: GridColors.textSecondary)), // ★
                            if (!doc.lido)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: GridColors.secondary
                                        .withOpacity(0.15), // ★
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    'Novo',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: GridColors.secondary), // ★
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        'R\$${doc.valor.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: GridColors.primary, // ★
                        ),
                      ),
                      if (!doc.lido)
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: GridColors.secondary, // ★
                          ),
                          onPressed: () => _marcarDocumentoComoLido(doc.id),
                          tooltip: 'Marcar como lido',
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
