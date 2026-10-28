import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/models/fitness/nutricao_farmaco_model.dart';

void main() {
  const dieta = DietaProtocoloModel(
    id: 'dieta_1',
    alunoId: 'aluno_1',
    titulo: 'Dieta QA',
    objetivo: 'manutencao',
    caloriasMeta: 0,
    proteinasMeta: 0,
    carboidratosMeta: 0,
    gordurasMeta: 0,
    dataInicio: '2026-10-28',
    refeicoes: [
      RefeicaoModel(
        id: 'cafe',
        nome: 'Café',
        horario: '07:00',
        itens: [
          ItemRefeicaoModel(
            alimentoId: 'aveia',
            alimentoNome: 'Aveia',
            quantidadeGramas: 40,
            calorias: 0,
            proteinas: 0,
            carboidratos: 0,
            gorduras: 0,
          ),
        ],
      ),
      RefeicaoModel(
        id: 'jantar',
        nome: 'Jantar',
        horario: '19:00',
        itens: [
          ItemRefeicaoModel(
            alimentoId: 'frango',
            alimentoNome: 'Frango',
            quantidadeGramas: 150,
            calorias: 0,
            proteinas: 0,
            carboidratos: 0,
            gorduras: 0,
          ),
          ItemRefeicaoModel(
            alimentoId: 'aveia',
            alimentoNome: 'Aveia',
            quantidadeGramas: 20,
            calorias: 0,
            proteinas: 0,
            carboidratos: 0,
            gorduras: 0,
          ),
        ],
      ),
    ],
  );

  test('consolida alimentos repetidos e multiplica pelo período', () {
    final lista = dieta.gerarListaCompras(14);

    expect(lista.map((item) => item.alimentoNome), ['Aveia', 'Frango']);
    expect(lista[0].quantidadeDiariaGramas, 60);
    expect(lista[0].quantidadeTotalGramas, 840);
    expect(lista[1].quantidadeDiariaGramas, 150);
    expect(lista[1].quantidadeTotalGramas, 2100);
  });

  test('rejeita período sem dias', () {
    expect(() => dieta.gerarListaCompras(0), throwsArgumentError);
  });
}
