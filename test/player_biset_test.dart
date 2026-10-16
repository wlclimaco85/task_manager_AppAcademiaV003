import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/ui/screens/fitness/player_treino_ao_vivo_screen.dart';

void main() {
  testWidgets('bi-set troca sem descanso A/B e retoma série seguinte offline',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(500, 1100);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    const divisao =
        DivisaoTreinoModel(id: 'd', letra: 'A', nome: 'Bi-set', exercicios: [
      ItemTreinoModel(
          id: 'a',
          exercicioId: 'ex_1',
          exercicioNome: 'Primeiro exercício',
          grupoMuscular: 'Peito',
          series: 2,
          cargaSugeridaKg: 20,
          tecnica: 'Bi-set',
          exercicioBiset: ItemTreinoModel(
              id: 'b',
              exercicioId: 'ex_2',
              exercicioNome: 'Segundo exercício',
              grupoMuscular: 'Peito',
              series: 2,
              cargaSugeridaKg: 10))
    ]);
    Finder titulo(String nome) => find.byWidgetPredicate(
        (w) => w is Text && w.data == nome && w.style?.fontSize == 17);
    Widget app() => const MaterialApp(
        home: PlayerTreinoAoVivoScreen(
            divisao: divisao, planoId: 'p', alunoId: 'a'));
    Future<void> aguardar() async {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)));
      await t.pumpAndSettle();
    }

    await t.pumpWidget(app());
    await aguardar();
    expect(titulo('Primeiro exercício'), findsOneWidget);
    await t.tap(find.byIcon(Icons.check).first);
    await aguardar();
    expect(titulo('Segundo exercício'), findsOneWidget);
    expect(find.text('Intervalo de descanso...'), findsNothing);
    await t.tap(find.byIcon(Icons.check).first);
    await aguardar();
    expect(titulo('Primeiro exercício'), findsOneWidget);
    expect(find.text('Intervalo de descanso...'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    final chave =
        prefs.getKeys().singleWhere((k) => k.startsWith('fitness_player_'));
    final salvo = jsonDecode(prefs.getString(chave)!);
    expect(salvo['series']['0'][0]['concluida'], true);
    expect(salvo['series']['1'][0]['concluida'], true);
    expect(salvo['series']['0'][1]['concluida'], false);
    await t.pumpWidget(const MaterialApp(home: SizedBox()));
    await t.pumpWidget(app());
    await aguardar();
    expect(titulo('Primeiro exercício'), findsOneWidget);
    await t.tap(find.byIcon(Icons.check).last);
    await aguardar();
    expect(titulo('Segundo exercício'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const MaterialApp(home: SizedBox()));
    await t.pumpAndSettle();
  });
}
