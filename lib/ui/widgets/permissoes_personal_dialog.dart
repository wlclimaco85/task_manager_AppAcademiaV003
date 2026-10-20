import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/services/permissoes_aluno_service.dart';

/// Popup que pergunta ao aluno o que o personal pode ver.
/// Treino fica travado como liberado. Devolve as escolhas, ou null se fechar sem responder.
class PermissoesPersonalDialog extends StatefulWidget {
  final String nomePersonal;
  final Map<String, bool> inicial;
  final Map<String, dynamic> contrato;

  const PermissoesPersonalDialog({
    super.key,
    required this.nomePersonal,
    required this.inicial,
    required this.contrato,
  });

  @override
  State<PermissoesPersonalDialog> createState() =>
      _PermissoesPersonalDialogState();
}

class _PermissoesPersonalDialogState extends State<PermissoesPersonalDialog> {
  late final Map<String, bool> _escolhas = {
    for (final area in PermissoesAlunoService.areasOpcionais)
      area: widget.inicial[area] == true,
  };
  bool _enviando = false;
  bool _aceitouTermos = false;

  static const Map<String, String> _rotulos = {
    'dieta': 'Dieta',
    'suplementacao': 'Suplementação',
    'avaliacoes': 'Avaliações físicas',
    'metas': 'Metas e evolução do corpo',
  };

  Future<void> _confirmar(Map<String, bool> escolhas,
      {required bool aceitarContrato}) async {
    setState(() => _enviando = true);
    final ok = await PermissoesAlunoService.responder(
      escolhas,
      aceitarContrato: aceitarContrato,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, escolhas);
      return;
    }
    setState(() => _enviando = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: CustomColors.primaryGreen,
      content: Text('Não foi possível salvar agora. Tente de novo com conexão.',
          style: TextStyle(color: Colors.white)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Permissões para ${widget.nomePersonal}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revise a proposta antes de confirmar o vínculo.',
            ),
            const SizedBox(height: 12),
            if (widget.contrato.isNotEmpty) ...[
              _linhaContrato(
                  'Plano',
                  widget.contrato['planoNome']?.toString() ??
                      widget.contrato['tipoCobranca']?.toString() ??
                      'Acompanhamento'),
              _linhaContrato('Valor',
                  'R\$ ${((widget.contrato['valorMensalidade'] as num?)?.toDouble() ?? 0).toStringAsFixed(2).replaceAll('.', ',')}'),
              _linhaContrato('Vencimento',
                  'Dia ${widget.contrato['diaVencimento'] ?? '-'}'),
              _linhaContrato('Academia',
                  widget.contrato['academiaNome']?.toString() ?? '-'),
              _linhaContrato('Aula semanal',
                  '${_diaSemana(widget.contrato['diaSemana'])}, ${widget.contrato['horarioInicio'] ?? '-'} às ${widget.contrato['horarioFim'] ?? '-'}'),
              const SizedBox(height: 8),
              Text(
                widget.contrato['termos']?.toString() ?? '',
                style: TextStyle(fontSize: 12, color: GridColors.textSecondary),
              ),
              CheckboxListTile(
                key: const Key('aceite_termos_contrato'),
                contentPadding: EdgeInsets.zero,
                value: _aceitouTermos,
                title: const Text(
                    'Li e aceito os termos, valores, academia e horário'),
                onChanged: _enviando
                    ? null
                    : (valor) => setState(() => _aceitouTermos = valor == true),
              ),
              const Divider(),
            ] else
              const Text(
                'A proposta está incompleta. Peça ao personal para reenviar informando academia e horário.',
                style: TextStyle(color: Colors.redAccent),
              ),
            const Text('Permissões de acesso aos seus dados:'),
            // Treino: sempre liberado, nao muda.
            const SwitchListTile(
              key: Key('permissao_treino'),
              contentPadding: EdgeInsets.zero,
              title: Text('Treinos'),
              subtitle: Text(
                  'Obrigatório: o personal monta e acompanha seus treinos.'),
              value: true,
              onChanged: null,
            ),
            for (final area in PermissoesAlunoService.areasOpcionais)
              SwitchListTile(
                key: Key('permissao_$area'),
                contentPadding: EdgeInsets.zero,
                title: Text(_rotulos[area] ?? area),
                value: _escolhas[area] == true,
                onChanged: _enviando
                    ? null
                    : (valor) => setState(() => _escolhas[area] = valor),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('permissoes_nao_permitir'),
          onPressed: _enviando
              ? null
              : () => _confirmar(
                    {
                      for (final area in PermissoesAlunoService.areasOpcionais)
                        area: false
                    },
                    aceitarContrato: false,
                  ),
          child: const Text('Recusar contrato'),
        ),
        ElevatedButton(
          key: const Key('permissoes_permitir'),
          style: ElevatedButton.styleFrom(
            backgroundColor: CustomColors.primaryGreen,
            foregroundColor: Colors.white,
          ),
          onPressed: _enviando || !_aceitouTermos || widget.contrato.isEmpty
              ? null
              : () => _confirmar(_escolhas, aceitarContrato: true),
          child: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Permitir selecionados'),
        ),
      ],
    );
  }

  Widget _linhaContrato(String rotulo, String valor) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 105,
              child: Text(rotulo,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            Expanded(child: Text(valor)),
          ],
        ),
      );

  String _diaSemana(Object? valor) {
    const dias = [
      '',
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo'
    ];
    final numero = valor is num ? valor.toInt() : int.tryParse('$valor') ?? 0;
    return numero >= 1 && numero <= 7 ? dias[numero] : 'Dia não informado';
  }
}
