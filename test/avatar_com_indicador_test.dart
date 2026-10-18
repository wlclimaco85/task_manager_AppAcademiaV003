import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/ui/widgets/avatar_com_indicador.dart';

Widget _montar({required bool alerta}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: AvatarComIndicador(
          mostrarAlerta: alerta,
          rotulo: 'Cadastro incompleto',
          titulo: 'Cadastro inicial pendente',
          corpo: 'Maria ainda não preencheu a foto ou as medidas.',
          avatar: const CircleAvatar(radius: 24, child: Text('M')),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('sem pendencia nao mostra o "!"', (tester) async {
    await tester.pumpWidget(_montar(alerta: false));

    expect(find.text('!'), findsNothing);
    expect(find.text('M'), findsOneWidget);
  });

  testWidgets('com pendencia mostra o "!" amarelo ao lado do avatar', (tester) async {
    await tester.pumpWidget(_montar(alerta: true));

    expect(find.text('!'), findsOneWidget);
    expect(find.text('M'), findsOneWidget);
    expect(find.byTooltip('Cadastro incompleto'), findsOneWidget);
  });

  testWidgets('tocar no "!" abre o aviso com titulo e texto', (tester) async {
    await tester.pumpWidget(_montar(alerta: true));

    await tester.tap(find.text('!'));
    await tester.pumpAndSettle();

    expect(find.text('Cadastro inicial pendente'), findsOneWidget);
    expect(find.text('Maria ainda não preencheu a foto ou as medidas.'), findsOneWidget);

    await tester.tap(find.text('Entendi'));
    await tester.pumpAndSettle();
    expect(find.text('Cadastro inicial pendente'), findsNothing);
  });
}
