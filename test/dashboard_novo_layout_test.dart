import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/dashboard_aluno_model.dart';
import 'package:task_manager_flutter/data/models/fitness/dashboard_fitness_model.dart';
import 'package:task_manager_flutter/data/services/dashboard_layout_preferencia.dart';
import 'package:task_manager_flutter/ui/screens/fitness/dashboard_aluno_screen.dart';
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

DashboardAlunoModel _modeloAluno() => DashboardAlunoModel.fromJson({
      'mes': '2026-11',
      'treinosNoMes': 4,
      'diasTreinadosNoMes': 3,
      'treinosUltimos7Dias': 2,
      'ultimoTreino': '2026-11-09',
      'diasSemTreinar': 1,
      'treinosPorDia': [
        {'dia': 1, 'treinos': 0},
        {'dia': 2, 'treinos': 1},
        {'dia': 3, 'treinos': 2},
      ],
      'ficha': {'titulo': 'Hipertrofia A', 'dataValidade': '2026-11-15', 'diasParaVencer': 5},
      'evolucaoCargas': [
        {'exercicio': 'Supino Reto', 'cargaAnteriorKg': 40.0, 'cargaAtualKg': 45.0, 'variacaoPct': 12.5},
      ],
    });

Future<void> _pumpLargura(WidgetTester tester, Widget tela) async {
  // Largura de celular (sem estourar); altura alta para o ListView construir todos os cartoes.
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: tela));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('personal ve alunos vinculados e ranking no layout novo', (tester) async {
    await _pumpLargura(
      tester,
      DashboardFitnessScreen(
        academia: false,
        carregar: (academia, mes) async => DashboardFitnessModel.fromJson(_respostaPersonal()),
      ),
    );

    expect(find.text('Alunos vinculados'), findsOneWidget);
    expect(find.text('Ranking do mês'), findsOneWidget);
    expect(find.text('Matriculados'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('academia ve matriculados e melhor desempenho (indicadores diferentes do personal)', (tester) async {
    await _pumpLargura(
      tester,
      DashboardFitnessScreen(
        academia: true,
        carregar: (academia, mes) async => DashboardFitnessModel.fromJson(_respostaPersonal()),
      ),
    );

    expect(find.text('Matriculados'), findsOneWidget);
    expect(find.text('Melhor desempenho do mês'), findsOneWidget);
    expect(find.text('Alunos vinculados'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('aluno ve treinos, ficha e evolucao de carga no layout novo', (tester) async {
    await _pumpLargura(tester, DashboardAlunoScreen(carregar: (mes) async => _modeloAluno()));

    expect(find.text('Treinos no mês'), findsOneWidget);
    expect(find.text('Minha ficha'), findsOneWidget);
    expect(find.text('Hipertrofia A'), findsOneWidget);
    expect(find.text('Supino Reto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('aluno pode trocar para o layout classico e a escolha fica salva', (tester) async {
    await _pumpLargura(tester, DashboardAlunoScreen(carregar: (mes) async => _modeloAluno()));

    await tester.tap(find.byType(PopupMenuButton<DashboardLayout>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Layout clássico'));
    await tester.pumpAndSettle();

    expect(find.text('Minha ficha'), findsOneWidget);
    expect(find.text('Evolução de carga (30 dias)'), findsOneWidget);
    final salvo = await tester.runAsync(DashboardLayoutPreferencia.carregar);
    expect(salvo, DashboardLayout.classico);
  });

  test('layout padrao e o novo quando nada foi escolhido', () async {
    expect(await DashboardLayoutPreferencia.carregar(), DashboardLayout.novo);
  });
}
