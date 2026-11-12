import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/fitness/dashboard_aluno_model.dart';
import 'package:task_manager_flutter/data/models/fitness/dashboard_fitness_model.dart';
import 'package:task_manager_flutter/ui/screens/fitness/dashboard_novo_widgets.dart';

/// Conteudo do layout novo para personal e academia. Mesmo dado, indicadores diferentes por papel:
/// o personal enxerga os alunos vinculados e as fichas; a academia enxerga matriculados e frequencia.
class DashboardNovoPersonalAcademia extends StatelessWidget {
  const DashboardNovoPersonalAcademia({super.key, required this.modelo, required this.academia, this.cabecalho});

  final DashboardFitnessModel modelo;
  final bool academia;

  /// Seletor de mes exibido acima dos indicadores.
  final Widget? cabecalho;

  @override
  Widget build(BuildContext context) {
    final r = modelo.resumo;
    final inativos = (r.totalAlunos - r.ativosUltimos30Dias).clamp(0, r.totalAlunos);
    final frequenciaMedia = r.frequenciaMediaPct == null ? '—' : '${r.frequenciaMediaPct!.toStringAsFixed(1)}%';
    final primeiroNome = modelo.frequencia.isEmpty ? '' : _primeiroNome(modelo.frequencia.first.nome);
    final ultimoNome = modelo.frequencia.isEmpty ? '' : _primeiroNome(modelo.frequencia.last.nome);

    final kpis = academia
        ? [
            DashboardKpi(rotulo: 'Matriculados', valor: '${r.totalAlunos}'),
            DashboardKpi(rotulo: 'Ativos (30 dias)', valor: '${r.ativosUltimos30Dias}', destaque: true),
            DashboardKpi(rotulo: 'Inativos (30 dias)', valor: '$inativos'),
            DashboardKpi(rotulo: 'Sem ficha', valor: '${r.semFicha}'),
            DashboardKpi(rotulo: 'Frequência média', valor: frequenciaMedia),
            DashboardKpi(rotulo: 'Evoluindo', valor: '${r.evoluindo}'),
          ]
        : [
            DashboardKpi(rotulo: 'Alunos vinculados', valor: '${r.totalAlunos}'),
            DashboardKpi(rotulo: 'Ativos (30 dias)', valor: '${r.ativosUltimos30Dias}', destaque: true),
            DashboardKpi(rotulo: 'Sem ficha', valor: '${r.semFicha}'),
            DashboardKpi(rotulo: 'Trocar ficha (7 dias)', valor: '${r.proximosTrocaFicha}'),
            DashboardKpi(rotulo: 'Frequência média', valor: frequenciaMedia),
            DashboardKpi(rotulo: 'Evoluindo', valor: '${r.evoluindo}'),
          ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (cabecalho != null) ...[cabecalho!, const SizedBox(height: 12)],
        DashboardNovoKpis(kpis: kpis),
        DashboardNovoCard(
          titulo: academia ? 'Alunos ativos x inativos (30 dias)' : 'Meus alunos ativos x inativos (30 dias)',
          child: DashboardNovoRosca(
            parte: r.ativosUltimos30Dias,
            total: r.totalAlunos,
            rotuloParte: 'ativos',
            rotuloTotal: academia ? 'matriculados' : 'alunos',
          ),
        ),
        DashboardNovoCard(
          titulo: 'Frequência por aluno (% da contratada)',
          child: DashboardNovoBarras(
            valores: [for (final a in modelo.frequencia.take(12)) a.percentual ?? 0],
            rotulos: modelo.frequencia.isEmpty ? null : [primeiroNome, ultimoNome],
          ),
        ),
        if (academia) ...[
          DashboardNovoCard(
            titulo: 'Melhor desempenho do mês',
            child: modelo.melhorDesempenho.isEmpty
                ? const DashboardNovoVazio('Ainda não há treinos concluídos neste mês.')
                : Column(children: [
                    for (final a in modelo.melhorDesempenho)
                      DashboardNovoLinha(
                        titulo: a.nome,
                        subtitulo: '${a.treinosNoMes ?? 0} treino(s) no mês',
                        detalhe: a.percentual == null ? null : '${a.percentual!.toStringAsFixed(0)}%',
                      ),
                  ]),
          ),
          DashboardNovoCard(
            titulo: 'Abaixo da frequência contratada',
            child: modelo.frequencia.isEmpty
                ? const DashboardNovoVazio('Nenhum aluno com frequência contratada.')
                : Column(children: [
                    for (final a in modelo.frequencia.take(5))
                      DashboardNovoLinha(
                        titulo: a.nome,
                        subtitulo: '${a.treinosNoMes ?? 0} de ${a.frequenciaContratada ?? 0} por semana',
                        detalhe: '${a.percentual?.toStringAsFixed(0) ?? '0'}%',
                      ),
                  ]),
          ),
        ] else ...[
          DashboardNovoCard(
            titulo: 'Próximos de trocar a ficha (7 dias)',
            child: modelo.proximosTrocaFicha.isEmpty
                ? const DashboardNovoVazio('Nenhuma ficha vence nos próximos 7 dias.')
                : Column(children: [
                    for (final a in modelo.proximosTrocaFicha)
                      DashboardNovoLinha(
                        titulo: a.nome,
                        subtitulo: '${a.treino ?? ''} · vence ${_dataBr(a.vencimento)}',
                        detalhe: _textoDias(a.diasRestantes),
                      ),
                  ]),
          ),
          DashboardNovoCard(
            titulo: 'Ranking do mês',
            child: modelo.rankingMes.isEmpty
                ? const DashboardNovoVazio('Nenhum treino concluído neste mês.')
                : Column(children: [
                    for (final a in modelo.rankingMes.take(5))
                      DashboardNovoLinha(
                        titulo: '${a.posicao ?? ''}. ${a.nome}',
                        detalhe: '${a.treinosNoMes ?? 0} treino(s)',
                      ),
                  ]),
          ),
        ],
        DashboardNovoCard(
          titulo: 'Sem ficha ativa',
          child: modelo.semFicha.isEmpty
              ? const DashboardNovoVazio('Todos os alunos têm ficha ativa.')
              : Column(children: [
                  for (final a in modelo.semFicha) DashboardNovoLinha(titulo: a.nome),
                ]),
        ),
      ],
    );
  }

  static String _primeiroNome(String nome) => nome.trim().split(' ').first;

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

