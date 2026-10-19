import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';

/// Retorno explícito nas telas abertas pelo menu Mais, inclusive sem AppBar.
class FitnessMenuPage extends StatelessWidget {
  final Widget child;
  const FitnessMenuPage({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Column(children: [
    Material(color: context.appSurface, child: SizedBox(width: double.infinity,
      child: Align(alignment: Alignment.centerLeft,
        child: TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: GridColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back), label: const Text('Voltar'),
        ),
      ),
    )),
    Expanded(child: child),
  ]);
}
