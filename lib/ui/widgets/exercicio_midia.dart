import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:task_manager_flutter/data/utils/exercicio_video_link.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

class ExercicioMidia extends StatefulWidget {
  final String url;
  final double height;
  const ExercicioMidia({super.key, required this.url, this.height = 250});
  @override
  State<ExercicioMidia> createState() => _ExercicioMidiaState();
}

class _ExercicioMidiaState extends State<ExercicioMidia> {
  bool _abrir = false;
  bool _erro = false;
  @override
  Widget build(BuildContext context) {
    final embed = exercicioVideoEmbed(widget.url);
    if (embed == null) {
      return Image.network(widget.url,
          height: widget.height,
          width: double.infinity,
          fit: BoxFit.contain, errorBuilder: (_, error, stack) {
        AppLogger.i.warn('Demonstracao do exercicio indisponivel.');
        return SizedBox(
            height: widget.height,
            child: const Center(child: Text('Demonstração indisponível')));
      });
    }
    return SizedBox(
        height: widget.height,
        child: !_abrir || _erro
            ? Center(
                child: FilledButton.icon(
                icon: const Icon(Icons.play_circle_outline),
                label: Text(_erro
                    ? 'Falha ao carregar. Tentar novamente'
                    : 'Assistir demonstração'),
                onPressed: () => setState(() {
                  _abrir = true;
                  _erro = false;
                }),
              ))
            : InAppWebView(
          initialUrlRequest: kIsWeb ? URLRequest(url: WebUri(embed.toString())) : null,
          initialData: kIsWeb ? null : InAppWebViewInitialData(
                  baseUrl: WebUri(
                      'https://com.washingtonclimaco.task_manager_appacademia/'),
                  data: '''<!DOCTYPE html><html><head>
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="referrer" content="strict-origin-when-cross-origin">
<style>html,body{margin:0;height:100%;background:#000}iframe{width:100%;height:100%;border:0}</style>
</head><body><iframe src="${const HtmlEscape(HtmlEscapeMode.attribute).convert(embed.toString())}"
allow="autoplay; encrypted-media; fullscreen; picture-in-picture" allowfullscreen
referrerpolicy="strict-origin-when-cross-origin"
sandbox="allow-scripts allow-same-origin allow-presentation allow-forms"></iframe></body></html>''',
                ),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  allowsInlineMediaPlayback: true,
                  mediaPlaybackRequiresUserGesture: true,
                  useShouldOverrideUrlLoading: true,
                  supportMultipleWindows: false,
                  javaScriptCanOpenWindowsAutomatically: false,
                  iframeAllow:
                      'autoplay; encrypted-media; fullscreen; picture-in-picture',
                  iframeAllowFullscreen: true,
            iframeReferrerPolicy: ReferrerPolicy.STRICT_ORIGIN_WHEN_CROSS_ORIGIN,
            iframeSandbox: {Sandbox.ALLOW_SCRIPTS, Sandbox.ALLOW_SAME_ORIGIN,
              Sandbox.ALLOW_PRESENTATION, Sandbox.ALLOW_FORMS},
                ),
                shouldOverrideUrlLoading: (_, navigation) async {
                  final scheme = navigation.request.url?.scheme;
                  return ['https', 'http', 'about'].contains(scheme)
                      ? NavigationActionPolicy.ALLOW
                      : NavigationActionPolicy.CANCEL;
                },
                onCreateWindow: (_, action) async => false,
                onReceivedError: (_, request, error) {
                  if (request.isForMainFrame == true) {
                    AppLogger.i
                        .warn('Falha ao carregar player interno do exercicio.');
                    if (mounted) setState(() => _erro = true);
                  }
                },
              ));
  }
}
