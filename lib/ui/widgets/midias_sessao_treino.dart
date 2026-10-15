import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';
import 'package:task_manager_flutter/data/utils/exercicio_video_link.dart';
import 'package:task_manager_flutter/data/utils/midias_treino.dart';
import 'package:task_manager_flutter/ui/widgets/exercicio_midia.dart';
import 'package:task_manager_flutter/ui/widgets/fechamento_modal_seguro.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';
export 'package:task_manager_flutter/data/utils/midias_treino.dart';

class MidiasSessaoTreinoEditor extends StatefulWidget {
  final List<String> fotosBase64;
  final List<String> videosUrls;
  final void Function(List<String>, List<String>) onChanged;
  const MidiasSessaoTreinoEditor(
      {super.key,
      required this.fotosBase64,
      required this.videosUrls,
      required this.onChanged});

  @override
  State<MidiasSessaoTreinoEditor> createState() =>
      _MidiasSessaoTreinoEditorState();
}

class _MidiasSessaoTreinoEditorState extends State<MidiasSessaoTreinoEditor> {
  late List<String> _fotos;
  late final List<TextEditingController> _links;
  bool _carregando = false;
  @override
  void initState() {
    super.initState();
    _fotos = List.of(widget.fotosBase64);
    _links = List.generate(
        3,
        (i) => TextEditingController(
            text: i < widget.videosUrls.length ? widget.videosUrls[i] : ''));
  }

  @override
  void dispose() {
    for (final c in _links) {
      c.dispose();
    }
    super.dispose();
  }

  void _notificar() => widget.onChanged(List.of(_fotos),
      _links.map((c) => c.text.trim()).where((v) => v.isNotEmpty).toList());

  Future<void> _foto(ImageSource origem, {int? indice}) async {
    if (_carregando || (indice == null && _fotos.length >= 3)) return;
    setState(() => _carregando = true);
    try {
      final arquivo = await ImagePicker().pickImage(
          source: origem, maxWidth: 1600, maxHeight: 1600, imageQuality: 88);
      if (arquivo == null) return;
      final foto = await prepararFotoTreino(await arquivo.readAsBytes());
      if (!mounted) return;
      setState(() {
        if (indice == null) {
          _fotos.add(foto);
        } else {
          _fotos[indice] = foto;
        }
      });
      _notificar();
    } catch (e, st) {
      AppLogger.i.error('Falha ao selecionar foto da sessão: $e', st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e is FormatException
                ? e.message
                : 'Não foi possível abrir a foto. Tente novamente.')));
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Fotos do treino (${_fotos.length}/3)',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (_fotos.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < _fotos.length; i++)
                SizedBox(
                    width: 100,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _fotoMiniatura(_fotos[i],
                              width: 100, height: 100)),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                                tooltip: 'Substituir foto ${i + 1}',
                                onPressed: _carregando
                                    ? null
                                    : () =>
                                        _foto(ImageSource.gallery, indice: i),
                                icon:
                                    const Icon(Icons.edit_outlined, size: 20)),
                            IconButton(
                                tooltip: 'Remover foto ${i + 1}',
                                onPressed: _carregando
                                    ? null
                                    : () {
                                        setState(() => _fotos.removeAt(i));
                                        _notificar();
                                      },
                                icon:
                                    const Icon(Icons.delete_outline, size: 20)),
                          ]),
                    ])),
            ]),
          Wrap(spacing: 8, children: [
            OutlinedButton.icon(
                onPressed: _carregando || _fotos.length >= 3
                    ? null
                    : () => _foto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Adicionar foto')),
            OutlinedButton.icon(
                onPressed: _carregando || _fotos.length >= 3
                    ? null
                    : () => _foto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Câmera')),
          ]),
          if (_carregando) const LinearProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Vídeos do treino (até 3)',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const Text('Cole links do YouTube ou de arquivos do Google Drive.',
              style: TextStyle(fontSize: 12)),
          for (var i = 0; i < _links.length; i++)
            Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextFormField(
                  controller: _links[i],
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  validator: (valor) => (valor?.trim().length ?? 0) > 2048
                      ? 'Use um link de até 2048 caracteres.'
                      : validarLinkVideoExercicio(valor),
                  onChanged: (_) => _notificar(),
                  decoration: InputDecoration(
                      labelText: 'Link do vídeo ${i + 1} (opcional)',
                      hintText: 'https://...',
                      suffixIcon: IconButton(
                          tooltip: 'Remover link ${i + 1}',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _links[i].clear();
                            setState(() {});
                            _notificar();
                          })),
                )),
        ],
      );
}

