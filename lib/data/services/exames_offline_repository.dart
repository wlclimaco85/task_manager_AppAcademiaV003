import 'dart:convert';
import 'package:task_manager_flutter/data/services/fitness_conta_sync.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/exame_registro_model.dart';

/// Repositório Offline-First de Exames Laboratoriais e Laudos em PDF
class ExamesOfflineRepository {
  static const String _kExamesKey = 'appacademia_exames_laboratoriais_v1';

  static final ExamesOfflineRepository _instance =
      ExamesOfflineRepository._internal();
  factory ExamesOfflineRepository() => _instance;
  ExamesOfflineRepository._internal();

  Future<List<ExameRegistroModel>> getExames({String? alunoId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = FitnessContaSync.chave(_kExamesKey);
    final remoto = await FitnessContaSync.carregar('exames');
    if (remoto != null) await prefs.setString(key, json.encode(remoto));
    final raw = prefs.getString(key);

    List<ExameRegistroModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = [];
      await _salvar(lista);
    } else {
      try {
        final decoded = json.decode(raw) as List<dynamic>;
        lista = decoded
            .map((e) => ExameRegistroModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        AppLogger.i.warn('[ExamesOfflineRepository] Erro decode: $e');
        lista = [];
      }
    }

    if (alunoId != null && alunoId.isNotEmpty) {
      return lista.where((e) => e.alunoId == alunoId).toList();
    }
    return lista.toList();
  }

  Future<void> salvarExame(ExameRegistroModel exame) async {
    final lista = await getExames();
    final idx = lista.indexWhere((e) => e.id == exame.id);
    if (idx >= 0) {
      lista[idx] = exame;
    } else {
      lista.insert(0, exame);
    }
    await _salvar(lista);
    await FitnessContaSync.salvar('exames', exame.toMap());
  }

  Future<void> excluirExame(String exameId) async {
    final lista = await getExames();
    lista.removeWhere((e) => e.id == exameId);
    await _salvar(lista);
    await FitnessContaSync.salvar('exames', {'id': exameId, '_excluir': true});
  }

  Future<void> _salvar(List<ExameRegistroModel> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(lista.map((e) => e.toMap()).toList());
    await prefs.setString(FitnessContaSync.chave(_kExamesKey), jsonStr);
  }


}
