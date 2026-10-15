import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';

const _cache = 'appacademia_sessoes_treino_v1_conta_101';
const _fila = 'fitness_pendentes_sessoes_conta_101';
const _link = 'https://youtu.be/abcdefghijk';
const _sessao = SessaoTreinoRegistroModel(
  id: 's', treinoId: 'f', divisaoLetra: 'A', divisaoNome: 'Treino',
  alunoId: '101', dataHoraInicio: '2026-10-15T12:00:00',
  dataHoraFim: '2026-10-15T12:30:00', duracaoSegundos: 1800,
  exerciciosExecutados: [],
);

class _StoreComFalha extends InMemorySharedPreferencesStore {
  _StoreComFalha(this.chaveFalha, this.lancar)
      : super.withData({'flutter.$_cache': jsonEncode([_sessao.toMap()])});
  final String chaveFalha;
  final bool lancar;
  bool falhar = true;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (falhar && key == 'flutter.$chaveFalha') {
      if (lancar) throw StateError('Quota de armazenamento');
      return false;
    }
    return super.setValue(type, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() {
    SharedPreferences.setMockInitialValues({});
    AuthUtility.userInfo = LoginModel();
  });
  for (final lancar in [false, true]) {
    for (final chaveFalha in [_fila, _cache]) {
      test('falha em $chaveFalha (exceção=$lancar) preserva dados duráveis', () async {
        SharedPreferences.setMockInitialValues({});
        final store = _StoreComFalha(chaveFalha, lancar);
        SharedPreferencesStorePlatform.instance = store;
        AuthUtility.userInfo = LoginModel(token: 'conta101', login: Login(id: 101));
        final repo = FitnessOfflineRepository();
        await http.runWithClient(() async {
          await expectLater(repo.atualizarSessaoMidias('s',
              fotosBase64: [], videosUrls: [_link]), throwsStateError);
          // Recarregar do armazenamento durável elimina valores apenas em memória.
          final prefs = await SharedPreferences.getInstance();
          await prefs.reload();
          if (chaveFalha == _fila) {
            expect(prefs.getString(_fila), isNull);
            expect(jsonDecode(prefs.getString(_cache)!).single['videosUrls'], isEmpty);
          } else {
            expect(jsonDecode(prefs.getString(_fila)!)['s']['videosUrls'], [_link]);
            store.falhar = false;
            final recuperada = (await repo.getSessoesConcluidas()).single;
            expect(recuperada.videosDoTreino, [_link]);
          }
        }, () => MockClient((req) async => req.method == 'PUT'
            ? http.Response('{}', 503)
            : http.Response(jsonEncode({'data': [_sessao.toMap()]}), 200)));
      });
    }
  }
}
