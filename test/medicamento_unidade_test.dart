import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/models/fitness/nutricao_farmaco_model.dart';
import 'package:task_manager_flutter/data/services/unidade_medida_catalogo.dart';

MedicamentoProtocoloModel _medicamento({double? quantidade = 2, String? unidade = 'ML'}) =>
    MedicamentoProtocoloModel(
      id: 'med_1',
      alunoId: 'aluno_1',
      nomeComposto: 'Enantato de Testosterona',
      dosagem: '2 ML',
      doseQuantidade: quantidade,
      doseUnidade: unidade,
      frequencia: '1x por semana',
      categoria: 'ergogenico_ciclo',
      dataInicio: '2026-10-01',
    );

void main() {
  group('quantidade e unidade do medicamento', () {
    test('quantidade e unidade sobrevivem ao salvar e ler (toMap/fromMap)', () {
      final lido = MedicamentoProtocoloModel.fromMap(_medicamento().toMap());

      expect(lido.doseQuantidade, 2);
      expect(lido.doseUnidade, 'ML');
      expect(lido.dosagem, '2 ML');
    });

    test('registro antigo, sem quantidade/unidade, continua valido', () {
      final antigo = Map<String, dynamic>.from(_medicamento().toMap())
        ..remove('doseQuantidade')
        ..remove('doseUnidade')
        ..['dosagem'] = '250mg';

      final lido = MedicamentoProtocoloModel.fromMap(antigo);

      expect(lido.doseQuantidade, isNull);
      expect(lido.doseUnidade, isNull);
      expect(lido.dosagem, '250mg');
    });
  });

  group('edicao e finalizacao sem excluir', () {
    test('finalizar uso marca fim e inativa, mantendo id e inicio', () {
      final finalizado = _medicamento().copyWith(ativo: false, dataFim: '2026-10-16');

      expect(finalizado.id, 'med_1');
      expect(finalizado.dataInicio, '2026-10-01');
      expect(finalizado.dataFim, '2026-10-16');
      expect(finalizado.ativo, isFalse);
    });

    test('reabrir uso limpa a data de fim pelo save com ativo', () {
      final finalizado = _medicamento().copyWith(ativo: false, dataFim: '2026-10-16');

      final reaberto = finalizado.copyWith(ativo: true, dataFim: null);

      expect(reaberto.ativo, isTrue);
    });

    test('inicio pode ser corrigido retroativamente', () {
      final corrigido = _medicamento().copyWith(dataInicio: '2026-06-03');

      expect(corrigido.dataInicio, '2026-06-03');
      expect(corrigido.id, 'med_1');
    });
  });

  group('catalogo de unidades (cadastro do backend)', () {
    test('extrai simbolos em maiusculo, sem duplicados', () {
      final corpo = {
        'data': {
          'dados': [
            {'simbolo': 'ml'},
            {'simbolo': 'UI'},
            {'simbolo': 'ML'},
            {'simbolo': ' comp '},
          ],
        },
      };

      expect(UnidadeMedidaCatalogo.simbolosDaResposta(corpo), ['ML', 'UI', 'COMP']);
    });

    test('aceita o corpo como texto JSON', () {
      const corpo = '{"data":{"dados":[{"simbolo":"UI"}]}}';

      expect(UnidadeMedidaCatalogo.simbolosDaResposta(corpo), ['UI']);
    });

    test('resposta fora do formato devolve lista vazia, sem lancar erro', () {
      expect(UnidadeMedidaCatalogo.simbolosDaResposta({'erro': true}), isEmpty);
      expect(UnidadeMedidaCatalogo.simbolosDaResposta(null), isEmpty);
    });

    test('unidades padrao de anabolizante', () {
      expect(UnidadeMedidaCatalogo.unidadesPadrao, ['ML', 'UI', 'COMP']);
    });
  });
}
