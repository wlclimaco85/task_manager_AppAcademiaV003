import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/models/fitness/nutricao_farmaco_model.dart';
import 'package:task_manager_flutter/data/services/importacao_dieta_parser.dart';
import 'package:task_manager_flutter/data/services/importacao_dieta_preparacao.dart';

const conhecido = AlimentoModel(
    id: 'existente',
    nome: 'Maçã',
    categoria: 'frutas',
    calorias: 60,
    proteinas: 1,
    carboidratos: 14,
    gorduras: 0,
    fibras: 2);
LinhaImportacaoDieta linha(String nome,
        {bool macros = false, String horario = '08:00'}) =>
    LinhaImportacaoDieta(
        numeroLinha: 2,
        refeicao: 'Café da manhã',
        horario: horario,
        alimento: nome,
        quantidadeGramas: 50,
        calorias: macros ? 100 : null,
        proteinas: macros ? 5 : null,
        carboidratos: macros ? 15 : null,
        gorduras: macros ? 2 : null,
        fibras: macros ? 1 : null);
void main() {
  test('reutiliza nome exato normalizado e calcula macros da quantidade', () {
    final p = ImportacaoDietaPreparacao(
        ResultadoImportacaoDieta([linha('  MACA  ')], []), [conhecido]);
    expect(p.novos, isEmpty);
    expect(p.itens.single.alimento!.id, 'existente');
    final r = p.gerarRefeicoes().single;
    expect(r.itens.single.calorias, 30);
    expect(r.itens.single.quantidadeGramas, 50);
  });
  test(
      'nome parecido não vira correspondência inventada e não cria macros ausentes',
      () {
    final p = ImportacaoDietaPreparacao(
        ResultadoImportacaoDieta([linha('Maçã com recheio')], []), [conhecido]);
    expect(p.itens.single.alimento, isNull);
    expect(p.novos, isEmpty);
    expect(p.gerarRefeicoes, throwsStateError);
  });
  test(
      'repetições do alimento novo usam um cadastro e refeições agrupadas por horário',
      () {
    final p = ImportacaoDietaPreparacao(
        ResultadoImportacaoDieta([
          linha('Receita própria', macros: true),
          linha('RECEITA PRÓPRIA', macros: true),
          linha('Receita própria', macros: true, horario: '15:00'),
        ], []),
        []);
    expect(p.novos.length, 1);
    expect(p.novosUtilizados.length, 1);
    expect(p.gerarRefeicoes().length, 2);
    expect(p.gerarRefeicoes().first.itens.length, 2);
    for (final i in p.itens) {
      i.incluir = false;
    }
    expect(p.novosUtilizados, isEmpty);
    expect(p.gerarRefeicoes, throwsStateError);
  });
  test('ambiguidade de cadastro exige escolha e diferenças nutricionais avisam',
      () {
    final p = ImportacaoDietaPreparacao(
        ResultadoImportacaoDieta([linha('Maçã')], []), [
      conhecido,
      AlimentoModel.fromMap({...conhecido.toMap(), 'id': 'outro'})
    ]);
    expect(p.itens.single.alimento, isNull);
    final diferente = ImportacaoDietaPreparacao(
        ResultadoImportacaoDieta([linha('Maçã', macros: true)], []),
        [conhecido]);
    expect(diferente.itens.single.avisos, isNotEmpty);
    expect(diferente.itens.single.alimento!.calorias, 60);
  });
}
