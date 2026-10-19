import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/fitness/financeiro_academia_model.dart';
import 'package:task_manager_flutter/data/services/financeiro_academia_service.dart';

/// Valor e dia de vencimento digitados no diálogo. Null = entrada invalida.
typedef MensalidadeInformada = ({double valor, int dia});

/// Interpreta o valor (aceita virgula) e o dia de vencimento (1 a 31).
/// Devolve null quando algum campo nao e valido.
MensalidadeInformada? interpretarMensalidade(String valorTexto, String diaTexto) {
  final valor = double.tryParse(valorTexto.trim().replaceAll(',', '.'));
  final dia = int.tryParse(diaTexto.trim());
  if (valor == null || valor < 0) return null;
  if (dia == null || dia < 1 || dia > 31) return null;
  return (valor: valor, dia: dia);
}

/// Financeiro da academia: quem pagou e quem esta pendente ou atrasado no mes.
class FinanceiroAcademiaScreen extends StatefulWidget {
  const FinanceiroAcademiaScreen({super.key});

  @override
  State<FinanceiroAcademiaScreen> createState() => _FinanceiroAcademiaScreenState();
}

class _FinanceiroAcademiaScreenState extends State<FinanceiroAcademiaScreen> {
  static const _meses = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];

  late DateTime _referencia;
  FinanceiroAcademiaMes? _dados;
  bool _carregando = true;
  final Set<String> _baixaEmAndamento = {};

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    _referencia = DateTime(agora.year, agora.month);
    _carregar();
  }

  String get _mesChave => '${_referencia.year}-${_referencia.month.toString().padLeft(2, '0')}';

  String get _mesRotulo => '${_meses[_referencia.month - 1]} de ${_referencia.year}';

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final dados = await FinanceiroAcademiaService.buscar(_mesChave);
    if (!mounted) return;
    if (dados == null) {
      _mostrarErro('Não foi possível carregar o financeiro agora. Tente novamente.');
    }
    setState(() {
      _dados = dados;
      _carregando = false;
    });
  }

  void _mudarMes(int deslocamento) {
    setState(() {
      _referencia = DateTime(_referencia.year, _referencia.month + deslocamento);
      _dados = null;
    });
    _carregar();
  }

  Future<void> _alternarBaixa(FinanceiroAcademiaAluno aluno) async {
    if (_baixaEmAndamento.contains(aluno.alunoId)) return;
    setState(() => _baixaEmAndamento.add(aluno.alunoId));
    final ok = await FinanceiroAcademiaService.darBaixa(
      mes: _mesChave,
      alunoId: aluno.alunoId,
      pago: !aluno.pago,
    );
    if (!mounted) return;
    setState(() => _baixaEmAndamento.remove(aluno.alunoId));
    if (!ok) {
      _mostrarErro('Não foi possível registrar a baixa de ${aluno.nome}. Tente novamente.');
      return;
    }
    await _carregar();
  }

  Future<void> _editarMensalidade(FinanceiroAcademiaAluno aluno) async {
    final valorCtrl = TextEditingController(text: aluno.valor.toStringAsFixed(2).replaceAll('.', ','));
    final diaCtrl = TextEditingController(text: aluno.diaVencimento.toString());
    final informado = await showDialog<MensalidadeInformada>(
      context: context,
      builder: (context) {
        String? erro;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('Mensalidade de ${aluno.nome}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: valorCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Valor (R\$)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: diaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Dia de vencimento (1 a 31)',
                    border: const OutlineInputBorder(),
                    errorText: erro,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: CustomColors.primaryGreen),
                onPressed: () {
                  final resultado = interpretarMensalidade(valorCtrl.text, diaCtrl.text);
                  if (resultado == null) {
                    setDialogState(() => erro = 'Informe um valor válido e um dia entre 1 e 31');
                    return;
                  }
                  Navigator.pop(context, resultado);
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
        );
      },
    );
    valorCtrl.dispose();
    diaCtrl.dispose();
    if (informado == null || !mounted) return;

    final ok = await FinanceiroAcademiaService.darBaixa(
      mes: _mesChave,
      alunoId: aluno.alunoId,
      pago: aluno.pago,
      valor: informado.valor,
      diaVencimento: informado.dia,
    );
    if (!mounted) return;
    if (!ok) {
      _mostrarErro('Não foi possível salvar a mensalidade de ${aluno.nome}. Tente novamente.');
      return;
    }
    await _carregar();
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensagem),
      backgroundColor: GridColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financeiro da academia')),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _seletorMes(),
            const SizedBox(height: 16),
            if (_carregando && _dados == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_dados != null) ...[
              _totais(_dados!),
              const SizedBox(height: 16),
              if (_dados!.alunos.isEmpty)
                Text(
                  'Nenhum aluno matriculado nesta academia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: GridColors.textSecondary),
                )
              else
                for (final aluno in _dados!.alunos) _cardAluno(aluno),
            ],
          ],
        ),
      ),
    );
  }

  Widget _seletorMes() {
    return Row(
      children: [
        IconButton(
          tooltip: 'Mês anterior',
          onPressed: () => _mudarMes(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            _mesRotulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GridColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Próximo mês',
          onPressed: () => _mudarMes(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _totais(FinanceiroAcademiaMes dados) {
    return Row(
      children: [
        _metrica('Recebido', dados.recebido, CustomColors.primaryGreen),
        const SizedBox(width: 8),
        _metrica('Pendente', dados.pendente, GridColors.info),
        const SizedBox(width: 8),
        _metrica('Atrasado', dados.atrasado, GridColors.error),
      ],
    );
  }

  Widget _metrica(String titulo, double valor, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: GridColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: TextStyle(color: GridColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              'R\$ ${valor.toStringAsFixed(2)}',
              style: TextStyle(color: cor, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardAluno(FinanceiroAcademiaAluno aluno) {
    final (rotulo, cor) = switch (aluno.status) {
      StatusMensalidadeAcademia.pago => ('PAGO', CustomColors.primaryGreen),
      StatusMensalidadeAcademia.atrasado => ('ATRASADO', GridColors.error),
      StatusMensalidadeAcademia.pendente => ('PENDENTE', GridColors.secondaryDark),
    };
    final ocupado = _baixaEmAndamento.contains(aluno.alunoId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GridColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  aluno.nome,
                  style: TextStyle(color: GridColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              IconButton(
                tooltip: 'Editar valor e vencimento',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => _editarMensalidade(aluno),
                icon: Icon(Icons.edit_outlined, color: GridColors.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rotulo,
                  style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Vencimento: dia ${aluno.diaVencimento} • R\$ ${aluno.valor.toStringAsFixed(2)}',
            style: TextStyle(color: GridColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: aluno.pago
                ? OutlinedButton(
                    onPressed: ocupado ? null : () => _alternarBaixa(aluno),
                    child: Text(ocupado ? 'Salvando...' : 'Desfazer baixa'),
                  )
                : FilledButton(
                    onPressed: ocupado ? null : () => _alternarBaixa(aluno),
                    style: FilledButton.styleFrom(backgroundColor: CustomColors.primaryGreen),
                    child: Text(ocupado ? 'Salvando...' : 'Dar baixa'),
                  ),
          ),
        ],
      ),
    );
  }
}
