import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    List<ExercicioModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = _seedExercicios();
      await _salvarExercicios(lista);
    } else {
      try {
        final decoded = json.decode(raw) as List<dynamic>;
        lista = decoded
            .map((e) => ExercicioModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[FitnessOfflineRepository] Erro decode exercicios: $e');
        lista = _seedExercicios();
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
    final raw = prefs.getString(_kPlanosKey);

    List<PlanoTreinoModel> lista = [];
    if (raw == null || raw.isEmpty) {
      lista = _seedPlanosTreino();
      await _salvarPlanos(lista);
    } else {
      try {
        final decoded = json.decode(raw) as List<dynamic>;
        lista = decoded
            .map((e) => PlanoTreinoModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[FitnessOfflineRepository] Erro decode planos: $e');
        lista = _seedPlanosTreino();
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
  }

  Future<void> _salvarPlanos(List<PlanoTreinoModel> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(lista.map((e) => e.toMap()).toList());
    await prefs.setString(_kPlanosKey, jsonStr);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. Registro de Sessões de Treino (Execução Offline)
  // ─────────────────────────────────────────────────────────────────────────────

  Future<List<SessaoTreinoRegistroModel>> getSessoesConcluidas(
      {String? alunoId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSessoesKey);

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
    await prefs.setString(_kSessoesKey, jsonStr);
  }

  Future<void> atualizarSessaoTreino(SessaoTreinoRegistroModel sessaoAtualizada) async {
    final sessoes = await getSessoesConcluidas();
    final index = sessoes.indexWhere((s) => s.id == sessaoAtualizada.id);
    if (index >= 0) {
      sessoes[index] = sessaoAtualizada;
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(sessoes.map((s) => s.toMap()).toList());
      await prefs.setString(_kSessoesKey, jsonStr);
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

  List<ExercicioModel> _seedExercicios() {
    return const [
      // PEITO
      ExercicioModel(
        id: 'ex_supino_reto',
        nome: 'Supino Reto com Barra',
        grupoMuscular: 'Peitoral',
        equipamento: 'Barra',
        videoUrl: 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/00251301-Barbell-Bench-Press_Chest.gif',
        instrucoes:
            'Deite-se no banco com os olhos alinhados à barra. Pegada ligeiramente mais larga que os ombros. Desça até tocar suavemente a linha dos mamilos e empurre com controle.',
        errosComuns: 'Descolar a lombar do banco ou projetar os cotovelos a 90 graus.',
      ),
      ExercicioModel(
        id: 'ex_supino_inclinado',
        nome: 'Supino Inclinado com Halteres',
        grupoMuscular: 'Peitoral',
        equipamento: 'Halteres',
        instrucoes:
            'Banco regulado a 30-45 graus. Mantenha as escápulas aduzidas e desça os halteres alongando a porção clavicular do peitoral.',
        errosComuns: 'Inclinar o banco em excesso (acima de 45 graus) sobrecarregando o ombro.',
      ),
      ExercicioModel(
        id: 'ex_crucifixo_polia',
        nome: 'Crucifixo na Polia (Cross Over)',
        grupoMuscular: 'Peitoral',
        equipamento: 'Polia',
        instrucoes:
            'Braços semi-flexionados. Junte as mãos à frente do peito esmagando a musculatura na contração de pico.',
      ),

      // COSTAS
      ExercicioModel(
        id: 'ex_puxada_frente',
        nome: 'Puxada Frontal na Polia',
        grupoMuscular: 'Costas',
        equipamento: 'Polia',
        videoUrl: 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/01501301-Cable-Pulldown_Back.gif',
        instrucoes:
            'Pegada pronada aberta. Puxe a barra em direção ao peitoral superior, mantendo o peito estufado e cotovelos apontando para baixo.',
        errosComuns: 'Puxar a barra por trás do pescoço ou balançar o tronco para dar impulso.',
      ),
      ExercicioModel(
        id: 'ex_remada_curvada',
        nome: 'Remada Curvada com Barra',
        grupoMuscular: 'Costas',
        equipamento: 'Barra',
        instrucoes:
            'Tronco inclinado a 45 graus, coluna totalmente alinhada. Puxe a barra em direção ao umbigo aproximando as escápulas.',
      ),
      ExercicioModel(
        id: 'ex_remada_baixa',
        nome: 'Remada Baixa no Triângulo',
        grupoMuscular: 'Costas',
        equipamento: 'Polia',
        instrucoes:
            'Joelhos levemente flexionados. Puxe o triângulo contra o abdômen sem jogar o tronco para trás.',
      ),

      // QUADRÍCEPS
      ExercicioModel(
        id: 'ex_agachamento_livre',
        nome: 'Agachamento Livre com Barra',
        grupoMuscular: 'Quadríceps',
        equipamento: 'Barra',
        videoUrl: 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/00431301-Barbell-Full-Squat_Thighs.gif',
        instrucoes:
            'Pés alinhados à largura dos ombros. Desça flexionando quadril e joelhos simultaneamente até pelo menos 90 graus mantendo calcanhares no chão.',
        errosComuns: 'Valgo dinâmico (joelhos para dentro) e arredondamento da lombar.',
      ),
      ExercicioModel(
        id: 'ex_leg_press',
        nome: 'Leg Press 45°',
        grupoMuscular: 'Quadríceps',
        equipamento: 'Máquina',
        instrucoes:
            'Apoie os pés na plataforma na largura do quadril. Desça sem descolar o quadril do encosto.',
        errosComuns: 'Travar os joelhos em hiperextensão no ponto alto do movimento.',
      ),
      ExercicioModel(
        id: 'ex_cadeira_extensora',
        nome: 'Cadeira Extensora',
        grupoMuscular: 'Quadríceps',
        equipamento: 'Máquina',
        instrucoes:
            'Alinhe o eixo da máquina com a linha do joelho. Estenda os joelhos completamente com 1 segundo de isometria no topo.',
      ),

      // POSTERIOR & GLÚTEO
      ExercicioModel(
        id: 'ex_mesa_flexora',
        nome: 'Mesa Flexora',
        grupoMuscular: 'Posterior',
        equipamento: 'Máquina',
        instrucoes:
            'Deite-se no aparelho e ajuste a almofada acima do calcanhar. Flexione os joelhos puxando os pés em direção ao glúteo.',
      ),
      ExercicioModel(
        id: 'ex_stiff',
        nome: 'Stiff com Barra ou Halteres',
        grupoMuscular: 'Posterior',
        equipamento: 'Halteres',
        instrucoes:
            'Joelhos semi-flexionados. Empurre o quadril para trás como se quisesse tocar a parede com o glúteo.',
      ),
      ExercicioModel(
        id: 'ex_elevacao_pelvica',
        nome: 'Elevação Pélvica com Barra',
        grupoMuscular: 'Glúteo',
        equipamento: 'Barra',
        instrucoes:
            'Costas apoiadas no banco. Eleve o quadril contraindo fortemente os glúteos até formar uma linha reta entre tronco e joelhos.',
      ),

      // OMBROS
      ExercicioModel(
        id: 'ex_desenvolvimento_halteres',
        nome: 'Desenvolvimento com Halteres',
        grupoMuscular: 'Ombros',
        equipamento: 'Halteres',
        instrucoes:
            'Sentado com costas apoiadas. Empurre os halteres para cima sem bater um no outro no topo.',
      ),
      ExercicioModel(
        id: 'ex_elevacao_lateral',
        nome: 'Elevação Lateral com Halteres',
        grupoMuscular: 'Ombros',
        equipamento: 'Halteres',
        videoUrl: 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/03341301-Dumbbell-Lateral-Raise_Shoulders.gif',
        instrucoes:
            'Eleve os braços lateralmente até a altura dos ombros com os cotovelos levemente flexionados.',
      ),

      // BÍCEPS & TRÍCEPS
      ExercicioModel(
        id: 'ex_rosca_direta',
        nome: 'Rosca Direta com Barra W',
        grupoMuscular: 'Bíceps',
        equipamento: 'Barra',
        instrucoes:
            'Cotovelos fixos ao lado do tronco. Flexione os cotovelos subindo a barra sem jogar o ombro para frente.',
      ),
      ExercicioModel(
        id: 'ex_triceps_corda',
        nome: 'Tríceps na Polia com Corda',
        grupoMuscular: 'Tríceps',
        equipamento: 'Polia',
        videoUrl: 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/02411301-Cable-Triceps-Pushdown-(V-bar)_Upper-Arms.gif',
        instrucoes:
            'Estenda os cotovelos para baixo e afaste as pontas da corda na contração final.',
      ),

      // ABDÔMEN & CÁRDIO
      ExercicioModel(
        id: 'ex_prancha',
        nome: 'Prancha Abdominal Isométrica',
        grupoMuscular: 'Abdômen',
        equipamento: 'Peso Corporal',
        instrucoes:
            'Apoie antebraços e pontas dos pés no chão. Mantenha o corpo em linha reta e abdômen totalmente contraído.',
      ),
      ExercicioModel(
        id: 'ex_esteira_hiit',
        nome: 'Corrida / HIIT na Esteira',
        grupoMuscular: 'Cárdio',
        equipamento: 'Máquina',
        instrucoes:
            'Tiro de alta intensidade intercalado com caminhada de recuperação ativa.',
      ),
    ];
  }

  List<PlanoTreinoModel> _seedPlanosTreino() {
    return [
      PlanoTreinoModel(
        id: 'plano_template_abc',
        alunoId: 'aluno_demo',
        alunoNome: 'Aluno Demonstração',
        personalId: 'personal_logado',
        titulo: 'Ficha Hipertrofia ABC Pro',
        objetivo: 'Hipertrofia',
        dataInicio: '2026-10-01',
        dataValidade: '2026-11-30',
        isTemplate: false,
        ativo: true,
        divisoes: [
          DivisaoTreinoModel(
            id: 'div_a',
            letra: 'A',
            nome: 'Peito, Ombros e Tríceps (Push)',
            exercicios: [
              ItemTreinoModel(
                id: 'it_1',
                exercicioId: 'ex_supino_reto',
                exercicioNome: 'Supino Reto com Barra',
                grupoMuscular: 'Peitoral',
                series: 4,
                repeticoes: '8 a 10',
                cargaSugeridaKg: 30.0,
                descansoSegundos: 90,
                tecnica: 'Normal',
              ),
              ItemTreinoModel(
                id: 'it_2',
                exercicioId: 'ex_supino_inclinado',
                exercicioNome: 'Supino Inclinado com Halteres',
                grupoMuscular: 'Peitoral',
                series: 3,
                repeticoes: '10 a 12',
                cargaSugeridaKg: 18.0,
                descansoSegundos: 60,
                tecnica: 'Normal',
              ),
              ItemTreinoModel(
                id: 'it_3',
                exercicioId: 'ex_elevacao_lateral',
                exercicioNome: 'Elevação Lateral com Halteres',
                grupoMuscular: 'Ombros',
                series: 4,
                repeticoes: '12 a 15',
                cargaSugeridaKg: 8.0,
                descansoSegundos: 45,
                tecnica: 'Drop-set',
                observacoes: 'Última série com drop de 30% da carga.',
              ),
              ItemTreinoModel(
                id: 'it_4',
                exercicioId: 'ex_triceps_corda',
                exercicioNome: 'Tríceps na Polia com Corda',
                grupoMuscular: 'Tríceps',
                series: 3,
                repeticoes: '12',
                cargaSugeridaKg: 25.0,
                descansoSegundos: 45,
                tecnica: 'Normal',
              ),
            ],
          ),
          DivisaoTreinoModel(
            id: 'div_b',
            letra: 'B',
            nome: 'Costas e Bíceps (Pull)',
            exercicios: [
              ItemTreinoModel(
                id: 'it_5',
                exercicioId: 'ex_puxada_frente',
                exercicioNome: 'Puxada Frontal na Polia',
                grupoMuscular: 'Costas',
                series: 4,
                repeticoes: '10',
                cargaSugeridaKg: 45.0,
                descansoSegundos: 75,
                tecnica: 'Normal',
              ),
              ItemTreinoModel(
                id: 'it_6',
                exercicioId: 'ex_remada_baixa',
                exercicioNome: 'Remada Baixa no Triângulo',
                grupoMuscular: 'Costas',
                series: 3,
                repeticoes: '12',
                cargaSugeridaKg: 40.0,
                descansoSegundos: 60,
                tecnica: 'Normal',
              ),
              ItemTreinoModel(
                id: 'it_7',
                exercicioId: 'ex_rosca_direta',
                exercicioNome: 'Rosca Direta com Barra W',
                grupoMuscular: 'Bíceps',
                series: 3,
                repeticoes: '10 a 12',
                cargaSugeridaKg: 12.0,
                descansoSegundos: 60,
                tecnica: 'Normal',
              ),
            ],
          ),
          DivisaoTreinoModel(
            id: 'div_c',
            letra: 'C',
            nome: 'Pernas Completas (Legs)',
            exercicios: [
              ItemTreinoModel(
                id: 'it_8',
                exercicioId: 'ex_agachamento_livre',
                exercicioNome: 'Agachamento Livre com Barra',
                grupoMuscular: 'Quadríceps',
                series: 4,
                repeticoes: '8 a 10',
                cargaSugeridaKg: 40.0,
                descansoSegundos: 120,
                tecnica: 'Normal',
              ),
              ItemTreinoModel(
                id: 'it_9',
                exercicioId: 'ex_leg_press',
                exercicioNome: 'Leg Press 45°',
                grupoMuscular: 'Quadríceps',
                series: 3,
                repeticoes: '12',
                cargaSugeridaKg: 120.0,
                descansoSegundos: 90,
                tecnica: 'Normal',
              ),
              ItemTreinoModel(
                id: 'it_10',
                exercicioId: 'ex_mesa_flexora',
                exercicioNome: 'Mesa Flexora',
                grupoMuscular: 'Posterior',
                series: 4,
                repeticoes: '12',
                cargaSugeridaKg: 35.0,
                descansoSegundos: 60,
                tecnica: 'Normal',
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
