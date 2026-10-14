import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/utils/cadastro_personal_regras.dart';

void main() {
  group('CREF', () {
    test('monta no formato oficial e valida', () {
      expect(montarCref('12345', 'G', 'MG'), '012345-G/MG');
      expect(validarCref('12345', 'G', 'MG'), isNull);
      expect(validarCref('', 'G', 'MG'), 'Informe o número do CREF');
      expect(validarCref('12345', 'G', null), 'Escolha a UF do CREF');
      expect(validarCref('1234567', 'P', 'SP'), contains('Formato inválido'));
    });
  });

  group('WhatsApp', () {
    test('mascara, valida e gera DDI', () {
      expect(mascararCelular('34999990000'), '(34) 99999-0000');
      expect(validarWhatsapp('(34) 99999-0000'), isNull);
      expect(validarWhatsapp('(34) 3333-0000'), contains('celular'));
      expect(validarWhatsapp(''), 'Informe o WhatsApp');
      expect(whatsappComDdi('(34) 99999-0000'), '5534999990000');
    });
  });

  group('moeda e valor por aula', () {
    test('mascara pelos centavos e le o valor', () {
      expect(mascararMoeda('25000'), r'R$ 250,00');
      expect(mascararMoeda('123456'), r'R$ 1.234,56');
      expect(lerMoeda(r'R$ 1.234,56'), 1234.56);
      expect(lerMoeda(''), isNull);
    });

    test('valor por aula do plano', () {
      expect(valorPorAula(250, 8), 31.25);
      expect(valorPorAula(250, 0), isNull);
      expect(formatarMoeda(31.25), r'R$ 31,25');
    });
  });

  group('dias e horarios', () {
    test('resumo compacto dos dias', () {
      expect(resumoDias({0, 1, 2, 3, 4}), 'Seg–Sex');
      expect(resumoDias({0, 2, 4}), 'Seg, Qua, Sex');
      expect(resumoDias({0, 1, 2, 5}), 'Seg–Qua, Sáb');
      expect(resumoDias({5, 6}), 'Sáb, Dom');
    });

    test('faixa invalida sem dias ou com horario invertido', () {
      expect(validarFaixa({}, '06:00', '10:00'), 'Escolha pelo menos um dia');
      expect(validarFaixa({0}, '10:00', '06:00'), contains('depois'));
      expect(validarFaixa({0}, '06:00', '10:00'), isNull);
    });

    test('conflito de horario entre academias no mesmo dia', () {
      final smart = FaixaAtendimento(
          academiaId: 1, localNome: 'SmartFit', dias: {0, 2}, inicio: '06:00', fim: '10:00');
      final conflitante = FaixaAtendimento(
          academiaId: 2, localNome: 'Bodytech', dias: {2}, inicio: '09:00', fim: '11:00');
      final encostada = FaixaAtendimento(
          academiaId: 2, localNome: 'Bodytech', dias: {0}, inicio: '10:00', fim: '12:00');

      expect(conflitoFaixa(conflitante, [smart]), 'Conflito: Qua 06:00–10:00 já está em SmartFit');
      expect(conflitoFaixa(encostada, [smart]), isNull);
    });

    test('rascunho: faixa ida e volta e senha nunca salva', () {
      final f = FaixaAtendimento(
          academiaId: 153, localNome: 'SmartFit', dias: {4, 0}, inicio: '06:00', fim: '10:00');
      final volta = FaixaAtendimento.fromRascunho(f.toRascunho());
      expect(volta.toApi(), f.toApi());
      expect(volta.localNome, 'SmartFit');

      expect(limparRascunho({'nome': 'A', 'senha': 'x', 'confirmarSenha': 'x'}), {'nome': 'A'});
    });

    test('payload da API usa nomes completos dos dias', () {
      final f = FaixaAtendimento(
          academiaId: null, localNome: 'Online', dias: {4, 0}, inicio: '19:00', fim: '21:00');
      expect(f.toApi(), {
        'academiaId': null,
        'dias': ['Segunda-feira', 'Sexta-feira'],
        'inicio': '19:00',
        'fim': '21:00',
      });
      expect(f.resumo, 'Seg, Sex · 19:00–21:00');
    });
  });
}
