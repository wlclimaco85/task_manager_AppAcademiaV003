import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/medida_corporal_model.dart';
import 'package:task_manager_flutter/data/models/saude_diaria_model.dart';
import 'package:task_manager_flutter/data/services/cadastro_inicial_service.dart';
import 'package:task_manager_flutter/data/services/medida_corporal_caller.dart';
import 'package:task_manager_flutter/data/services/saude_diaria_caller.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';
import 'package:task_manager_flutter/ui/widgets/edit_form_helpers.dart';

/// Jornada de fotos e medidas. Peso e altura nao pedem foto; cada lado do
/// corpo tem sua propria foto e medida para comparacoes futuras.
class CadastroInicialScreen extends StatefulWidget {
  const CadastroInicialScreen({super.key});

  @override
  State<CadastroInicialScreen> createState() => _CadastroInicialScreenState();
}

class _CadastroInicialScreenState extends State<CadastroInicialScreen> {
  static const _etapas = <_EtapaCadastro>[
    _EtapaCadastro('Dados basicos', 'Comece pelo ponto de partida. Peso e altura nao precisam de foto.', Icons.monitor_weight_outlined, ['peso', 'altura']),
    _EtapaCadastro('Cintura e quadril', 'Registre a medida e uma foto da cintura para acompanhar sua evolucao.', Icons.accessibility_new_outlined, ['cintura', 'quadril'], foto: 'cintura'),
    _EtapaCadastro('Braco direito', 'Foto e medida do braco direito.', Icons.fitness_center_outlined, ['braco_direito'], foto: 'braco_direito'),
    _EtapaCadastro('Braco esquerdo', 'Foto e medida do braco esquerdo.', Icons.fitness_center_outlined, ['braco_esquerdo'], foto: 'braco_esquerdo'),
    _EtapaCadastro('Coxa direita', 'Foto e medida da coxa direita.', Icons.directions_walk_outlined, ['coxa_direita'], foto: 'coxa_direita'),
    _EtapaCadastro('Coxa esquerda', 'Foto e medida da coxa esquerda.', Icons.directions_walk_outlined, ['coxa_esquerda'], foto: 'coxa_esquerda'),
    _EtapaCadastro('Panturrilha direita', 'Foto e medida da panturrilha direita.', Icons.directions_run_outlined, ['panturrilha_direita'], foto: 'panturrilha_direita'),
    _EtapaCadastro('Panturrilha esquerda', 'Foto e medida da panturrilha esquerda.', Icons.directions_run_outlined, ['panturrilha_esquerda'], foto: 'panturrilha_esquerda'),
  ];

  final _controllers = <String, TextEditingController>{
    for (final medida in CadastroInicialService.medidas) medida.chave: TextEditingController(),
  };
  final _fotosDataUri = <String, String>{};
  final _fotosPreview = <String, File>{};
  bool _carregando = true;
  bool _salvando = false;
  bool _temPersonal = true;
  int _etapaAtual = 0;

  _EtapaCadastro get _etapa => _etapas[_etapaAtual];
  int get _camposPreenchidos => CadastroInicialService.totalCampos - CadastroInicialService.pendencias(_dados()).length;

  Map<String, dynamic> _dados() => <String, dynamic>{
        'fotos': _fotosDataUri,
        for (final medida in CadastroInicialService.medidas) medida.chave: _controllers[medida.chave]!.text.trim(),
      };

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _carregar() async {
    final remoto = await CadastroInicialService.buscarRemoto();
    final dados = remoto?.dados ?? await CadastroInicialService.carregar();
    if (!mounted) return;
    for (final medida in CadastroInicialService.medidas) {
      final valor = dados[medida.chave];
      if (valor != null) _controllers[medida.chave]!.text = valor.toString();
    }
    if (dados['fotos'] is Map) {
      for (final entrada in (dados['fotos'] as Map).entries) {
        if (entrada.value is String && (entrada.value as String).isNotEmpty) {
          _fotosDataUri[entrada.key.toString()] = entrada.value as String;
        }
      }
    }
    setState(() {
      _temPersonal = remoto?.temPersonal ?? true;
      _carregando = false;
    });
  }

