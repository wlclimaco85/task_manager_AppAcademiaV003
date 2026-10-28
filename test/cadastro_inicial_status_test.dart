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

  test('o cadastro inicial tem fotos por regiao e medidas laterais', () {
    expect(CadastroInicialService.totalCampos, CadastroInicialService.medidas.length + CadastroInicialService.fotos.length);
  });

  test('pendencias listam foto e medidas faltantes e somem quando completo', () {
    final vazio = CadastroInicialService.pendencias({});
    expect(vazio, hasLength(CadastroInicialService.totalCampos));
    expect(vazio.first, 'Foto: Cintura');

    final completo = <String, dynamic>{
      'fotos': {for (final foto in CadastroInicialService.fotos) foto.chave: 'data:image/jpeg;base64,AAAA'},
      for (final m in CadastroInicialService.medidas) m.chave: 10.0,
    };
    expect(CadastroInicialService.pendencias(completo), isEmpty);
  });
}
