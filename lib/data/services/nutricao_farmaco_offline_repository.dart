import 'dart:convert';
import 'package:task_manager_flutter/data/services/fitness_conta_sync.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';
import 'package:task_manager_flutter/data/models/fitness/nutricao_farmaco_model.dart';
import 'package:task_manager_flutter/data/services/exames_offline_repository.dart';

/// Repositório Offline-First de Nutrição, Farmacologia, Suplementação e Timeline 360
class NutricaoFarmacoOfflineRepository {
  static const String _kAlimentosKey = 'appacademia_alimentos_v1';
  static const String _kAlimentosImportadosKey =
      'appacademia_alimentos_importados_v1';
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

  Future<List<AlimentoModel>> getAlimentos(
      {String? busca, String? categoria}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAlimentosKey);

    final catalogo = await _seedAlimentos();
    List<AlimentoModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = catalogo;
      await _salvarAlimentos(lista);
    } else {
      try {
        final decoded = json.decode(raw) as List<dynamic>;
        final salvos = decoded
            .map((e) => AlimentoModel.fromMap(e as Map<String, dynamic>))
            .toList();
        // Aparelhos com a lista antiga recebem os alimentos novos e as descrições.
        lista = mesclarCatalogo(salvos, catalogo);
        if (json.encode(lista.map((e) => e.toMap()).toList()) != raw) {
          await _salvarAlimentos(lista);
        }
      } catch (e) {
        AppLogger.i
            .warn('Erro ao ler alimentos salvos; usando o catálogo padrão: $e');
        lista = catalogo;
      }
    }

    final chaveImportados = FitnessContaSync.chave(_kAlimentosImportadosKey);
    final remotosImportados = await FitnessContaSync.carregar('alimentos');
    if (FitnessContaSync.chave(_kAlimentosImportadosKey) != chaveImportados) {
      throw StateError('A conta mudou. Abra o catálogo novamente.');
    }
    if (remotosImportados != null &&
        !await prefs.setString(
            chaveImportados, json.encode(remotosImportados))) {
      throw StateError('Não foi possível atualizar o catálogo neste aparelho.');
    }
    final importadosRaw = prefs.getString(chaveImportados);
    if (importadosRaw != null) {
      final importados = (json.decode(importadosRaw) as List)
          .map((e) => AlimentoModel.fromMap(Map<String, dynamic>.from(e)));
      final porId = {for (final a in lista) a.id: a};
      for (final a in importados) {
        porId[a.id] = a;
      }
      lista = porId.values.toList();
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
              a.categoria.toLowerCase().contains(query) ||
              (a.grupo ?? '').toLowerCase().contains(query))
          .toList();
    }

    return lista;
  }

  Future<void> addAlimento(AlimentoModel alimento) async {
    await salvarAlimentosImportados([alimento]);
  }

  /// Lote idempotente por ID; fila durável precede cache para não perder pendências.
  Future<void> salvarAlimentosImportados(List<AlimentoModel> alimentos) async {
    if (alimentos.isEmpty) return;
    final chave = FitnessContaSync.chave(_kAlimentosImportadosKey);
    final filaKey = FitnessContaSync.chave('fitness_pendentes_alimentos');
    final autenticado = FitnessContaSync.autenticado;
    try {
      for (final a in alimentos) {
        if (a.nome.trim().isEmpty ||
            !a.porcaoPadraoGramas.isFinite ||
            a.porcaoPadraoGramas <= 0 ||
            [a.calorias, a.proteinas, a.carboidratos, a.gorduras, a.fibras]
                .any((v) => !v.isFinite || v < 0)) {
          throw ArgumentError('Dados nutricionais inválidos: ${a.nome}');
        }
      }
      final prefs = await SharedPreferences.getInstance();
      final lista = (json.decode(prefs.getString(chave) ?? '[]') as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final porId = {for (final a in lista) a['id']: a};
      for (final a in alimentos) {
        porId[a.id] = a.toMap();
      }
      if (autenticado) {
        final fila = Map<String, dynamic>.from(
            json.decode(prefs.getString(filaKey) ?? '{}'));
        for (final a in alimentos) {
          fila[a.id] = a.toMap();
        }
        if (!await prefs.setString(filaKey, json.encode(fila))) {
          throw StateError(
              'Não foi possível guardar os alimentos para sincronizar.');
        }
      }
      if (!await prefs.setString(chave, json.encode(porId.values.toList()))) {
        throw StateError(
            'Não foi possível salvar os alimentos neste aparelho.');
      }
      if (autenticado &&
          FitnessContaSync.chave(_kAlimentosImportadosKey) == chave) {
        await FitnessContaSync.carregar('alimentos');
      }
    } catch (error, stack) {
      AppLogger.i.error('Falha ao salvar alimentos importados.', stack);
      rethrow;
    }
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
    final key = FitnessContaSync.chave(_kDietasKey);
    final remoto = await FitnessContaSync.carregar('dietas');
    if (remoto != null) await prefs.setString(key, json.encode(remoto));
    final raw = prefs.getString(key);

    List<DietaProtocoloModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = [];
      await _salvarDietas(lista);
    } else {
      try {
        final decoded = json.decode(raw) as List<dynamic>;
        lista = decoded
            .map((e) => DietaProtocoloModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        AppLogger.i.warn('[NutricaoRepo] Erro decode dietas: $e');
        lista = [];
      }
    }

    if (alunoId != null && alunoId.isNotEmpty) {
      return lista
          .where((d) => d.alunoId == alunoId || d.alunoId.isEmpty)
          .toList();
    }
    return lista;
  }

  Future<void> salvarDieta(DietaProtocoloModel dieta) async {
    final chave = FitnessContaSync.chave(_kDietasKey);
    final lista = await getDietas();
    if (FitnessContaSync.chave(_kDietasKey) != chave) {
      throw StateError('A conta mudou. Abra a dieta novamente.');
    }
    final idx = lista.indexWhere((d) => d.id == dieta.id);
    if (idx >= 0) {
      lista[idx] = dieta;
    } else {
      lista.insert(0, dieta);
    }
    final prefs = await SharedPreferences.getInstance();
    if (FitnessContaSync.chave(_kDietasKey) != chave) {
      throw StateError('A conta mudou. Abra a dieta novamente.');
    }
    if (!await prefs.setString(
        chave, json.encode(lista.map((e) => e.toMap()).toList()))) {
      throw StateError('Não foi possível salvar a dieta neste aparelho.');
    }
    if (FitnessContaSync.chave(_kDietasKey) != chave) {
      throw StateError('A conta mudou. A dieta foi mantida na conta original.');
    }
    await FitnessContaSync.salvar('dietas', dieta.toMap());
  }

  Future<void> _salvarDietas(List<DietaProtocoloModel> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(lista.map((e) => e.toMap()).toList());
    await prefs.setString(FitnessContaSync.chave(_kDietasKey), jsonStr);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. MEDICAMENTOS, CICLOS / HORMÔNIOS E PROTETORES
  // ─────────────────────────────────────────────────────────────────────────────

  Future<List<MedicamentoProtocoloModel>> getMedicamentos(
      {String? alunoId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = FitnessContaSync.chave(_kMedicamentosKey);
    final remoto = await FitnessContaSync.carregar('medicamentos');
    if (remoto != null) await prefs.setString(key, json.encode(remoto));
    final raw = prefs.getString(key);

    List<MedicamentoProtocoloModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = [];
      await _salvarMedicamentos(lista);
    } else {
      try {
        final decoded = json.decode(raw) as List<dynamic>;
        lista = decoded
            .map((e) =>
                MedicamentoProtocoloModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        AppLogger.i.warn('[NutricaoRepo] Erro decode medicamentos: $e');
        lista = [];
      }
    }

    if (alunoId != null && alunoId.isNotEmpty) {
      return lista
          .where((m) => m.alunoId == alunoId || m.alunoId.isEmpty)
          .toList();
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
    await FitnessContaSync.salvar('medicamentos', med.toMap());
  }

  Future<void> _salvarMedicamentos(
      List<MedicamentoProtocoloModel> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(lista.map((e) => e.toMap()).toList());
    await prefs.setString(FitnessContaSync.chave(_kMedicamentosKey), jsonStr);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. SUPLEMENTAÇÃO
  // ─────────────────────────────────────────────────────────────────────────────

  Future<List<SuplementoProtocoloModel>> getSuplementos(
      {String? alunoId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = FitnessContaSync.chave(_kSuplementosKey);
    final remoto = await FitnessContaSync.carregar('suplementos');
    if (remoto != null) await prefs.setString(key, json.encode(remoto));
    final raw = prefs.getString(key);

    List<SuplementoProtocoloModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = [];
      await _salvarSuplementos(lista);
    } else {
      try {
        final decoded = json.decode(raw) as List<dynamic>;
        lista = decoded
            .map((e) =>
                SuplementoProtocoloModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        AppLogger.i.warn('[NutricaoRepo] Erro decode suplementos: $e');
        lista = [];
      }
    }

    if (alunoId != null && alunoId.isNotEmpty) {
      return lista
          .where((s) => s.alunoId == alunoId || s.alunoId.isEmpty)
          .toList();
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
    await FitnessContaSync.salvar('suplementos', sup.toMap());
  }

  Future<void> _salvarSuplementos(List<SuplementoProtocoloModel> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(lista.map((e) => e.toMap()).toList());
    await prefs.setString(FitnessContaSync.chave(_kSuplementosKey), jsonStr);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. TIMELINE FITNESS 360 (Evolução de Peso, % Gordura, Dietas e Medicamentos)
  // ─────────────────────────────────────────────────────────────────────────────

  Future<List<TimelineFitnessEventModel>> getTimelineEventos(
      {String? alunoId}) async {
    final eventos = <TimelineFitnessEventModel>[];

    // 1. Avaliações Físicas (Peso & % BF ao longo do tempo)
    final avaliacoes = <Map<String, dynamic>>[];
    for (final av in avaliacoes) {
      eventos.add(
        TimelineFitnessEventModel(
          data: av['data'] as DateTime,
          tipo: 'avaliacao_fisica',
          titulo: '📊 Avaliação Física',
          descricao:
              'Peso: ${(av['peso'] as double).toStringAsFixed(1)} kg | Gordura: ${(av['bf'] as double).toStringAsFixed(1)}%',
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
            descricao:
                '${d.caloriasMeta.toStringAsFixed(0)} kcal • P: ${d.proteinasMeta.toStringAsFixed(0)}g C: ${d.carboidratosMeta.toStringAsFixed(0)}g G: ${d.gordurasMeta.toStringAsFixed(0)}g',
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
            descricao:
                'Dose: ${m.dosagem} (${m.frequencia}) • Categoria: ${m.categoria}',
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
            descricao:
                'Lab: ${ex.laboratorio} • PDF: ${ex.nomeArquivoPdf ?? "laudo.pdf"}${ex.observacoesResultados != null ? " • " + ex.observacoesResultados! : ""}',
            tagCorHex: '#8B5CF6', // Purple
          ),
        );
      }
    }

    // Ordenar cronologicamente
    eventos.sort((a, b) => a.data.compareTo(b.data));
    return eventos;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SEEDS INICIAIS (Tabela Nutricional & Medicamentos)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Catálogo padrão de alimentos (assets/data/alimentos_catalogo.json).
  /// Valores por 100 g da TACO 4ª ed. (NEPA/UNICAMP); mesma fonte da migration
  /// V2026101405 do backend. Gerado por tool/catalogo_alimentos.
  static const String catalogoAsset = 'assets/data/alimentos_catalogo.json';
  List<AlimentoModel>? _catalogoCache;

  Future<List<AlimentoModel>> _seedAlimentos() async {
    if (_catalogoCache != null) return _catalogoCache!;
    try {
      final raw = await rootBundle.loadString(catalogoAsset);
      final decoded = json.decode(raw) as List<dynamic>;
      _catalogoCache = decoded
          .map(
              (e) => AlimentoModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e, st) {
      AppLogger.i.error('Falha ao carregar o catálogo de alimentos: $e', st);
      _catalogoCache = [];
    }
    return _catalogoCache!;
  }

  /// Une os alimentos salvos no aparelho com o catálogo padrão atual: os itens
  /// do catálogo são atualizados (descrição e valores TACO por 100 g), os novos
  /// são incluídos e alimentos que não fazem parte do catálogo são preservados.
  static List<AlimentoModel> mesclarCatalogo(
    List<AlimentoModel> salvos,
    List<AlimentoModel> catalogo,
  ) {
    final porId = {for (final a in catalogo) a.id: a};
    final vistos = <String>{};
    final resultado = <AlimentoModel>[
      for (final salvo in salvos)
        if (vistos.add(salvo.id)) porId[salvo.id] ?? salvo,
    ];
    resultado.addAll(catalogo.where((a) => !vistos.contains(a.id)));
    return resultado;
  }
}
