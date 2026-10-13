import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
import 'package:task_manager_flutter/data/utils/exercicio_video_link.dart';
import 'package:task_manager_flutter/ui/screens/fitness/biblioteca_exercicios_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('YouTube aceita watch, compartilhamento, shorts e embed', () {
    for (final url in [
      'https://www.youtube.com/watch?v=jNQXAC9IVRw',
      'https://youtu.be/jNQXAC9IVRw?si=teste',
      'https://www.youtube.com/shorts/jNQXAC9IVRw',
      'https://www.youtube.com/embed/jNQXAC9IVRw',
    ]) {
      expect(exercicioVideoEmbed(url)?.path, '/embed/jNQXAC9IVRw');
    }
  });
  test('Drive aceita arquivo e compartilhamento por ID', () {
    for (final url in [
      'https://drive.google.com/file/d/abc_123/view?usp=sharing',
      'https://drive.google.com/open?id=abc_123'
    ]) {
      expect(exercicioVideoEmbed(url).toString(),
          'https://drive.google.com/file/d/abc_123/preview');
    }
  });
  test('rejeita URL maliciosa, pasta e identificador invalido', () {
    for (final url in [
      'javascript:alert(1)',
      'http://youtu.be/jNQXAC9IVRw',
      'https://youtube.com.evil.test/watch?v=jNQXAC9IVRw',
      'https://drive.google.com/drive/folders/abc',
      'https://youtu.be/invalido'
    ]) {
      expect(validarLinkVideoExercicio(url), isNotNull);
    }
    expect(validarLinkVideoExercicio(''), isNull);
  });
  test('alterar e remover video preserva demais dados do exercicio', () async {
    final repo = FitnessOfflineRepository();
    final original = (await repo.getExercicios()).first;
    await repo.atualizarVideoExercicio(
        original.id, 'https://youtu.be/jNQXAC9IVRw');
    final editado =
        (await repo.getExercicios()).firstWhere((e) => e.id == original.id);
    expect(editado.toMap(),
        {...original.toMap(), 'videoUrl': 'https://youtu.be/jNQXAC9IVRw'});
    await repo.atualizarVideoExercicio(original.id, null);
    expect(
        (await repo.getExercicios())
            .firstWhere((e) => e.id == original.id)
            .videoUrl,
        isNull);
  });
  testWidgets('cadastro salva link e detalhes oferecem player interno',
      (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: BibliotecaExerciciosScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Novo Exercício'));
    await tester.pumpAndSettle();
    Finder campo(String label) => find.byWidgetPredicate((widget) =>
        widget is TextField && widget.decoration?.labelText == label);
    await tester.enterText(
        campo('Nome do Exercício *'), 'Exercicio video teste');
    final video = campo('Vídeo do YouTube ou Google Drive');
    await tester.ensureVisible(video);
    await tester.enterText(video, 'https://youtu.be/jNQXAC9IVRw');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Exercicio video teste'), findsOneWidget);
    await tester.tap(find.text('Exercicio video teste'));
    await tester.pumpAndSettle();
    expect(find.text('Assistir demonstração'), findsOneWidget);
    expect(find.text('Alterar vídeo'), findsOneWidget);
    final exercicio = (await FitnessOfflineRepository().getExercicios())
        .firstWhere((e) => e.nome == 'Exercicio video teste');
    expect(exercicio.videoUrl, 'https://youtu.be/jNQXAC9IVRw');
  });
}
