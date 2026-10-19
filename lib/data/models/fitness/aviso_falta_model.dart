/// Modelo de Aviso de Falta — Aluno avisa Personal e Personal avisa Alunos.
/// Persiste offline em SharedPreferences; sincroniza em background quando autenticado.
class AvisoFaltaModel {
  final String id;

  /// Quem enviou o aviso: 'aluno' ou 'personal'
  final String remetenteTipo;

  /// ID e nome de quem enviou
  final String remetenteId;
  final String remetenteNome;

  /// ID e nome do destinatário
  final String destinatarioId;
  final String destinatarioNome;

  /// Data da aula que não ocorrerá (apenas data, sem hora)
  final String dataAula; // ISO 8601 date: 'YYYY-MM-DD'

  /// Horário estimado (ex: '07:30')
  final String? horario;

  /// Motivo (opcional)
  final String motivo;

  /// Data/hora em que o aviso foi enviado
  final DateTime enviadoEm;

  /// Status: 'aguardando' | 'visto'
  final String status;

  /// Data/hora em que foi marcado como visto (null se ainda não lido)
  final DateTime? vistoEm;

  const AvisoFaltaModel({
    required this.id,
    required this.remetenteTipo,
    required this.remetenteId,
    required this.remetenteNome,
    required this.destinatarioId,
    required this.destinatarioNome,
    required this.dataAula,
    this.horario,
    this.motivo = '',
    required this.enviadoEm,
    this.status = 'aguardando',
    this.vistoEm,
  });

  bool get foiVisto => status == 'visto';

  AvisoFaltaModel copyWith({
    String? status,
    DateTime? vistoEm,
  }) =>
      AvisoFaltaModel(
        id: id,
        remetenteTipo: remetenteTipo,
        remetenteId: remetenteId,
        remetenteNome: remetenteNome,
        destinatarioId: destinatarioId,
        destinatarioNome: destinatarioNome,
        dataAula: dataAula,
        horario: horario,
        motivo: motivo,
        enviadoEm: enviadoEm,
        status: status ?? this.status,
        vistoEm: vistoEm ?? this.vistoEm,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'remetenteTipo': remetenteTipo,
        'remetenteId': remetenteId,
        'remetenteNome': remetenteNome,
        'destinatarioId': destinatarioId,
        'destinatarioNome': destinatarioNome,
        'dataAula': dataAula,
        'horario': horario,
        'motivo': motivo,
        'enviadoEm': enviadoEm.toIso8601String(),
        'status': status,
        'vistoEm': vistoEm?.toIso8601String(),
      };

  factory AvisoFaltaModel.fromMap(Map<String, dynamic> map) => AvisoFaltaModel(
        id: map['id']?.toString() ?? '',
        remetenteTipo: map['remetenteTipo']?.toString() ?? 'aluno',
        remetenteId: map['remetenteId']?.toString() ?? '',
        remetenteNome: map['remetenteNome']?.toString() ?? '',
        destinatarioId: map['destinatarioId']?.toString() ?? '',
        destinatarioNome: map['destinatarioNome']?.toString() ?? '',
        dataAula: map['dataAula']?.toString() ?? '',
        horario: map['horario']?.toString(),
        motivo: map['motivo']?.toString() ?? '',
        enviadoEm: DateTime.tryParse(map['enviadoEm']?.toString() ?? '') ??
            DateTime.now(),
        status: map['status']?.toString() ?? 'aguardando',
        vistoEm: map['vistoEm'] != null
            ? DateTime.tryParse(map['vistoEm'].toString())
            : null,
      );
}
