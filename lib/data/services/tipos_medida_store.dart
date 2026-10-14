import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/services/fitness_conta_sync.dart';

/// Catálogo de tipos/unidades, sem valores ou avaliações de demonstração.
class TiposMedidaStore {
  static const padrao = <String, String>{
    'Peso': 'kg', 'Altura': 'cm', 'IMC': 'kg/m²',
    'Pescoço': 'cm', 'Ombros': 'cm', 'Tórax': 'cm', 'Cintura': 'cm',
    'Abdômen': 'cm', 'Quadril': 'cm',
    'Braço direito relaxado': 'cm', 'Braço esquerdo relaxado': 'cm',
    'Braço direito flexionado': 'cm', 'Braço esquerdo flexionado': 'cm',
    'Antebraço direito': 'cm', 'Antebraço esquerdo': 'cm',
    'Coxa direita': 'cm', 'Coxa esquerda': 'cm',
    'Panturrilha direita': 'cm', 'Panturrilha esquerda': 'cm',
    'Gordura corporal': '%', 'Massa muscular': '%', 'Água corporal': '%',
  };
  static Future<Map<String, String>> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final key = FitnessContaSync.chave('fitness_tipos_medida');
    final remoto = await FitnessContaSync.carregar('tiposmedida');
    if (remoto != null && remoto.isNotEmpty) {
      final doc = remoto.firstWhere((e) => e['id'] == 'catalogo', orElse: () => {});
      if (doc['tipos'] is Map) await prefs.setString(key, jsonEncode(doc['tipos']));
    }
    final raw = prefs.getString(key);
    if (raw != null) return Map<String, String>.from(jsonDecode(raw));
    await prefs.setString(key, jsonEncode(padrao));
    await FitnessContaSync.salvar('tiposmedida', {'id': 'catalogo', 'tipos': padrao});
    return Map.from(padrao);
  }
}
