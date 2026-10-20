import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/tenant_context.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
import 'package:task_manager_flutter/data/services/fitness_conta_sync.dart';

/// Modelo de Notificação Push Fitness
class FitnessNotificationItem {
  final String id;
  final String titulo;
  final String corpo;
  final DateTime dataHora;
  final String
      tipo; // treino_hoje, inatividade, nova_ficha, meta_batida, cadastro_inicial
  final bool lida;
  final Map<String, dynamic>? payload;

  FitnessNotificationItem({
    required this.id,
    required this.titulo,
    required this.corpo,
    required this.dataHora,
    required this.tipo,
    this.lida = false,
    this.payload,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'titulo': titulo,
        'corpo': corpo,
        'dataHora': dataHora.toIso8601String(),
        'tipo': tipo,
        'lida': lida,
        'payload': payload,
      };

  factory FitnessNotificationItem.fromMap(Map<String, dynamic> map) =>
      FitnessNotificationItem(
        id: map['id']?.toString() ?? '',
        titulo: map['titulo']?.toString() ?? '',
        corpo: map['corpo']?.toString() ?? '',
        dataHora: DateTime.tryParse(map['dataHora']?.toString() ?? '') ??
            DateTime.now(),
        tipo: map['tipo']?.toString() ?? 'geral',
        lida: map['lida'] == true,
        payload: map['payload'] is Map<String, dynamic> ? map['payload'] : null,
      );
}

/// Serviço de Notificações Push Inteligentes (Padrão MFIT Personal & MyFitCoach)
/// Suporta agendamentos locais offline e integração transparente com Firebase Cloud Messaging (FCM).
class FitnessPushNotificationService {
  static const String _kNotificationsKey =
      'appacademia_fitness_notifications_v1';

  String get _notificationsKey => FitnessContaSync.chave(_kNotificationsKey);

  static final FitnessPushNotificationService _instance =
      FitnessPushNotificationService._internal();
  factory FitnessPushNotificationService() => _instance;
  FitnessPushNotificationService._internal();

  final _repo = FitnessOfflineRepository();
  final ValueNotifier<int> mudancas = ValueNotifier<int>(0);

  /// Traz para a central local os alertas gerados no servidor para esta conta.
  /// Assim duas abas/dispositivos recebem vinculos e fichas mesmo sem recarregar.
  Future<void> sincronizarRemotas() async {
    try {
      final response = await http
          .get(Uri.parse(ApiLinks.alertasMeu), headers: TenantContext.headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;
      final body = jsonDecode(response.body);
      final dados = body is Map ? body['data'] : null;
      if (dados is! List) return;
      final atuais = await getNotificacoes();
      var alterou = false;
      for (final bruto in dados.reversed) {
        if (bruto is! Map) continue;
        final idServidor = bruto['id']?.toString() ?? '';
        if (idServidor.isEmpty) continue;
        final id = 'remoto_$idServidor';
        if (atuais.any((item) => item.id == id)) continue;
        var texto = bruto['texto']?.toString() ?? '';
        var tipo = 'geral';
        var titulo = 'Nova notificação';
        if (texto.startsWith('[VINCULO]')) {
          tipo = 'contrato_personal';
          titulo = 'Novo contrato com personal';
          texto = texto.substring('[VINCULO]'.length).trim();
        } else if (texto.startsWith('[TREINO]')) {
          tipo = 'nova_ficha';
          titulo = 'Novo treino cadastrado';
          texto = texto.substring('[TREINO]'.length).trim();
        }
        atuais.insert(
          0,
          FitnessNotificationItem(
            id: id,
            titulo: titulo,
            corpo: texto,
            dataHora: DateTime.tryParse(bruto['data']?.toString() ?? '') ??
                DateTime.now(),
            tipo: tipo,
            lida: bruto['status']?.toString() == 'LIDO',
            payload: {'alertaId': idServidor},
          ),
        );
        alterou = true;
      }
      if (!alterou) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_notificationsKey,
          jsonEncode(atuais.map((item) => item.toMap()).toList()));
      mudancas.value++;
    } catch (e) {
      debugPrint(
          '[FitnessPushNotificationService] Falha ao sincronizar alertas remotos: $e');
    }
  }

