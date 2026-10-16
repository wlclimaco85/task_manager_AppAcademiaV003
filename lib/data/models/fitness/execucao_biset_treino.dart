import 'plano_treino_model.dart';
import 'sessao_treino_registro_model.dart';

/// Mantém registros independentes, alternando A1/B1, A2/B2 no bi-set.
class ExecucaoBisetTreino {
  final List<ItemTreinoModel> exercicios = [];
  final Map<int, int> parceiros = {};
  final Set<int> segundos = {};

  ExecucaoBisetTreino(List<ItemTreinoModel> prescritos) {
    for (final item in prescritos) {
      final indice = exercicios.length;
      exercicios.add(item);
      final segundo = item.exercicioBiset;
      if (segundo != null) {
        exercicios.add(segundo);
        parceiros[indice] = indice + 1;
        parceiros[indice + 1] = indice;
        segundos.add(indice + 1);
      }
    }
  }

  ({int indice, int serie})? proximaSerie(
      int indice, Map<int, List<SerieRegistroModel>> registros) {
    final parceiro = parceiros[indice];
    if (parceiro == null) return null;
    final primeiro = segundos.contains(indice) ? parceiro : indice;
    final segundo = primeiro + 1;
    final a = registros[primeiro] ?? [];
    final b = registros[segundo] ?? [];
    final quantidade = a.length > b.length ? a.length : b.length;
    for (var serie = 0; serie < quantidade; serie++) {
      if (serie < a.length && !a[serie].concluida) {
        return (indice: primeiro, serie: serie);
      }
      if (serie < b.length && !b[serie].concluida) {
        return (indice: segundo, serie: serie);
      }
    }
    return null;
  }
}
