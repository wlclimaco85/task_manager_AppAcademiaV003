import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/ui/widgets/permissoes_personal_dialog.dart';

void main() {
  Future<void> abrir(WidgetTester tester, Map<String, bool> inicial) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PermissoesPersonalDialog(
          nomePersonal: 'Personal QA',
          inicial: inicial,
          contrato: const {
            'planoNome': 'Mensal 2x/semana',
            'valorMensalidade': 500,
            'diaVencimento': 10,
            'academiaNome': 'Biotech Prime',
            'diaSemana': 1,
            'horarioInicio': '08:00',
            'horarioFim': '09:00',
            'termos': 'Termos do acompanhamento',
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('treino aparece sempre ligado e travado', (tester) async {
    await abrir(tester, const {});

    final treino = tester
        .widget<SwitchListTile>(find.byKey(const Key('permissao_treino')));
    expect(treino.value, isTrue);
    expect(treino.onChanged, isNull, reason: 'treino nao pode ser desligado');
  });

  testWidgets('demais areas nascem com o valor vindo do servidor',
      (tester) async {
    await abrir(tester, const {
      'dieta': true,
      'suplementacao': false,
      'avaliacoes': true,
      'metas': false
    });

    expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('permissao_dieta')))
            .value,
        isTrue);
    expect(
        tester
            .widget<SwitchListTile>(
                find.byKey(const Key('permissao_suplementacao')))
            .value,
        isFalse);
    expect(
        tester
            .widget<SwitchListTile>(
                find.byKey(const Key('permissao_avaliacoes')))
            .value,
        isTrue);
    expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('permissao_metas')))
            .value,
        isFalse);
  });

  testWidgets('mostra os dois botoes de resposta', (tester) async {
    await abrir(tester, const {});

    expect(find.byKey(const Key('permissoes_nao_permitir')), findsOneWidget);
    expect(find.byKey(const Key('permissoes_permitir')), findsOneWidget);
    expect(find.text('Recusar contrato'), findsOneWidget);
    expect(find.text('Permitir selecionados'), findsOneWidget);
  });

  testWidgets('exige aceite dos termos antes de confirmar', (tester) async {
    await abrir(tester, const {});
    final botaoAntes = tester
        .widget<ElevatedButton>(find.byKey(const Key('permissoes_permitir')));
    expect(botaoAntes.onPressed, isNull);

    await tester.tap(find.byKey(const Key('aceite_termos_contrato')));
    await tester.pump();
    final botaoDepois = tester
        .widget<ElevatedButton>(find.byKey(const Key('permissoes_permitir')));
    expect(botaoDepois.onPressed, isNotNull);
  });

  testWidgets('trocar um switch de area libera so essa area', (tester) async {
    await abrir(tester, const {});

    await tester.tap(find.byKey(const Key('permissao_dieta')));
    await tester.pumpAndSettle();

    expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('permissao_dieta')))
            .value,
        isTrue);
    expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('permissao_metas')))
            .value,
        isFalse);
  });
}
