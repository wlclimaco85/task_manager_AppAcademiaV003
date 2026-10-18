import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/services/cadastro_inicial_service.dart';

void main() {
  group('pendencias', () {
    test('cadastro vazio pede foto e todas as medidas', () {
      final faltando = CadastroInicialService.pendencias({});

      expect(faltando.first, 'Foto');
      expect(faltando, contains('Peso'));
      expect(faltando, contains('Cintura'));
      expect(faltando.length, 1 + CadastroInicialService.medidas.length);
    });

    test('texto so com espacos conta como nao preenchido', () {
      final faltando = CadastroInicialService.pendencias({'foto': '   '});

      expect(faltando, contains('Foto'));
    });

    test('preenchendo tudo nao sobra pendencia', () {
      final completo = <String, dynamic>{'foto': 'data:image/jpeg;base64,AAAA'};
      for (final m in CadastroInicialService.medidas) {
        completo[m.chave] = 10.0;
      }

      expect(CadastroInicialService.pendencias(completo), isEmpty);
    });
  });

  group('salvar e carregar', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('guarda o que foi informado e le de volta', () async {
      await CadastroInicialService.salvar({'peso': 82.5, 'altura': 178.0});

      final dados = await CadastroInicialService.carregar();

      expect(dados['peso'], 82.5);
      expect(dados['altura'], 178.0);
    });

    test('campo vazio apaga o valor anterior', () async {
      await CadastroInicialService.salvar({'cintura': 90.0});
      await CadastroInicialService.salvar({'cintura': ''});

      final dados = await CadastroInicialService.carregar();

      expect(dados.containsKey('cintura'), isFalse);
    });

    test('dado corrompido no aparelho devolve vazio, sem erro', () async {
      SharedPreferences.setMockInitialValues({'cadastro_inicial_v1': '{quebrado'});

      expect(await CadastroInicialService.carregar(), isEmpty);
    });
  });
}
