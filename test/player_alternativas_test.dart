import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/ui/screens/fitness/player_treino_ao_vivo_screen.dart';

void main() {
  testWidgets('aluno troca alternativa, preserva série feita e retoma offline',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(400, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    const divisao = DivisaoTreinoModel(id: 'divisao', letra: 'A', nome: 'Costas',
      exercicios: [
        ItemTreinoModel(id: 'p1', exercicioId: 'ex_13',
          exercicioNome: 'Puxada Frontal na Polia', grupoMuscular: 'Costas',
          series: 2, cargaSugeridaKg: 40,
          exerciciosAlternativos: ['Remada Baixa no Triângulo']),
      ]);
    Widget app() => const MaterialApp(home: PlayerTreinoAoVivoScreen(
      divisao: divisao, planoId: 'plano', alunoId: 'aluno'));
    await t.pumpWidget(app());
    await t.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    await t.tap(find.byIcon(Icons.check).first);
    await t.pump();
    await t.tap(find.text('Máquina ocupada? Trocar exercício'));
    await t.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await t.pumpAndSettle();
    expect(find.text('Alternativa cadastrada'), findsOneWidget);
    await t.tap(find.text('Remada Baixa no Triângulo'));
    await t.pumpAndSettle();
    expect(find.text('Alternativa de Puxada Frontal na Polia'), findsOneWidget);
    expect(find.text('40.0 kg'), findsOneWidget);
    expect(find.text('0.0 kg'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getKeys().singleWhere((k) => k.startsWith('fitness_player_'));
    final saved = jsonDecode(prefs.getString(key)!);
    expect(saved['series']['0'][0]['concluida'], isTrue);
    expect(saved['execucao']['realizados']['0']['0']['exercicioId'], 'ex_13');
    expect(saved['execucao']['selecionados']['0']['exercicioNome'],
      'Remada Baixa no Triângulo');
    await t.pumpWidget(const MaterialApp(home: SizedBox()));
    await t.pumpAndSettle();
    await t.pumpWidget(app());
    await t.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await t.pumpAndSettle();
    expect(find.text('Alternativa de Puxada Frontal na Polia'), findsOneWidget);
    expect(find.text('40.0 kg'), findsOneWidget);
    await t.tap(find.text('Máquina ocupada? Trocar exercício'));
    await t.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await t.pumpAndSettle();
    await t.tap(find.text('Exercício original'));
    await t.pumpAndSettle();
    expect(find.text('Alternativa de Puxada Frontal na Polia'), findsNothing);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const MaterialApp(home: SizedBox()));
    await t.pumpAndSettle();
  });
}
