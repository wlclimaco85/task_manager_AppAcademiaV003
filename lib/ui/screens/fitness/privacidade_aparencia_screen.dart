import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/services/fitness_conta_sync.dart';
import 'package:task_manager_flutter/data/services/permissoes_aluno_service.dart';
import 'package:task_manager_flutter/data/services/preferencia_tema_service.dart';
import 'package:task_manager_flutter/data/utils/fitness_access.dart';

/// Privacidade e aparência do usuário.
/// - O aluno gerencia o que o personal pode acompanhar e visibilidade.
/// - O personal gerencia visibilidade na vitrine, solicitações, exibição de contato e menções.
/// - Todos escolhem o tema do app e têm acesso às informações de proteção de dados (LGPD).
class PrivacidadeAparenciaScreen extends StatefulWidget {
  const PrivacidadeAparenciaScreen({super.key});

  @override
  State<PrivacidadeAparenciaScreen> createState() => _PrivacidadeAparenciaScreenState();
}

class _PrivacidadeAparenciaScreenState extends State<PrivacidadeAparenciaScreen> {
  // ─── Estado Aluno ───
  Map<String, bool>? _privacidade;
  bool _salvando = false;

  // ─── Estado Personal ───
  Map<String, bool> _privacidadePersonal = {
    'visivel_vitrine': true,
    'receber_solicitacoes': true,
    'exibir_whatsapp': true,
    'exibir_instagram': true,
    'permitir_mencao_treinos': true,
  };

  static const Map<String, String> _rotulosPrivacidade = {
    'dieta': 'Dieta',
    'suplementacao': 'Suplementação',
    'avaliacoes': 'Avaliações físicas',
    'metas': 'Metas e evolução do corpo',
  };

  static const Map<TemaApp, String> _rotulosTema = {
    TemaApp.padrao: 'Padrão (visual atual)',
    TemaApp.branco: 'Branco',
    TemaApp.preto: 'Preto',
    TemaApp.barby: 'Barby (rosa)',
  };

  bool get _ehAluno => !podeGerenciarAlunos(AuthUtility.userInfo);

  @override
  void initState() {
    super.initState();
    if (_ehAluno) {
      _carregarPrivacidadeAluno();
    } else {
      _carregarPrivacidadePersonal();
    }
  }

