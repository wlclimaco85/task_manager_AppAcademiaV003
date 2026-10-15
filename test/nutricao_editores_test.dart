import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/models/fitness/nutricao_farmaco_model.dart';
import 'package:task_manager_flutter/data/services/nutricao_farmaco_offline_repository.dart';
import 'package:task_manager_flutter/ui/widgets/nutricao_editores.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthUtility.userInfo = LoginModel();
  });
  Future<void> abrir(WidgetTester t, Widget editor) async {
    t.view.physicalSize = const Size(400, 1100);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () =>
                        showDialog(context: context, builder: (_) => editor),
                    child: const Text('Abrir'))))));
    await t.tap(find.text('Abrir'));
    await t.pumpAndSettle();
  }

  testWidgets(
      'dieta permite escolher refeicao, alimento e quantidade sem inserir exemplos',
      (t) async {
    await t.runAsync(() => NutricaoFarmacoOfflineRepository().addAlimento(
        const AlimentoModel(
            id: 'teste_catalogo',
            nome: 'Alimento unitário QA',
            categoria: 'geral',
            calorias: 200,
            proteinas: 10,
            carboidratos: 20,
            gorduras: 5)));
    await abrir(t, const DietaEditor());
    expect(find.text('Nenhuma refeição adicionada.'), findsOneWidget);
    expect(find.textContaining('Ovo Cozido'), findsNothing);
    await t.enterText(
        find.widgetWithText(TextFormField, 'Título da dieta'), 'Minha dieta');
    await t.tap(find.text('Adicionar refeição'));
    await t.pumpAndSettle();
    await t.tap(find.byType(DropdownButtonFormField<String>).last);
    await t.pumpAndSettle();
    await t.tap(find.text('Almoço').last);
    await t.pumpAndSettle();
    await t.enterText(
        find.widgetWithText(TextFormField, 'Horário (HH:mm)'), '12:30');
    await t.tap(find.text('Adicionar alimento').last);
    await t.pumpAndSettle();
    await t.enterText(find.widgetWithText(TextField, 'Buscar alimento'),
        'Alimento unitário QA');
    await t.pumpAndSettle();
    await t.tap(find.text('Alimento unitário QA').last);
    await t.pumpAndSettle();
    await t.enterText(
        find.widgetWithText(TextFormField, 'Quantidade (g)'), '50');
    await t.tap(find.widgetWithText(FilledButton, 'Adicionar alimento'));
    await t.pumpAndSettle();
    await t.tap(find.text('Salvar refeição'));
    await t.pumpAndSettle();
    await t.tap(find.text('Salvar dieta'));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    final d = (await NutricaoFarmacoOfflineRepository().getDietas()).single;
    expect(d.refeicoes.single.nome, 'Almoço');
    expect(d.refeicoes.single.horario, '12:30');
    expect(d.refeicoes.single.itens.single.quantidadeGramas, 50);
    expect(d.totalCaloriasReal, 100);
    expect(d.caloriasMeta, 0);
    await abrir(t, DietaEditor(dieta: d));
    expect(find.text('Almoço (12:30)'), findsOneWidget);
  });
  testWidgets('suplemento salva marca tamanho do pote e horario selecionado',
      (t) async {
    await abrir(t, const SuplementoEditor());
    await t.enterText(
        find.widgetWithText(TextFormField, 'Nome do suplemento'), 'Creatina');
    await t.enterText(
        find.widgetWithText(TextFormField, 'Marca'), 'Marca informada');
    await t.enterText(
        find.widgetWithText(TextFormField, 'Quantidade do pote'), '300');
    await t.enterText(
        find.widgetWithText(TextFormField, 'Dosagem por uso'), '5 g');
    await t.tap(find.byType(DropdownButtonFormField<String>).last);
    await t.pumpAndSettle();
    await t.tap(find.text('Pós-Treino').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Salvar'));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    final s =
        (await NutricaoFarmacoOfflineRepository().getSuplementos()).single;
    expect(s.marca, 'Marca informada');
    expect(s.quantidadePote, 300);
    expect(s.unidadePote, 'g');
    expect(s.horario, 'Pós-Treino');
    final legado = SuplementoProtocoloModel.fromMap(
        {'id': 'antigo', 'nome': 'Legado', 'horario': 'Horário personalizado'});
    expect(legado.quantidadePote, isNull);
    expect(legado.marca, isEmpty);
    await abrir(t, SuplementoEditor(suplemento: legado));
    expect(find.text('Horário personalizado'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  test('documentos dieta e suplemento recuperam todos campos apos limpar cache',
      () async {
    AuthUtility.userInfo = LoginModel(token: 'nutricao', login: Login(id: 981));
    final documentos = <String, Map<String, dynamic>>{};
    await http.runWithClient(() async {
      final r = NutricaoFarmacoOfflineRepository();
      await r.salvarDieta(const DietaProtocoloModel(
          id: 'd',
          alunoId: '981',
          titulo: 'Dieta',
          objetivo: '',
          caloriasMeta: 0,
          proteinasMeta: 0,
          carboidratosMeta: 0,
          gordurasMeta: 0,
          dataInicio: '2026-10-15',
          refeicoes: [
            RefeicaoModel(id: 'j', nome: 'Jantar', horario: '19:30', itens: [
              ItemRefeicaoModel(
                  alimentoId: 'x',
                  alimentoNome: 'Item cadastrado',
                  quantidadeGramas: 60,
                  calorias: 120,
                  proteinas: 6,
                  carboidratos: 12,
                  gorduras: 3)
            ])
          ]));
      await r.salvarSuplemento(const SuplementoProtocoloModel(
          id: 's',
          alunoId: '981',
          nome: 'Suplemento',
          marca: 'Marca',
          quantidadePote: 90,
          unidadePote: 'cápsulas',
          dosagem: '1 cápsula',
          horario: 'Almoço',
          dataInicio: '2026-10-15'));
      SharedPreferences.setMockInitialValues({});
      expect(
          (await r.getDietas())
              .single
              .refeicoes
              .single
              .itens
              .single
              .quantidadeGramas,
          60);
      expect((await r.getSuplementos()).single.quantidadePote, 90);
      expect((await r.getSuplementos()).single.marca, 'Marca');
    },
        () => MockClient((q) async {
              final tipo = q.url.pathSegments[q.method == 'PUT'
                  ? q.url.pathSegments.length - 2
                  : q.url.pathSegments.length - 1];
              if (q.method == 'PUT') {
                documentos[tipo] =
                    Map<String, dynamic>.from(jsonDecode(q.body));
                return http.Response(q.body, 200);
              }
              return http.Response(
                  jsonEncode({
                    'data':
                        documentos.containsKey(tipo) ? [documentos[tipo]] : []
                  }),
                  200);
            }));
  });
}
