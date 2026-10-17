import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/services/permissoes_aluno_service.dart';
import 'package:task_manager_flutter/data/services/preferencia_tema_service.dart';
import 'package:task_manager_flutter/data/utils/fitness_access.dart';

/// Privacidade e aparencia do usuario. O aluno ve e altera o que o personal pode acompanhar;
/// todos escolhem o tema (padrao, branco ou preto).
class PrivacidadeAparenciaScreen extends StatefulWidget {
  const PrivacidadeAparenciaScreen({super.key});

  @override
  State<PrivacidadeAparenciaScreen> createState() => _PrivacidadeAparenciaScreenState();
}

class _PrivacidadeAparenciaScreenState extends State<PrivacidadeAparenciaScreen> {
  /// null = ainda carregando (ou nao se aplica). Preenchido so para aluno.
  Map<String, bool>? _privacidade;
  bool _salvando = false;
  bool _falhouCarregar = false;

  static const Map<String, String> _rotulosPrivacidade = {
    'dieta': 'Dieta',
    'suplementacao': 'Suplementação',
    'avaliacoes': 'Avaliações físicas',
    'metas': 'Metas e evolução do corpo',
  };

  static const Map<TemaApp, String> _rotulosTema = {
    TemaApp.padrao: 'Padrão (visual atual)',
    TemaApp.branco: 'Branco',
    TemaApp.preto: 'Preto',
  };

  bool get _ehAluno => !podeGerenciarAlunos(AuthUtility.userInfo);

  @override
  void initState() {
    super.initState();
    if (_ehAluno) _carregarPrivacidade();
  }

  Future<void> _carregarPrivacidade() async {
    final estado = await PermissoesAlunoService.meu();
    if (!mounted) return;
    if (estado == null) {
      setState(() => _falhouCarregar = true);
      return;
    }
    setState(() => _privacidade = estado.permissoes);
  }

  Future<void> _salvarPrivacidade() async {
    final escolhas = _privacidade;
    if (escolhas == null) return;
    setState(() => _salvando = true);
    final ok = await PermissoesAlunoService.responder({
      for (final area in PermissoesAlunoService.areasOpcionais) area: escolhas[area] == true,
    });
    if (!mounted) return;
    setState(() => _salvando = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: ok ? CustomColors.primaryGreen : null,
      content: Text(ok
          ? 'Privacidade atualizada.'
          : 'Não foi possível salvar agora. Tente de novo com conexão.'),
    ));
  }

  Widget _secaoAparencia() {
    return ValueListenableBuilder<TemaApp>(
      valueListenable: PreferenciaTema.tema,
      builder: (context, tema, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aparência', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          for (final opcao in TemaApp.values)
            RadioListTile<TemaApp>(
              key: Key('tema_${opcao.name}'),
              contentPadding: EdgeInsets.zero,
              title: Text(_rotulosTema[opcao] ?? opcao.name),
              value: opcao,
              groupValue: tema,
              onChanged: (escolha) {
                if (escolha != null) PreferenciaTema.definir(escolha);
              },
            ),
        ],
      ),
    );
  }

  Widget _secaoPrivacidade() {
    final escolhas = _privacidade;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Privacidade', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        const Text('Escolha o que o seu personal pode acompanhar. Você pode mudar quando quiser.'),
        const SwitchListTile(
          key: Key('privacidade_treino'),
          contentPadding: EdgeInsets.zero,
          title: Text('Treinos'),
          subtitle: Text('Obrigatório: o personal monta e acompanha seus treinos.'),
          value: true,
          onChanged: null,
        ),
        for (final area in PermissoesAlunoService.areasOpcionais)
          SwitchListTile(
            key: Key('privacidade_$area'),
            contentPadding: EdgeInsets.zero,
            title: Text(_rotulosPrivacidade[area] ?? area),
            value: escolhas?[area] == true,
            onChanged: (escolhas == null || _salvando)
                ? null
                : (valor) => setState(() => _privacidade = {...escolhas, area: valor}),
          ),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('privacidade_salvar'),
          onPressed: (escolhas == null || _salvando) ? null : _salvarPrivacidade,
          child: Text(_salvando ? 'Salvando...' : 'Salvar privacidade'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidade e aparência')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _secaoAparencia(),
              if (_ehAluno) ...[
                const SizedBox(height: 28),
                if (_falhouCarregar)
                  const Text('Não foi possível carregar sua privacidade. Verifique a conexão.')
                else if (_privacidade == null)
                  const Center(child: CircularProgressIndicator())
                else
                  _secaoPrivacidade(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
