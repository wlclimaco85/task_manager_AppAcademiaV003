import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

class CompartilharTreinoSheet extends StatefulWidget {
  final String treino;
  final int minutos, series, rpe;
  final double tonelagemKg;
  final VoidCallback onFechar;
  const CompartilharTreinoSheet({super.key, required this.treino,
    required this.minutos, required this.series, required this.rpe,
    required this.tonelagemKg, required this.onFechar});
  @override
  State<CompartilharTreinoSheet> createState() => _CompartilharTreinoSheetState();
}

class _CompartilharTreinoSheetState extends State<CompartilharTreinoSheet> {
  final _cardKey = GlobalKey();
  Uint8List? _foto;
  bool _ocupado = false;
  // TODO: substituir os links de teste pelos links publicados do AppAcademia.
  // Pode configurar sem alterar o fonte por --dart-define APP_PLAYSTORE_URL e APP_APPSTORE_URL.
  static const _play = String.fromEnvironment('APP_PLAYSTORE_URL',
    defaultValue: 'https://play.google.com/store/apps');
  static const _apple = String.fromEnvironment('APP_APPSTORE_URL',
    defaultValue: 'https://apps.apple.com/br/');
  static String _linkLoja(String valor, String host) {
    final uri = Uri.tryParse(valor);
    return uri?.scheme == 'https' && uri?.host == host ? valor : '';
  }
  String get _playUrl => _linkLoja(_play, 'play.google.com');
  String get _appleUrl => _linkLoja(_apple, 'apps.apple.com');
  String get _legenda => 'Treino concluído no Eu Atleta!\n'
      '${widget.treino}\n${widget.minutos} min • ${widget.series} séries\n'
      '${widget.tonelagemKg.toStringAsFixed(0)} kg de volume total\n'
      '${_playUrl.isEmpty ? '' : '${_playUrl == 'https://play.google.com/store/apps' ? 'Android (link de teste)' : 'Baixe para Android'}: $_playUrl\n'}'
      '${_appleUrl.isEmpty ? '' : '${_appleUrl == 'https://apps.apple.com/br/' ? 'iPhone (link de teste)' : 'Baixe para iPhone'}: $_appleUrl\n'}'
      '#EuAtleta';

  Future<void> _escolherFoto(ImageSource source) async {
    try {
      final arquivo = await ImagePicker().pickImage(source: source,
        maxWidth: 1600, imageQuality: 90);
      if (arquivo == null) return;
      final bytes = await arquivo.readAsBytes();
      if (mounted) setState(() => _foto = bytes);
    } catch (error, stack) {
      AppLogger.i.error('Falha ao selecionar foto do treino.', stack);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a foto. Tente novamente.')));
    }
  }
  Future<void> _compartilhar() async {
    setState(() => _ocupado = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final imagem = await boundary.toImage(pixelRatio: 3);
      final dados = await imagem.toByteData(format: ui.ImageByteFormat.png);
      imagem.dispose();
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox;
      await Share.shareXFiles([XFile.fromData(dados!.buffer.asUint8List(),
        mimeType: 'image/png', name: 'meu-treino.png')],
        text: _legenda, sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
    } catch (error, stack) {
      AppLogger.i.error('Falha ao compartilhar foto do treino.', stack);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível compartilhar. Tente novamente.')));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }
  @override
  Widget build(BuildContext context) => SafeArea(child: SingleChildScrollView(
    padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Treino salvo! Compartilhar?', style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        RepaintBoundary(key: _cardKey, child: Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF064E3B),
            borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            const Text('EU ATLETA', style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 12),
            if (_foto != null) ClipRRect(borderRadius: BorderRadius.circular(12),
              child: Image.memory(_foto!, height: 220, width: double.infinity, fit: BoxFit.cover)),
            const SizedBox(height: 12),
            Text(widget.treino, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 12),
            Text('${widget.minutos} min • ${widget.series} séries • RPE ${widget.rpe}/10',
              style: const TextStyle(color: Colors.white)),
            Text('${widget.tonelagemKg.toStringAsFixed(0)} kg de volume total',
              style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
            const Text('#EuAtleta', style: TextStyle(color: Colors.white)),
            if (_playUrl.isNotEmpty) Text('Android: $_playUrl',
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11)),
            if (_appleUrl.isNotEmpty) Text('iPhone: $_appleUrl',
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11)),
            if (_playUrl == 'https://play.google.com/store/apps')
              const Text('Links de teste • App em preparação para publicação',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10)),
          ]),
        )),
        Wrap(spacing: 8, children: [
          TextButton.icon(onPressed: _ocupado ? null : () => _escolherFoto(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined), label: const Text('Adicionar foto')),
          TextButton.icon(onPressed: _ocupado ? null : () => _escolherFoto(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined), label: const Text('Tirar foto')),
          if (_foto != null) TextButton(onPressed: _ocupado ? null : () => setState(() => _foto = null),
            child: const Text('Remover foto')),
        ]),
        const Text('Escolha Instagram ou Facebook no compartilhamento do celular.'),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _ocupado ? null : _compartilhar,
          icon: const Icon(Icons.share), label: const Text('Compartilhar foto do treino')),
        TextButton(onPressed: () async {
          await Clipboard.setData(ClipboardData(text: _legenda));
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Legenda copiada. Cole na sua publicação.')));
        }, child: const Text('Copiar legenda')),
        TextButton(onPressed: _ocupado ? null : widget.onFechar, child: const Text('Agora não / Fechar')),
      ],
    ),
  ));
}
