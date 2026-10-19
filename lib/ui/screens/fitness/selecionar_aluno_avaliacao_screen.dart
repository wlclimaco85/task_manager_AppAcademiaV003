import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/fitness/personal_gestao_model.dart';
import 'package:task_manager_flutter/data/services/personal_gestao_offline_repository.dart';
import 'package:task_manager_flutter/ui/screens/fitness/avaliacao_fisica_pro_screen.dart';

/// Lista para o personal escolher de quem e a avaliacao fisica: a propria
/// (minha avaliacao) ou a de um aluno. Assim a avaliacao nao se mistura.
class SelecionarAlunoAvaliacaoScreen extends StatefulWidget {
  const SelecionarAlunoAvaliacaoScreen({super.key});

  @override
  State<SelecionarAlunoAvaliacaoScreen> createState() =>
      _SelecionarAlunoAvaliacaoScreenState();
}

class _SelecionarAlunoAvaliacaoScreenState extends State<SelecionarAlunoAvaliacaoScreen> {
  List<PersonalAlunoGestaoModel> _alunos = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final alunos = await PersonalGestaoOfflineRepository().getAlunos();
    if (!mounted) return;
    setState(() {
      _alunos = alunos;
      _carregando = false;
    });
  }

  /// [alunoId] vazio = avaliacao do proprio personal (nao depende de permissao de aluno).
  void _abrir(String rotulo, {String? alunoId}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AvaliacaoFisicaProScreen(alunoNome: rotulo, alunoId: alunoId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nomePersonal = AuthUtility.userInfo.login?.nome ?? 'Eu';
    return Scaffold(
      appBar: AppBar(title: const Text('Avaliação física — de quem?')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: CustomColors.primaryGreen,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text('Minha avaliação ($nomePersonal)'),
                    subtitle: const Text('Avaliação do próprio personal'),
                    onTap: () => _abrir('Eu ($nomePersonal)'),
                  ),
                ),
                const SizedBox(height: 8),
                for (final aluno in _alunos)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: CustomColors.primaryGreen.withValues(alpha: 0.2),
                        child: Text(
                          aluno.nome.isNotEmpty ? aluno.nome[0].toUpperCase() : 'A',
                          style: TextStyle(color: CustomColors.primaryGreen),
                        ),
                      ),
                      title: Text(aluno.nome),
                      subtitle: Text(aluno.objetivo),
                      onTap: () => _abrir(aluno.nome, alunoId: aluno.id),
                    ),
                  ),
                if (_alunos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text('Nenhum aluno cadastrado ainda.', textAlign: TextAlign.center),
                  ),
              ],
            ),
    );
  }
}
