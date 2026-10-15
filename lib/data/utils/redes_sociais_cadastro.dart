/// Identificação opcional informada pelo usuário, sem consultar a rede social.
String? normalizarInstagramCadastro(String? valor) {
  var nome = (valor ?? '').trim();
  if (nome.isEmpty) return '';
  if (nome.startsWith('http://') || nome.startsWith('https://')) {
    final uri = Uri.tryParse(nome);
    if (uri == null ||
        !{'instagram.com', 'www.instagram.com'}
            .contains(uri.host.toLowerCase()) ||
        uri.userInfo.isNotEmpty ||
        (uri.hasPort && uri.port != (uri.scheme == 'https' ? 443 : 80))) {
      return null;
    }
    final partes = uri.pathSegments.where((p) => p.isNotEmpty).toList();
    if (partes.length != 1) return null;
    nome = partes.single;
  }
  if (nome.startsWith('@')) nome = nome.substring(1);
  return RegExp(r'^[A-Za-z0-9._]{1,30}$').hasMatch(nome) ? nome : null;
}

String? validarInstagramCadastro(String? valor) =>
    normalizarInstagramCadastro(valor) == null
        ? 'Informe @usuário ou o link do perfil no Instagram.'
        : null;

String? validarLinkBioCadastro(String? valor) {
  final texto = (valor ?? '').trim();
  if (texto.isEmpty) return null;
  final uri = Uri.tryParse(texto);
  return texto.length <= 2048 &&
          !RegExp(r'\s').hasMatch(texto) &&
          uri != null &&
          {'http', 'https'}.contains(uri.scheme) &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty
      ? null
      : 'Informe um link completo, começando com https://.';
}
