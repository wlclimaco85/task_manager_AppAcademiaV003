import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/personal_conta_pagar_model.dart';
import 'package:task_manager_flutter/data/models/fitness/personal_pix_cobranca_model.dart';
import 'package:task_manager_flutter/data/services/agenda_repository.dart';
import 'package:task_manager_flutter/data/services/personal_gestao_offline_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. Contas a Pagar do Personal (Despesas Operacionais)', () {
    test('criação de conta a pagar, verificação de atraso e toMap/fromMap', () {
      final contaVencida = PersonalContaPagarModel(
        id: 'cp_1',
        descricao: 'Aluguel do Estúdio',
        categoria: CategoriaContaPagar.espacoAcademia,
        valor: 1200.0,
        dataVencimento: DateTime(2026, 10, 1),
        pago: false,
      );

      expect(contaVencida.pago, isFalse);
      expect(contaVencida.atrasado, isTrue);
      expect(contaVencida.categoria, CategoriaContaPagar.espacoAcademia);

      final map = contaVencida.toMap();
      final reconstruida = PersonalContaPagarModel.fromMap(map);

      expect(reconstruida.id, 'cp_1');
      expect(reconstruida.descricao, 'Aluguel do Estúdio');
      expect(reconstruida.valor, 1200.0);
      expect(reconstruida.pago, isFalse);
      expect(reconstruida.atrasado, isTrue);

      final contaPaga = contaVencida.copyWith(pago: true, dataPagamento: DateTime(2026, 10, 2));
      expect(contaPaga.pago, isTrue);
      expect(contaPaga.atrasado, isFalse);
    });

    test('repositório gerencia CRUD de contas a pagar offline', () async {
      final repo = PersonalGestaoOfflineRepository();
      final contasIniciais = await repo.getContasPagar();
      expect(contasIniciais.length, greaterThanOrEqualTo(1));

      final nova = PersonalContaPagarModel(
        id: 'cp_teste',
        descricao: 'Equipamentos Elásticos',
        categoria: CategoriaContaPagar.equipamentos,
        valor: 85.0,
        dataVencimento: DateTime(2026, 10, 25),
      );

      await repo.salvarContaPagar(nova);
      final contasAtualizadas = await repo.getContasPagar();
      expect(contasAtualizadas.any((c) => c.id == 'cp_teste'), isTrue);

      await repo.registrarPagamentoConta('cp_teste');
      final contasAposBaixa = await repo.getContasPagar();
      final contaBaixada = contasAposBaixa.firstWhere((c) => c.id == 'cp_teste');
      expect(contaBaixada.pago, isTrue);

      await repo.excluirContaPagar('cp_teste');
      final contasFinais = await repo.getContasPagar();
      expect(contasFinais.any((c) => c.id == 'cp_teste'), isFalse);
    });
  });

  group('2. Pix Copia e Cola & QR Code no Perfil do Personal', () {
    test('geração de payload BACEN padrão EMV Co/BR Code', () {
      final config = PersonalPixCobrancaModel(
        chavePix: '11999998888',
        tipoChavePix: TipoChavePix.telefone,
        nomeTitular: 'Carlos Personal',
        cidade: 'Sao Paulo',
        valorMensalidadePadrao: 250.0,
      );

      final payload = config.obterCodigoPixParaValor(valor: 250.0);
      expect(payload, startsWith('000201'));
      expect(payload, contains('BR.GOV.BCB.PIX'));
      expect(payload, contains('11999998888'));
      expect(payload, contains('CARLOS PERSONAL'));
      expect(payload, contains('250.00'));

      // Validação do formato final CRC16 (últimos 4 dígitos hexadecimais em maiúsculo)
      final crcPart = payload.substring(payload.length - 4);
      expect(RegExp(r'^[0-9A-F]{4}$').hasMatch(crcPart), isTrue);
    });

    test('salvamento e recuperação das configurações Pix no repositório', () async {
      final repo = PersonalGestaoOfflineRepository();
      final config = PersonalPixCobrancaModel(
        chavePix: 'carlos@personal.com',
        tipoChavePix: TipoChavePix.email,
        nomeTitular: 'Carlos Eduardo',
        cidade: 'Rio de Janeiro',
        valorMensalidadePadrao: 300.0,
      );

      await repo.salvarPixCobranca(config);
      final recuperado = await repo.getPixCobranca();
      expect(recuperado.chavePix, 'carlos@personal.com');
      expect(recuperado.tipoChavePix, TipoChavePix.email);
      expect(recuperado.nomeTitular, 'Carlos Eduardo');
      expect(recuperado.valorMensalidadePadrao, 300.0);
    });
  });

  group('3. Cancelamento de Aula pelo Aluno com Justificativa', () {
    test('AgendaRepository.cancelar grava motivo na observação e marca CANCELADO', () async {
      final repo = AgendaRepository();

      final eventosCriados = await repo.criar({
        'titulo': 'Musculação Hipertrofia',
        'tipo': 'AULA',
        'inicio': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'fim': DateTime.now().add(const Duration(days: 1, hours: 1)).toIso8601String(),
        'compartilhado': true,
        'alunoId': 'aluno_123',
        'alunoNome': 'Lucas Atleta',
        'status': 'AGENDADO',
      });
      expect(eventosCriados.isNotEmpty, isTrue);
      final eventoId = eventosCriados.first.id;

      // Aluno cancela com justificativa
      await repo.cancelar(eventoId, motivo: 'Imprevisto no trabalho, preciso remarcar');

      final eventosAposCancel = await repo.listar(
        DateTime.now().subtract(const Duration(days: 1)),
        DateTime.now().add(const Duration(days: 7)),
      );
      final cancelado = eventosAposCancel.firstWhere((e) => e.id == eventoId);
      expect(cancelado.cancelado, isTrue);
      expect(cancelado.status, 'CANCELADO');
      expect(cancelado.observacao, contains('Cancelado pelo aluno: Imprevisto no trabalho'));
    });
  });

  group('4. Ocultar Ficha de Treino do Aluno', () {
    test('personal ativa ocultação da ficha e repository reflete no aluno', () async {
      final repo = PersonalGestaoOfflineRepository();
      final alunos = await repo.getAlunos();
      if (alunos.isNotEmpty) {
        final primeiro = alunos.first;
        await repo.definirFichaOculta(alunoId: primeiro.id, oculta: true);

        final alunosAtualizados = await repo.getAlunos();
        final alunoModificado = alunosAtualizados.firstWhere((a) => a.id == primeiro.id);
        expect(alunoModificado.fichaOcultaParaAluno, isTrue);

        // Desfaz para manter idempotência
        await repo.definirFichaOculta(alunoId: primeiro.id, oculta: false);
        final alunosRestaurados = await repo.getAlunos();
        expect(alunosRestaurados.firstWhere((a) => a.id == primeiro.id).fichaOcultaParaAluno, isFalse);
      }
    });
  });
}
