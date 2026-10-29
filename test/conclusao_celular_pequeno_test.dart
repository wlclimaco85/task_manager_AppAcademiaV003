import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/plano_treino_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
import 'package:task_manager_flutter/ui/screens/fitness/player_treino_ao_vivo_screen.dart';

void main() {
  testWidgets('conclusao em celular pequeno (360x640) continua utilizavel', (t) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(360, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    const divisao = DivisaoTreinoModel(id: 'div', letra: 'A', nome: 'Treino real',
      exercicios: [ItemTreinoModel(id: 'item', exercicioId: 'ex', exercicioNome: 'Exercicio',
        grupoMuscular: 'Costas', series: 1)]);
    await t.pumpWidget(const MaterialApp(home: PlayerTreinoAoVivoScreen(
      divisao: divisao, planoId: 'ficha', alunoId: 'aluno')));
    await t.runAsync(() async => Future<void>.delayed(const Duration(milliseconds: 150)));
    await t.pumpAndSettle();
    await t.tap(find.text('Concluir').first);
    await t.pumpAndSettle();
    expect(find.text('Treino incompleto'), findsOneWidget);
    expect(find.text('Você ainda não marcou 1 de 1 séries em 1 exercício(s). Deseja concluir mesmo assim?'), findsOneWidget);
    await t.tap(find.text('Concluir mesmo assim'));
    await t.pumpAndSettle();
    final duracao = find.widgetWithText(TextFormField, 'Duração do treino');
    expect(duracao, findsOneWidget);
    await t.enterText(duracao, '75');
    const links = ['https://youtu.be/jNQXAC9IVRw',
      'https://drive.google.com/file/d/abc_123/view',
      'https://www.youtube.com/watch?v=jNQXAC9IVRw'];
    for (var i = 0; i < 3; i++) {
      final campo = find.widgetWithText(TextFormField, 'Link do vídeo ${i + 1} (opcional)');
      await t.ensureVisible(campo);
      await t.enterText(campo, links[i]);
    }
    await t.tap(find.text('Salvar treino'));
    await t.runAsync(() async => Future<void>.delayed(const Duration(milliseconds: 250)));
    await t.pumpAndSettle();
    final sessoes = await FitnessOfflineRepository().getSessoesConcluidas();
    expect(sessoes.length, 1);
    expect(sessoes.single.videosDoTreino, links);
    expect(sessoes.single.treinoId, 'ficha');
    expect(sessoes.single.fotosBase64, isEmpty);
    expect(sessoes.single.duracaoSegundos, 75 * 60);
    final inicio = DateTime.parse(sessoes.single.dataHoraInicio);
    final fim = DateTime.parse(sessoes.single.dataHoraFim);
    expect(fim.difference(inicio), const Duration(minutes: 75));
    expect(t.takeException(), isNull);
  });
}
