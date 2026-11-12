import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/fitness/dashboard_aluno_model.dart';
import 'package:task_manager_flutter/data/services/dashboard_aluno_service.dart';
import 'package:task_manager_flutter/data/services/dashboard_layout_preferencia.dart';
import 'package:task_manager_flutter/ui/screens/fitness/dashboard_novo_conteudo.dart';
import 'package:task_manager_flutter/ui/screens/fitness/dashboard_novo_widgets.dart';

const _meses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

/// Dashboard do proprio aluno: treinos, dias sem treinar, ficha e evolucao de carga.
class DashboardAlunoScreen extends StatefulWidget {
  const DashboardAlunoScreen({super.key, this.carregar});

  /// Permite injetar a leitura nos testes. Sem ele, usa o servico real.
  final Future<DashboardAlunoModel> Function(String mes)? carregar;

  @override
  State<DashboardAlunoScreen> createState() => _DashboardAlunoScreenState();
}

class _DashboardAlunoScreenState extends State<DashboardAlunoScreen> {
  late DateTime _mes;
  late Future<DashboardAlunoModel> _future;
  DashboardLayout _layout = DashboardLayout.novo;

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    _mes = DateTime(agora.year, agora.month);
    _future = _buscar();
    DashboardLayoutPreferencia.carregar().then((layout) {
      if (mounted) setState(() => _layout = layout);
    });
  }

  String get _mesIso => '${_mes.year}-${_mes.month.toString().padLeft(2, '0')}';

  Future<DashboardAlunoModel> _buscar() {
    final leitura = widget.carregar ?? (mes) => DashboardAlunoService.carregar(mes: mes);
    return leitura(_mesIso);
  }

  void _trocarMes(int deslocamento) {
    setState(() {
      _mes = DateTime(_mes.year, _mes.month + deslocamento);
      _future = _buscar();
    });
  }

  void _trocarLayout(DashboardLayout layout) {
    setState(() => _layout = layout);
    DashboardLayoutPreferencia.salvar(layout);
  }

  Future<void> _recarregar() async {
    final novo = _buscar();
    setState(() => _future = novo);
    try {
      await novo;
    } catch (_) {
      // O FutureBuilder ja mostra o erro e o botao de tentar novamente.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu dashboard'),
        actions: [DashboardLayoutBotao(atual: _layout, onMudou: _trocarLayout)],
      ),
      body: RefreshIndicator(
        onRefresh: _recarregar,
        child: FutureBuilder<DashboardAlunoModel>(
          future: _future,
          builder: (context, snapshot) {
            final seletor = _SeletorMesAluno(
              rotulo: '${_meses[_mes.month - 1]} de ${_mes.year}',
              onAnterior: () => _trocarMes(-1),
              onProximo: () => _trocarMes(1),
            );
            if (snapshot.connectionState != ConnectionState.done) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [seletor, const SizedBox(height: 48), const Center(child: CircularProgressIndicator())],
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  seletor,
                  const SizedBox(height: 32),
                  Text(_mensagemErro(snapshot.error), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Center(
                    child: FilledButton.icon(
                      onPressed: _recarregar,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ),
                ],
              );
            }
            final modelo = snapshot.data!;
            if (_layout == DashboardLayout.novo) {
              return DashboardNovoAluno(modelo: modelo, cabecalho: seletor);
            }
            return _VisaoClassica(modelo: modelo, seletor: seletor);
          },
        ),
      ),
    );
  }

  String _mensagemErro(Object? erro) {
    final texto = erro?.toString().replaceFirst('Exception: ', '') ?? '';
    return texto.isEmpty ? 'Não foi possível carregar o seu dashboard.' : texto;
  }
}

/// Layout clássico do aluno: lista simples dos mesmos indicadores.
class _VisaoClassica extends StatelessWidget {
  const _VisaoClassica({required this.modelo, required this.seletor});

  final DashboardAlunoModel modelo;
  final Widget seletor;

  @override
  Widget build(BuildContext context) {
    final ficha = modelo.ficha;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        seletor,
        ListTile(title: const Text('Treinos no mês'), trailing: Text('${modelo.treinosNoMes}')),
        ListTile(title: const Text('Dias treinados'), trailing: Text('${modelo.diasTreinadosNoMes}')),
        ListTile(title: const Text('Últimos 7 dias'), trailing: Text('${modelo.treinosUltimos7Dias}')),
        ListTile(
          title: const Text('Dias sem treinar'),
          trailing: Text(modelo.diasSemTreinar == null ? '—' : '${modelo.diasSemTreinar}'),
        ),
        const Divider(),
        ListTile(
          title: const Text('Minha ficha'),
          subtitle: Text(ficha == null
              ? 'Você ainda não tem uma ficha ativa.'
              : '${ficha.titulo} · ${ficha.diasParaVencer == null ? 'sem validade' : 'vence em ${ficha.diasParaVencer} dia(s)'}'),
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('Evolução de carga (30 dias)', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        if (modelo.evolucaoCargas.isEmpty)
          const Text('Ainda não há aumento de carga nos últimos 30 dias.')
        else
          for (final e in modelo.evolucaoCargas)
            ListTile(
              title: Text(e.exercicio),
              subtitle: Text('${e.cargaAnteriorKg.toStringAsFixed(1)} kg → ${e.cargaAtualKg.toStringAsFixed(1)} kg'),
              trailing: Text('+${e.variacaoPct.toStringAsFixed(1)}%'),
            ),
      ],
    );
  }
}

class _SeletorMesAluno extends StatelessWidget {
  const _SeletorMesAluno({required this.rotulo, required this.onAnterior, required this.onProximo});

  final String rotulo;
  final VoidCallback onAnterior;
  final VoidCallback onProximo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: onAnterior, icon: const Icon(Icons.chevron_left), tooltip: 'Mês anterior'),
        Text(rotulo, style: Theme.of(context).textTheme.titleMedium),
        IconButton(onPressed: onProximo, icon: const Icon(Icons.chevron_right), tooltip: 'Próximo mês'),
      ],
    );
  }
}
