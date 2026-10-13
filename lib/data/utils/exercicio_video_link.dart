/// Converte apenas links de video conhecidos para seus players incorporados.
Uri? exercicioVideoEmbed(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.scheme != 'https' || uri.userInfo.isNotEmpty) {
    return null;
  }
  final host = uri.host.toLowerCase();
  String? id;
  if (host == 'youtu.be') {
    id = uri.pathSegments.firstOrNull;
  } else if ([
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'youtube-nocookie.com',
    'www.youtube-nocookie.com'
  ].contains(host)) {
    if (uri.path == '/watch') id = uri.queryParameters['v'];
    if (uri.pathSegments.length >= 2 &&
        ['embed', 'shorts', 'live'].contains(uri.pathSegments.first)) {
      id = uri.pathSegments[1];
    }
  }
  if (id != null && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id)) {
    return Uri.https(
        'www.youtube.com', '/embed/$id', {'playsinline': '1', 'rel': '0'});
  }
  if (host == 'drive.google.com') {
    final segments = uri.pathSegments;
    if (segments.length >= 3 && segments[0] == 'file' && segments[1] == 'd') {
      id = segments[2];
    } else if (uri.path == '/open' || uri.path == '/uc') {
      id = uri.queryParameters['id'];
    }
    if (id != null && RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) {
      return Uri.https('drive.google.com', '/file/d/$id/preview');
    }
  }
  return null;
}

String? validarLinkVideoExercicio(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return exercicioVideoEmbed(value) == null
      ? 'Informe um link HTTPS de vídeo do YouTube ou de arquivo do Google Drive.'
      : null;
}
