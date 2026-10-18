import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/services/fitness_conta_sync.dart';

/// Cadastro inicial do aluno: foto e medidas corporais. Tudo opcional.
/// Guardado no aparelho, por conta. Sincronizacao com o servidor fica para a proxima etapa.
class CadastroInicialService {
  CadastroInicialService._();

  static const String _chaveBase = 'cadastro_inicial_v1';

  /// Campos de medida que o aluno pode informar (chave, rotulo, unidade).
  static const List<({String chave, String rotulo, String unidade})> medidas = [
    (chave: 'peso', rotulo: 'Peso', unidade: 'kg'),
    (chave: 'altura', rotulo: 'Altura', unidade: 'cm'),
    (chave: 'cintura', rotulo: 'Cintura', unidade: 'cm'),
    (chave: 'quadril', rotulo: 'Quadril', unidade: 'cm'),
    (chave: 'braco', rotulo: 'Braço', unidade: 'cm'),
    (chave: 'coxa', rotulo: 'Coxa', unidade: 'cm'),
    (chave: 'panturrilha', rotulo: 'Panturrilha', unidade: 'cm'),
  ];

  /// Itens que ainda faltam para o cadastro ficar completo (lista vazia = completo).
  /// Nao bloqueia nada: serve so para o lembrete.
  static List<String> pendencias(Map<String, dynamic> dados) {
    final faltando = <String>[];
    if (!_preenchido(dados['foto'])) faltando.add('Foto');
    for (final m in medidas) {
      if (!_preenchido(dados[m.chave])) faltando.add(m.rotulo);
    }
    return faltando;
  }

  static bool _preenchido(Object? valor) {
    if (valor == null) return false;
    if (valor is String) return valor.trim().isNotEmpty;
    return true;
  }

  static Future<Map<String, dynamic>> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(FitnessContaSync.chave(_chaveBase));
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  /// Grava os campos informados. Campo vazio apaga o valor anterior.
  static Future<void> salvar(Map<String, dynamic> novos) async {
    final atuais = await carregar();
    for (final entrada in novos.entries) {
      if (_preenchido(entrada.value)) {
        atuais[entrada.key] = entrada.value;
      } else {
        atuais.remove(entrada.key);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(FitnessContaSync.chave(_chaveBase), jsonEncode(atuais));
  }
}
