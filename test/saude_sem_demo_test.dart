import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/services/nutricao_farmaco_offline_repository.dart';
import 'package:task_manager_flutter/data/services/fitness_360_local_store.dart';
import 'package:task_manager_flutter/data/services/exames_offline_repository.dart';
import 'package:task_manager_flutter/ui/widgets/registro_medida_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() { SharedPreferences.setMockInitialValues({}); AuthUtility.userInfo = LoginModel(); });
  test('conta sem dados nao recebe dieta medicamento suplemento exame ou atividade', () async {
    final repo = NutricaoFarmacoOfflineRepository();
    expect(await repo.getDietas(), isEmpty);
    expect(await repo.getMedicamentos(), isEmpty);
    expect(await repo.getSuplementos(), isEmpty);
    expect(await ExamesOfflineRepository().getExames(), isEmpty);
    expect(await Fitness360LocalStore.records(), isEmpty);
    expect(await Fitness360LocalStore.weeklySeries('corpo'), List.filled(7, 0));
  });
  testWidgets('dropdown de medida salva peso e fecha sem excecao', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(
      body: TextButton(onPressed: () => showModalBottomSheet(context: context,
        isScrollControlled: true, builder: (_) => const RegistroMedidaSheet()),
        child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Valor'), '100,5');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final registros = await Fitness360LocalStore.records(type: 'corpo');
    expect(registros.single.title, 'Peso');
    expect(registros.single.value, '100.5 kg');
    expect((await Fitness360LocalStore.summary()).weightKg, 100.5);
  });
}
