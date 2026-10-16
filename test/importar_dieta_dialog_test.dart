import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/services/importacao_dieta_parser.dart';
import 'package:task_manager_flutter/ui/widgets/importar_dieta_dialog.dart';

void main() {
  Future<void> abrir(WidgetTester t, LinhaImportacaoDieta linha,
      void Function(DietaImportada?) receber) async {
    t.view.physicalSize = const Size(400, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(
        home: Builder(
            builder: (c) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      receber(await showDialog<DietaImportada>(
                          context: c,
                          builder: (_) => ImportarDietaDialog(
                              resultado: ResultadoImportacaoDieta([linha], []),
                              catalogo: const [])));
                    },
                    child: const Text('Abrir'))))));
    await t.tap(find.text('Abrir'));
    await t.pumpAndSettle();
  }

  testWidgets('preview aplica refeicao e alimento novo sem persistir',
      (t) async {
    DietaImportada? result;
    await abrir(
        t,
        const LinhaImportacaoDieta(
            numeroLinha: 2,
            refeicao: 'Jantar',
            horario: '19:00',
            alimento: 'Item informado',
            quantidadeGramas: 50,
            calorias: 200,
            proteinas: 10,
            carboidratos: 20,
            gorduras: 8,
            fibras: 2),
        (v) => result = v);
    expect(find.textContaining('Novo alimento'), findsOneWidget);
    await t.tap(find.text('Aplicar à dieta (1)'));
    await t.pumpAndSettle();
    expect(result!.novosAlimentos.length, 1);
    expect(result!.refeicoes.single.itens.single.calorias, 100);
    expect(t.takeException(), isNull);
  });
  testWidgets('nutrientes ausentes exigem revisao e cancelamento nao aplica',
      (t) async {
    DietaImportada? result;
    await abrir(
        t,
        const LinhaImportacaoDieta(
            numeroLinha: 2,
            refeicao: 'Almoço',
            horario: '12:00',
            alimento: 'Item sem macros',
            quantidadeGramas: 80),
        (v) => result = v);
    expect(find.textContaining('Pendente:'), findsOneWidget);
    await t.tap(find.text('Aplicar à dieta (1)'));
    await t.pumpAndSettle();
    expect(result, isNull);
    expect(find.text('Revisar importação'), findsOneWidget);
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(result, isNull);
    expect(t.takeException(), isNull);
  });
}
