import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/ui/screens/fitness/avaliacao_fisica_pro_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('avaliacao propria (sem aluno) abre o formulario normalmente', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: AvaliacaoFisicaProScreen()));
    await tester.pump();

    expect(find.textContaining('não liberou'), findsNothing);
    expect(find.text('Salvar e Gerar Relatório de Evolução'), findsOneWidget);
  });

  testWidgets('avaliacao de aluno sem resposta de permissao fica bloqueada', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(
      home: AvaliacaoFisicaProScreen(alunoNome: 'Ana', alunoId: '7'),
    ));
    // A consulta de permissao falha offline e cai no padrao restritivo.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();

    expect(find.textContaining('não liberou avaliações físicas'), findsOneWidget);
    expect(find.text('Salvar e Gerar Relatório de Evolução'), findsNothing);
  });
}
