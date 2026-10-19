import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/data/models/fitness/financeiro_academia_model.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/utils/fitness_access.dart';

void main() {
  group('FinanceiroAcademiaMes.fromMap', () {
    test('lê alunos, status e totais do servidor', () {
      final mes = FinanceiroAcademiaMes.fromMap({
        'mes': '2026-09',
        'alunos': [
          {
            'alunoId': 77,
            'nome': 'Ana',
            'telefone': '34999',
            'valor': 150.0,
            'diaVencimento': 10,
            'status': 'PAGO',
            'dataPagamento': '2026-09-08T10:00:00',
          },
          {'alunoId': 78, 'nome': 'Bia', 'valor': 90, 'diaVencimento': 20, 'status': 'ATRASADO'},
          {'alunoId': 79, 'nome': 'Caio', 'valor': 0, 'status': 'PENDENTE'},
        ],
        'totais': {'recebido': 150, 'pendente': 0, 'atrasado': 90},
      });

      expect(mes.mes, '2026-09');
      expect(mes.alunos.map((a) => a.nome), ['Ana', 'Bia', 'Caio']);
      expect(mes.alunos[0].pago, isTrue);
      expect(mes.alunos[1].status, StatusMensalidadeAcademia.atrasado);
      expect(mes.alunos[2].status, StatusMensalidadeAcademia.pendente);
      expect(mes.recebido, 150);
      expect(mes.atrasado, 90);
    });

    test('status desconhecido cai em pendente e dados ausentes viram zero', () {
      final aluno = FinanceiroAcademiaAluno.fromMap({'alunoId': 1, 'status': 'QUALQUER'});
      expect(aluno.status, StatusMensalidadeAcademia.pendente);
      expect(aluno.valor, 0);
      expect(aluno.diaVencimento, 10);
      expect(aluno.nome, '');
    });

    test('lista ausente nao quebra a tela', () {
      final mes = FinanceiroAcademiaMes.fromMap({'mes': '2026-09'});
      expect(mes.alunos, isEmpty);
      expect(mes.recebido, 0);
    });
  });

  group('ehAcademia', () {
    test('so o login de academia tem o financeiro da academia', () {
      expect(ehAcademia(LoginModel(login: Login(tipoLogin: LoginEnum.APP_ACADEMIA))), isTrue);
      expect(ehAcademia(LoginModel(login: Login(tipoLogin: LoginEnum.APP_PERSONAL))), isFalse);
      expect(ehAcademia(LoginModel(login: Login(tipoLogin: LoginEnum.APP_ALUNO))), isFalse);
      expect(ehAcademia(LoginModel()), isFalse);
    });
  });
}
