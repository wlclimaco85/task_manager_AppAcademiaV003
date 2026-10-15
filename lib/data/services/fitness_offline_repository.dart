import 'dart:convert';
import 'package:task_manager_flutter/data/services/fitness_conta_sync.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';
import 'package:task_manager_flutter/data/utils/midias_treino.dart';
import 'package:task_manager_flutter/data/models/fitness/exercicio_model.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';

/// Repositório Offline-First de Treinos e Exercícios (AppAcademia V003)
/// Funciona 100% offline no dispositivo e sincroniza com a nuvem quando conectado.
class FitnessOfflineRepository {
  static const String _kExerciciosKey = 'appacademia_exercicios_v1';
  static const String _kPlanosKey = 'appacademia_planos_treino_v1';
  static const String _kSessoesKey = 'appacademia_sessoes_treino_v1';

  static final FitnessOfflineRepository _instance =
      FitnessOfflineRepository._internal();
  factory FitnessOfflineRepository() => _instance;
  FitnessOfflineRepository._internal();

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. Catálogo de Exercícios (com Seed Inicial Completo Padrão MFIT)
  // ─────────────────────────────────────────────────────────────────────────────

  Future<List<ExercicioModel>> getExercicios({String? grupoMuscular}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kExerciciosKey);

    final catalogo = await _seedExercicios();
    List<ExercicioModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = catalogo;
      await _salvarExercicios(lista);
    } else {
      try {
        final decoded = json.decode(raw) as List<dynamic>;
        final salvos = decoded
            .map((e) => ExercicioModel.fromMap(e as Map<String, dynamic>))
            .toList();
        // Aparelhos com o catálogo antigo recebem os exercícios novos e a
        // descrição passo a passo sem perder vídeos ou exercícios próprios.
        lista = mesclarCatalogo(salvos, catalogo);
        if (json.encode(lista.map((e) => e.toMap()).toList()) != raw) {
          await _salvarExercicios(lista);
        }
      } catch (e) {
        AppLogger.i.warn('Erro ao ler exercícios salvos; usando o catálogo padrão: $e');
        lista = catalogo;
      }
    }

    if (grupoMuscular != null &&
        grupoMuscular.isNotEmpty &&
        grupoMuscular != 'Todos') {
      return lista
          .where((e) =>
              e.grupoMuscular.toLowerCase() == grupoMuscular.toLowerCase())
          .toList();
    }
    return lista;
  }

  Future<void> addExercicio(ExercicioModel exercicio) async {
    final atuais = await getExercicios();
    atuais.insert(0, exercicio);
    await _salvarExercicios(atuais);
  }

  Future<void> atualizarVideoExercicio(String id, String? videoUrl) async {
    final atuais = await getExercicios();
    final index = atuais.indexWhere((ex) => ex.id == id);
    if (index < 0) throw StateError('Exercicio nao encontrado.');
    final dados = atuais[index].toMap()..['videoUrl'] = videoUrl;
    atuais[index] = ExercicioModel.fromMap(dados);
    await _salvarExercicios(atuais);
  }

  Future<void> _salvarExercicios(List<ExercicioModel> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(lista.map((e) => e.toMap()).toList());
    await prefs.setString(_kExerciciosKey, jsonStr);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. Fichas e Planos de Treino
  // ─────────────────────────────────────────────────────────────────────────────

  Future<List<PlanoTreinoModel>> getPlanosTreino({String? alunoId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = FitnessContaSync.chave(_kPlanosKey);
    final remotos = await FitnessContaSync.carregar('planos');
    if (remotos != null) await prefs.setString(key, jsonEncode(remotos));
    final raw = prefs.getString(key);

    List<PlanoTreinoModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = [];
      await _salvarPlanos(lista);
    } else {
      try {
        final decoded = json.decode(raw) as List<dynamic>;
        lista = decoded
            .map((e) => PlanoTreinoModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[FitnessOfflineRepository] Erro decode planos: $e');
        lista = [];
      }
    }

    if (alunoId != null && alunoId.isNotEmpty) {
      return lista.where((p) => p.alunoId == alunoId || p.isTemplate).toList();
    }
    return lista;
  }

  Future<PlanoTreinoModel?> getPlanoAtivo({required String alunoId}) async {
    final planos = await getPlanosTreino(alunoId: alunoId);
    try {
      return planos.firstWhere((p) => p.ativo && !p.isTemplate);
    } catch (_) {
      return planos.isNotEmpty ? planos.first : null;
    }
  }

  Future<void> salvarPlanoTreino(PlanoTreinoModel plano) async {
    final atuais = await getPlanosTreino();
    final index = atuais.indexWhere((p) => p.id == plano.id);
    if (index >= 0) {
      atuais[index] = plano;
    } else {
      atuais.insert(0, plano);
    }
    await _salvarPlanos(atuais);
    await FitnessContaSync.salvar('planos', plano.toMap());
  }

  Future<void> _salvarPlanos(List<PlanoTreinoModel> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(lista.map((e) => e.toMap()).toList());
    await prefs.setString(FitnessContaSync.chave(_kPlanosKey), jsonStr);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. Registro de Sessões de Treino (Execução Offline)
  // ─────────────────────────────────────────────────────────────────────────────

  Future<List<SessaoTreinoRegistroModel>> getSessoesConcluidas(
      {String? alunoId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = FitnessContaSync.chave(_kSessoesKey);
    final remotos = await FitnessContaSync.carregar('sessoes');
    if (remotos != null) await prefs.setString(key, jsonEncode(remotos));
    final raw = prefs.getString(key);

    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = json.decode(raw) as List<dynamic>;
      final lista = decoded
          .map((e) =>
              SessaoTreinoRegistroModel.fromMap(e as Map<String, dynamic>))
          .toList();
      if (alunoId != null && alunoId.isNotEmpty) {
        return lista.where((s) => s.alunoId == alunoId).toList();
      }
      return lista;
    } catch (e) {
      debugPrint('[FitnessOfflineRepository] Erro decode sessoes: $e');
      return [];
    }
  }

  Future<void> registrarSessaoConcluida(
      SessaoTreinoRegistroModel sessao) async {
    final sessoes = await getSessoesConcluidas();
    sessoes.insert(0, sessao);
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(sessoes.map((s) => s.toMap()).toList());
    await prefs.setString(FitnessContaSync.chave(_kSessoesKey), jsonStr);
    await FitnessContaSync.salvar('sessoes', sessao.toMap());
  }

  /// Atualiza somente mídias de uma sessão real, sem duplicar o histórico.
  /// Grava primeiro no aparelho e usa a fila existente para sincronizar.
  Future<SessaoTreinoRegistroModel> atualizarSessaoMidias(String id, {
    required List<String> fotosBase64,
    required List<String> videosUrls,
  }) async {
    // A conta proprietária é capturada antes do primeiro await.
    final key = FitnessContaSync.chave(_kSessoesKey);
    final chaveFila = FitnessContaSync.chave('fitness_pendentes_sessoes');
    final autenticado = FitnessContaSync.autenticado;
    final fotos = List<String>.of(fotosBase64);
    final videos = videosUrls.map((v) => v.trim()).where((v) => v.isNotEmpty).toList();
    final erro = validarMidiasSessaoTreino(fotos, videos);
    if (erro != null) throw ArgumentError(erro);
    try {
      final prefs = await SharedPreferences.getInstance();
      final lista = (jsonDecode(prefs.getString(key) ?? '[]') as List)
          .map((e) => Map<String, dynamic>.from(e)).toList();
      final index = lista.indexWhere((e) => e['id'] == id);
      if (index < 0) {
        throw StateError('Treino não encontrado no histórico deste aparelho.');
      }
      final atualizada = SessaoTreinoRegistroModel.fromMap({
        ...lista[index],
        'fotosBase64': fotos,
        'videosUrls': videos,
        'videoUrl': null,
        'sincronizado': false,
      });
      lista[index] = atualizada.toMap();
      if (!await prefs.setString(key, jsonEncode(lista))) {
        throw StateError('Não foi possível salvar as mídias neste aparelho.');
      }
      if (autenticado) {
        final fila = Map<String, dynamic>.from(
            jsonDecode(prefs.getString(chaveFila) ?? '{}'));
        fila[id] = atualizada.toMap();
        if (!await prefs.setString(chaveFila, jsonEncode(fila))) {
          throw StateError('Não foi possível guardar a sincronização pendente.');
        }
        // Logout/troca de conta não pode enviar os anexos pela outra conta.
        if (FitnessContaSync.autenticado &&
            FitnessContaSync.chave(_kSessoesKey) == key) {
          await FitnessContaSync.carregar('sessoes');
        }
      }
      return atualizada;
    } catch (e, st) {
      AppLogger.i.error('Falha ao atualizar mídias do treino $id: $e', st);
      rethrow;
    }
  }

  Future<void> atualizarSessaoTreino(SessaoTreinoRegistroModel sessaoAtualizada) async {
    final sessoes = await getSessoesConcluidas();
    final index = sessoes.indexWhere((s) => s.id == sessaoAtualizada.id);
    if (index >= 0) {
      sessoes[index] = sessaoAtualizada;
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(sessoes.map((s) => s.toMap()).toList());
      await prefs.setString(FitnessContaSync.chave(_kSessoesKey), jsonStr);
    }
  }

  /// Retorna o último registro de execução de um exercício específico
  Future<ExercicioExecutadoRegistroModel?> getUltimaExecucaoExercicio(
      String exercicioId,
      {String? alunoId}) async {
    final sessoes = await getSessoesConcluidas(alunoId: alunoId);
    for (final s in sessoes) {
      for (final ex in s.exerciciosExecutados) {
        if (ex.exercicioId == exercicioId &&
            ex.series.any((serie) => serie.concluida)) {
          return ex;
        }
      }
    }
    return null;
  }

  /// Algoritmo MyFitCoach: Calcula sugestão de sobrecarga progressiva (+2kg / +5%)
  /// Se o aluno completou todas as séries com facilidade (RPE <= 7 ou reps batidas),
  /// recomenda um incremento de carga inteligente.
  Future<Map<String, dynamic>> calcularSugestaoSobrecarga({
    required String exercicioId,
    required double cargaAtualKg,
    required int repsPrescritas,
    String? alunoId,
  }) async {
    final ultima = await getUltimaExecucaoExercicio(exercicioId, alunoId: alunoId);
    if (ultima == null || ultima.series.isEmpty) {
      return {
        'temSugestao': false,
        'incrementoKg': 0.0,
        'cargaSugeridaKg': cargaAtualKg,
        'motivo': 'Primeira execução registrada.',
      };
    }

    final seriesValidas = ultima.series.where((s) => s.concluida).toList();
    if (seriesValidas.isEmpty) {
      return {
        'temSugestao': false,
        'incrementoKg': 0.0,
        'cargaSugeridaKg': cargaAtualKg,
        'motivo': 'Sem séries concluídas na sessão anterior.',
      };
    }

    final maxCargaAnterior = seriesValidas
        .map((s) => s.cargaRealKg)
        .reduce((a, b) => a > b ? a : b);

    // Se completou as repetições prescritas na última sessão com a carga anterior
    final bateuMeta = seriesValidas.every((s) => s.repeticoesRealizadas >= repsPrescritas);

    if (bateuMeta) {
      // Incremento padrão: +2kg para membros superiores / halteres ou +5kg para barras/pernas
      final incremento = maxCargaAnterior >= 40 ? 4.0 : 2.0;
      return {
        'temSugestao': true,
        'incrementoKg': incremento,
        'cargaSugeridaKg': maxCargaAnterior + incremento,
        'cargaAnteriorKg': maxCargaAnterior,
        'motivo': 'Você bateu todas as reps na última sessão! Sobrecarga recomendada: +${incremento.toStringAsFixed(0)}kg',
      };
    }

    return {
      'temSugestao': false,
      'incrementoKg': 0.0,
      'cargaSugeridaKg': maxCargaAnterior,
      'cargaAnteriorKg': maxCargaAnterior,
      'motivo': 'Mantenha a carga de ${maxCargaAnterior.toStringAsFixed(1)}kg até completar todas as repetições.',
    };
  }

  /// Calcula sequência de dias consecutivos treinados (Streak)
  Future<int> calcularStreakDias({String? alunoId}) async {
    final sessoes = await getSessoesConcluidas(alunoId: alunoId);
    if (sessoes.isEmpty) return 0;

    final diasUnicos = <String>{};
    for (final s in sessoes) {
      final dt = DateTime.tryParse(s.dataHoraInicio);
      if (dt != null) {
        diasUnicos.add('${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}');
      }
    }

    final hoje = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 30; i++) {
      final checkDia = hoje.subtract(Duration(days: i));
      final key = '${checkDia.year}-${checkDia.month.toString().padLeft(2, '0')}-${checkDia.day.toString().padLeft(2, '0')}';
      if (diasUnicos.contains(key)) {
        streak++;
      } else if (i > 0) {
        break; // quebrou a sequência
      }
    }
    return streak;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Seeds Iniciais (Padrão MFIT Personal)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Catálogo padrão de exercícios (assets/data/exercicios_catalogo.json).
  /// Mesma fonte da migration V2026101404 do backend; descrição passo a passo
  /// e imagens da free-exercise-db (domínio público).
  static const String catalogoAsset = 'assets/data/exercicios_catalogo.json';
  List<ExercicioModel>? _catalogoCache;

  Future<List<ExercicioModel>> _seedExercicios() async {
    if (_catalogoCache != null) return _catalogoCache!;
    try {
      final raw = await rootBundle.loadString(catalogoAsset);
      final decoded = json.decode(raw) as List<dynamic>;
      _catalogoCache = decoded
          .map((e) => ExercicioModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e, st) {
      AppLogger.i.error('Falha ao carregar o catálogo de exercícios: $e', st);
      _catalogoCache = [];
    }
    return _catalogoCache!;
  }

  /// Une o catálogo salvo no aparelho com o catálogo padrão atual: inclui os
  /// exercícios novos e atualiza textos/imagem dos padrões, preservando o
  /// vídeo que o personal cadastrou e todos os exercícios personalizados.
  static List<ExercicioModel> mesclarCatalogo(
    List<ExercicioModel> salvos,
    List<ExercicioModel> catalogo,
  ) {
    final porId = {for (final e in catalogo) e.id: e};
    final resultado = <ExercicioModel>[];
    final vistos = <String>{};
    for (final salvo in salvos) {
      vistos.add(salvo.id);
      final padrao = porId[salvo.id];
      if (padrao == null || salvo.isCustom) {
        resultado.add(salvo);
        continue;
      }
      resultado.add(ExercicioModel(
        id: padrao.id,
        nome: padrao.nome,
        grupoMuscular: padrao.grupoMuscular,
        equipamento: padrao.equipamento,
        // Vídeo do personal tem prioridade; sem ele, usa o vídeo do catálogo.
        videoUrl: _videoValido(salvo.videoUrl) ?? padrao.videoUrl,
        thumbnailUrl: padrao.thumbnailUrl,
        instrucoes: padrao.instrucoes,
        errosComuns: padrao.errosComuns,
        descricao: padrao.descricao,
        nivel: padrao.nivel,
      ));
    }
    resultado.addAll(catalogo.where((e) => !vistos.contains(e.id)));
    return resultado;
  }

  /// O seed antigo gravava GIFs da free-exercise-db que não existem (404).
  static String? _videoValido(String? url) {
    if (url == null || url.isEmpty) return null;
    final gifQuebrado =
        url.contains('/free-exercise-db/main/exercises/') && url.endsWith('.gif');
    return gifQuebrado ? null : url;
  }

}
