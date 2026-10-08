import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/nutricao_farmaco_model.dart';
import 'package:task_manager_flutter/data/models/fitness/exame_registro_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
import 'package:task_manager_flutter/data/services/exames_offline_repository.dart';

/// Repositório Offline-First de Nutrição, Farmacologia, Suplementação e Timeline 360
class NutricaoFarmacoOfflineRepository {
  static const String _kAlimentosKey = 'appacademia_alimentos_v1';
  static const String _kDietasKey = 'appacademia_dietas_v1';
  static const String _kMedicamentosKey = 'appacademia_medicamentos_v1';
  static const String _kSuplementosKey = 'appacademia_suplementos_v1';

  static final NutricaoFarmacoOfflineRepository _instance =
      NutricaoFarmacoOfflineRepository._internal();
  factory NutricaoFarmacoOfflineRepository() => _instance;
  NutricaoFarmacoOfflineRepository._internal();

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. BANCO DE ALIMENTOS (Tabela TACO / IBGE / Nutrição Esportiva)
  // ─────────────────────────────────────────────────────────────────────────────

  Future<List<AlimentoModel>> getAlimentos({String? busca, String? categoria}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAlimentosKey);

    List<AlimentoModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = _seedAlimentos();
      await _salvarAlimentos(lista);
    } else {
      try {
        final decoded = json.decode(raw) as List<dynamic>;
        lista = decoded
            .map((e) => AlimentoModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[NutricaoRepo] Erro decode alimentos: $e');
        lista = _seedAlimentos();
      }
    }

    if (categoria != null && categoria.isNotEmpty && categoria != 'Todos') {
      lista = lista
          .where((a) => a.categoria.toLowerCase() == categoria.toLowerCase())
          .toList();
    }

    if (busca != null && busca.trim().isNotEmpty) {
      final query = busca.toLowerCase().trim();
      lista = lista
          .where((a) =>
              a.nome.toLowerCase().contains(query) ||
              a.categoria.toLowerCase().contains(query))
          .toList();
    }

    return lista;
  }

  Future<void> addAlimento(AlimentoModel alimento) async {
    final lista = await getAlimentos();
    lista.insert(0, alimento);
    await _salvarAlimentos(lista);
  }

  Future<void> _salvarAlimentos(List<AlimentoModel> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(lista.map((e) => e.toMap()).toList());
    await prefs.setString(_kAlimentosKey, jsonStr);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. DIETAS & PROTOCOLOS DE MACRONUTRIENTES
  // ─────────────────────────────────────────────────────────────────────────────

  Future<List<DietaProtocoloModel>> getDietas({String? alunoId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDietasKey);

    List<DietaProtocoloModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = _seedDietas();
      await _salvarDietas(lista);
    } else {
      try {
        final decoded = json.decode(raw) as List<dynamic>;
        lista = decoded
            .map((e) => DietaProtocoloModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[NutricaoRepo] Erro decode dietas: $e');
        lista = _seedDietas();
      }
    }

    if (alunoId != null && alunoId.isNotEmpty) {
      return lista.where((d) => d.alunoId == alunoId || d.alunoId.isEmpty).toList();
    }
    return lista;
  }

  Future<void> salvarDieta(DietaProtocoloModel dieta) async {
    final lista = await getDietas();
    final idx = lista.indexWhere((d) => d.id == dieta.id);
    if (idx >= 0) {
      lista[idx] = dieta;
    } else {
      lista.insert(0, dieta);
    }
    await _salvarDietas(lista);
  }

  Future<void> _salvarDietas(List<DietaProtocoloModel> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(lista.map((e) => e.toMap()).toList());
    await prefs.setString(_kDietasKey, jsonStr);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. MEDICAMENTOS, CICLOS / HORMÔNIOS E PROTETORES
  // ─────────────────────────────────────────────────────────────────────────────

  Future<List<MedicamentoProtocoloModel>> getMedicamentos({String? alunoId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kMedicamentosKey);

    List<MedicamentoProtocoloModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = _seedMedicamentos();
      await _salvarMedicamentos(lista);
    } else {
      try {
        final decoded = json.decode(raw) as List<dynamic>;
        lista = decoded
            .map((e) =>
                MedicamentoProtocoloModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[NutricaoRepo] Erro decode medicamentos: $e');
        lista = _seedMedicamentos();
      }
    }

    if (alunoId != null && alunoId.isNotEmpty) {
      return lista.where((m) => m.alunoId == alunoId || m.alunoId.isEmpty).toList();
    }
    return lista;
  }

  Future<void> salvarMedicamento(MedicamentoProtocoloModel med) async {
    final lista = await getMedicamentos();
    final idx = lista.indexWhere((m) => m.id == med.id);
    if (idx >= 0) {
      lista[idx] = med;
    } else {
      lista.insert(0, med);
    }
    await _salvarMedicamentos(lista);
  }

  Future<void> _salvarMedicamentos(List<MedicamentoProtocoloModel> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(lista.map((e) => e.toMap()).toList());
    await prefs.setString(_kMedicamentosKey, jsonStr);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. SUPLEMENTAÇÃO
  // ─────────────────────────────────────────────────────────────────────────────

  Future<List<SuplementoProtocoloModel>> getSuplementos({String? alunoId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSuplementosKey);

    List<SuplementoProtocoloModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = _seedSuplementos();
      await _salvarSuplementos(lista);
    } else {
      try {
        final decoded = json.decode(raw) as List<dynamic>;
        lista = decoded
            .map((e) =>
                SuplementoProtocoloModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[NutricaoRepo] Erro decode suplementos: $e');
        lista = _seedSuplementos();
      }
    }

    if (alunoId != null && alunoId.isNotEmpty) {
      return lista.where((s) => s.alunoId == alunoId || s.alunoId.isEmpty).toList();
    }
    return lista;
  }

  Future<void> salvarSuplemento(SuplementoProtocoloModel sup) async {
    final lista = await getSuplementos();
    final idx = lista.indexWhere((s) => s.id == sup.id);
    if (idx >= 0) {
      lista[idx] = sup;
    } else {
      lista.insert(0, sup);
    }
    await _salvarSuplementos(lista);
  }

  Future<void> _salvarSuplementos(List<SuplementoProtocoloModel> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(lista.map((e) => e.toMap()).toList());
    await prefs.setString(_kSuplementosKey, jsonStr);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. TIMELINE FITNESS 360 (Evolução de Peso, % Gordura, Dietas e Medicamentos)
  // ─────────────────────────────────────────────────────────────────────────────

  Future<List<TimelineFitnessEventModel>> getTimelineEventos({String? alunoId}) async {
    final eventos = <TimelineFitnessEventModel>[];

    // 1. Avaliações Físicas (Peso & % BF ao longo do tempo)
    final avaliacoes = _seedAvaliacoesHistorico();
    for (final av in avaliacoes) {
      eventos.add(
        TimelineFitnessEventModel(
          data: av['data'] as DateTime,
          tipo: 'avaliacao_fisica',
          titulo: '📊 Avaliação Física',
          descricao: 'Peso: ${(av['peso'] as double).toStringAsFixed(1)} kg | Gordura: ${(av['bf'] as double).toStringAsFixed(1)}%',
          pesoKg: av['peso'] as double,
          percentualGordura: av['bf'] as double,
          tagCorHex: '#10B981', // Emerald
        ),
      );
    }

    // 2. Início e Fim de Dietas
    final dietas = await getDietas(alunoId: alunoId);
    for (final d in dietas) {
      final dtInicio = DateTime.tryParse(d.dataInicio);
      if (dtInicio != null) {
        eventos.add(
          TimelineFitnessEventModel(
            data: dtInicio,
            tipo: 'inicio_dieta',
            titulo: '🥗 Início: ${d.titulo}',
            descricao: '${d.caloriasMeta.toStringAsFixed(0)} kcal • P: ${d.proteinasMeta.toStringAsFixed(0)}g C: ${d.carboidratosMeta.toStringAsFixed(0)}g G: ${d.gordurasMeta.toStringAsFixed(0)}g',
            tagCorHex: '#059669', // Emerald Dark
          ),
        );
      }
      if (d.dataFim != null) {
        final dtFim = DateTime.tryParse(d.dataFim!);
        if (dtFim != null) {
          eventos.add(
            TimelineFitnessEventModel(
              data: dtFim,
              tipo: 'fim_dieta',
              titulo: '🏁 Término: ${d.titulo}',
              descricao: 'Conclusão do protocolo alimentar.',
              tagCorHex: '#64748B',
            ),
          );
        }
      }
    }

    // 3. Início e Fim de Medicamentos / Ciclos
    final medicamentos = await getMedicamentos(alunoId: alunoId);
    for (final m in medicamentos) {
      final dtInicio = DateTime.tryParse(m.dataInicio);
      if (dtInicio != null) {
        eventos.add(
          TimelineFitnessEventModel(
            data: dtInicio,
            tipo: 'inicio_medicamento',
            titulo: '💊 Início Protocolo: ${m.nomeComposto}',
            descricao: 'Dose: ${m.dosagem} (${m.frequencia}) • Categoria: ${m.categoria}',
            tagCorHex: '#EF4444', // Red / Atenção
          ),
        );
      }
      if (m.dataFim != null) {
        final dtFim = DateTime.tryParse(m.dataFim!);
        if (dtFim != null) {
          eventos.add(
            TimelineFitnessEventModel(
              data: dtFim,
              tipo: 'fim_medicamento',
              titulo: '🏁 Fim Ciclo: ${m.nomeComposto}',
              descricao: 'Término do período de administração.',
              tagCorHex: '#94A3B8',
            ),
          );
        }
      }
    }

    // 4. Início de Suplementos
    final suplementos = await getSuplementos(alunoId: alunoId);
    for (final s in suplementos) {
      final dtInicio = DateTime.tryParse(s.dataInicio);
      if (dtInicio != null) {
        eventos.add(
          TimelineFitnessEventModel(
            data: dtInicio,
            tipo: 'inicio_suplemento',
            titulo: '🧪 Suplemento: ${s.nome}',
            descricao: '${s.dosagem} • ${s.horario}',
            tagCorHex: '#3B82F6', // Blue
          ),
        );
      }
    }

    // 5. Exames Clínicos / Laboratoriais (Laudos PDF & Marcadores)
    final exames = await ExamesOfflineRepository().getExames(alunoId: alunoId);
    for (final ex in exames) {
      final dtExame = DateTime.tryParse(ex.dataExame);
      if (dtExame != null) {
        eventos.add(
          TimelineFitnessEventModel(
            data: dtExame,
            tipo: 'exame_laboratorial',
            titulo: '📄 Exame: ${ex.titulo}',
            descricao: 'Lab: ${ex.laboratório} • PDF: ${ex.nomeArquivoPdf ?? "laudo.pdf"}${ex.observacoesResultados != null ? " • " + ex.observacoesResultados! : ""}',
            tagCorHex: '#8B5CF6', // Purple
          ),
        );
      }
    }

    // Ordenar cronologicamente
    eventos.sort((a, b) => a.data.compareTo(b.data));
    return eventos;
  }

  List<Map<String, dynamic>> _seedAvaliacoesHistorico() {
    final hoje = DateTime.now();
    return [
      {
        'data': hoje.subtract(const Duration(days: 90)),
        'peso': 88.5,
        'bf': 19.2,
      },
      {
        'data': hoje.subtract(const Duration(days: 60)),
        'peso': 85.8,
        'bf': 16.4,
      },
      {
        'data': hoje.subtract(const Duration(days: 30)),
        'peso': 83.2,
        'bf': 13.8,
      },
      {
        'data': hoje,
        'peso': 81.4,
        'bf': 11.2,
      },
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SEEDS INICIAIS (Tabela Nutricional & Medicamentos)
  // ─────────────────────────────────────────────────────────────────────────────

  List<AlimentoModel> _seedAlimentos() {
    return const [
      // CARBOIDRATOS
      AlimentoModel(id: 'alim_1', nome: 'Arroz Branco Cozido', categoria: 'carboidratos', calorias: 128.0, proteinas: 2.5, carboidratos: 28.1, gorduras: 0.2, fibras: 1.6),
      AlimentoModel(id: 'alim_2', nome: 'Arroz Integral Cozido', categoria: 'carboidratos', calorias: 124.0, proteinas: 2.6, carboidratos: 25.8, gorduras: 1.0, fibras: 2.7),
      AlimentoModel(id: 'alim_3', nome: 'Feijão Carioca Cozido', categoria: 'carboidratos', calorias: 76.0, proteinas: 4.8, carboidratos: 13.6, gorduras: 0.5, fibras: 8.5),
      AlimentoModel(id: 'alim_4', nome: 'Feijão Preto Cozido', categoria: 'carboidratos', calorias: 77.0, proteinas: 4.5, carboidratos: 14.0, gorduras: 0.5, fibras: 8.4),
      AlimentoModel(id: 'alim_5', nome: 'Batata Doce Cozida', categoria: 'carboidratos', calorias: 77.0, proteinas: 0.6, carboidratos: 18.4, gorduras: 0.1, fibras: 2.2),
      AlimentoModel(id: 'alim_6', nome: 'Mandioca / Aipim Cozido', categoria: 'carboidratos', calorias: 125.0, proteinas: 0.6, carboidratos: 30.1, gorduras: 0.3, fibras: 1.6),
      AlimentoModel(id: 'alim_7', nome: 'Aveia em Flocos', categoria: 'carboidratos', calorias: 394.0, proteinas: 13.9, carboidratos: 66.6, gorduras: 8.5, fibras: 9.1),
      AlimentoModel(id: 'alim_8', nome: 'Pão Integral (Fatia)', categoria: 'carboidratos', porcaoPadraoGramas: 50.0, calorias: 120.0, proteinas: 5.0, carboidratos: 22.0, gorduras: 1.5, fibras: 3.5),

      // PROTEÍNAS
      AlimentoModel(id: 'alim_9', nome: 'Peito de Frango Grelhado', categoria: 'proteinas', calorias: 159.0, proteinas: 32.0, carboidratos: 0.0, gorduras: 3.2, fibras: 0.0),
      AlimentoModel(id: 'alim_10', nome: 'Carne Bovina Patinho Grelhado', categoria: 'proteinas', calorias: 185.0, proteinas: 35.9, carboidratos: 0.0, gorduras: 4.5, fibras: 0.0),
      AlimentoModel(id: 'alim_11', nome: 'Filé de Tilápia Grelhado', categoria: 'proteinas', calorias: 128.0, proteinas: 26.0, carboidratos: 0.0, gorduras: 2.7, fibras: 0.0),
      AlimentoModel(id: 'alim_12', nome: 'Ovo de Galinha Cozido (Unidade)', categoria: 'proteinas', porcaoPadraoGramas: 50.0, calorias: 72.0, proteinas: 6.3, carboidratos: 0.6, gorduras: 4.8, fibras: 0.0),
      AlimentoModel(id: 'alim_13', nome: 'Clara de Ovo Cozida (Unidade)', categoria: 'proteinas', porcaoPadraoGramas: 33.0, calorias: 17.0, proteinas: 3.6, carboidratos: 0.2, gorduras: 0.1, fibras: 0.0),
      AlimentoModel(id: 'alim_14', nome: 'Whey Protein Concentrado 80%', categoria: 'proteinas', porcaoPadraoGramas: 30.0, calorias: 120.0, proteinas: 24.0, carboidratos: 3.0, gorduras: 1.5, fibras: 0.0),
      AlimentoModel(id: 'alim_15', nome: 'Whey Protein Isolado 90%', categoria: 'proteinas', porcaoPadraoGramas: 30.0, calorias: 110.0, proteinas: 27.0, carboidratos: 0.5, gorduras: 0.2, fibras: 0.0),

      // FRUTAS & GORDURAS
      AlimentoModel(id: 'alim_16', nome: 'Banana Prata', categoria: 'frutas', porcaoPadraoGramas: 100.0, calorias: 98.0, proteinas: 1.3, carboidratos: 26.0, gorduras: 0.1, fibras: 2.0),
      AlimentoModel(id: 'alim_17', nome: 'Abacate', categoria: 'frutas', calorias: 96.0, proteinas: 1.2, carboidratos: 6.0, gorduras: 8.4, fibras: 6.3),
      AlimentoModel(id: 'alim_18', nome: 'Maçã Fuji com Casca', categoria: 'frutas', calorias: 56.0, proteinas: 0.3, carboidratos: 15.2, gorduras: 0.2, fibras: 1.3),
      AlimentoModel(id: 'alim_19', nome: 'Pasta de Amendoim Integral', categoria: 'gorduras', porcaoPadraoGramas: 30.0, calorias: 180.0, proteinas: 8.0, carboidratos: 6.0, gorduras: 15.0, fibras: 2.0),
      AlimentoModel(id: 'alim_20', nome: 'Azeite de Oliva Extra Virgem (Colher de Sopa)', categoria: 'gorduras', porcaoPadraoGramas: 13.0, calorias: 119.0, proteinas: 0.0, carboidratos: 0.0, gorduras: 13.5, fibras: 0.0),
      AlimentoModel(id: 'alim_21', nome: 'Leite Desnatado (Copo 200ml)', categoria: 'laticinios', porcaoPadraoGramas: 200.0, calorias: 70.0, proteinas: 6.2, carboidratos: 10.0, gorduras: 0.4, fibras: 0.0),
    ];
  }

  List<DietaProtocoloModel> _seedDietas() {
    final hoje = DateTime.now();
    return [
      DietaProtocoloModel(
        id: 'dieta_1',
        alunoId: 'aluno_1',
        titulo: 'Cutting Definido 2.200 kcal',
        objetivo: 'emagrecimento',
        caloriasMeta: 2200.0,
        proteinasMeta: 180.0,
        carboidratosMeta: 220.0,
        gordurasMeta: 65.0,
        dataInicio: hoje.subtract(const Duration(days: 60)).toIso8601String().substring(0, 10),
        dataFim: hoje.add(const Duration(days: 30)).toIso8601String().substring(0, 10),
        ativa: true,
        refeicoes: [
          const RefeicaoModel(
            id: 'ref_1',
            nome: 'Café da Manhã',
            horario: '07:30',
            itens: [
              ItemRefeicaoModel(alimentoId: 'alim_12', alimentoNome: 'Ovo de Galinha Cozido', quantidadeGramas: 150, calorias: 216, proteinas: 18.9, carboidratos: 1.8, gorduras: 14.4),
              ItemRefeicaoModel(alimentoId: 'alim_7', alimentoNome: 'Aveia em Flocos', quantidadeGramas: 50, calorias: 197, proteinas: 7.0, carboidratos: 33.3, gorduras: 4.2),
              ItemRefeicaoModel(alimentoId: 'alim_16', alimentoNome: 'Banana Prata', quantidadeGramas: 100, calorias: 98, proteinas: 1.3, carboidratos: 26.0, gorduras: 0.1),
            ],
          ),
          const RefeicaoModel(
            id: 'ref_2',
            nome: 'Almoço',
            horario: '12:30',
            itens: [
              ItemRefeicaoModel(alimentoId: 'alim_9', alimentoNome: 'Peito de Frango Grelhado', quantidadeGramas: 180, calorias: 286, proteinas: 57.6, carboidratos: 0.0, gorduras: 5.7),
              ItemRefeicaoModel(alimentoId: 'alim_1', alimentoNome: 'Arroz Branco Cozido', quantidadeGramas: 150, calorias: 192, proteinas: 3.7, carboidratos: 42.1, gorduras: 0.3),
              ItemRefeicaoModel(alimentoId: 'alim_3', alimentoNome: 'Feijão Carioca Cozido', quantidadeGramas: 100, calorias: 76, proteinas: 4.8, carboidratos: 13.6, gorduras: 0.5),
              ItemRefeicaoModel(alimentoId: 'alim_20', alimentoNome: 'Azeite de Oliva Extra Virgem', quantidadeGramas: 13, calorias: 119, proteinas: 0.0, carboidratos: 0.0, gorduras: 13.5),
            ],
          ),
          const RefeicaoModel(
            id: 'ref_3',
            nome: 'Pré-Treino & Lanche da Tarde',
            horario: '16:30',
            itens: [
              ItemRefeicaoModel(alimentoId: 'alim_5', alimentoNome: 'Batata Doce Cozida', quantidadeGramas: 150, calorias: 115, proteinas: 0.9, carboidratos: 27.6, gorduras: 0.1),
              ItemRefeicaoModel(alimentoId: 'alim_14', alimentoNome: 'Whey Protein Concentrado 80%', quantidadeGramas: 30, calorias: 120, proteinas: 24.0, carboidratos: 3.0, gorduras: 1.5),
            ],
          ),
          const RefeicaoModel(
            id: 'ref_4',
            nome: 'Jantar',
            horario: '20:00',
            itens: [
              ItemRefeicaoModel(alimentoId: 'alim_10', alimentoNome: 'Carne Bovina Patinho Grelhado', quantidadeGramas: 160, calorias: 296, proteinas: 57.4, carboidratos: 0.0, gorduras: 7.2),
              ItemRefeicaoModel(alimentoId: 'alim_1', alimentoNome: 'Arroz Branco Cozido', quantidadeGramas: 120, calorias: 153, proteinas: 3.0, carboidratos: 33.7, gorduras: 0.2),
            ],
          ),
        ],
      ),
    ];
  }

  List<MedicamentoProtocoloModel> _seedMedicamentos() {
    final hoje = DateTime.now();
    return [
      MedicamentoProtocoloModel(
        id: 'med_1',
        alunoId: 'aluno_1',
        nomeComposto: 'Enantato de Testosterona (TRT / Reposição)',
        dosagem: '250 mg / 1 ml',
        frequencia: '1x a cada 7 dias',
        viaAdministracao: 'Intramuscular',
        categoria: 'ergogenico_ciclo',
        dataInicio: hoje.subtract(const Duration(days: 75)).toIso8601String().substring(0, 10),
        dataFim: hoje.add(const Duration(days: 45)).toIso8601String().substring(0, 10),
        ativo: true,
        horario: 'Segunda-feira 09:00',
        observacoes: 'Aplicação no glúteo ou vasto lateral. Manter exames de hematócrito e estradiol a cada 60 dias.',
      ),
      MedicamentoProtocoloModel(
        id: 'med_2',
        alunoId: 'aluno_1',
        nomeComposto: 'Anastrozol (Inibidor de Aromatase)',
        dosagem: '0.5 mg',
        frequencia: 'DSDN (Dia Sim, Dia Não)',
        viaAdministracao: 'Oral',
        categoria: 'tpc_protetor',
        dataInicio: hoje.subtract(const Duration(days: 60)).toIso8601String().substring(0, 10),
        dataFim: hoje.add(const Duration(days: 45)).toIso8601String().substring(0, 10),
        ativo: true,
        horario: 'Junto com almoço',
        observacoes: 'Controle de sensibilidade e ginecomastia.',
      ),
    ];
  }

  List<SuplementoProtocoloModel> _seedSuplementos() {
    final hoje = DateTime.now();
    return [
      SuplementoProtocoloModel(
        id: 'sup_1',
        alunoId: 'aluno_1',
        nome: 'Creatina Monohidratada 100% Pura',
        dosagem: '5 g',
        horario: 'Pós-Treino com carboidrato',
        dataInicio: hoje.subtract(const Duration(days: 90)).toIso8601String().substring(0, 10),
        ativo: true,
        observacoes: 'Uso contínuo mesmo nos dias sem treino para saturação celular.',
      ),
      SuplementoProtocoloModel(
        id: 'sup_2',
        alunoId: 'aluno_1',
        nome: 'Ômega 3 (EPA 840mg / DHA 560mg)',
        dosagem: '2 cápsulas',
        horario: 'Almoço e Jantar',
        dataInicio: hoje.subtract(const Duration(days: 90)).toIso8601String().substring(0, 10),
        ativo: true,
        observacoes: 'Ação anti-inflamatória e melhora do perfil lipídico.',
      ),
      SuplementoProtocoloModel(
        id: 'sup_3',
        alunoId: 'aluno_1',
        nome: 'Multivitamínico de Alta Potência',
        dosagem: '1 tablete',
        horario: 'Café da manhã',
        dataInicio: hoje.subtract(const Duration(days: 90)).toIso8601String().substring(0, 10),
        ativo: true,
      ),
    ];
  }
}
