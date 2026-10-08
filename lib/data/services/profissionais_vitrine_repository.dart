import 'dart:convert';
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
    final raw = prefs.getString(_kAcademiasKey);

    List<AcademiaAtendimentoModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = _seedAcademiasUberaba();
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
        lista = _seedAcademiasUberaba();
      }
    }
    return lista;
  }

  Future<void> _salvarAcademias(List<AcademiaAtendimentoModel> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(lista.map((e) => e.toMap()).toList());
    await prefs.setString(_kAcademiasKey, jsonStr);
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
    final raw = prefs.getString(_kProfissionaisKey);

    List<ProfissionalVitrineModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = _seedProfissionais();
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
        lista = _seedProfissionais();
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
    await prefs.setString(_kProfissionaisKey, jsonStr);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. Seeds Oficiais de Uberaba - MG & Redes
  // ─────────────────────────────────────────────────────────────────────────────

  List<AcademiaAtendimentoModel> _seedAcademiasUberaba() {
    return const [
      AcademiaAtendimentoModel(
        id: 'ura-1',
        nome: 'SmartFit - Shopping Uberaba',
        endereco: 'Av. Santa Beatriz da Silva, 1501',
        bairroCidade: 'São Benedito, Uberaba - MG',
      ),
      AcademiaAtendimentoModel(
        id: 'ura-2',
        nome: 'SmartFit - Leopoldino de Oliveira',
        endereco: 'Av. Leopoldino de Oliveira, 2400',
        bairroCidade: 'Centro, Uberaba - MG',
      ),
      AcademiaAtendimentoModel(
        id: 'ura-3',
        nome: 'World Fitness Uberaba',
        endereco: 'Rua Tristão de Castro, 680',
        bairroCidade: 'Centro, Uberaba - MG',
      ),
      AcademiaAtendimentoModel(
        id: 'ura-4',
        nome: 'Academia Mega Fit',
        endereco: 'Av. Santos Dumont, 1100',
        bairroCidade: 'Universitário, Uberaba - MG',
      ),
      AcademiaAtendimentoModel(
        id: 'ura-5',
        nome: 'Academia Fisio & Forma',
        endereco: 'Av. Elias Cruvinel, 850',
        bairroCidade: 'Boa Vista, Uberaba - MG',
      ),
      AcademiaAtendimentoModel(
        id: 'ura-6',
        nome: 'Ironberg Franchising',
        endereco: 'Atendimento Regional / Consultoria',
        bairroCidade: 'Rede Nacional',
      ),
    ];
  }

  List<ProfissionalVitrineModel> _seedProfissionais() {
    final academias = _seedAcademiasUberaba();

    return [
      ProfissionalVitrineModel(
        id: 'prof-1',
        nome: 'Rodrigo Medeiros (Personal Pro)',
        categoria: CategoriaProfissional.personal,
        registroProfissional: 'CREF 038920-G/MG',
        especialidade: 'Hipertrofia Pesada & Biomecânica',
        bioResumo:
            'Personal Trainer atuante em Uberaba - MG nas principais academias. Especialista em periodização de alta intensidade e correção biomecânica.',
        avaliacaoMedia: 4.9,
        totalAvaliacoes: 48,
        anosExperiencia: 8,
        whatsapp: '(34) 99876-1122',
        instagram: '@rodrigo_personal_ura',
        precoMinimoMensal: 320.0,
        academiasAtendidas: [
          academias[0], // SmartFit Shopping Uberaba
          academias[1], // SmartFit Leopoldino
          academias[2], // World Fitness Uberaba
        ],
        gradeHorarios: const [
          HorarioAtendimentoProfissional(
            diaSemana: 'Segunda-feira',
            horarioInicio: '06:00',
            horarioFim: '21:00',
            horariosDisponiveis: ['07:00', '10:00', '15:00', '16:00'],
            horariosOcupados: ['06:00', '08:00', '09:00', '18:00', '19:00', '20:00'],
          ),
          HorarioAtendimentoProfissional(
            diaSemana: 'Terça-feira',
            horarioInicio: '06:00',
            horarioFim: '21:00',
            horariosDisponiveis: ['09:00', '14:00', '15:00'],
            horariosOcupados: ['07:00', '08:00', '18:00', '19:00'],
          ),
          HorarioAtendimentoProfissional(
            diaSemana: 'Quarta-feira',
            horarioInicio: '06:00',
            horarioFim: '21:00',
            horariosDisponiveis: ['07:00', '11:00', '16:00'],
            horariosOcupados: ['06:00', '08:00', '18:00', '19:00'],
          ),
          HorarioAtendimentoProfissional(
            diaSemana: 'Quinta-feira',
            horarioInicio: '06:00',
            horarioFim: '21:00',
            horariosDisponiveis: ['08:00', '14:00', '17:00'],
            horariosOcupados: ['07:00', '09:00', '18:00', '19:00'],
          ),
          HorarioAtendimentoProfissional(
            diaSemana: 'Sexta-feira',
            horarioInicio: '06:00',
            horarioFim: '20:00',
            horariosDisponiveis: ['08:00', '10:00', '15:00'],
            horariosOcupados: ['06:00', '07:00', '18:00'],
          ),
        ],
        pacotes: const [
          PacoteContratacaoModel(
            id: 'pac-1',
            titulo: 'Treino Presencial Uberaba 3x/Semana',
            descricao:
                'Acompanhamento presencial na academia com ajuste fino de cargas, correção postural e periodização completa.',
            precoMensal: 600.0,
            aulasPorSemana: 3,
            destaque: true,
          ),
          PacoteContratacaoModel(
            id: 'pac-2',
            titulo: 'Treino Presencial 2x/Semana',
            descricao: 'Ideal para consistência e divisão de treinos em dias alternados.',
            precoMensal: 420.0,
            aulasPorSemana: 2,
          ),
          PacoteContratacaoModel(
            id: 'pac-3',
            titulo: 'Consultoria Online Pro',
            descricao:
                'Fichas personalizadas no app, suporte via WhatsApp diário e reavaliações mensais.',
            precoMensal: 220.0,
            isConsultoriaOnline: true,
          ),
        ],
      ),
      ProfissionalVitrineModel(
        id: 'prof-2',
        nome: 'Dra. Camila Rezende (Nutri)',
        categoria: CategoriaProfissional.nutricionista,
        registroProfissional: 'CRN-9 29481/MG',
        especialidade: 'Nutrição Esportiva & Dieta Flexível TACO',
        bioResumo:
            'Nutricionista Esportiva em Uberaba - MG. Elaboração de planos alimentares focados em composição corporal, hipertrofia e adesão real.',
        avaliacaoMedia: 5.0,
        totalAvaliacoes: 62,
        anosExperiencia: 7,
        whatsapp: '(34) 99123-4455',
        instagram: '@camila_nutri_uberaba',
        precoMinimoMensal: 250.0,
        academiasAtendidas: [
          academias[0], // SmartFit Shopping
          academias[3], // Mega Fit Santos Dumont
          const AcademiaAtendimentoModel(
            id: 'ura-clinica',
            nome: 'Consultório Clínico Santos Dumont',
            endereco: 'Av. Santos Dumont, 820',
            bairroCidade: 'Universitário, Uberaba - MG',
          ),
        ],
        gradeHorarios: const [
          HorarioAtendimentoProfissional(
            diaSemana: 'Segunda-feira',
            horarioInicio: '08:00',
            horarioFim: '19:00',
            horariosDisponiveis: ['09:00', '11:00', '14:00', '16:00'],
            horariosOcupados: ['08:00', '10:00', '15:00', '17:00'],
          ),
          HorarioAtendimentoProfissional(
            diaSemana: 'Quarta-feira',
            horarioInicio: '08:00',
            horarioFim: '19:00',
            horariosDisponiveis: ['10:00', '13:00', '17:00'],
            horariosOcupados: ['09:00', '11:00', '14:00'],
          ),
          HorarioAtendimentoProfissional(
            diaSemana: 'Sexta-feira',
            horarioInicio: '08:00',
            horarioFim: '18:00',
            horariosDisponiveis: ['08:30', '10:30', '14:30'],
            horariosOcupados: ['11:30', '15:30'],
          ),
        ],
        pacotes: const [
          PacoteContratacaoModel(
            id: 'pac-4',
            titulo: 'Plano Nutricional Mensal TACO',
            descricao:
                'Cálculo de macros baseado na tabela TACO, lista de compras, cardápio flexível e acompanhamento semanal via WhatsApp.',
            precoMensal: 250.0,
            destaque: true,
          ),
          PacoteContratacaoModel(
            id: 'pac-5',
            titulo: 'Acompanhamento Trimestral Performance',
            descricao:
                '3 meses de acompanhamento com ajustes quinzenais e avaliação física por dobras cutâneas.',
            precoMensal: 200.0,
          ),
        ],
      ),
      ProfissionalVitrineModel(
        id: 'prof-3',
        nome: 'Marcos Vinícius (Personal Fit)',
        categoria: CategoriaProfissional.personal,
        registroProfissional: 'CREF 041122-G/MG',
        especialidade: 'Condicionamento Físico & Emagrecimento',
        bioResumo:
            'Personal Trainer atuante na região da Boa Vista e Centro de Uberaba. Foco em saúde, condicionamento e emagrecimento sustentável.',
        avaliacaoMedia: 4.8,
        totalAvaliacoes: 35,
        anosExperiencia: 6,
        whatsapp: '(34) 99654-7788',
        instagram: '@mv_personal_uberaba',
        precoMinimoMensal: 260.0,
        academiasAtendidas: [
          academias[1], // SmartFit Leopoldino
          academias[4], // Fisio & Forma Boa Vista
          academias[3], // Mega Fit Santos Dumont
        ],
        gradeHorarios: const [
          HorarioAtendimentoProfissional(
            diaSemana: 'Terça-feira',
            horarioInicio: '06:00',
            horarioFim: '20:00',
            horariosDisponiveis: ['08:00', '12:00', '17:00'],
            horariosOcupados: ['06:00', '07:00', '18:00', '19:00'],
          ),
          HorarioAtendimentoProfissional(
            diaSemana: 'Quinta-feira',
            horarioInicio: '06:00',
            horarioFim: '20:00',
            horariosDisponiveis: ['09:00', '13:00', '16:00'],
            horariosOcupados: ['06:00', '07:00', '18:00', '19:00'],
          ),
        ],
        pacotes: const [
          PacoteContratacaoModel(
            id: 'pac-6',
            titulo: 'Treino Acompanhado 2x/Semana',
            descricao: 'Treinos focados em mobilidade e alta queima calórica.',
            precoMensal: 380.0,
            aulasPorSemana: 2,
            destaque: true,
          ),
        ],
      ),
    ];
  }
}