  Future<void> _escolherFoto(String chave, ImageSource origem) async {
    final (arquivo, base64Str) = await pickImageWithValidation(origem);
    if (!mounted) return;
    if (base64Str == 'LIMITE_EXCEDIDO') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A imagem deve ter no maximo 2 MB.')));
      return;
    }
    if (arquivo != null && base64Str != null) {
      setState(() {
        _fotosPreview[chave] = arquivo;
        _fotosDataUri[chave] = 'data:image/jpeg;base64,$base64Str';
      });
    }
  }

  Future<void> _abrirSeletorFoto(String chave) =>
      showImageSourceDialog(context, (origem) => _escolherFoto(chave, origem));

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    final novos = <String, dynamic>{'fotos': _fotosDataUri};
    for (final medida in CadastroInicialService.medidas) {
      novos[medida.chave] = double.tryParse(_controllers[medida.chave]!.text.trim().replaceAll(',', '.'));
    }
    await CadastroInicialService.salvar(novos);
    final enviado = await CadastroInicialService.enviar(await CadastroInicialService.carregar());
    if (!mounted) return;
    if (!enviado) {
      // O preenchimento local ja foi concluido. Nao manter o aluno preso na
      // ultima etapa por uma falha temporaria de rede; o aviso deixa claro
      // que a copia sera sincronizada quando houver conexao.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Jornada salva neste aparelho. Ela sera sincronizada quando houver conexao.'),
      ));
      Navigator.pop(context, true);
      return;
    }
    await _registrarEvolucao(novos);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  /// O cadastro inicial tambem e o primeiro marco da evolucao corporal.
  /// Sem este registro, Corpo e Exames nao teria ponto algum para o grafico.
  Future<void> _registrarEvolucao(Map<String, dynamic> dados) async {
    final peso = dados['peso'] as double?;
    final altura = dados['altura'] as double?;
    final circunferencias = <String, double>{
      for (final medida in CadastroInicialService.medidas)
        if (medida.chave != 'peso' && medida.chave != 'altura')
          if (dados[medida.chave] is double) medida.chave: dados[medida.chave] as double,
    };
    try {
      final resumoAtual = await SaudeDiariaCaller().fetchResumo();
      final base = resumoAtual ?? ResumoSaudeDiaria(
        data: DateTime.now(), passos: 0, treinoMinutos: 0, batimentos: null,
        sonoMinutos: 0, pesoKg: null, pesoMetaKg: null, historicoSemanal: const [],
      );
      final resumoSalvo = await SaudeDiariaCaller().salvarResumo(ResumoSaudeDiaria(
        data: DateTime.now(), passos: base.passos, treinoMinutos: base.treinoMinutos,
        batimentos: base.batimentos, sonoMinutos: base.sonoMinutos,
        pesoKg: peso ?? base.pesoKg, pesoMetaKg: base.pesoMetaKg,
        alturaCm: altura?.round() ?? base.alturaCm, distanciaKm: base.distanciaKm,
        caloriasAtivas: base.caloriasAtivas, historicoSemanal: base.historicoSemanal,
      ));
      final medidaSalva = circunferencias.isEmpty
          ? true
          : await MedidaCorporalCaller().registrarMedida(MedidaCorporal(
              data: DateTime.now(), circunferencias: circunferencias,
            )) != null;
      if (resumoSalvo == null || !medidaSalva) {
        AppLogger.i.warn('[CadastroInicial] Cadastro salvo, mas a evolucao corporal nao sincronizou.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Cadastro salvo. O grafico sera atualizado ao sincronizar.'),
          ));
        }
      }
    } catch (error, stackTrace) {
      AppLogger.i.error('[CadastroInicial] Falha ao criar o primeiro registro corporal: $error', stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cadastro salvo. O grafico sera atualizado ao sincronizar.'),
        ));
      }
    }
  }

  void _proximaEtapa() {
    if (_etapaAtual == _etapas.length - 1) {
      _salvar();
      return;
    }
    setState(() => _etapaAtual++);
  }

  ImageProvider? _imagem(String chave) {
    if (_fotosPreview[chave] != null) return FileImage(_fotosPreview[chave]!);
    final dataUri = _fotosDataUri[chave];
    return dataUri != null && dataUri.startsWith('data:image')
        ? MemoryImage(base64Decode(dataUri.split(',').last))
        : null;
  }

  Widget _foto() {
    final chave = _etapa.foto!;
    final imagem = _imagem(chave);
    return InkWell(
      key: Key('cadastro_foto_$chave'),
      onTap: () => _abrirSeletorFoto(chave),
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        height: 190,
        decoration: BoxDecoration(
          color: GridColors.primarySubtle,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: GridColors.primary.withValues(alpha: .35), width: 1.5),
          image: imagem == null ? null : DecorationImage(image: imagem, fit: BoxFit.cover),
        ),
        child: imagem == null
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_a_photo_outlined, color: GridColors.primary, size: 42),
                const SizedBox(height: 10),
                Text('Adicionar foto', style: TextStyle(color: GridColors.textPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Toque para camera ou galeria', style: TextStyle(color: GridColors.textSecondary, fontSize: 12)),
              ])
            : Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: GridColors.card, shape: BoxShape.circle),
                  child: Icon(Icons.edit_outlined, color: GridColors.primary),
                ),
              ),
      ),
    );
  }

  Widget _campo(String chave) {
    final medida = CadastroInicialService.medidas.firstWhere((item) => item.chave == chave);
    return TextField(
      key: Key('cadastro_medida_$chave'),
      controller: _controllers[chave],
      onChanged: (_) => setState(() {}),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: '${medida.rotulo} (${medida.unidade})',
        prefixIcon: Icon(Icons.straighten_outlined, color: GridColors.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Sua jornada inicial')),
        body: _carregando
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: ListView(padding: const EdgeInsets.all(20), children: [
                      if (!_temPersonal)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: GridColors.secondaryLight, borderRadius: BorderRadius.circular(14)),
                          child: Row(children: [
                            Icon(Icons.info_outline, color: GridColors.secondaryDark),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('Voce ainda nao tem personal vinculado.')),
                          ]),
                        ),
                      Text('Jornada de evolucao', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Faca no seu ritmo. Cada registro ajuda a comparar sua evolucao.', style: TextStyle(color: GridColors.textSecondary)),
                      const SizedBox(height: 18),
                      Row(children: [
                        Expanded(child: LinearProgressIndicator(value: (_etapaAtual + 1) / _etapas.length, minHeight: 10, borderRadius: BorderRadius.circular(8), color: GridColors.primary, backgroundColor: GridColors.filterBackground)),
                        const SizedBox(width: 12),
                        Text('${_etapaAtual + 1}/${_etapas.length}', style: TextStyle(color: GridColors.primary, fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 8),
                      Text('$_camposPreenchidos de ${CadastroInicialService.totalCampos} conquistas registradas', key: const Key('cadastro_inicial_progresso'), textAlign: TextAlign.center, style: TextStyle(color: GridColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 24),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Container(
                          key: ValueKey(_etapaAtual),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: GridColors.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: GridColors.inputBorder)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            CircleAvatar(radius: 25, backgroundColor: GridColors.primarySubtle, child: Icon(_etapa.icone, color: GridColors.primary)),
                            const SizedBox(height: 16),
                            Text(_etapa.titulo, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text(_etapa.descricao, style: TextStyle(color: GridColors.textSecondary)),
                            if (_etapa.foto != null) ...[const SizedBox(height: 20), _foto()],
                            const SizedBox(height: 20),
                            for (final chave in _etapa.medidas) ...[_campo(chave), const SizedBox(height: 12)],
                          ]),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(children: [
                        if (_etapaAtual > 0) Expanded(child: OutlinedButton.icon(onPressed: () => setState(() => _etapaAtual--), icon: const Icon(Icons.arrow_back), label: const Text('Voltar'))),
                        if (_etapaAtual > 0) const SizedBox(width: 12),
                        Expanded(child: FilledButton.icon(onPressed: _salvando ? null : _proximaEtapa, icon: Icon(_etapaAtual == _etapas.length - 1 ? Icons.emoji_events_outlined : Icons.arrow_forward), label: Text(_salvando ? 'Salvando...' : _etapaAtual == _etapas.length - 1 ? 'Concluir jornada' : 'Proxima etapa'))),
                      ]),
                      TextButton(onPressed: _salvando ? null : () => Navigator.pop(context, false), child: const Text('Fazer depois')),
                    ]),
                  ),
                ),
              ),
      );
}

class _EtapaCadastro {
  final String titulo;
  final String descricao;
  final IconData icone;
  final List<String> medidas;
  final String? foto;

  const _EtapaCadastro(this.titulo, this.descricao, this.icone, this.medidas, {this.foto});
}
