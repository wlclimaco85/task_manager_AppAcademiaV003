import 'dart:convert';
import 'package:task_manager_flutter/data/services/fitness_conta_sync.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/profissional_vitrine_model.dart';

/// Repositório Offline-First de Vitrine e Contratação de Profissionais
/// Focado no ecossistema de Uberaba - MG e redes parceiras
class ProfissionaisVitrineRepository {
  static const String _kProfissionaisKey = 'appacademia_vitrine_profissionais_v2';
  static const String _kAcademiasKey = 'appacademia_lista_academias_uberaba_v1';

  static final ProfissionaisVitrineRepository _instance =
      ProfissionaisVitrineRepository._internal();
  factory ProfissionaisVitrineRepository() => _instance;
  ProfissionaisVitrineRepository._internal();

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. Gestão e Listagem de Academias (Uberaba & Redes)
  // ─────────────────────────────────────────────────────────────────────────────

  Future<List<AcademiaAtendimentoModel>> getAcademiasCadastradas() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(FitnessContaSync.chave(_kAcademiasKey + '_real'));

    List<AcademiaAtendimentoModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = [];
      await _salvarAcademias(lista);
    } else {
      try {
        final decoded = json.decode(raw) as List<dynamic>;
        lista = decoded
            .map((e) =>
                AcademiaAtendimentoModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[ProfissionaisVitrineRepository] Erro decode academias: $e');
        lista = [];
      }
    }
    return lista;
  }

  Future<void> _salvarAcademias(List<AcademiaAtendimentoModel> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(lista.map((e) => e.toMap()).toList());
    await prefs.setString(FitnessContaSync.chave(_kAcademiasKey + '_real'), jsonStr);
  }

  /// Permite que o personal/gestor cadastre uma nova academia no app
  Future<void> cadastrarNovaAcademia(AcademiaAtendimentoModel academia) async {
    final atuais = await getAcademiasCadastradas();
    final idx = atuais.indexWhere((a) => a.id == academia.id);
    if (idx >= 0) {
      atuais[idx] = academia;
    } else {
      atuais.insert(0, academia);
    }
    await _salvarAcademias(atuais);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. Vitrine de Profissionais & Grade de Horários
  // ─────────────────────────────────────────────────────────────────────────────

  Future<List<ProfissionalVitrineModel>> getProfissionais({
    CategoriaProfissional? categoria,
    String? academiaFiltro,
    String? buscaTexto,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(FitnessContaSync.chave(_kProfissionaisKey + '_real'));

    List<ProfissionalVitrineModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = [];
      await _salvar(lista);
    } else {
      try {
        final decoded = json.decode(raw) as List<dynamic>;
        lista = decoded
            .map((e) =>
                ProfissionalVitrineModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[ProfissionaisVitrineRepository] Erro decode profs: $e');
        lista = [];
      }
    }

    if (categoria != null) {
      lista = lista
          .where((p) =>
              p.categoria == categoria ||
              p.categoria == CategoriaProfissional.ambos)
          .toList();
    }

    if (academiaFiltro != null &&
        academiaFiltro.isNotEmpty &&
        academiaFiltro != 'Todas as Academias' &&
        academiaFiltro != 'Todas de Uberaba') {
      lista = lista
          .where((p) => p.academiasAtendidas.any((a) =>
              a.nome.toLowerCase().contains(academiaFiltro.toLowerCase())))
          .toList();
    }

    if (buscaTexto != null && buscaTexto.trim().isNotEmpty) {
      final query = buscaTexto.toLowerCase();
      lista = lista
          .where((p) =>
              p.nome.toLowerCase().contains(query) ||
              p.especialidade.toLowerCase().contains(query) ||
              p.academiasAtendidas.any((a) => a.nome.toLowerCase().contains(query)))
          .toList();
    }

    return lista;
  }

  Future<ProfissionalVitrineModel?> getProfissionalPorId(String id) async {
    final lista = await getProfissionais();
    try {
      return lista.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> salvarProfissional(ProfissionalVitrineModel prof) async {
    final lista = await getProfissionais();
    final idx = lista.indexWhere((p) => p.id == prof.id);
    if (idx >= 0) {
      lista[idx] = prof;
    } else {
      lista.insert(0, prof);
    }
    await _salvar(lista);
  }

  /// Adiciona uma academia à lista de locais atendidos por um personal
  Future<void> vincularAcademiaAoPersonal({
    required String personalId,
    required AcademiaAtendimentoModel academia,
  }) async {
    final lista = await getProfissionais();
    final idx = lista.indexWhere((p) => p.id == personalId);
    if (idx >= 0) {
      final prof = lista[idx];
      if (!prof.academiasAtendidas.any((a) => a.nome.toLowerCase() == academia.nome.toLowerCase())) {
        final novas = [...prof.academiasAtendidas, academia];
        lista[idx] = ProfissionalVitrineModel(
          id: prof.id,
          nome: prof.nome,
          categoria: prof.categoria,
          registroProfissional: prof.registroProfissional,
          fotoUrl: prof.fotoUrl,
          especialidade: prof.especialidade,
          bioResumo: prof.bioResumo,
          avaliacaoMedia: prof.avaliacaoMedia,
          totalAvaliacoes: prof.totalAvaliacoes,
          anosExperiencia: prof.anosExperiencia,
          whatsapp: prof.whatsapp,
          instagram: prof.instagram,
          precoMinimoMensal: prof.precoMinimoMensal,
          academiasAtendidas: novas,
          gradeHorarios: prof.gradeHorarios,
          pacotes: prof.pacotes,
          aceitaNovosAlunos: prof.aceitaNovosAlunos,
        );
        await _salvar(lista);
      }
    }
  }

  /// Atualiza a grade de disponibilidade do personal (adicionar/remover horário livre)
  Future<void> atualizarDisponibilidadeHorario({
    required String personalId,
    required String diaSemana,
    required String horario,
    required bool marcarComoLivre,
  }) async {
    final lista = await getProfissionais();
    final idx = lista.indexWhere((p) => p.id == personalId);
    if (idx >= 0) {
      final prof = lista[idx];
      final novaGrade = prof.gradeHorarios.map((g) {
        if (g.diaSemana == diaSemana) {
          final livres = List<String>.from(g.horariosDisponiveis);
          final ocupados = List<String>.from(g.horariosOcupados);
          if (marcarComoLivre) {
            ocupados.remove(horario);
            if (!livres.contains(horario)) livres.add(horario);
            livres.sort();
          } else {
            livres.remove(horario);
            if (!ocupados.contains(horario)) ocupados.add(horario);
            ocupados.sort();
          }
          return HorarioAtendimentoProfissional(
            diaSemana: g.diaSemana,
            horarioInicio: g.horarioInicio,
            horarioFim: g.horarioFim,
            horariosDisponiveis: livres,
            horariosOcupados: ocupados,
          );
        }
        return g;
      }).toList();

      lista[idx] = ProfissionalVitrineModel(
        id: prof.id,
        nome: prof.nome,
        categoria: prof.categoria,
        registroProfissional: prof.registroProfissional,
        fotoUrl: prof.fotoUrl,
        especialidade: prof.especialidade,
        bioResumo: prof.bioResumo,
        avaliacaoMedia: prof.avaliacaoMedia,
        totalAvaliacoes: prof.totalAvaliacoes,
        anosExperiencia: prof.anosExperiencia,
        whatsapp: prof.whatsapp,
        instagram: prof.instagram,
        precoMinimoMensal: prof.precoMinimoMensal,
        academiasAtendidas: prof.academiasAtendidas,
        gradeHorarios: novaGrade,
        pacotes: prof.pacotes,
        aceitaNovosAlunos: prof.aceitaNovosAlunos,
      );
      await _salvar(lista);
    }
  }

  Future<void> _salvar(List<ProfissionalVitrineModel> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(lista.map((e) => e.toMap()).toList());
    await prefs.setString(FitnessContaSync.chave(_kProfissionaisKey + '_real'), jsonStr);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. Seeds Oficiais de Uberaba - MG & Redes
  // ─────────────────────────────────────────────────────────────────────────────




}
