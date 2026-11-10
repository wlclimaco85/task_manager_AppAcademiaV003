import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/academia_cadastro_service.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/screens/fitness/cadastro_academia_screen.dart';

/// Cliente HTTP falso: registra as chamadas e devolve o cadastro e a resposta configurados.
class _ClienteFalso extends NetworkCaller {
  _ClienteFalso({required this.cadastro});

  Map<String, dynamic> cadastro;
  NetworkResponse? respostaPut;
  final List<String> chamadas = [];

  @override
  Future<NetworkResponse> getRequest(String url) async {
    chamadas.add('GET $url');
    return NetworkResponse(true, 200, {'data': cadastro});
  }

  @override
  Future<NetworkResponse> putRequest(String url, dynamic body) async {
    chamadas.add('PUT $url');
    return respostaPut ?? NetworkResponse(true, 200, {'data': null});
  }
}

Map<String, dynamic> _cadastro({String nome = 'Academia Alpha'}) => {
      'cadastrada': true,
      'dados': {'nome': nome},
      'horarios': [
        {'diaSemana': 1, 'abertura': '06:00', 'fechamento': '22:00'},
      ],
      'planos': [
        {'id': 10, 'nome': 'Mensal', 'valor': 99.9, 'qtdAula': 8},
      ],
      'personais': [
        {'personalId': 5, 'nome': 'Carla Personal'},
      ],
    };

Future<void> _abrirTela(WidgetTester tester, _ClienteFalso cliente) async {
  // Superficie alta: todos os botoes ficam visiveis sem depender de rolagem.
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  AcademiaCadastroService.fabricaRede = () => cliente;
  await tester.pumpWidget(const MaterialApp(home: CadastroAcademiaScreen()));
  await tester.pumpAndSettle();
}

String _valorCampo(WidgetTester tester, String rotulo) =>
    tester.widget<TextFormField>(find.widgetWithText(TextFormField, rotulo)).controller!.text;

void main() {
  final cliente = _ClienteFalso(cadastro: _cadastro());

  setUp(() {
    cliente.chamadas.clear();
    cliente.respostaPut = null;
    cliente.cadastro = _cadastro();
  });

  tearDown(() {
    AcademiaCadastroService.fabricaRede = () => NetworkCaller();
  });

  testWidgets('carrega dados, planos e personais vinculados da academia', (tester) async {
    await _abrirTela(tester, cliente);

    expect(find.text('Cadastro da academia'), findsOneWidget);
    expect(_valorCampo(tester, 'Nome da academia *'), 'Academia Alpha');
    expect(find.text('Mensal'), findsOneWidget);
    expect(find.text('Carla Personal'), findsOneWidget);
    expect(cliente.chamadas, ['GET ${ApiLinks.fitnessAcademiaCadastro}']);
  });

  testWidgets('nome vazio bloqueia o salvamento e nao chama o servidor', (tester) async {
    cliente.cadastro = _cadastro(nome: '');
    await _abrirTela(tester, cliente);

    await tester.ensureVisible(find.text('Salvar dados'));
    await tester.tap(find.text('Salvar dados'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o nome da academia'), findsOneWidget);
    expect(cliente.chamadas.where((c) => c.startsWith('PUT')), isEmpty);
  });

  testWidgets('salvar dados validos envia o PUT e recarrega o cadastro', (tester) async {
    await _abrirTela(tester, cliente);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome da academia *'), 'Academia Beta');
    await tester.ensureVisible(find.text('Salvar dados'));
    await tester.tap(find.text('Salvar dados'));
    await tester.pumpAndSettle();

    expect(cliente.chamadas, contains('PUT ${ApiLinks.fitnessAcademiaCadastroDados}'));
    expect(find.text('Dados da academia salvos'), findsOneWidget);
    expect(cliente.chamadas.where((c) => c.startsWith('GET')).length, 2);
  });

  testWidgets('erro do servidor aparece na tela com a mensagem do backend', (tester) async {
    cliente.respostaPut = NetworkResponse(false, 400, {'message': 'Dados invalidos no servidor'});
    await _abrirTela(tester, cliente);

    await tester.ensureVisible(find.text('Salvar dados'));
    await tester.tap(find.text('Salvar dados'));
    await tester.pumpAndSettle();

    expect(find.text('Dados invalidos no servidor'), findsOneWidget);
  });
}
