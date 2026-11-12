import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/dashboard_fitness_model.dart';
import 'package:task_manager_flutter/ui/screens/fitness/dashboard_fitness_screen.dart';

Map<String, dynamic> _respostaPersonal() => {
      'mes': '2026-11',
      'resumo': {
        'totalAlunos': 3,
        'ativosUltimos30Dias': 2,
        'semFicha': 1,
        'proximosTrocaFicha': 1,
        'evoluindo': 1,
        'frequenciaMediaPct': 46.7,
      },
      'semFicha': [
        {'alunoId': 1, 'nome': 'Ana Sem Ficha'},
      ],
      'proximosTrocaFicha': [
        {'alunoId': 2, 'nome': 'Bruno Vence', 'treino': 'Hipertrofia A', 'vencimento': '2026-11-10', 'diasRestantes': 3},
      ],
      'evoluindo': [
        {'alunoId': 2, 'nome': 'Bruno Vence', 'cargaAnteriorKg': 50.0, 'cargaAtualKg': 60.0, 'variacaoPct': 20.0},
      ],
      'rankingMes': [
        {'posicao': 1, 'alunoId': 2, 'nome': 'Bruno Vence', 'treinosNoMes': 6, 'frequenciaContratada': 3, 'percentual': 46.7},
      ],
      'melhorDesempenho': [
        {'alunoId': 2, 'nome': 'Bruno Vence', 'treinosNoMes': 6, 'percentual': 46.7},
      ],
      'frequencia': [
        {'alunoId': 2, 'nome': 'Bruno Vence', 'treinosNoMes': 6, 'frequenciaContratada': 3, 'percentual': 46.7},
      ],
    };

void main() {
  // Este arquivo cobre o layout clássico; o layout novo tem testes proprios.
  setUp(() => SharedPreferences.setMockInitialValues({'dashboard_layout_v1': 'classico'}));

  test('modelo lê indicadores e listas da resposta do backend', () {
    final modelo = DashboardFitnessModel.fromJson(_respostaPersonal());

    expect(modelo.mes, '2026-11');
    expect(modelo.resumo.ativosUltimos30Dias, 2);
    expect(modelo.resumo.frequenciaMediaPct, 46.7);
    expect(modelo.semFicha.single.nome, 'Ana Sem Ficha');
    expect(modelo.proximosTrocaFicha.single.diasRestantes, 3);
    expect(modelo.evoluindo.single.variacaoPct, 20.0);
    expect(modelo.rankingMes.single.posicao, 1);
  });

  test('modelo tolera resposta vazia sem quebrar', () {
    final modelo = DashboardFitnessModel.fromJson(const {});

    expect(modelo.resumo.totalAlunos, 0);
    expect(modelo.resumo.frequenciaMediaPct, isNull);
    expect(modelo.rankingMes, isEmpty);
  });

  testWidgets('mostra indicadores e listas do dashboard do personal', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DashboardFitnessScreen(
        academia: false,
        carregar: (academia, mes) async => DashboardFitnessModel.fromJson(_respostaPersonal()),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard do personal'), findsOneWidget);
    expect(find.text('Ana Sem Ficha'), findsOneWidget);
    expect(find.text('Bruno Vence'), findsWidgets);
    expect(find.text('46.7%'), findsWidgets);
    expect(find.textContaining('vence 10/11/2026'), findsOneWidget);
  });

  testWidgets('mostra erro com botao de tentar novamente quando a leitura falha', (tester) async {
    var chamadas = 0;
    await tester.pumpWidget(MaterialApp(
      home: DashboardFitnessScreen(
        academia: true,
        carregar: (academia, mes) async {
          chamadas++;
          // Falha assincrona, como a rede: o FutureBuilder ja esta ouvindo quando o erro chega.
          await Future<void>.delayed(Duration.zero);
          throw Exception('Sem permissão para ver o dashboard.');
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard da academia'), findsOneWidget);
    expect(find.text('Sem permissão para ver o dashboard.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(chamadas, 2);
  });
}
