import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/customization/dynamic_grid_dynamic_screen.dart';
import 'package:task_manager_flutter/ui/widgets/fitness_menu_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))).load();
  });
  for (final largura in [390.0, 1200.0]) {
    testWidgets('Academias carrega metadata e nomes reais em largura $largura', (tester) async {
      final debugAnterior = debugPrint;
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(largura, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var consultouMetadata = false;
      var consultouAcademias = false;
      try {
      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: FitnessMenuPage(
          child: DynamicGridDynamicScreen(telaNome: 'academia', hasPermission: permitir),
        )));
        await tester.pumpAndSettle();
        expect(consultouMetadata, isTrue);
        expect(consultouAcademias, isTrue);
        expect(find.text('Academias'), findsOneWidget);
        expect(find.text('Academia do teste'), findsOneWidget);
        expect(find.text('Cidade do teste'), findsOneWidget);
        expect(find.text('Erro'), findsNothing);
        expect(tester.takeException(), isNull);
      }, () => MockClient((request) async {
        if (request.url.path.endsWith('/api/telas/academia')) {
          consultouMetadata = true;
          return http.Response(jsonEncode({
            'id': 123, 'nome': 'academia', 'titulo': 'Academias',
            'fetchEndpoint': '/api/academias', 'createEndpoint': '/api/academias',
            'updateEndpoint': '/api/academias/:id', 'deleteEndpoint': '/api/academias/:id',
            'idFieldName': 'id', 'enableDebugMode': false,
            'fields': [
              {'fieldName': 'id', 'label': 'Código', 'fieldType': 'number', 'isInForm': false},
              {'fieldName': 'codDadosPessoal.nome', 'label': 'Nome', 'fieldType': 'text'},
              {'fieldName': 'observacao', 'label': 'Observação', 'fieldType': 'multiline'},
            ],
          }), 200);
        }
        if (request.url.path.endsWith('/api/academias')) {
          consultouAcademias = true;
          expect(request.url.queryParameters['pagina'], '0');
          expect(request.url.queryParameters['tamanho'], '20');
          return http.Response(jsonEncode({'data': [
            {'id': 1, 'codDadosPessoal': {'nome': 'Academia do teste', 'cidade': 'Cidade do teste'}, 'observacao': 'Musculação'},
          ], 'totalElements': 1}), 200);
        }
        return http.Response('{"data":[]}', 200);
      }));
      } finally {
        debugPrint = debugAnterior;
      }
    });
  }
}

bool permitir(String _) => true;
