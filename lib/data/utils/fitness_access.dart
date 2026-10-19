import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';

/// Gestão de alunos pertence ao personal, independentemente das permissões
/// compartilhadas de consulta a treinos.
bool podeGerenciarAlunos([LoginModel? sessao]) {
  final login = (sessao ?? AuthUtility.userInfo).login;
  if (login?.tipoLogin == LoginEnum.APP_ALUNO) return false;
  return login?.tipoLogin == LoginEnum.APP_PERSONAL ||
      (login?.roles?.any((r) => r.key == 'ROLE_PERSONAL') ?? false);
}

/// Financeiro da academia (mensalidades dos alunos matriculados) e exclusivo do login de academia.
bool ehAcademia([LoginModel? sessao]) {
  final login = (sessao ?? AuthUtility.userInfo).login;
  return login?.tipoLogin == LoginEnum.APP_ACADEMIA;
}
