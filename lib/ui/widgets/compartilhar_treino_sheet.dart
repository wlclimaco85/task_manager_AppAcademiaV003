import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';
import 'package:task_manager_flutter/ui/widgets/midias_sessao_treino.dart';

import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/utils/fitness_access.dart';

class CompartilharTreinoSheet extends StatefulWidget {
  final String treino;
  final int minutos, series, rpe;
  final double tonelagemKg;
  final VoidCallback onFechar;
  final List<String> fotosIniciais;
  final Future<void> Function(List<String>)? onFotosAlteradas;
  final String? personalNome;
  final String? personalInstagram;

  /// Permite reutilizar o card de publicação para uma atividade sem exibir
  /// métricas de musculação.
  final String tituloCompartilhamento;
  final String? resumoPrincipal;
  final String? resumoSecundario;

  const CompartilharTreinoSheet({
    super.key,
    required this.treino,
    required this.minutos,
    required this.series,
    required this.rpe,
    required this.tonelagemKg,
    required this.onFechar,
    this.fotosIniciais = const [],
    this.onFotosAlteradas,
    this.personalNome,
    this.personalInstagram,
    this.tituloCompartilhamento = 'Treino salvo! Compartilhar?',
    this.resumoPrincipal,
    this.resumoSecundario,
  });

  @override
  State<CompartilharTreinoSheet> createState() =>
      _CompartilharTreinoSheetState();
}

class _CompartilharTreinoSheetState extends State<CompartilharTreinoSheet> {
  final _cardKey = GlobalKey();
  late final List<String> _fotos = List.of(widget.fotosIniciais.take(3));
  int _fotoSelecionada = 0;
  Uint8List? _fotoEmMemoria;
  String? _base64DaFotoEmMemoria;
  late final TextEditingController _personalCtrl;
  bool _temPersonalVinculado = false;

  static const _instagramOficialUrl =
      'https://www.instagram.com/euatletafitnes/';
  static const _instagramOficialArroba = '@euatletafitnes';

  @override
  void initState() {
    super.initState();
    _inicializarPersonal();
  }

  @override
  void dispose() {
    _personalCtrl.dispose();
    super.dispose();
  }

  void _inicializarPersonal() {
    String nomePersonal = widget.personalNome?.trim() ?? '';
    if (nomePersonal.isEmpty && !podeGerenciarAlunos()) {
      final parceiro = AuthUtility.userInfo.login?.parceiro;
      nomePersonal =
          parceiro?.nome?.trim() ?? parceiro?.razaoSocial?.trim() ?? '';
    }

    String arrobaPersonal = widget.personalInstagram?.trim() ?? '';
    if (arrobaPersonal.isEmpty && nomePersonal.isNotEmpty) {
      final limpo =
          nomePersonal.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
      arrobaPersonal = '@$limpo';
    } else if (arrobaPersonal.isNotEmpty && !arrobaPersonal.startsWith('@')) {
      arrobaPersonal = '@$arrobaPersonal';
    }

    _temPersonalVinculado =
        nomePersonal.isNotEmpty || arrobaPersonal.isNotEmpty;
    _personalCtrl = TextEditingController(text: arrobaPersonal);
  }

  String get _personalArrobaFormatado {
    final texto = _personalCtrl.text.trim();
    if (texto.isEmpty) return '';
    return texto.startsWith('@') ? texto : '@$texto';
  }

  Uint8List? get _foto {
    if (_fotos.isEmpty) return null;
    final base64 = _fotos[_fotoSelecionada];
    if (_base64DaFotoEmMemoria == base64 && _fotoEmMemoria != null)
      return _fotoEmMemoria;
    try {
      final foto = base64Decode(base64);
      _base64DaFotoEmMemoria = base64;
      _fotoEmMemoria = foto;
      return foto;
    } on FormatException {
      _base64DaFotoEmMemoria = base64;
      _fotoEmMemoria = null;
      return null;
    }
  }

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

