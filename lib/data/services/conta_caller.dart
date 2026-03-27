import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/conta_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

final token =
    AuthUtility.userInfo?.token; // Assuming userInfo.token is available

class ContaApi {
  Future<List<ContaBancariaModel>> listarSaldos(
      {required int empresaId, int? parceiroId}) async {
    final uri =
        Uri.parse(ApiLinks.financeFluxoDiarioSaldo).replace(queryParameters: {
      'empresaId': empresaId.toString(),
      if (parceiroId != null) 'parceiroId': parceiroId.toString(),
    });
    final r = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json', // Important: Add Accept header
      },
    );
    if (r.statusCode != 200) throw Exception('Saldos HTTP ${r.statusCode}');
    final arr = jsonDecode(r.body) as List;
    return arr.map((e) => ContaBancariaModel.fromJson(e)).toList();
  }

  Future<List<ContaSaldoDia>> evolucao(
      {required int contaId, int days = 30}) async {
    final uri = Uri.parse(ApiLinks.financeFluxoEvolucao(contaId))
        .replace(queryParameters: {
      'days': days.toString(),
    });
    final r = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json', // Important: Add Accept header
      },
    );
    if (r.statusCode != 200) throw Exception('Evolução HTTP ${r.statusCode}');
    final arr = jsonDecode(r.body) as List;
    return arr.map((e) => ContaSaldoDia.fromJson(e)).toList();
  }

  Future<Uri> extratoPdfLink(
      {required int contaId,
      required int empresaId,
      int? parceiroId,
      required DateTime de,
      required DateTime ate}) async {
    final uri =
        Uri.parse(ApiLinks.financeFluxoDiarioPdf).replace(queryParameters: {
      'contaId': contaId.toString(),
      'empresaId': empresaId.toString(),
      if (parceiroId != null) 'parceiroId': parceiroId.toString(),
      'de': de.toIso8601String().substring(0, 10),
      'ate': ate.toIso8601String().substring(0, 10),
    });
    return uri;
  }
}
