import 'dart:async';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/services/perfil_conta_service.dart';
import 'package:task_manager_flutter/ui/screens/fitness/meu_perfil_screen.dart';

class FakePerfil extends PerfilContaService {
  Map<String, dynamic>? enviado;
  bool falhar = false;
  @override
  Future<Map<String, dynamic>> carregar() async => {
        'nome': 'Pessoa cadastrada',
        'email': 'pessoa@teste.local',
        'cpf': '123',
        'telefone': '',
        'instagram': '',
        'linkBio': '',
        'foto': ''
      };
  @override
  Future<Map<String, dynamic>> salvar(Map<String, dynamic> d) async {
    if (falhar) throw StateError('Servidor indisponível.');
    enviado = d;
    return d;
  }
}

class _StoreLento extends InMemorySharedPreferencesStore {
  _StoreLento() : super.withData({});
  final iniciou = Completer<void>();
  final liberar = Completer<void>();
  bool primeira = true;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == 'flutter.user_data' && primeira) {
      primeira = false;
      iniciou.complete();
      await liberar.future;
    }
    return super.setValue(type, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthUtility.userInfo =
        LoginModel(token: 'teste', login: Login(id: 101, nome: 'Anterior'));
  });
  tearDown(() {
    AuthUtility.userInfo = LoginModel();
  });
  test('persiste perfil na sessão sem perder token e permissões', () async {
    await http.runWithClient(() async {
      final p = await PerfilContaService()
          .salvar({'nome': 'Nome atualizado', 'foto': ''});
      expect(p['nome'], 'Nome atualizado');
      expect(AuthUtility.userInfo.login!.nome, 'Nome atualizado');
      expect(AuthUtility.userInfo.token, 'teste');
      final recuperado = await AuthUtility.getUserInfo();
      expect(recuperado!.perfilConta!['foto'], '');
      expect(recuperado.login!.id, 101);
    },
        () => MockClient((q) async {
              expect(q.headers['Authorization'], 'Bearer teste');
              return http.Response(
                  jsonEncode({
                    'nome': 'Nome atualizado',
                    'foto': '',
                    'email': 'pessoa@teste.local'
                  }),
                  200);
            }));
  });
  test('resposta de outra sessão não modifica conta atual', () async {
    await http.runWithClient(() async {
      await expectLater(PerfilContaService().carregar(), throwsStateError);
      expect(AuthUtility.userInfo.login!.id, 202);
      expect(AuthUtility.userInfo.perfilConta, isNull);
    },
        () => MockClient((q) async {
              AuthUtility.userInfo = LoginModel(
                  token: 'outra', login: Login(id: 202, nome: 'Outra'));
              return http.Response('{"nome":"Conta anterior"}', 200);
            }));
  });
  test('logout durante armazenamento não restaura sessão anterior', () async {
    final store = _StoreLento();
    SharedPreferencesStorePlatform.instance = store;
    await http.runWithClient(() async {
      final leitura = PerfilContaService().carregar();
      final verificacao = expectLater(leitura, throwsStateError);
      await store.iniciou.future;
      final sair = AuthUtility.clearUserInfo();
      store.liberar.complete();
      await verificacao;
      await sair;
      expect(AuthUtility.userInfo.token, isNull);
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(prefs.getString('user_data'), isNull);
    },
        () => MockClient((_) async => http.Response(
            '{"nome":"Anterior","email":"a@teste.local","foto":""}', 200)));
  });
  test('imagem inválida não vira foto de perfil', () {
    expect(() => prepararFotoPerfil(utf8.encode('arquivo inválido')),
        throwsFormatException);
  });
  for (final largura in [390.0, 1200.0]) {
    testWidgets('perfil permite editar e preserva campos ao falhar em $largura',
        (t) async {
      t.view.physicalSize = Size(largura, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final service = FakePerfil()..falhar = true;
      await t.pumpWidget(MaterialApp(home: MeuPerfilScreen(service: service)));
      await t.pumpAndSettle();
      expect(find.text('Escolher foto'), findsOneWidget);
      await t.enterText(
          find.widgetWithText(TextFormField, 'Nome'), 'Meu novo nome');
      final salvar = find.text('Salvar perfil');
      await t.ensureVisible(salvar);
      await t.tap(salvar);
      await t.pumpAndSettle();
      expect(find.text('Servidor indisponível.'), findsOneWidget);
      expect(find.text('Meu novo nome'), findsWidgets);
      expect(service.enviado, isNull);
      expect(t.takeException(), isNull);
    });
  }
}