  // ─── Carregamento Aluno ───
  Future<void> _carregarPrivacidadeAluno() async {
    final prefs = await SharedPreferences.getInstance();
    final chave = FitnessContaSync.chave('privacidade_aluno_config_v1');
    final jsonStr = prefs.getString(chave);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _privacidade = {
              'treino': true,
              for (final area in PermissoesAlunoService.areasOpcionais)
                area: map[area] == true,
            };
          });
        }
      } catch (_) {}
    }

    _privacidade ??= {
      'treino': true,
      for (final area in PermissoesAlunoService.areasOpcionais) area: true,
    };

    try {
      final estado = await PermissoesAlunoService.meu();
      if (!mounted) return;
      if (estado != null) {
        setState(() => _privacidade = estado.permissoes);
        await prefs.setString(chave, jsonEncode(estado.permissoes));
      }
    } catch (_) {}
  }

  // ─── Salvamento Aluno ───
  Future<void> _salvarPrivacidadeAluno() async {
    final escolhas = _privacidade;
    if (escolhas == null) return;
    setState(() => _salvando = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final chave = FitnessContaSync.chave('privacidade_aluno_config_v1');
      await prefs.setString(chave, jsonEncode(escolhas));
      await PermissoesAlunoService.responder({
        for (final area in PermissoesAlunoService.areasOpcionais) area: escolhas[area] == true,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.green,
        content: Text('Privacidade atualizada com sucesso.'),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao salvar privacidade: $e'),
      ));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  // ─── Carregamento Personal ───
  Future<void> _carregarPrivacidadePersonal() async {
    final prefs = await SharedPreferences.getInstance();
    final chave = FitnessContaSync.chave('privacidade_personal_config_v1');
    final jsonStr = prefs.getString(chave);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _privacidadePersonal = {
              'visivel_vitrine': map['visivel_vitrine'] ?? true,
              'receber_solicitacoes': map['receber_solicitacoes'] ?? true,
              'exibir_whatsapp': map['exibir_whatsapp'] ?? true,
              'exibir_instagram': map['exibir_instagram'] ?? true,
              'permitir_mencao_treinos': map['permitir_mencao_treinos'] ?? true,
            };
          });
          return;
        }
      } catch (_) {}
    }
  }

  // ─── Salvamento Personal ───
  Future<void> _salvarPrivacidadePersonal() async {
    setState(() => _salvando = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final chave = FitnessContaSync.chave('privacidade_personal_config_v1');
      await prefs.setString(chave, jsonEncode(_privacidadePersonal));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.green,
        content: Text('Configurações de privacidade salvas com sucesso.'),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao salvar: $e'),
      ));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Widget _secaoAparencia() {
    return ValueListenableBuilder<TemaApp>(
      valueListenable: PreferenciaTema.tema,
      builder: (context, tema, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, size: 20, color: GridColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Aparência', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final opcao in TemaApp.values)
            RadioListTile<TemaApp>(
              key: Key('tema_${opcao.name}'),
              contentPadding: EdgeInsets.zero,
              title: Text(_rotulosTema[opcao] ?? opcao.name),
              value: opcao,
              groupValue: tema,
              onChanged: (escolha) {
                if (escolha != null) PreferenciaTema.definir(escolha);
              },
            ),
        ],
      ),
    );
  }

  Widget _secaoPrivacidadeAluno() {
    final escolhas = _privacidade ?? {
      'treino': true,
      for (final area in PermissoesAlunoService.areasOpcionais) area: true,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.security_outlined, size: 20, color: GridColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Privacidade', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Escolha o que o seu personal pode acompanhar. Você pode alterar essas permissões a qualquer momento.',
          style: TextStyle(color: context.appTextSecondary, fontSize: 13),
        ),
        const SizedBox(height: 8),
        const SwitchListTile(
          key: Key('privacidade_treino'),
          contentPadding: EdgeInsets.zero,
          title: Text('Treinos', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('Obrigatório: o personal prescreve e acompanha seus treinos.'),
          value: true,
          onChanged: null,
        ),
        for (final area in PermissoesAlunoService.areasOpcionais)
          SwitchListTile(
            key: Key('privacidade_$area'),
            contentPadding: EdgeInsets.zero,
            title: Text(_rotulosPrivacidade[area] ?? area, style: const TextStyle(fontWeight: FontWeight.w600)),
            value: escolhas[area] == true,
            onChanged: _salvando
                ? null
                : (valor) => setState(() => _privacidade = {...escolhas, area: valor}),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('privacidade_salvar'),
          onPressed: _salvando ? null : _salvarPrivacidadeAluno,
          icon: const Icon(Icons.check),
          label: Text(_salvando ? 'Salvando...' : 'Salvar privacidade'),
        ),
      ],
    );
  }

  Widget _secaoPrivacidadePersonal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shield_outlined, size: 20, color: GridColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Privacidade e Visibilidade Profissional',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Defina como o seu perfil profissional é exibido para alunos e visitantes no Eu Atleta.',
          style: TextStyle(color: context.appTextSecondary, fontSize: 13),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          key: const Key('privacidade_visivel_vitrine'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Aparecer na busca de Personais', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Permite que novos alunos encontrem seu perfil na vitrine de personais.'),
          value: _privacidadePersonal['visivel_vitrine'] ?? true,
          onChanged: _salvando
              ? null
              : (val) => setState(() => _privacidadePersonal['visivel_vitrine'] = val),
        ),
        SwitchListTile(
          key: const Key('privacidade_receber_solicitacoes'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Receber solicitações de novos alunos', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Permite que alunos interessados iniciem conversas ou solicitem acompanhamento.'),
          value: _privacidadePersonal['receber_solicitacoes'] ?? true,
          onChanged: _salvando
              ? null
              : (val) => setState(() => _privacidadePersonal['receber_solicitacoes'] = val),
        ),
        SwitchListTile(
          key: const Key('privacidade_exibir_whatsapp'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Exibir WhatsApp no perfil', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Facilita o contato de alunos que queiram tirar dúvidas sobre seus planos.'),
          value: _privacidadePersonal['exibir_whatsapp'] ?? true,
          onChanged: _salvando
              ? null
              : (val) => setState(() => _privacidadePersonal['exibir_whatsapp'] = val),
        ),
        SwitchListTile(
          key: const Key('privacidade_exibir_instagram'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Exibir Instagram no perfil', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Mostra seu @ oficial do Instagram no perfil profissional.'),
          value: _privacidadePersonal['exibir_instagram'] ?? true,
          onChanged: _salvando
              ? null
              : (val) => setState(() => _privacidadePersonal['exibir_instagram'] = val),
        ),
        SwitchListTile(
          key: const Key('privacidade_permitir_mencao_treinos'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Permitir marcação nos treinos compartilhados', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Quando seus alunos compartilham no Instagram ou Facebook, seu perfil é marcado.'),
          value: _privacidadePersonal['permitir_mencao_treinos'] ?? true,
          onChanged: _salvando
              ? null
              : (val) => setState(() => _privacidadePersonal['permitir_mencao_treinos'] = val),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('privacidade_personal_salvar'),
          onPressed: _salvando ? null : _salvarPrivacidadePersonal,
          icon: const Icon(Icons.check),
          label: Text(_salvando ? 'Salvando...' : 'Salvar privacidade'),
        ),
      ],
    );
  }

  Widget _cardLgpd() {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, size: 20, color: GridColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Segurança e LGPD',
                  style: TextStyle(
                    color: context.appText,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Seus dados pessoais, cadastrais e de atividades físicas são armazenados de forma estritamente protegida, em total conformidade com a Lei Geral de Proteção de Dados (Lei nº 13.709/2018). Você possui total controle sobre a visibilidade e compartilhamento dos seus dados.',
            style: TextStyle(
              color: context.appTextSecondary,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _mostrarPoliticaPrivacidade(context),
            child: Row(
              children: [
                Icon(Icons.policy_outlined, size: 16, color: GridColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ler Política de Privacidade e Termos de Uso',
                    style: TextStyle(
                      color: GridColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarPoliticaPrivacidade(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.appSurface,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.75,
            ),
            child: ListView(
              children: [
                Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined, color: GridColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Política de Privacidade e LGPD',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '1. Coleta e Finalidade dos Dados\n'
                  'O aplicativo Eu Atleta coleta dados cadastrais (nome, e-mail, telefone) e informações fitness (treinos realizados, medidas corporais e preferências) com a finalidade exclusiva de prestar o serviço de prescrição de treinos, acompanhamento físico e conexão entre alunos e personais trainers.\n\n'
                  '2. Compartilhamento e Sigilo\n'
                  'Seus dados nunca são vendidos ou compartilhados com terceiros para fins publicitários. O compartilhamento ocorre unicamente entre você e o profissional (personal trainer ou academia) que você autorizou expressamente.\n\n'
                  '3. Seus Direitos (LGPD - Lei 13.709/2018)\n'
                  'Você pode a qualquer momento:\n'
                  '• Alterar as permissões de acesso aos seus dados de treino, dieta e avaliações.\n'
                  '• Solicitar a retificação de dados incorretos ou desatualizados.\n'
                  '• Revogar consentimentos e solicitar a exclusão de sua conta e histórico.\n\n'
                  '4. Armazenamento e Segurança\n'
                  'Todas as comunicações com os servidores utilizam criptografia HTTPS/TLS, garantindo a integridade e inviolabilidade de suas informações.',
                  style: TextStyle(color: ctx.appTextSecondary, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidade e aparência')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _secaoAparencia(),
              const SizedBox(height: 24),
              Divider(color: context.appBorder),
              const SizedBox(height: 20),
              if (_ehAluno)
                _secaoPrivacidadeAluno()
              else
                _secaoPrivacidadePersonal(),
              _cardLgpd(),
            ],
          ),
        ),
      ),
    );
  }
}

