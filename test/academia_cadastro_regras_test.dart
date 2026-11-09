import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/utils/academia_cadastro_regras.dart';

void main() {
  test('CNPJ com digitos verificadores validos passa e os invalidos sao recusados', () {
    expect(AcademiaCadastroRegras.cnpjOpcional('11.222.333/0001-81'), isNull);
    expect(AcademiaCadastroRegras.cnpjOpcional('11.222.333/0001-82'), 'CNPJ invalido');
    expect(AcademiaCadastroRegras.cnpjOpcional('11111111111111'), 'CNPJ invalido');
    expect(AcademiaCadastroRegras.cnpjOpcional(''), isNull);
  });

  test('nome da academia e obrigatorio', () {
    expect(AcademiaCadastroRegras.nomeObrigatorio('  '), 'Informe o nome da academia');
    expect(AcademiaCadastroRegras.nomeObrigatorio('Academia X'), isNull);
  });

  test('UF e CEP sao opcionais, mas quando preenchidos precisam ser validos', () {
    expect(AcademiaCadastroRegras.ufOpcional(''), isNull);
    expect(AcademiaCadastroRegras.ufOpcional('mg'), isNull);
    expect(AcademiaCadastroRegras.ufOpcional('XX'), 'UF invalida');
    expect(AcademiaCadastroRegras.cepOpcional('38400-000'), isNull);
    expect(AcademiaCadastroRegras.cepOpcional('3840'), 'CEP deve ter 8 digitos');
  });

  test('horario exige HH:mm e fechamento depois da abertura', () {
    expect(AcademiaCadastroRegras.horario('06:00', '22:30'), isNull);
    expect(AcademiaCadastroRegras.horario('22:00', '06:00'), 'O fechamento deve ser depois da abertura');
    expect(AcademiaCadastroRegras.horario('8:00', '18:00'), 'Use o formato HH:mm');
    expect(AcademiaCadastroRegras.horario('08:00', '08:00'), 'O fechamento deve ser depois da abertura');
  });

  test('valor do plano aceita virgula e recusa negativo ou vazio', () {
    expect(AcademiaCadastroRegras.valorPlano('99,90'), isNull);
    expect(AcademiaCadastroRegras.valorPlano('-1'), 'Informe um valor valido');
    expect(AcademiaCadastroRegras.valorPlano(''), 'Informe um valor valido');
  });

  test('nome do plano e obrigatorio', () {
    expect(AcademiaCadastroRegras.nomePlano(''), 'Informe o nome do plano');
    expect(AcademiaCadastroRegras.nomePlano('Mensal'), isNull);
  });
}
