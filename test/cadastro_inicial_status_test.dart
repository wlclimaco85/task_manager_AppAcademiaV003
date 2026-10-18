import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/models/fitness/personal_gestao_model.dart';
import 'package:task_manager_flutter/data/services/cadastro_inicial_service.dart';

void main() {
  test('sem o campo do servidor o aluno nao vira alarme no personal', () {
    final aluno = PersonalAlunoGestaoModel.fromMap({
      'id': '1',
      'nome': 'Maria',
      'email': 'maria@exemplo.com',
      'telefone': '',
    });

    expect(aluno.cadastroInicialCompleto, isTrue);
  });

  test('cadastro incompleto do servidor marca o aluno com pendencia', () {
    final aluno = PersonalAlunoGestaoModel.fromMap({
      'id': '1',
      'nome': 'Maria',
      'email': 'maria@exemplo.com',
      'telefone': '',
      'cadastroInicialCompleto': false,
    });

    expect(aluno.cadastroInicialCompleto, isFalse);
    expect(aluno.copyWith(cadastroInicialCompleto: true).cadastroInicialCompleto, isTrue);
  });

  test('o cadastro inicial tem foto mais as 7 medidas', () {
    expect(CadastroInicialService.totalCampos, 8);
  });

  test('pendencias listam foto e medidas faltantes e somem quando completo', () {
    final vazio = CadastroInicialService.pendencias({});
    expect(vazio, hasLength(8));
    expect(vazio.first, 'Foto');

    final completo = <String, dynamic>{
      'foto': 'data:image/jpeg;base64,AAAA',
      for (final m in CadastroInicialService.medidas) m.chave: 10.0,
    };
    expect(CadastroInicialService.pendencias(completo), isEmpty);
  });
}
