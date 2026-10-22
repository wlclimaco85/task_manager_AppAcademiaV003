import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Finaliza o foco do campo antes de desmontar o modal por teclado.
/// Uma repetição de Esc não pode fechar também a janela que está por baixo.
class FechamentoModalSeguro extends StatefulWidget {
  final Widget child;
  const FechamentoModalSeguro({super.key, required this.child});
  @override
  State<FechamentoModalSeguro> createState() => _FechamentoModalSeguroState();
}

class _FechamentoModalSeguroState extends State<FechamentoModalSeguro> {
  final _focoDeFechamento = FocusNode(skipTraversal: true);
  bool _fechando = false;

  @override
  void dispose() {
    _focoDeFechamento.dispose();
    super.dispose();
  }

  void _fechar() {
    final route = ModalRoute.of(context);
    if (_fechando || route?.isCurrent != true) return;
    _fechando = true;
    _focoDeFechamento.requestFocus();
    // Mantém Esc preso a este popup enquanto encerra o campo ativo. O segundo
    // frame deixa o Focus/Actions atualizar as dependências antes do pop.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && route!.isCurrent) Navigator.of(context).maybePop();
      });
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  Widget build(BuildContext context) => Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.escape): DismissIntent()
        },
        child: Actions(actions: {
          DismissIntent: CallbackAction<DismissIntent>(onInvoke: (_) {
            _fechar();
            return null;
          })
        }, child: Focus(focusNode: _focoDeFechamento, child: widget.child)),
      );
}
