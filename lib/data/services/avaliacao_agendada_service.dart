import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/services/fitness_conta_sync.dart';

/// Situacao de uma avaliacao fisica agendada para um aluno.
enum SituacaoAvaliacao { vencida, proxima, distante }

/// Datas de nova avaliacao fisica agendadas pelo personal, por aluno.
/// Guardado por conta no aparelho; nao mistura contas diferentes.
class AvaliacaoAgendadaService {
  AvaliacaoAgendadaService._();

  /// Dentro desse numero de dias a avaliacao vira alerta no card do aluno.
  static const int diasAviso = 7;

  static const String _chaveBase = 'avaliacoes_agendadas_v1';

  /// Compara so as datas (sem hora). Data passada = vencida.
  static SituacaoAvaliacao situacao(DateTime data, DateTime hoje) {
    final dias = _soData(data).difference(_soData(hoje)).inDays;
    if (dias < 0) return SituacaoAvaliacao.vencida;
    if (dias <= diasAviso) return SituacaoAvaliacao.proxima;
    return SituacaoAvaliacao.distante;
  }

  static DateTime _soData(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Mapa alunoId -> data agendada (ISO yyyy-mm-dd).
  static Future<Map<String, DateTime>> listar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(FitnessContaSync.chave(_chaveBase));
    if (raw == null || raw.isEmpty) return {};
    try {
      final mapa = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return {
        for (final e in mapa.entries)
          if (DateTime.tryParse(e.value.toString()) != null)
            e.key: DateTime.parse(e.value.toString()),
      };
    } catch (_) {
      return {};
    }
  }

  static Future<void> agendar(String alunoId, DateTime data) async {
    final atuais = await listar();
    atuais[alunoId] = _soData(data);
    await _salvar(atuais);
  }

  static Future<void> cancelar(String alunoId) async {
    final atuais = await listar();
    atuais.remove(alunoId);
    await _salvar(atuais);
  }

  static Future<void> _salvar(Map<String, DateTime> mapa) async {
    final prefs = await SharedPreferences.getInstance();
    final json = {
      for (final e in mapa.entries)
        e.key: '${e.value.year.toString().padLeft(4, '0')}-'
            '${e.value.month.toString().padLeft(2, '0')}-'
            '${e.value.day.toString().padLeft(2, '0')}',
    };
    await prefs.setString(FitnessContaSync.chave(_chaveBase), jsonEncode(json));
  }
}
