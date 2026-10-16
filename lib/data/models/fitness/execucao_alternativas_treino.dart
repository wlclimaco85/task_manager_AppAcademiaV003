import 'plano_treino_model.dart';
import 'sessao_treino_registro_model.dart';
import 'exercicio_model.dart';

/// Identifica a execução real sem alterar a prescrição da ficha.
class ExecucaoAlternativasTreino {
  final List<ItemTreinoModel> prescritos;
  final Map<int, ItemTreinoModel> selecionados = {};
  final Map<int, Map<int, ItemTreinoModel>> realizados = {};

  ExecucaoAlternativasTreino(this.prescritos);

  ItemTreinoModel atual(int indice) =>
      selecionados[indice] ?? prescritos[indice];

  void selecionar(int indice, ExercicioModel? alternativa) {
    final original = prescritos[indice];
    if (alternativa == null || alternativa.id == original.exercicioId) {
      selecionados.remove(indice);
      return;
    }
    if (!original.exerciciosAlternativos.contains(alternativa.nome)) {
      throw ArgumentError('Alternativa não cadastrada na ficha.');
    }
    selecionados[indice] = ItemTreinoModel(
      id: original.id,
      exercicioId: alternativa.id,
      exercicioNome: alternativa.nome,
      grupoMuscular: alternativa.grupoMuscular,
      videoUrl: alternativa.videoUrl,
      series: original.series,
      repeticoes: original.repeticoes,
      descansoSegundos: original.descansoSegundos,
      tecnica: original.tecnica,
      observacoes: original.observacoes,
      exerciciosAlternativos: original.exerciciosAlternativos,
      exercicioBiset: original.exercicioBiset,
    );
  }

  void marcarSerie(int indice, int serie, bool concluida) {
    final registro = realizados.putIfAbsent(indice, () => {});
    if (concluida) {
      registro[serie] = atual(indice);
    } else {
      registro.remove(serie);
    }
  }

  List<ExercicioExecutadoRegistroModel> historico(
      Map<int, List<SerieRegistroModel>> series) {
    final resultado = <ExercicioExecutadoRegistroModel>[];
    for (var i = 0; i < prescritos.length; i++) {
      final grupos = <String, List<SerieRegistroModel>>{};
      final exercicios = <String, ItemTreinoModel>{};
      for (var s = 0; s < (series[i]?.length ?? 0); s++) {
        final registro = series[i]![s];
        if (!registro.concluida) continue;
        final ex = realizados[i]?[s] ?? prescritos[i];
        exercicios[ex.exercicioId] = ex;
        grupos.putIfAbsent(ex.exercicioId, () => []).add(registro);
      }
      for (final id in grupos.keys) {
        final ex = exercicios[id]!;
        resultado.add(ExercicioExecutadoRegistroModel(
          exercicioId: id,
          exercicioNome: ex.exercicioNome,
          grupoMuscular: ex.grupoMuscular,
          series: grupos[id]!,
          observacaoAluno: id == prescritos[i].exercicioId
              ? null
              : 'Alternativa de ${prescritos[i].exercicioNome}',
        ));
      }
    }
    return resultado;
  }

  Map<String, dynamic> toMap() => {
        'prescricao': prescritos.map((e) => e.toMap()).toList(),
        'selecionados': {
          for (final e in selecionados.entries)
            e.key.toString(): e.value.toMap()
        },
        'realizados': {
          for (final e in realizados.entries)
            e.key.toString(): {
              for (final s in e.value.entries) s.key.toString(): s.value.toMap()
            }
        },
      };

  bool restaurar(Map<String, dynamic> map) {
    // Não associar índices de uma ficha antiga a uma prescrição alterada.
    final anterior = (map['prescricao'] as List?) ?? [];
    if (anterior.length != prescritos.length) return false;
    for (var i = 0; i < anterior.length; i++) {
      if (anterior[i]['id'] != prescritos[i].id ||
          anterior[i]['exercicioId'] != prescritos[i].exercicioId ||
          anterior[i]['series'] != prescritos[i].series) {
        return false;
      }
    }
    selecionados.clear();
    realizados.clear();
    for (final e
        in Map<String, dynamic>.from(map['selecionados'] ?? {}).entries) {
      selecionados[int.parse(e.key)] =
          ItemTreinoModel.fromMap(Map<String, dynamic>.from(e.value));
    }
    for (final e
        in Map<String, dynamic>.from(map['realizados'] ?? {}).entries) {
      realizados[int.parse(e.key)] = {
        for (final s in Map<String, dynamic>.from(e.value).entries)
          int.parse(s.key):
              ItemTreinoModel.fromMap(Map<String, dynamic>.from(s.value))
      };
    }
    return true;
  }
}
