import '../models/fitness/nutricao_farmaco_model.dart';
import 'importacao_dieta_parser.dart';

String normalizarNomeAlimento(String nome) {
  const com = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const sem = 'aaaaaeeeeiiiiooooouuuuc';
  var s = nome.toLowerCase().trim();
  for (var i = 0; i < com.length; i++) {
    s = s.replaceAll(com[i], sem[i]);
  }
  return s.replaceAll(RegExp(r'\s+'), ' ');
}

class ItemImportacaoDieta {
  final LinhaImportacaoDieta linha;
  AlimentoModel? alimento;
  bool incluir = true;
  final List<String> avisos;
  ItemImportacaoDieta(this.linha, {this.alimento, List<String>? avisos})
      : avisos = [...linha.avisos, ...?avisos];
}

class ImportacaoDietaPreparacao {
  final List<ItemImportacaoDieta> itens = [];
  final List<AlimentoModel> novos = [];
  ImportacaoDietaPreparacao(
      ResultadoImportacaoDieta resultado, List<AlimentoModel> catalogo) {
    final porNome = <String, List<AlimentoModel>>{};
    for (final a in catalogo) {
      (porNome[normalizarNomeAlimento(a.nome)] ??= []).add(a);
    }
    for (final l in resultado.linhas) {
      final encontrados = porNome[normalizarNomeAlimento(l.alimento)] ?? [];
      final item = ItemImportacaoDieta(l);
      if (encontrados.length == 1) {
        item.alimento = encontrados.single;
        final a = encontrados.single;
        if ((l.calorias != null &&
                (l.calorias! - a.calorias * 100 / a.porcaoPadraoGramas).abs() >
                    .1) ||
            (l.proteinas != null &&
                (l.proteinas! - a.proteinas * 100 / a.porcaoPadraoGramas)
                        .abs() >
                    .1) ||
            (l.carboidratos != null &&
                (l.carboidratos! - a.carboidratos * 100 / a.porcaoPadraoGramas)
                        .abs() >
                    .1) ||
            (l.gorduras != null &&
                (l.gorduras! - a.gorduras * 100 / a.porcaoPadraoGramas).abs() >
                    .1)) {
          item.avisos.add(
              'Valores diferentes do catálogo. Confira a correspondência antes de importar.');
        }
      } else if (encontrados.isEmpty &&
          l.temMacrosCompletos &&
          l.fibras != null) {
        final novo = criarAlimento(l);
        item.alimento = novo;
        novos.add(novo);
        porNome[normalizarNomeAlimento(novo.nome)] = [novo];
      } else {
        item.avisos.add(encontrados.length > 1
            ? 'Há mais de um alimento com esse nome. Escolha o correto.'
            : 'Alimento novo: informe os nutrientes por 100 g ou escolha um do catálogo.');
      }
      itens.add(item);
    }
  }

  static AlimentoModel criarAlimento(LinhaImportacaoDieta l) => AlimentoModel(
        id: 'alim_import_${DateTime.now().microsecondsSinceEpoch}',
        nome: l.alimento,
        categoria: 'geral',
        porcaoPadraoGramas: 100,
        calorias: l.calorias!,
        proteinas: l.proteinas!,
        carboidratos: l.carboidratos!,
        gorduras: l.gorduras!,
        fibras: l.fibras!,
        descricao: 'Cadastrado por importação. Valores fornecidos por 100 g.',
      );

  List<AlimentoModel> get novosUtilizados {
    final ids =
        itens.where((i) => i.incluir).map((i) => i.alimento?.id).toSet();
    return novos.where((a) => ids.contains(a.id)).toList();
  }

  List<RefeicaoModel> gerarRefeicoes() {
    final selecionados = itens.where((i) => i.incluir).toList();
    if (selecionados.isEmpty)
      throw StateError('Selecione pelo menos uma linha.');
    if (selecionados.any((i) => i.alimento == null)) {
      throw StateError('Resolva os alimentos pendentes antes de importar.');
    }
    final grupos = <String, List<ItemImportacaoDieta>>{};
    for (final i in selecionados) {
      (grupos['${i.linha.refeicao}\n${i.linha.horario}'] ??= []).add(i);
    }
    var numero = 0;
    final prefixo = DateTime.now().microsecondsSinceEpoch;
    return grupos.values
        .map((g) => RefeicaoModel(
              id: 'ref_import_${prefixo}_${numero++}',
              nome: g.first.linha.refeicao,
              horario: g.first.linha.horario,
              itens: g
                  .map((i) => ItemRefeicaoModel.calcular(
                        alimento: i.alimento!,
                        quantidadeGramas: i.linha.quantidadeGramas,
                      ))
                  .toList(),
            ))
        .toList();
  }
}
