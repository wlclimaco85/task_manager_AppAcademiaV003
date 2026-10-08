import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/profissional_vitrine_model.dart';

/// Repositório Offline-First de Vitrine e Contratação de Profissionais
class ProfissionaisVitrineRepository {
  static const String _kProfissionaisKey = 'appacademia_vitrine_profissionais_v1';

  static final ProfissionaisVitrineRepository _instance =
      ProfissionaisVitrineRepository._internal();
  factory ProfissionaisVitrineRepository() => _instance;
  ProfissionaisVitrineRepository._internal();

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
        debugPrint('[ProfissionaisVitrineRepository] Erro decode: $e');
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
        academiaFiltro != 'Todas as Academias') {
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

  Future<void> _salvar(List<ProfissionalVitrineModel> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(lista.map((e) => e.toMap()).toList());
    await prefs.setString(_kProfissionaisKey, jsonStr);
  }

  List<ProfissionalVitrineModel> _seedProfissionais() {
    return [
      ProfissionalVitrineModel(
        id: 'prof-1',
        nome: 'Rodrigo Medeiros',
        categoria: CategoriaProfissional.personal,
        registroProfissional: 'CREF 084920-G/SP',
        especialidade: 'Hipertrofia Pesada & Biomecânica',
        bioResumo:
            'Especialista em biomecânica aplicada à musculação de alta intensidade e periodização de atletas e iniciantes.',
        avaliacaoMedia: 4.9,
        totalAvaliacoes: 42,
        anosExperiencia: 8,
        whatsapp: '(11) 98111-2233',
        instagram: '@rodrigo_coach',
        precoMinimoMensal: 350.0,
        academiasAtendidas: const [
          AcademiaAtendimentoModel(
            id: 'acad-1',
            nome: 'Ironberg Alphaville',
            endereco: 'Al. Rio Negro, 500',
            bairroCidade: 'Alphaville, Barueri - SP',
          ),
          AcademiaAtendimentoModel(
            id: 'acad-2',
            nome: 'SmartFit Jardins',
            endereco: 'Rua Augusta, 2100',
            bairroCidade: 'Jardins, São Paulo - SP',
          ),
          AcademiaAtendimentoModel(
            id: 'acad-3',
            nome: 'BlueFit Paulista',
            endereco: 'Av. Paulista, 1500',
            bairroCidade: 'Bela Vista, São Paulo - SP',
          ),
        ],
        gradeHorarios: const [
          HorarioAtendimentoProfissional(
            diaSemana: 'Segunda-feira',
            horarioInicio: '06:00',
            horarioFim: '21:00',
            horariosDisponiveis: ['07:00', '11:00', '15:00', '16:00'],
            horariosOcupados: ['06:00', '08:00', '09:00', '18:00', '19:00', '20:00'],
          ),
          HorarioAtendimentoProfissional(
            diaSemana: 'Terça-feira',
            horarioInicio: '06:00',
            horarioFim: '21:00',
            horariosDisponiveis: ['10:00', '14:00', '15:00'],
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
            horariosDisponiveis: ['09:00', '14:00', '17:00'],
            horariosOcupados: ['07:00', '08:00', '18:00', '19:00'],
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
            titulo: 'Acompanhamento Presencial 3x/Semana',
            descricao:
                'Treinos presenciais na academia com ajuste de carga ao vivo, correção postural e periodização completa.',
            precoMensal: 650.0,
            aulasPorSemana: 3,
            destaque: true,
          ),
          PacoteContratacaoModel(
            id: 'pac-2',
            titulo: 'Consultoria Online Pro',
            descricao:
                'Montagem de treinos individualizados no app, suporte via WhatsApp diário e reavaliação a cada 30 dias.',
            precoMensal: 250.0,
            isConsultoriaOnline: true,
          ),
        ],
      ),
      ProfissionalVitrineModel(
        id: 'prof-2',
        nome: 'Dra. Beatriz Albuquerque',
        categoria: CategoriaProfissional.nutricionista,
        registroProfissional: 'CRN-3 48190/SP',
        especialidade: 'Nutrição Esportiva & Emagrecimento',
        bioResumo:
            'Especialista em modulação metabólica, dietas flexíveis e periodização nutricional para ganho de massa magra e definição.',
        avaliacaoMedia: 5.0,
        totalAvaliacoes: 56,
        anosExperiencia: 6,
        whatsapp: '(11) 97222-4455',
        instagram: '@dra_beatriz_nutri',
        precoMinimoMensal: 280.0,
        academiasAtendidas: const [
          AcademiaAtendimentoModel(
            id: 'acad-1',
            nome: 'Clínica BioNutri Jardins',
            endereco: 'Rua Bela Cintra, 1200',
            bairroCidade: 'Consolação, São Paulo - SP',
          ),
          AcademiaAtendimentoModel(
            id: 'acad-2',
            nome: 'Atendimento Online / Presencial Ironberg',
            endereco: 'Al. Rio Negro, 500',
            bairroCidade: 'Alphaville, Barueri - SP',
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
        ],
        pacotes: const [
          PacoteContratacaoModel(
            id: 'pac-3',
            titulo: 'Plano Nutricional Mensal Pro',
            descricao:
                'Cálculo de macros TACO sob medida, plano de suplementação, substituição de alimentos e acompanhamento semanal.',
            precoMensal: 280.0,
            destaque: true,
          ),
          PacoteContratacaoModel(
            id: 'pac-4',
            titulo: 'Combo Trimestral Performance',
            descricao:
                'Acompanhamento completo de 90 dias com 3 consultas e ajustes quinzenais de cardápio.',
            precoMensal: 220.0,
          ),
        ],
      ),
      ProfissionalVitrineModel(
        id: 'prof-3',
        nome: 'Marcos Vinícius (MV Personal)',
        categoria: CategoriaProfissional.personal,
        registroProfissional: 'CREF 112233-G/SP',
        especialidade: 'Condicionamento Físico & Funcional',
        bioResumo:
            'Treinamento voltado para mobilidade, ganho de força e queima calórica acelerada para rotinas corridas.',
        avaliacaoMedia: 4.8,
        totalAvaliacoes: 31,
        anosExperiencia: 5,
        whatsapp: '(11) 99333-6677',
        instagram: '@mv_personal_fit',
        precoMinimoMensal: 220.0,
        academiasAtendidas: const [
          AcademiaAtendimentoModel(
            id: 'acad-4',
            nome: 'Bio Ritmo Moema',
            endereco: 'Av. Ibirapuera, 3103',
            bairroCidade: 'Moema, São Paulo - SP',
          ),
          AcademiaAtendimentoModel(
            id: 'acad-3',
            nome: 'BlueFit Paulista',
            endereco: 'Av. Paulista, 1500',
            bairroCidade: 'Bela Vista, São Paulo - SP',
          ),
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
            id: 'pac-5',
            titulo: 'Treino Acompanhado 2x/Semana',
            descricao: 'Ideal para quem busca consistência e foco com acompanhamento presencial.',
            precoMensal: 450.0,
            aulasPorSemana: 2,
            destaque: true,
          ),
        ],
      ),
    ];
  }
}
