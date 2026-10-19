class AgendaEventoModel {
  final String id;
  final String? serieId;
  final String titulo;
  final String tipo;
  final DateTime inicio;
  final DateTime fim;
  final String local;
  final String observacao;
  final String status;
  final bool compartilhado;
  final int lembreteMinutos;
  final String? alunoId;
  final String? alunoNome;
  final String? personalNome;
  final bool podeEditar;

  const AgendaEventoModel({
    required this.id,
    this.serieId,
    required this.titulo,
    required this.tipo,
    required this.inicio,
    required this.fim,
    this.local = '',
    this.observacao = '',
    this.status = 'AGENDADO',
    this.compartilhado = false,
    this.lembreteMinutos = 60,
    this.alunoId,
    this.alunoNome,
    this.personalNome,
    this.podeEditar = false,
  });

  bool get cancelado => status == 'CANCELADO';

  factory AgendaEventoModel.fromMap(Map<String, dynamic> map) =>
      AgendaEventoModel(
        id: map['id']?.toString() ?? '',
        serieId: map['serieId']?.toString(),
        titulo: map['titulo']?.toString() ?? 'Evento',
        tipo: map['tipo']?.toString() ?? 'OUTRO',
        inicio: DateTime.tryParse(map['inicio']?.toString() ?? '') ??
            DateTime.now(),
        fim: DateTime.tryParse(map['fim']?.toString() ?? '') ?? DateTime.now(),
        local: map['local']?.toString() ?? '',
        observacao: map['observacao']?.toString() ?? '',
        status: map['status']?.toString() ?? 'AGENDADO',
        compartilhado: map['compartilhado'] == true,
        lembreteMinutos: (map['lembreteMinutos'] as num?)?.toInt() ?? 60,
        alunoId: map['alunoId']?.toString(),
        alunoNome: map['alunoNome']?.toString(),
        personalNome: map['personalNome']?.toString(),
        podeEditar: map['podeEditar'] == true,
      );
}
