import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/services/fitness_conta_sync.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

/// Cadastro inicial do aluno: foto e medidas corporais. Tudo opcional.
/// O servidor e a fonte da verdade (o personal enxerga o status); o aparelho guarda
/// uma copia por conta para mostrar o lembrete sem depender da rede.
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

  /// Total de campos do cadastro: foto + todas as medidas.
  static int get totalCampos => medidas.length + 1;

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
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(FitnessContaSync.chave(_chaveBase));
      if (raw == null || raw.isEmpty) return {};
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (e) {
      AppLogger.i.warn('[CadastroInicial] Copia local invalida, ignorando: $e');
      return {};
    }
  }

  /// Grava os campos informados na copia local. Campo vazio apaga o valor anterior.
  static Future<void> salvar(Map<String, dynamic> novos) async {
    final atuais = await carregar();
    for (final entrada in novos.entries) {
      if (_preenchido(entrada.value)) {
        atuais[entrada.key] = entrada.value;
      } else {
        atuais.remove(entrada.key);
      }
    }
    await _gravarCopia(atuais);
  }

  /// Busca o cadastro no servidor e atualiza a copia local. Devolve null se a rede falhar.
  /// [temPersonal] diz se o aluno tem personal vinculado (usado pelo "!" da tela).
  static Future<({bool temPersonal, Map<String, dynamic> dados})?> buscarRemoto() async {
    try {
      final resposta = await NetworkCaller().getRequest(ApiLinks.cadastroInicialMeu);
      final data = resposta.body?['data'];
      if (!resposta.isSuccess || data is! Map) return null;
      final medidasRemotas = data['medidas'] is Map ? data['medidas'] as Map : const {};
      final dados = <String, dynamic>{
        'foto': data['foto'],
        for (final m in medidas) m.chave: medidasRemotas[m.chave],
      };
      await _gravarCopia(dados);
      return (temPersonal: data['temPersonal'] == true, dados: dados);
    } catch (e) {
      AppLogger.i.warn('[CadastroInicial] Falha ao consultar o cadastro no servidor: $e');
      return null;
    }
  }

  /// Envia foto e medidas ao servidor. Devolve false se o servidor recusar ou a rede falhar.
  static Future<bool> enviar(Map<String, dynamic> dados) async {
    try {
      final corpo = <String, dynamic>{
        'foto': dados['foto'],
        'medidas': {for (final m in medidas) m.chave: dados[m.chave]},
      };
      final resposta = await NetworkCaller().putRequest(ApiLinks.cadastroInicialMeu, corpo);
      if (!resposta.isSuccess) {
        AppLogger.i.warn('[CadastroInicial] Servidor recusou o cadastro (status ${resposta.statusCode}).');
        return false;
      }
      return true;
    } catch (e) {
      AppLogger.i.warn('[CadastroInicial] Falha ao enviar o cadastro: $e');
      return false;
    }
  }

  static Future<void> _gravarCopia(Map<String, dynamic> dados) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(FitnessContaSync.chave(_chaveBase), jsonEncode(dados));
    } catch (e) {
      AppLogger.i.warn('[CadastroInicial] Nao foi possivel gravar a copia local: $e');
    }
  }
}