/// Conteudo do layout novo para o aluno: os proprios treinos, ficha e evolucao de carga.
class DashboardNovoAluno extends StatelessWidget {
  const DashboardNovoAluno({super.key, required this.modelo, this.cabecalho});

  final DashboardAlunoModel modelo;

  /// Seletor de mes exibido acima dos indicadores.
  final Widget? cabecalho;

  @override
  Widget build(BuildContext context) {
    final ficha = modelo.ficha;
    final diasNoMes = modelo.treinosPorDia.length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (cabecalho != null) ...[cabecalho!, const SizedBox(height: 12)],
        DashboardNovoKpis(kpis: [
          DashboardKpi(rotulo: 'Treinos no mês', valor: '${modelo.treinosNoMes}', destaque: true),
          DashboardKpi(rotulo: 'Dias treinados', valor: '${modelo.diasTreinadosNoMes}'),
          DashboardKpi(rotulo: 'Últimos 7 dias', valor: '${modelo.treinosUltimos7Dias}'),
          DashboardKpi(
              rotulo: 'Dias sem treinar',
              valor: modelo.diasSemTreinar == null ? '—' : '${modelo.diasSemTreinar}'),
        ]),
        DashboardNovoCard(
          titulo: 'Treinos por dia',
          child: DashboardNovoBarras(
            valores: [for (final t in modelo.treinosPorDia) t.toDouble()],
            rotulos: diasNoMes == 0 ? null : ['1', '$diasNoMes'],
          ),
        ),
        DashboardNovoCard(
          titulo: 'Minha ficha',
          child: ficha == null
              ? const DashboardNovoVazio('Você ainda não tem uma ficha ativa.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ficha.titulo.isEmpty ? 'Ficha ativa' : ficha.titulo,
                        style: const TextStyle(color: DashboardNovoPaleta.preto, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(_textoVencimento(ficha.diasParaVencer, ficha.dataValidade),
                        style: const TextStyle(color: DashboardNovoPaleta.cinza, fontSize: 12)),
                  ],
                ),
        ),
        DashboardNovoCard(
          titulo: 'Evolução de carga (30 dias)',
          child: modelo.evolucaoCargas.isEmpty
              ? const DashboardNovoVazio('Ainda não há aumento de carga nos últimos 30 dias.')
              : Column(children: [
                  for (final e in modelo.evolucaoCargas)
                    DashboardNovoLinha(
                      titulo: e.exercicio,
                      subtitulo: '${e.cargaAnteriorKg.toStringAsFixed(1)} kg → ${e.cargaAtualKg.toStringAsFixed(1)} kg',
                      detalhe: '+${e.variacaoPct.toStringAsFixed(1)}%',
                    ),
                ]),
        ),
        DashboardNovoCard(
          titulo: 'Último treino',
          child: Text(
            modelo.ultimoTreino == null
                ? 'Você ainda não concluiu nenhum treino.'
                : '${_dataBr(modelo.ultimoTreino)} · ${modelo.diasSemTreinar ?? 0} dia(s) atrás',
            style: const TextStyle(color: DashboardNovoPaleta.preto, fontSize: 13),
          ),
        ),
      ],
    );
  }

  static String _textoVencimento(int? dias, String? iso) {
    if (dias == null) return 'Sem data de validade.';
    final data = _dataBr(iso);
    if (dias < 0) return 'Vencida há ${-dias} dia(s) ($data).';
    if (dias == 0) return 'Vence hoje ($data).';
    return 'Vence em $dias dia(s) ($data).';
  }

  static String _dataBr(String? iso) {
    final partes = (iso ?? '').split('-');
    if (partes.length != 3) return iso ?? '';
    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }
}
