import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/grid_colors.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/wizard_aluno_screen.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/wizard_personal_screen.dart';

class CriarContaScreen extends StatelessWidget {
  const CriarContaScreen({super.key});

  void _mostrarEmBreve(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Em breve')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(title: const Text('Criar conta')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _OpcaoCadastroCard(
            icone: Icons.fitness_center,
            titulo: 'Aluno',
            descricao: 'Quero treinar',
            habilitado: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const WizardAlunoScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _OpcaoCadastroCard(
            icone: Icons.sports_gymnastics,
            titulo: 'Personal',
            descricao: 'Sou personal trainer',
            habilitado: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const WizardPersonalScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _OpcaoCadastroCard(
            icone: Icons.apartment,
            titulo: 'Academia',
            descricao: 'Tenho uma academia',
            habilitado: false,
            onTap: () => _mostrarEmBreve(context),
          ),
        ],
      ),
    );
  }
}

class _OpcaoCadastroCard extends StatelessWidget {
  const _OpcaoCadastroCard({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.habilitado,
    required this.onTap,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final bool habilitado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color corIcone = habilitado ? GridColors.primary : GridColors.divider;
    final Color corTexto =
        habilitado ? GridColors.textSecondary : GridColors.divider;

    return Card(
      color: GridColors.card,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icone, size: 48, color: corIcone),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          titulo,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: corTexto,
                          ),
                        ),
                        if (!habilitado) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: GridColors.secondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Em breve',
                              style: TextStyle(
                                color: GridColors.textPrimary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descricao,
                      style: TextStyle(
                        fontSize: 16,
                        color: habilitado
                            ? GridColors.textSecondary
                            : GridColors.divider,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
