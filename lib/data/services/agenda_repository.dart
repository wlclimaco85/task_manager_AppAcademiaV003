import 'package:task_manager_flutter/data/models/fitness/agenda_evento_model.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

class AgendaRepository {
  final NetworkCaller _network;
  AgendaRepository({NetworkCaller? network})
      : _network = network ?? NetworkCaller();

  Future<List<AgendaEventoModel>> listar(DateTime inicio, DateTime fim) async {
    final uri = Uri.parse(ApiLinks.fitnessAgenda).replace(queryParameters: {
      'inicio': _semFuso(inicio),
      'fim': _semFuso(fim),
    });
    final response = await _network.getRequest(uri.toString());
    if (!response.isSuccess) {
      throw StateError('Não foi possível carregar a agenda.');
    }
    final raw = response.body?['data'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) =>
            AgendaEventoModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<AgendaEventoModel>> criar(Map<String, dynamic> dados) async {
    final response = await _network.postRequest(ApiLinks.fitnessAgenda, dados);
    if (!response.isSuccess) {
      throw StateError(
          'Não foi possível salvar o evento. Verifique o horário.');
    }
    final raw = response.body?['data'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) =>
            AgendaEventoModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<AgendaEventoModel> atualizar(
      String id, Map<String, dynamic> dados) async {
    final response =
        await _network.putRequest('${ApiLinks.fitnessAgenda}/$id', dados);
    if (!response.isSuccess) {
      throw StateError('Não foi possível alterar o evento.');
    }
    return AgendaEventoModel.fromMap(
        Map<String, dynamic>.from(response.body?['data'] as Map));
  }

  Future<void> cancelar(String id) async {
    final response =
        await _network.deleteRequest('${ApiLinks.fitnessAgenda}/$id');
    if (!response.isSuccess) {
      throw StateError('Não foi possível cancelar o evento.');
    }
  }

  static String _semFuso(DateTime value) =>
      value.toIso8601String().split('.').first;
}
