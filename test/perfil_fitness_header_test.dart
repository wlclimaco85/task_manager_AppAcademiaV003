import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/ui/widgets/perfil_fitness_header.dart';

void main() {
  testWidgets('Nome longo cabe no celular e ausência de foto usa iniciais',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 240,
          child: PerfilFitnessHeader(
            nome: 'Washington Climaco de Albuquerque com nome longo',
            perfil: 'Aluno',
          ),
        ),
      ),
    ));
    expect(find.text('WL'), findsOneWidget);
    expect(find.text('Aluno'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Conta sem nome não inventa identidade', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: PerfilFitnessHeader(nome: '', perfil: 'Personal'),
      ),
    ));
    expect(find.text('Minha conta'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