Widget _fotoMiniatura(String foto,
    {required double width,
    required double height,
    BoxFit fit = BoxFit.cover}) {
  try {
    return Image.memory(base64Decode(foto),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => SizedBox(
            width: width,
            height: height,
            child: const Icon(Icons.broken_image_outlined)));
  } catch (_) {
    return SizedBox(
        width: width,
        height: height,
        child: const Icon(Icons.broken_image_outlined));
  }
}

class MidiasSessaoTreinoGaleria extends StatelessWidget {
  final bool compacta;
  final List<String> fotosBase64;
  final List<String> videosUrls;
  const MidiasSessaoTreinoGaleria(
      {super.key,
      required this.fotosBase64,
      required this.videosUrls,
      this.compacta = false});
  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fotosBase64.isNotEmpty) ...[
            if (!compacta)
              const Text('Fotos do treino',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < fotosBase64.take(3).length; i++)
                Semantics(
                    label: 'Ver foto ${i + 1} do treino',
                    button: true,
                    child: InkWell(
                        onTap: () => showDialog(
                            context: context,
                            builder: (dialogContext) => Dialog(
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                      Flexible(
                                          child: InteractiveViewer(
                                              child: _fotoMiniatura(
                                                  fotosBase64[i],
                                                  width:
                                                      MediaQuery.sizeOf(context)
                                                              .width *
                                                          0.9,
                                                  height:
                                                      MediaQuery.sizeOf(context)
                                                              .height *
                                                          0.7,
                                                  fit: BoxFit.contain))),
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(dialogContext),
                                          child: const Text('Fechar')),
                                    ]))),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _fotoMiniatura(fotosBase64[i],
                                width: compacta ? 64 : 100,
                                height: compacta ? 64 : 100)))),
            ]),
          ],
          if (!compacta)
            for (var i = 0; i < videosUrls.take(3).length; i++) ...[
              const SizedBox(height: 12),
              Text('Vídeo do meu treino ${i + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              ExercicioMidia(url: videosUrls[i]),
            ],
          if (!compacta && fotosBase64.isEmpty && videosUrls.isEmpty)
            const Text('Nenhuma foto ou vídeo adicionado a este treino.'),
        ],
      );
}

Future<SessaoTreinoRegistroModel?> editarMidiasSessaoTreino(
        BuildContext context, SessaoTreinoRegistroModel sessao) =>
    showDialog<SessaoTreinoRegistroModel>(
        context: context,
        builder: (_) => _EditarMidiasSessaoDialog(sessao: sessao));

class _EditarMidiasSessaoDialog extends StatefulWidget {
  final SessaoTreinoRegistroModel sessao;
  const _EditarMidiasSessaoDialog({required this.sessao});
  @override
  State<_EditarMidiasSessaoDialog> createState() =>
      _EditarMidiasSessaoDialogState();
}

class _EditarMidiasSessaoDialogState extends State<_EditarMidiasSessaoDialog> {
  final _form = GlobalKey<FormState>();
  late List<String> _fotos = List.of(widget.sessao.fotosDoTreino);
  late List<String> _videos = List.of(widget.sessao.videosDoTreino);
  bool _salvando = false;
  String? _erro;
  Future<void> _salvar() async {
    if (_salvando || !_form.currentState!.validate()) return;
    final erro = validarMidiasSessaoTreino(_fotos, _videos);
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final atualizada = await FitnessOfflineRepository().atualizarSessaoMidias(
          widget.sessao.id,
          fotosBase64: _fotos,
          videosUrls: _videos);
      if (mounted) Navigator.pop(context, atualizada);
    } catch (e, st) {
      AppLogger.i.error('Falha ao salvar editor de mídias da sessão: $e', st);
      if (mounted) {
        setState(() => _erro =
            'Não foi possível salvar. Confira os arquivos e tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => FechamentoModalSeguro(
          child: AlertDialog(
        title: const Text('Fotos e vídeos do treino'),
        content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
                child: Form(
                    key: _form,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MidiasSessaoTreinoEditor(
                              fotosBase64: _fotos,
                              videosUrls: _videos,
                              onChanged: (fotos, videos) {
                                _fotos = fotos;
                                _videos = videos;
                              }),
                          if (_erro != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(_erro!,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error))),
                        ])))),
        actions: [
          TextButton(
              onPressed: _salvando ? null : () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: _salvando ? null : _salvar,
              child: Text(_salvando ? 'Salvando...' : 'Salvar mídias')),
        ],
      ));
}
