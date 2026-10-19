import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/app.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/services/preferencia_tema_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => PreferenciaTema.tema.value = TemaApp.padrao);

  test('padrao, branco e preto usam superfícies diferentes', () {
    expect(TaskManagerApp.fundoTemaClaro(TemaApp.padrao), GridColors.background);
    expect(TaskManagerApp.fundoTemaClaro(TemaApp.branco), Colors.white);

    final preto = TaskManagerApp.temaEscuro();
    expect(preto.scaffoldBackgroundColor, Colors.black);
    expect(preto.colorScheme.surface, const Color(0xFF111827));
    expect(preto.colorScheme.onSurface.computeLuminance(), greaterThan(.8));
    expect(preto.colorScheme.surface.computeLuminance(), lessThan(.03));
  });
}
