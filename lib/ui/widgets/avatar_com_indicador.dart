import 'package:flutter/material.dart';

/// Avatar com um "!" amarelo no canto quando ha pendencia. Mesmo visual no aluno e no personal.
/// O toque (44x44) abre um aviso com o titulo e o texto informados.
class AvatarComIndicador extends StatelessWidget {
  const AvatarComIndicador({
    super.key,
    required this.avatar,
    required this.mostrarAlerta,
    required this.rotulo,
    required this.titulo,
    required this.corpo,
  });

  final Widget avatar;
  final bool mostrarAlerta;

  /// Texto do tooltip e do leitor de tela.
  final String rotulo;
  final String titulo;
  final String corpo;

  static const Color _amarelo = Color(0xFFF5B700);
  static const Color _textoEscuro = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    if (!mostrarAlerta) return avatar;
    final corBorda = Theme.of(context).colorScheme.surface;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -8,
          bottom: -8,
          child: Semantics(
            button: true,
            label: rotulo,
            child: Tooltip(
              message: rotulo,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _abrirAviso(context),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _amarelo,
                        shape: BoxShape.circle,
                        border: Border.all(color: corBorda, width: 2),
                      ),
                      child: const Text(
                        '!',
                        style: TextStyle(
                          color: _textoEscuro,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _abrirAviso(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(corpo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
}
