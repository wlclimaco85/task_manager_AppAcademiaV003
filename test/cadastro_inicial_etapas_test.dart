import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/services/cadastro_inicial_service.dart';
import 'package:task_manager_flutter/ui/screens/fitness/cadastro_inicial_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('etapa de bracos mostra cada lado com sua foto e sua medida juntas', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: CadastroInicialScreen()));
    await tester.pumpAndSettle();

    // Dados basicos -> cintura -> bracos.
    await tester.tap(find.text('Proxima etapa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proxima etapa'));
    await tester.pumpAndSettle();

    final rotuloDireito = CadastroInicialService.medidas.firstWhere((m) => m.chave == 'braco_direito').rotulo;
    final rotuloEsquerdo = CadastroInicialService.medidas.firstWhere((m) => m.chave == 'braco_esquerdo').rotulo;

    expect(find.byKey(const Key('cadastro_foto_braco_direito')), findsOneWidget);
    expect(find.byKey(const Key('cadastro_foto_braco_esquerdo')), findsOneWidget);
    expect(find.byKey(const Key('cadastro_medida_braco_direito')), findsOneWidget);
    expect(find.byKey(const Key('cadastro_medida_braco_esquerdo')), findsOneWidget);
    expect(find.text(rotuloDireito), findsOneWidget);
    expect(find.text(rotuloEsquerdo), findsOneWidget);

    // Foto do lado direito vem antes da medida do lado direito, e a do esquerdo vem depois dela.
    final yFotoDireito = tester.getTopLeft(find.byKey(const Key('cadastro_foto_braco_direito'))).dy;
    final yMedidaDireito = tester.getTopLeft(find.byKey(const Key('cadastro_medida_braco_direito'))).dy;
    final yFotoEsquerdo = tester.getTopLeft(find.byKey(const Key('cadastro_foto_braco_esquerdo'))).dy;
    expect(yFotoDireito < yMedidaDireito, isTrue);
    expect(yMedidaDireito < yFotoEsquerdo, isTrue);

    expect(tester.takeException(), isNull);
  });
}
