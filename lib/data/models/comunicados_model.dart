import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'setor_model.dart';

class Comunicado {
  int? id;
  int? codApp;
  int? empId;
  String? titulo;
  String? conteudo;
  String? autor;
  Setor? setor;
  DateTime? dhCreatedAt;
  DateTime? dataPublicacao;

  Comunicado({
    this.id,
    this.codApp,
    this.empId,
    this.titulo,
    this.conteudo,
    this.autor,
    this.setor,
    this.dhCreatedAt,
    this.dataPublicacao,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empId': empId,
      'codApp': codApp,
      'titulo': titulo,
      'conteudo': conteudo,
      'setor': setor?.toJson(),
      'autor': autor,
      'dataPublicacao': dataPublicacao?.toIso8601String(),
      'dhCreatedAt': dhCreatedAt?.toIso8601String(),
    };
  }

  Comunicado.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    empId = json['empId'];
    codApp = json['codApp'];
    titulo = json['titulo'] ?? '';
    conteudo = json['conteudo'] ?? '';
    autor = json['autor'] ?? '';
    setor = json['setor'] != null ? Setor.fromJson(json['setor']) : null;
    dataPublicacao = json['dataPublicacao'] != null
        ? DateTime.tryParse(json['dataPublicacao'])
        : null;
  }

  static List<Comunicado> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Comunicado.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> loadSetoresDropdown() async {
    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.allSetores);
    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map((item) => {
                'value': item['id'],
                'label': item['nome'],
              })
          .toList();
    }
    return [];
  }
}
