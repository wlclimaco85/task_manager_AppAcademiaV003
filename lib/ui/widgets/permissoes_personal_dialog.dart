import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/services/permissoes_aluno_service.dart';

/// Popup que pergunta ao aluno o que o personal pode ver.
/// Treino fica travado como liberado. Devolve as escolhas, ou null se fechar sem responder.
class PermissoesPersonalDialog extends StatefulWidget {
  final String nomePersonal;
  final Map<String, bool> inicial;

  const PermissoesPersonalDialog({
    super.key,
    required this.nomePersonal,
    required this.inicial,
  });

  @override
  State<PermissoesPersonalDialog> createState() => _PermissoesPersonalDialogState();
}

class _PermissoesPersonalDialogState extends State<PermissoesPersonalDialog> {
  late final Map<String, bool> _escolhas = {
    for (final area in PermissoesAlunoService.areasOpcionais) area: widget.inicial[area] == true,
  };
  bool _enviando = false;

  static const Map<String, String> _rotulos = {
    'dieta': 'Dieta',
    'suplementacao': 'Suplementação',
    'avaliacoes': 'Avaliações físicas',
    'metas': 'Metas e evolução do corpo',
  };

  Future<void> _confirmar(Map<String, bool> escolhas) async {
    setState(() => _enviando = true);
    final ok = await PermissoesAlunoService.responder(escolhas);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, escolhas);
      return;
    }
    setState(() => _enviando = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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
              'Escolha o que o seu personal pode acompanhar. Você pode mudar isso depois.',
            ),
            const SizedBox(height: 12),
            // Treino: sempre liberado, nao muda.
            const SwitchListTile(
              key: Key('permissao_treino'),
              contentPadding: EdgeInsets.zero,
              title: Text('Treinos'),
              subtitle: Text('Obrigatório: o personal monta e acompanha seus treinos.'),
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
              : () => _confirmar({for (final area in PermissoesAlunoService.areasOpcionais) area: false}),
          child: const Text('Não permitir'),
        ),
        ElevatedButton(
          key: const Key('permissoes_permitir'),
          style: ElevatedButton.styleFrom(
            backgroundColor: CustomColors.primaryGreen,
            foregroundColor: Colors.white,
          ),
          onPressed: _enviando ? null : () => _confirmar(_escolhas),
          child: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Permitir selecionados'),
        ),
      ],
    );
  }
}
