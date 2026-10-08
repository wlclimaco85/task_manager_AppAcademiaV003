import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    final raw = prefs.getString(_kExamesKey);

    List<ExameRegistroModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = _seedExames();
      await _salvar(lista);
    } else {
      try {
        final decoded = json.decode(raw) as List<dynamic>;
        lista = decoded
            .map((e) => ExameRegistroModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[ExamesOfflineRepository] Erro decode: $e');
        lista = _seedExames();
      }
    }

    if (alunoId != null && alunoId.isNotEmpty) {
      return lista.where((e) => e.alunoId == alunoId).toList();
    }
    return lista;
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
  }

  Future<void> excluirExame(String exameId) async {
    final lista = await getExames();
    lista.removeWhere((e) => e.id == exameId);
    await _salvar(lista);
  }

  Future<void> _salvar(List<ExameRegistroModel> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(lista.map((e) => e.toMap()).toList());
    await prefs.setString(_kExamesKey, jsonStr);
  }

  List<ExameRegistroModel> _seedExames() {
    return const [
      ExameRegistroModel(
        id: 'exame-1',
        alunoId: 'aluno-1',
        alunoNome: 'Lucas Mendonça',
        titulo: 'Painel Hormonal Completo & Perfil Lipídico',
        categoria: CategoriaExame.hormonal,
        dataExame: '2026-09-28',
        laboratorio: 'Laboratório Sabin - Shopping Uberaba',
        medicoSolicitante: 'Dr. Roberto Endocrinologista',
        nomeArquivoPdf: 'laudo_hormonal_lucas_out2026.pdf',
        urlPdf: 'https://appacademia.com.br/docs/laudos/laudo_hormonal_lucas_out2026.pdf',
        tamanhoBytesPdf: 1450000,
        observacoesResultados:
            'Testosterona Total: 920 ng/dL (Ref: 240-870), Estradiol: 32 pg/mL, HDL: 52 mg/dL, LDL: 95 mg/dL, TGO: 28 U/L, TGP: 31 U/L.',
        alteracaoRelevante: false,
        visualizadoPeloMedico: true,
      ),
      ExameRegistroModel(
        id: 'exame-2',
        alunoId: 'aluno-2',
        alunoNome: 'Camila Rodrigues',
        titulo: 'Hemograma Completo + Ferritina + Vitamina D',
        categoria: CategoriaExame.sangue,
        dataExame: '2026-10-02',
        laboratorio: 'Laboratório Carlos Chagas Uberaba',
        medicoSolicitante: 'Dra. Camila Rezende Nutricionista',
        nomeArquivoPdf: 'laudo_sangue_camila_out2026.pdf',
        urlPdf: 'https://appacademia.com.br/docs/laudos/laudo_sangue_camila_out2026.pdf',
        tamanhoBytesPdf: 980000,
        observacoesResultados:
            'Ferritina: 48 ng/mL, Vitamina D: 42 ng/mL (Adequado), Glicemia de Jejum: 84 mg/dL, Hemoglobina: 13.8 g/dL.',
        alteracaoRelevante: false,
        visualizadoPeloMedico: true,
      ),
      ExameRegistroModel(
        id: 'exame-3',
        alunoId: 'aluno-3',
        alunoNome: 'Gabriel Santos',
        titulo: 'Ecocardiograma com Doppler + Teste Ergométrico',
        categoria: CategoriaExame.cardiaco,
        dataExame: '2026-08-15',
        laboratorio: 'Hospital São Domingos Uberaba',
        medicoSolicitante: 'Dr. Fernando Cardiologista',
        nomeArquivoPdf: 'eco_doppler_gabriel_ago2026.pdf',
        urlPdf: 'https://appacademia.com.br/docs/laudos/eco_doppler_gabriel_ago2026.pdf',
        tamanhoBytesPdf: 2300000,
        observacoesResultados:
            'Aptidão cardiovascular excelente para musculação e treinos de alta intensidade. Fração de Ejeção: 68%.',
        alteracaoRelevante: false,
        visualizadoPeloMedico: true,
      ),
    ];
  }
}