  String get _legenda {
    final sb = StringBuffer();
    sb.writeln(
        widget.tituloCompartilhamento.replaceFirst('! Compartilhar?', '') +
            ' no Eu Atleta! 💪');
    sb.writeln(widget.treino);
    sb.writeln(widget.resumoPrincipal ??
        '${widget.minutos} min • ${widget.series} séries • RPE ${widget.rpe}/10');
    if (widget.resumoSecundario != null) {
      sb.writeln(widget.resumoSecundario);
    } else {
      sb.writeln('${widget.tonelagemKg.toStringAsFixed(0)} kg de volume total');
    }
    sb.writeln();
    sb.writeln(_instagramOficialArroba);
    sb.writeln(_instagramOficialUrl);

    final personalTag = _personalArrobaFormatado;
    if (personalTag.isNotEmpty) {
      sb.writeln('Personal: $personalTag');
    }

    sb.writeln();
    if (_playUrl.isNotEmpty) {
      sb.writeln(
          '${_playUrl == 'https://play.google.com/store/apps' ? 'Android (link de teste)' : 'Baixe para Android'}: $_playUrl');
    }
    if (_appleUrl.isNotEmpty) {
      sb.writeln(
          '${_appleUrl == 'https://apps.apple.com/br/' ? 'iPhone (link de teste)' : 'Baixe para iPhone'}: $_appleUrl');
    }
    sb.write('#EuAtleta #euatletafitnes');
    return sb.toString();
  }

  Future<void> _alterarFotos(List<String> fotos) async {
    await widget.onFotosAlteradas?.call(fotos);
    if (!mounted) return;
    setState(() {
      _fotos
        ..clear()
        ..addAll(fotos);
      _fotoSelecionada = _fotos.isEmpty ? 0 : _fotos.length - 1;
    });
  }

  Future<void> _removerFoto() async {
    setState(() => _ocupado = true);
    try {
      final fotos = List<String>.of(_fotos)..removeAt(_fotoSelecionada);
      await _alterarFotos(fotos);
    } catch (error, stack) {
      AppLogger.i.error('Falha ao remover foto do histórico.', stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Não foi possível salvar a alteração. Tente novamente.')));
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _escolherFoto(ImageSource source) async {
    if (_fotos.length >= 3) return;
    setState(() => _ocupado = true);
    try {
      final arquivo = await ImagePicker()
          .pickImage(source: source, maxWidth: 1200, imageQuality: 80);
      if (arquivo == null) return;
      final foto = await prepararFotoTreino(await arquivo.readAsBytes());
      await _alterarFotos([..._fotos, foto]);
    } catch (error, stack) {
      AppLogger.i.error('Falha ao selecionar ou salvar foto do treino.', stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível salvar a foto. Tente novamente.')));
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  /// Renderiza o card EU ATLETA em PNG (bytes em memória).
  Future<Uint8List> _renderizarCardBytes() async {
    // A captura pode começar antes de Image.memory terminar a decodificação.
    // Sem aguardar essa etapa, o card mantém o espaço da foto, porém sai sem
    // os pixels dela no story compartilhado.
    final foto = _foto;
    if (foto != null) await precacheImage(MemoryImage(foto), context);
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final imagem = await boundary.toImage(pixelRatio: 3);
    final dados = await imagem.toByteData(format: ui.ImageByteFormat.png);
    imagem.dispose();
    return dados!.buffer.asUint8List();
  }

  Future<void> _compartilharInstagram() async {
    setState(() => _ocupado = true);
    try {
      final bytes = await _renderizarCardBytes();
      if (!mounted) return;

      // Copia a legenda para a área de transferência
      await Clipboard.setData(ClipboardData(text: _legenda));

      if (kIsWeb) {
        // Na Web: baixa a imagem para a máquina e abre o Instagram no perfil oficial
        final xFile = XFile.fromData(bytes,
            mimeType: 'image/png', name: 'meu-treino.png');
        try {
          await xFile.saveTo('meu-treino.png');
        } catch (_) {}

        final urlInstagram = Uri.parse(_instagramOficialUrl);
        await launchUrl(urlInstagram, mode: LaunchMode.externalApplication);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Imagem do treino baixada e legenda copiada marcando @euatletafitnes! Abra o Instagram para publicar.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // No Mobile (Android / iOS)
      final xFile =
          XFile.fromData(bytes, mimeType: 'image/png', name: 'meu-treino.png');
      final box = context.findRenderObject() as RenderBox?;
      final origin =
          box != null ? (box.localToGlobal(Offset.zero) & box.size) : null;

      final uriApp = Uri.parse('instagram://sharesheet');
      if (await canLaunchUrl(uriApp)) {
        await Share.shareXFiles([xFile],
            text: _legenda, sharePositionOrigin: origin);
      } else {
        await Share.shareXFiles([xFile],
            text: _legenda, sharePositionOrigin: origin);
        final uriWeb = Uri.parse('https://www.instagram.com/');
        if (await canLaunchUrl(uriWeb) && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Salve a imagem e publique no Instagram.')),
          );
        }
      }
    } catch (error, stack) {
      AppLogger.i.error('Falha ao compartilhar no Instagram.', stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Não foi possível abrir o Instagram. Verifique se está instalado.')));
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _compartilharFacebook() async {
    setState(() => _ocupado = true);
    try {
      final bytes = await _renderizarCardBytes();
      if (!mounted) return;

      // Copia a legenda para a área de transferência
      await Clipboard.setData(ClipboardData(text: _legenda));

      if (kIsWeb) {
        // Na Web: baixa a imagem para a máquina e abre o Facebook no navegador
        final xFile = XFile.fromData(bytes,
            mimeType: 'image/png', name: 'meu-treino.png');
        try {
          await xFile.saveTo('meu-treino.png');
        } catch (_) {}

        final urlFacebook = Uri.parse('https://www.facebook.com/');
        await launchUrl(urlFacebook, mode: LaunchMode.externalApplication);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Imagem do treino baixada e legenda copiada! Cole no Facebook para publicar.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // No Mobile (Android / iOS)
      final xFile =
          XFile.fromData(bytes, mimeType: 'image/png', name: 'meu-treino.png');
      final box = context.findRenderObject() as RenderBox?;
      final origin =
          box != null ? (box.localToGlobal(Offset.zero) & box.size) : null;
      await Share.shareXFiles([xFile],
          text: _legenda, sharePositionOrigin: origin);
    } catch (error, stack) {
      AppLogger.i.error('Falha ao compartilhar no Facebook.', stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Não foi possível abrir o Facebook. Verifique se está instalado.')));
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _compartilhar() async {
    setState(() => _ocupado = true);
    try {
      final bytes = await _renderizarCardBytes();
      if (!mounted) return;

      final xFile =
          XFile.fromData(bytes, mimeType: 'image/png', name: 'meu-treino.png');
      final box = context.findRenderObject() as RenderBox?;
      final origin =
          box != null ? (box.localToGlobal(Offset.zero) & box.size) : null;

      if (kIsWeb) {
        try {
          await Share.shareXFiles([xFile],
              text: _legenda, sharePositionOrigin: origin);
        } catch (_) {
          await xFile.saveTo('meu-treino.png');
          await Clipboard.setData(ClipboardData(text: _legenda));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Imagem baixada e legenda copiada!')),
            );
          }
        }
      } else {
        await Share.shareXFiles([xFile],
            text: _legenda, sharePositionOrigin: origin);
      }
    } catch (error, stack) {
      AppLogger.i.error('Falha ao compartilhar foto do treino.', stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível compartilhar. Tente novamente.')));
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.tituloCompartilhamento,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            RepaintBoundary(
                key: _cardKey,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: const Color(0xFF064E3B),
                      borderRadius: BorderRadius.circular(20)),
                  child: Column(children: [
                    const Text('EU ATLETA',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20)),
                    const SizedBox(height: 12),
                    if (_foto != null)
                      ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_foto!,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white))),
                    const SizedBox(height: 12),
                    Text(widget.treino,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18)),
                    const SizedBox(height: 12),
                    Text(
                        widget.resumoPrincipal ??
                            '${widget.minutos} min • ${widget.series} séries • RPE ${widget.rpe}/10',
                        style: const TextStyle(color: Colors.white)),
                    Text(
                        widget.resumoSecundario ??
                            '${widget.tonelagemKg.toStringAsFixed(0)} kg de volume total',
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 12),
                    const Text('#EuAtleta',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          FaIcon(FontAwesomeIcons.instagram,
                              color: Colors.white, size: 12),
                          SizedBox(width: 6),
                          Text('@euatletafitnes',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    if (_personalArrobaFormatado.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Personal: $_personalArrobaFormatado',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 6),
                    if (_playUrl.isNotEmpty)
                      Text('Android: $_playUrl',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11)),
                    if (_appleUrl.isNotEmpty)
                      Text('iPhone: $_appleUrl',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11)),
                    if (_playUrl == 'https://play.google.com/store/apps')
                      const Text(
                          'Links de teste • App em preparação para publicação',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 10)),
                  ]),
                )),
            if (_fotos.isNotEmpty)
              Wrap(spacing: 8, children: [
                for (var i = 0; i < _fotos.length; i++)
                  ChoiceChip(
                      label: Text('Foto ${i + 1}'),
                      selected: _fotoSelecionada == i,
                      onSelected: _ocupado
                          ? null
                          : (_) => setState(() => _fotoSelecionada = i)),
              ]),
            Text('Fotos: ${_fotos.length}/3'),
            Wrap(spacing: 8, children: [
              TextButton.icon(
                  onPressed: _ocupado || _fotos.length >= 3
                      ? null
                      : () => _escolherFoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Adicionar foto')),
              TextButton.icon(
                  onPressed: _ocupado || _fotos.length >= 3
                      ? null
                      : () => _escolherFoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Tirar foto')),
              if (_foto != null)
                TextButton(
                    onPressed: _ocupado ? null : _removerFoto,
                    child: const Text('Remover foto')),
            ]),
            if (_temPersonalVinculado) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextField(
                  controller: _personalCtrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline, size: 18),
                    labelText: 'Marcar Personal (Instagram)',
                    hintText: '@personal',
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
            // ── Botões de redes sociais ──────────────────────────────────
            const SizedBox(height: 8),
            const Text('Compartilhar em:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              // Botão Instagram
              Expanded(
                  child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE1306C),
                  side: const BorderSide(color: Color(0xFFE1306C)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _ocupado ? null : _compartilharInstagram,
                icon: const FaIcon(FontAwesomeIcons.instagram, size: 20),
                label: const Text('Instagram'),
              )),
              const SizedBox(width: 10),
              // Botão Facebook
              Expanded(
                  child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1877F2),
                  side: const BorderSide(color: Color(0xFF1877F2)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _ocupado ? null : _compartilharFacebook,
                icon: const FaIcon(FontAwesomeIcons.facebook, size: 20),
                label: const Text('Facebook'),
              )),
            ]),
            const SizedBox(height: 12),
            FilledButton.icon(
                onPressed: _ocupado ? null : _compartilhar,
                icon: const Icon(Icons.share),
                label: const Text('Compartilhar foto')),
            TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _legenda));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text('Legenda copiada. Cole na sua publicação.')));
                  }
                },
                child: const Text('Copiar legenda')),
            TextButton(
                onPressed: _ocupado ? null : widget.onFechar,
                child: const Text('Agora não / Fechar')),
          ],
        ),
      ));
}