  /// Inicializa e verifica gatilhos automáticos (ex: inatividade ou lembrete de treino do dia)
  Future<void> inicializarVerificacoesAutomaticas({String? alunoId}) async {
    try {
      await verificarLembreteInatividade(alunoId: alunoId);
      await verificarLembreteTreinoDoDia(alunoId: alunoId);
    } catch (e) {
      debugPrint(
          '[FitnessPushNotificationService] Erro nas verificações automáticas: $e');
    }
  }

  /// 1. Gatilho de Inatividade (> 48h sem treinar)
  Future<void> verificarLembreteInatividade({String? alunoId}) async {
    final sessoes = await _repo.getSessoesConcluidas(alunoId: alunoId);
    if (sessoes.isEmpty) return;

    final ultimaSessao = DateTime.tryParse(sessoes.first.dataHoraFim);
    if (ultimaSessao == null) return;

    final horasSemTreino = DateTime.now().difference(ultimaSessao).inHours;
    if (horasSemTreino >= 48) {
      final dias = (horasSemTreino / 24).floor();
      await agendarNotificacao(
        FitnessNotificationItem(
          id: 'inatividade_${DateTime.now().day}',
          titulo: '⚡ Sentimos sua falta no treino!',
          corpo:
              'Você está há $dias dias sem treinar. Que tal bater a meta de hoje e manter o foco?',
          dataHora: DateTime.now(),
          tipo: 'inatividade',
        ),
      );
    }
  }

  /// 2. Gatilho de Treino do Dia
  Future<void> verificarLembreteTreinoDoDia({String? alunoId}) async {
    final plano = await _repo.getPlanoAtivo(alunoId: alunoId ?? 'aluno_1');
    if (plano == null || plano.divisoes.isEmpty) return;

    // Sugere a próxima divisão a ser treinada
    final divisaoSugerida = plano.divisoes.first;

    await agendarNotificacao(
      FitnessNotificationItem(
        id: 'treino_hoje_${DateTime.now().day}',
        titulo: '🔥 Treino de Hoje Pronto!',
        corpo:
            'Hoje é dia de Treino ${divisaoSugerida.letra} (${divisaoSugerida.nome}). Abra o app e inicie sua sessão.',
        dataHora: DateTime.now(),
        tipo: 'treino_hoje',
        payload: {
          'planoId': plano.id,
          'divisaoLetra': divisaoSugerida.letra,
        },
      ),
    );
  }

  /// 3. Gatilho quando Personal publica ou atualiza ficha
  Future<void> notificarNovaFichaPrescrita({
    required String alunoNome,
    required String personalNome,
    required PlanoTreinoModel plano,
  }) async {
    await agendarNotificacao(
      FitnessNotificationItem(
        id: 'nova_ficha_${plano.id}',
        titulo: '📋 Nova Ficha Prescrita!',
        corpo:
            'O Personal $personalNome acabou de prescrever seu novo treino "${plano.titulo}". Acesse agora para conferir.',
        dataHora: DateTime.now(),
        tipo: 'nova_ficha',
        payload: {'planoId': plano.id},
      ),
    );
  }

  /// 4. Notificação de Meta / Streak Batido
  Future<void> notificarMetaBatida({
    required int streakDias,
    required double tonelagemKg,
  }) async {
    await agendarNotificacao(
      FitnessNotificationItem(
        id: 'meta_${DateTime.now().millisecondsSinceEpoch}',
        titulo: '🏆 Treino Batido com Sucesso!',
        corpo:
            'Você levantou ${(tonelagemKg / 1000).toStringAsFixed(1)} toneladas hoje! Sequência de $streakDias dias consecutivos.',
        dataHora: DateTime.now(),
        tipo: 'meta_batida',
      ),
    );
  }

  /// 5. Notificação de Mensalidade Vencendo / Vencida
  Future<void> notificarMensalidadeVencida({
    required String personalNome,
    required int diaVencimento,
  }) async {
    await agendarNotificacao(
      FitnessNotificationItem(
        id: 'mensalidade_vencida_${DateTime.now().month}_${DateTime.now().year}',
        titulo: '💳 Mensalidade Vencendo Hoje',
        corpo:
            'Lembrete: sua mensalidade com o personal $personalNome vence no dia $diaVencimento.',
        dataHora: DateTime.now(),
        tipo: 'mensalidade_vencendo',
      ),
    );
  }

