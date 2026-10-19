import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/services/cadastro_inicial_service.dart';
import 'package:task_manager_flutter/data/utils/fitness_access.dart';
import 'package:task_manager_flutter/ui/screens/fitness/cadastro_inicial_screen.dart';

/// Lembrete no Hub: "Complete seu cadastro inicial". Some quando nao falta nada.
/// So aparece para o aluno; o personal nao preenche o proprio cadastro de aluno.
class CadastroInicialBanner extends StatefulWidget {
  const CadastroInicialBanner({super.key});

  @override
  State<CadastroInicialBanner> createState() => _CadastroInicialBannerState();
}

class _CadastroInicialBannerState extends State<CadastroInicialBanner> {
  List<String> _pendencias = const [];
  bool _carregado = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    if (podeGerenciarAlunos(AuthUtility.userInfo)) {
      setState(() => _carregado = true);
      return;
    }
    // Atualiza a copia local pelo servidor; se a rede falhar, usa o que ja estava no aparelho.
    await CadastroInicialService.buscarRemoto();
    final dados = await CadastroInicialService.carregar();
    if (!mounted) return;
    setState(() {
      _pendencias = CadastroInicialService.pendencias(dados);
      _carregado = true;
    });
  }

  Future<void> _abrir() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CadastroInicialScreen()),
    );
    if (mounted) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    if (!_carregado || _pendencias.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: CustomColors.primaryGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: const Key('lembrete_cadastro_inicial'),
          borderRadius: BorderRadius.circular(14),
          onTap: _abrir,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.assignment_turned_in_outlined, color: CustomColors.primaryGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete seu cadastro inicial',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: context.appText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Faltam: ${_pendencias.take(3).join(', ')}${_pendencias.length > 3 ? '...' : ''}',
                        style: TextStyle(fontSize: 12, color: context.appTextSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: CustomColors.primaryGreen),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
