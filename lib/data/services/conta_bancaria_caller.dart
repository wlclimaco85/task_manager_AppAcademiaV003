import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import '../models/conta_bancaria_model.dart';

class ContaBancariaCaller {
  /// 🔹 Buscar todas as contas bancárias com paginação
  Future<List<ContaBancaria>> fetchContas(BuildContext context) async {
    List<ContaBancaria> contas = [];

    try {
      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.contasBancarias);

      if (response.isSuccess && response.body != null) {
        final List<dynamic> data = response.body!['data']['dados'] ?? [];
        contas = data
            .map((item) =>
                ContaBancaria.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      debugPrint('Erro ao buscar contas bancárias: $e');
    }

    return contas;
  }

  /// 🔹 Ativar ou desativar uma conta
  Future<bool> ativarConta(int id, bool ativo) async {
    try {
      final url = '${ApiLinks.contasBancarias}/$id/ativar?ativo=$ativo';
      final NetworkResponse response =
          await NetworkCaller().patchRequest(url, {});
      return response.isSuccess;
    } catch (e) {
      debugPrint('Erro ao ativar/desativar conta: $e');
      return false;
    }
  }

  /// 💰 Transferência entre contas
  Future<bool> transferirSaldo({
    required int contaOrigemId,
    required int contaDestinoId,
    required double valor,
    required int empresaId,
    int? parceiroId,
    String? historico,
  }) async {
    try {
      final url = '${ApiLinks.contasBancarias}/transferir'
          '?contaOrigemId=$contaOrigemId'
          '&contaDestinoId=$contaDestinoId'
          '&valor=$valor'
          '&empresaId=$empresaId'
          '${parceiroId != null ? '&parceiroId=$parceiroId' : ''}'
          '${historico != null && historico.isNotEmpty ? '&historico=$historico' : ''}';

      final NetworkResponse response =
          await NetworkCaller().postRequest(url, {});
      return response.isSuccess;
    } catch (e) {
      debugPrint('Erro ao transferir saldo: $e');
      return false;
    }
  }

  /// 📊 Extrato detalhado PDF
  Future<Uint8List?> gerarExtratoPdf({
    required int contaId,
    required int empresaId,
    int? parceiroId,
    required String de,
    required String ate,
  }) async {
    try {
      final url = '${ApiLinks.contasBancarias}/extrato/pdf'
          '?contaId=$contaId'
          '&empresaId=$empresaId'
          '${parceiroId != null ? '&parceiroId=$parceiroId' : ''}'
          '&de=$de'
          '&ate=$ate';

      final response = await NetworkCaller().getRawBytes(url);
      return response;
    } catch (e) {
      debugPrint('Erro ao gerar extrato PDF: $e');
      return null;
    }
  }

  /// 📑 Extrato consolidado
  Future<Uint8List?> gerarExtratoConsolidado({
    required int contaId,
    required String de,
    required String ate,
  }) async {
    try {
      final url = '${ApiLinks.contasBancarias}/extrato/consolidado'
          '?contaId=$contaId&de=$de&ate=$ate';
      final response = await NetworkCaller().getRawBytes(url);
      return response;
    } catch (e) {
      debugPrint('Erro ao gerar extrato consolidado: $e');
      return null;
    }
  }

  /// 📈 Evolução do saldo diário
  Future<List<Map<String, dynamic>>> evolucaoSaldoDiario(
      int contaId, int days) async {
    try {
      final url = '${ApiLinks.contasBancarias}/$contaId/evolucao?days=$days';
      final NetworkResponse response = await NetworkCaller().getRequest(url);

      if (response.isSuccess && response.body != null) {
        final body = response.body!;
        // Se vier lista direta ou dentro de um objeto "data"
        final List<dynamic> data = body is List ? body : (body['data'] ?? []);

        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('Erro ao buscar evolução de saldo: $e');
    }
    return [];
  }

  /// 💵 Listar saldos por empresa/parceiro
  Future<List<Map<String, dynamic>>> listarSaldos({
    required int empresaId,
    int? parceiroId,
  }) async {
    try {
      final url = '${ApiLinks.contasBancarias}/saldos'
          '?empresaId=$empresaId'
          '${parceiroId != null ? '&parceiroId=$parceiroId' : ''}';

      final NetworkResponse response = await NetworkCaller().getRequest(url);

      if (response.isSuccess && response.body != null) {
        final body = response.body!;
        // ✅ Pode vir como lista pura OU dentro de "data"
        final List<dynamic> data = body is List ? body : (body['data'] ?? []);

        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('Erro ao listar saldos: $e');
    }
    return [];
  }

  /// 🔹 Dropdown simplificado de contas
  static Future<List<Map<String, dynamic>>> loadContas() async {
    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.contasBancarias);
    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map((item) => {
                'value': item['id'],
                'label': '${item['banco'] ?? ''} - ${item['numero'] ?? ''}',
              })
          .toList();
    }
    return [];
  }
}
