// lib/data/models/conta_models.dart
class ContaBancariaModel {
  final int id;
  final String nome; // ex: "Itaú 1234-56789"
  final double saldo;

  ContaBancariaModel(
      {required this.id, required this.nome, required this.saldo});

  factory ContaBancariaModel.fromJson(Map<String, dynamic> j) {
    return ContaBancariaModel(
      id: j['contaId'] ?? j['id'],
      nome: j['nomeConta'] ?? '${j['banco']} ${j['agencia']}-${j['numero']}',
      saldo: (j['saldo'] as num).toDouble(),
    );
  }
}

class ContaSaldoDia {
  final DateTime day;
  final double saldo;
  ContaSaldoDia(this.day, this.saldo);

  factory ContaSaldoDia.fromJson(Map<String, dynamic> j) {
    return ContaSaldoDia(
        DateTime.parse(j['day']), (j['saldo'] as num).toDouble());
  }
}
