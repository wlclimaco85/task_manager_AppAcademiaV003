import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/services/dados_usuario_service.dart';

Map<String, dynamic> _cadastroAtual() => {
      'id': 42,
      'nome': 'Washington Luis',
      'cpf': '000.000.000-00',
      'email': 'antigo@exemplo.com',
      'telefone1': '(34) 99999-0000',
      'telefone2': null,
      'cep': '38400000',
      'logradouro': 'Rua A',
      'numero': '10',
      'bairro': 'Centro',
      'cidade': 'Uberaba',
      'estado': 'MG',
      'pais': 'Brasil',
      'photo': 'data:image/jpeg;base64,AAAA',
    };

void main() {
  group('montarCorpo', () {
    test('aplica so os campos editados e preserva o restante do cadastro', () {
      final corpo = DadosUsuarioService.montarCorpo(
        _cadastroAtual(),
        {'nome': 'Washington L. Climaco', 'email': 'novo@exemplo.com'},
      );

      expect(corpo['nome'], 'Washington L. Climaco');
      expect(corpo['email'], 'novo@exemplo.com');
      expect(corpo['cpf'], '000.000.000-00');
      expect(corpo['id'], 42);
      expect(corpo['cidade'], 'Uberaba');
      expect(corpo['photo'], 'data:image/jpeg;base64,AAAA');
    });

    test('remove espacos das pontas dos campos editados', () {
      final corpo = DadosUsuarioService.montarCorpo(
        _cadastroAtual(),
        {'nome': '   Maria   '},
      );

      expect(corpo['nome'], 'Maria');
    });

    test('troca a foto so quando uma nova foi escolhida', () {
      final semFoto = DadosUsuarioService.montarCorpo(_cadastroAtual(), {'nome': 'X'});
      final comFoto = DadosUsuarioService.montarCorpo(
        _cadastroAtual(),
        {'nome': 'X'},
        fotoDataUri: 'data:image/jpeg;base64,BBBB',
      );

      expect(semFoto['photo'], 'data:image/jpeg;base64,AAAA');
      expect(comFoto['photo'], 'data:image/jpeg;base64,BBBB');
    });

    test('nao altera o mapa original recebido', () {
      final atual = _cadastroAtual();

      DadosUsuarioService.montarCorpo(atual, {'nome': 'Outro'});

      expect(atual['nome'], 'Washington Luis');
    });
  });

  group('extrairDados', () {
    test('le o primeiro registro de data.dados', () {
      final corpo = {
        'data': {
          'dados': [
            {'id': 42, 'nome': 'Washington'},
          ],
          'totalElements': 1,
        },
        'response': {'error': false},
      };

      final dados = DadosUsuarioService.extrairDados(corpo);

      expect(dados?['id'], 42);
      expect(dados?['nome'], 'Washington');
    });

    test('aceita o corpo como texto JSON', () {
      const corpo = '{"data":{"dados":[{"id":7,"nome":"Ana"}]}}';

      expect(DadosUsuarioService.extrairDados(corpo)?['nome'], 'Ana');
    });

    test('resposta vazia ou fora do formato devolve null, sem lancar erro', () {
      expect(DadosUsuarioService.extrairDados({'data': {'dados': []}}), isNull);
      expect(DadosUsuarioService.extrairDados({'erro': true}), isNull);
      expect(DadosUsuarioService.extrairDados(null), isNull);
    });
  });
}
