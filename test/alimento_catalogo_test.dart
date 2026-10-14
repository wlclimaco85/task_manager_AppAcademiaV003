import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/nutricao_farmaco_model.dart';
import 'package:task_manager_flutter/data/services/nutricao_farmaco_offline_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('catalogo traz mais de 100 alimentos com descricao e valores por 100 g', () async {
    final lista = await NutricaoFarmacoOfflineRepository().getAlimentos();

    expect(lista.length, greaterThanOrEqualTo(100));
    expect(lista.map((a) => a.id).toSet().length, lista.length, reason: 'ids unicos');
    for (final a in lista) {
      expect(a.descricao, startsWith('Porção caseira:'), reason: a.id);
      expect(a.descricao, contains('Valores por 100 g:'), reason: a.id);
      expect(a.porcaoPadraoGramas, 100, reason: a.id);
      expect(a.grupo, isNotNull, reason: a.id);
    }
  });

  test('valores do arroz e do ovo batem com a TACO', () async {
    final lista = await NutricaoFarmacoOfflineRepository().getAlimentos();
    AlimentoModel porId(String id) => lista.firstWhere((a) => a.id == id);

    final arroz = porId('alim_1');
    expect(arroz.calorias, 128);
    expect(arroz.carboidratos, 28.1);
    expect(arroz.descricao, contains('TACO'));

    final ovo = porId('alim_12');
    expect(ovo.calorias, 146);
    expect(ovo.proteinas, 13.3);
  });

  test('macros de uma porcao sao proporcionais aos 100 g', () async {
    final lista = await NutricaoFarmacoOfflineRepository().getAlimentos();
    final frango = lista.firstWhere((a) => a.id == 'alim_9');

    final item = ItemRefeicaoModel.calcular(alimento: frango, quantidadeGramas: 150);

    expect(item.calorias, closeTo(frango.calorias * 1.5, 0.1));
    expect(item.proteinas, closeTo(frango.proteinas * 1.5, 0.1));
  });

  test('busca encontra pelo grupo da TACO', () async {
    final lista = await NutricaoFarmacoOfflineRepository().getAlimentos(busca: 'nozes e sementes');

    expect(lista.any((a) => a.nome == 'Castanha-do-Pará'), isTrue);
  });

  test('aparelho com lista antiga recebe descricoes e novos alimentos', () async {
    const antigo = AlimentoModel(
      id: 'alim_12',
      nome: 'Ovo de Galinha Cozido (Unidade)',
      categoria: 'proteinas',
      porcaoPadraoGramas: 50,
      calorias: 72,
      proteinas: 6.3,
      carboidratos: 0.6,
      gorduras: 4.8,
    );
    const foraDoCatalogo = AlimentoModel(
      id: 'alim_meu_1',
      nome: 'Receita da casa',
      categoria: 'proteinas',
      calorias: 200,
      proteinas: 20,
      carboidratos: 5,
      gorduras: 10,
    );
    SharedPreferences.setMockInitialValues({
      'appacademia_alimentos_v1': json.encode([antigo.toMap(), foraDoCatalogo.toMap()]),
    });

    final lista = await NutricaoFarmacoOfflineRepository().getAlimentos();
    final ovo = lista.firstWhere((a) => a.id == 'alim_12');

    expect(lista.length, greaterThanOrEqualTo(100));
    expect(ovo.porcaoPadraoGramas, 100);
    expect(ovo.descricao, startsWith('Porção caseira:'));
    expect(lista.any((a) => a.id == 'alim_meu_1'), isTrue);
  });
}
