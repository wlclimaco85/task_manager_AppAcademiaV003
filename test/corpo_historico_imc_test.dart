import 'dart:convert';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/models/fitness/graficos_fitness_dados.dart';
import 'package:task_manager_flutter/ui/screens/fitness_personal_screens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('troca de conta durante paginação não mistura histórico ou cache', () async {
    final antes = AuthUtility.userInfo;
    addTearDown(() => AuthUtility.userInfo = antes);
    AuthUtility.userInfo = LoginModel(token: 'conta_a', login: Login(id: 10));
    SharedPreferences.setMockInitialValues({});
    final iniciada = Completer<void>();
    final resposta = Completer<http.Response>();
    var consultas = 0;
    await http.runWithClient(() async {
      final carregando = GraficosFitnessDados.carregarDiario();
      await iniciada.future;
      AuthUtility.userInfo = LoginModel(token: 'conta_b', login: Login(id: 20));
      resposta.complete(http.Response('[{"data":"2026-10-25","pesoKg":101.65}]', 200));
      expect(await carregando, isEmpty);
      expect(consultas, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('fitness_graficos_diario_conta_10'), isNull);
      expect(prefs.getString('fitness_graficos_diario_conta_20'), isNull);
    }, () => MockClient((request) {
      consultas++;
      expect(request.headers['authorization'], 'Bearer conta_a');
      iniciada.complete();
      return resposta.future;
    }));
  });
  for (final dias in [90, 365]) {
  test('histórico de $dias dias respeita limite real de 60 dias do backend', () async {
    final antes = AuthUtility.userInfo;
    addTearDown(() => AuthUtility.userInfo = antes);
    AuthUtility.userInfo = LoginModel(token: 'teste', login: Login(id: 10));
    SharedPreferences.setMockInitialValues({});
    var consultas = 0;
    final datas = <DateTime>{};
    await http.runWithClient(() async {
      final diario = await GraficosFitnessDados.carregarDiario(dias: dias);
      expect(consultas, (dias / 60).ceil());
      expect(diario.length, consultas);
      expect(datas.length, dias);
    }, () => MockClient((request) async {
      consultas++;
      final inicio = DateTime.parse(request.url.queryParameters['inicio']!);
      final fim = DateTime.parse(request.url.queryParameters['fim']!);
      if (fim.difference(inicio).inDays > 60) return http.Response('{}', 400);
      for (var data = inicio; !data.isAfter(fim); data = data.add(const Duration(days: 1))) {
        expect(datas.add(data), isTrue, reason: 'Data repetida entre lotes');
      }
      return http.Response(jsonEncode([
        {'data': inicio.toIso8601String(), 'pesoKg': consultas == 1 ? 104 : 101.65},
      ]), 200);
    }));
  });
  }
  testWidgets('Corpo consulta altura do cadastro remoto quando copia local falta', (tester) async {
    final antes = AuthUtility.userInfo;
    addTearDown(() => AuthUtility.userInfo = antes);
    AuthUtility.userInfo = LoginModel();
    SharedPreferences.setMockInitialValues({'cadastro_inicial_v1': jsonEncode({'altura': ''})});
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: CorpoScreen()));
      await tester.pumpAndSettle();
      expect(find.text('31,4'), findsOneWidget);
      expect(find.text('Ainda não há registros para mostrar a evolução.'), findsNothing);
      expect(tester.takeException(), isNull);
    }, () => MockClient((request) async => http.Response(jsonEncode(
      request.url.path.endsWith('/resumo')
        ? {'data': DateTime.now().toIso8601String(), 'pesoKg': 101.65, 'alturaCm': 0, 'historicoSemanal': []}
        : request.url.path.contains('cadastro-inicial')
          ? {'data': {'medidas': {'altura': '180'}, 'fotos': {}}}
          : {'data': []}), 200)));
  });
  testWidgets('Corpo usa pesos de datas anteriores e altura registrada para IMC', (tester) async {
    final antes = AuthUtility.userInfo;
    addTearDown(() => AuthUtility.userInfo = antes);
    AuthUtility.userInfo = LoginModel();
    SharedPreferences.setMockInitialValues({
      'fitness_graficos_diario_365': jsonEncode([
        {'data': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(), 'pesoKg': 104},
        {'data': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(), 'pesoKg': 102},
      ]),
      'fitness360.records.v1': jsonEncode([
        for (final item in [(1, ' peso ', '103 kg', 20), (2, 'Peso', '101.65 kg', 0), (3, 'Altura', '180 cm', 9)])
          {'id': item.$1, 'type': 'corpo', 'title': item.$2, 'value': item.$3,
            'note': '', 'createdAt': DateTime.now().subtract(Duration(days: item.$4)).toIso8601String()},
      ]),
    });
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: CorpoScreen()));
      await tester.pumpAndSettle();
      expect(find.text('31,4'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Evolucao'), 400,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      final charts = tester.widgetList<LineChart>(find.byType(LineChart));
      expect(charts.any((c) => c.data.lineBarsData.any((s) =>
          s.spots.map((p) => p.y).toList().toString() == '[104.0, 103.0, 102.0, 101.65]')), isTrue);
      expect(tester.takeException(), isNull);
    }, () => MockClient((request) async => http.Response(
      jsonEncode(request.url.path.endsWith('/resumo')
          ? {'data': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(), 'pesoKg': 100,
             'historicoSemanal': [{'data': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(), 'pesoKg': null}]}
          : {'data': []}), 200)));
  });
}
