import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/fitness/dashboard_fitness_model.dart';
import 'package:task_manager_flutter/data/services/dashboard_fitness_service.dart';

const _meses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

/// Dashboard do personal (alunos vinculados) ou da academia (alunos matriculados).
class DashboardFitnessScreen extends StatefulWidget {
  const DashboardFitnessScreen({super.key, required this.academia, this.carregar});

  final bool academia;

  /// Permite injetar a leitura nos testes. Sem ele, usa o servico real.
  final Future<DashboardFitnessModel> Function(bool academia, String mes)? carregar;

  @override
  State<DashboardFitnessScreen> createState() => _DashboardFitnessScreenState();
}

class _DashboardFitnessScreenState extends State<DashboardFitnessScreen> {
  late DateTime _mes;
  late Future<DashboardFitnessModel> _future;

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    _mes = DateTime(agora.year, agora.month);
    _future = _buscar();
  }

  String get _mesIso => '${_mes.year}-${_mes.month.toString().padLeft(2, '0')}';

  Future<DashboardFitnessModel> _buscar() {
    final leitura = widget.carregar ?? DashboardFitnessService.carregar;
    return leitura(widget.academia, _mesIso);
  }

  void _trocarMes(int deslocamento) {
    setState(() {
      _mes = DateTime(_mes.year, _mes.month + deslocamento);
      _future = _buscar();
    });
  }

  Future<void> _recarregar() async {
    final novo = _buscar();
    setState(() {
      _future = novo;
    });
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
        title: Text(widget.academia ? 'Dashboard da academia' : 'Dashboard do personal'),
      ),
      body: RefreshIndicator(
        onRefresh: _recarregar,
        child: FutureBuilder<DashboardFitnessModel>(
          future: _future,
          builder: (context, snapshot) {
            final seletor = _SeletorMes(
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
                  Text(
                    _mensagemErro(snapshot.error),
                    textAlign: TextAlign.center,
                  ),
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
            return _Conteudo(modelo: snapshot.data!, seletor: seletor);
          },
        ),
      ),
    );
  }

  String _mensagemErro(Object? erro) {
    final texto = erro?.toString().replaceFirst('Exception: ', '') ?? '';
    return texto.isEmpty ? 'Não foi possível carregar o dashboard.' : texto;
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.modelo, required this.seletor});

  final DashboardFitnessModel modelo;
  final Widget seletor;

  @override
  Widget build(BuildContext context) {
    final r = modelo.resumo;
    final frequenciaMedia = r.frequenciaMediaPct == null ? '—' : '${r.frequenciaMediaPct!.toStringAsFixed(1)}%';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        seletor,
        const SizedBox(height: 12),
        Text('${r.totalAlunos} aluno(s) no total', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Indicador(rotulo: 'Ativos (30 dias)', valor: '${r.ativosUltimos30Dias}'),
            _Indicador(rotulo: 'Sem ficha', valor: '${r.semFicha}'),
            _Indicador(rotulo: 'Trocar ficha (7 dias)', valor: '${r.proximosTrocaFicha}'),
            _Indicador(rotulo: 'Evoluindo', valor: '${r.evoluindo}'),
            _Indicador(rotulo: 'Frequência média', valor: frequenciaMedia),
          ],
        ),
        const SizedBox(height: 20),
        _Secao(
          titulo: 'Sem ficha',
          vazio: 'Todos os alunos têm ficha ativa.',
          itens: [
            for (final a in modelo.semFicha) ListTile(title: Text(a.nome)),
          ],
        ),
        _Secao(
          titulo: 'Próximos de trocar a ficha',
          vazio: 'Nenhuma ficha vence nos próximos 7 dias.',
          itens: [
            for (final a in modelo.proximosTrocaFicha)
              ListTile(
                title: Text(a.nome),
                subtitle: Text('${a.treino ?? ''} · vence ${_dataBr(a.vencimento)}'),
                trailing: Text(_textoDias(a.diasRestantes)),
              ),
          ],
        ),
        _Secao(
          titulo: 'Evoluindo (carga, últimos 30 dias)',
          vazio: 'Nenhum aluno com aumento de carga no período.',
          itens: [
            for (final a in modelo.evoluindo)
              ListTile(
                title: Text(a.nome),
                subtitle: Text('${_kg(a.cargaAnteriorKg)} → ${_kg(a.cargaAtualKg)}'),
                trailing: Text('+${a.variacaoPct?.toStringAsFixed(1) ?? '0'}%'),
              ),
          ],
        ),
        _Secao(
          titulo: 'Ranking do mês',
          vazio: 'Nenhum treino concluído neste mês.',
          itens: [
            for (final a in modelo.rankingMes)
              ListTile(
                leading: CircleAvatar(child: Text('${a.posicao ?? ''}')),
                title: Text(a.nome),
                trailing: Text('${a.treinosNoMes ?? 0} treino(s)'),
              ),
          ],
        ),
        _Secao(
          titulo: 'Melhor desempenho',
          vazio: 'Ainda não há treinos concluídos neste mês.',
          itens: [
            for (final a in modelo.melhorDesempenho)
              ListTile(
                title: Text(a.nome),
                trailing: Text(a.percentual == null ? '${a.treinosNoMes ?? 0} treino(s)' : '${a.percentual}%'),
              ),
          ],
        ),
        _Secao(
          titulo: 'Frequência vs contratada',
          vazio: 'Nenhum aluno com frequência contratada.',
          itens: [
            for (final a in modelo.frequencia)
              ListTile(
                title: Text(a.nome),
                subtitle: Text('${a.treinosNoMes ?? 0} de ${a.frequenciaContratada ?? 0} por semana'),
                trailing: Text('${a.percentual}%'),
              ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  static String _kg(double? valor) => valor == null ? '—' : '${valor.toStringAsFixed(1)} kg';

  static String _textoDias(int? dias) {
    if (dias == null) return '';
    if (dias < 0) return 'vencida há ${-dias} dia(s)';
    if (dias == 0) return 'vence hoje';
    return 'em $dias dia(s)';
  }

  static String _dataBr(String? iso) {
    final partes = (iso ?? '').split('-');
    if (partes.length != 3) return iso ?? '';
    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }
}

class _SeletorMes extends StatelessWidget {
  const _SeletorMes({required this.rotulo, required this.onAnterior, required this.onProximo});

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

class _Indicador extends StatelessWidget {
  const _Indicador({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme;
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valor, style: Theme.of(context).textTheme.headlineSmall),
          Text(rotulo, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao({required this.titulo, required this.vazio, required this.itens});

  final String titulo;
  final String vazio;
  final List<Widget> itens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          if (itens.isEmpty) Text(vazio, style: Theme.of(context).textTheme.bodySmall) else ...itens,
        ],
      ),
    );
  }
}