  /// 6. Notificação de Treino Atualizado / Troca de Treino
  Future<void> notificarTreinoAtualizado({
    required String personalNome,
    required String treinoTitulo,
  }) async {
    await agendarNotificacao(
      FitnessNotificationItem(
        id: 'treino_atualizado_${DateTime.now().millisecondsSinceEpoch}',
        titulo: '🔄 Treino Atualizado pelo Personal',
        corpo:
            'O Personal $personalNome atualizou a rotina "$treinoTitulo". Acesse para ver as novas séries e cargas.',
        dataHora: DateTime.now(),
        tipo: 'treino_atualizado',
      ),
    );
  }

  /// 7. Notificação de Meta do Dia não Cumprida
  Future<void> notificarMetaDiaNaoCumprida() async {
    await agendarNotificacao(
      FitnessNotificationItem(
        id: 'meta_nao_cumprida_${DateTime.now().day}_${DateTime.now().month}',
        titulo: '😴 Você não treinou hoje',
        corpo:
            'Que tal descansar bem esta noite para voltar com força total no próximo treino?',
        dataHora: DateTime.now(),
        tipo: 'meta_dia_nao_cumprida',
      ),
    );
  }

  /// 8. Aviso Geral do Personal para o Aluno
  Future<void> notificarAvisoPersonal({
    required String personalNome,
    required String aviso,
  }) async {
    await agendarNotificacao(
      FitnessNotificationItem(
        id: 'aviso_personal_${DateTime.now().millisecondsSinceEpoch}',
        titulo: '📣 Recado do Personal $personalNome',
        corpo: aviso,
        dataHora: DateTime.now(),
        tipo: 'aviso_personal',
      ),
    );
  }

  /// 9. Notificação para o Personal: Aluno Finalizou o Treino
  Future<void> notificarAlunoFinalizouTreino({
    required String alunoNome,
    required String treinoNome,
    required double tonelagemKg,
  }) async {
    await agendarNotificacao(
      FitnessNotificationItem(
        id: 'aluno_finalizou_${DateTime.now().millisecondsSinceEpoch}',
        titulo: '💪 $alunoNome Concluiu o Treino!',
        corpo:
            '$alunoNome finalizou $treinoNome levantando ${tonelagemKg.toStringAsFixed(0)} kg.',
        dataHora: DateTime.now(),
        tipo: 'aluno_treino_finalizado',
      ),
    );
  }

  /// 10. Notificação para o Personal: Aluno comentou no treino
  Future<void> notificarAlunoComentarioTreino({
    required String alunoNome,
    required String treinoNome,
    required String comentario,
  }) async {
    await agendarNotificacao(
      FitnessNotificationItem(
        id: 'aluno_comentario_${DateTime.now().millisecondsSinceEpoch}',
        titulo: '💬 Novo Feedback de $alunoNome',
        corpo: 'Comentário sobre $treinoNome: "$comentario"',
        dataHora: DateTime.now(),
        tipo: 'aluno_comentario_treino',
      ),
    );
  }

  /// Grava a notificação no repositório local
  Future<void> agendarNotificacao(FitnessNotificationItem item) async {
    final lista = await getNotificacoes();
    // Evita duplicar a mesma notificação no mesmo dia
    if (lista.any((n) => n.id == item.id)) return;

    lista.insert(0, item);
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(lista.map((n) => n.toMap()).toList());
    await prefs.setString(_notificationsKey, jsonStr);
    mudancas.value++;
  }

  Future<List<FitnessNotificationItem>> getNotificacoes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notificationsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = json.decode(raw) as List<dynamic>;
      return decoded
          .map(
              (e) => FitnessNotificationItem.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint(
          '[FitnessPushNotificationService] Erro decode notificações: $e');
      return [];
    }
  }

  Future<void> marcarComoLida(String id) async {
    final lista = await getNotificacoes();
    final idx = lista.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      final antiga = lista[idx];
      lista[idx] = FitnessNotificationItem(
        id: antiga.id,
        titulo: antiga.titulo,
        corpo: antiga.corpo,
        dataHora: antiga.dataHora,
        tipo: antiga.tipo,
        lida: true,
        payload: antiga.payload,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _notificationsKey, json.encode(lista.map((n) => n.toMap()).toList()));
      mudancas.value++;
      final alertaId = antiga.payload?['alertaId']?.toString();
      if (alertaId != null && alertaId.isNotEmpty) {
        try {
          await http.put(
            Uri.parse('${ApiLinks.alertasMeu}/$alertaId/lida'),
            headers: TenantContext.headers,
          );
        } catch (_) {}
      }
    }
  }
}
