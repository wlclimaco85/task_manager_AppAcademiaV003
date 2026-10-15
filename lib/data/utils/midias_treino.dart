import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'exercicio_video_link.dart';

const maxFotosTreino = 3;
const maxVideosTreino = 3;
const maxBytesFotoTreino = 150 * 1024;

/// O conteúdo acompanha a sessão: não depende do caminho temporário da câmera.
Future<String> prepararFotoTreino(Uint8List bytes) =>
    compute(_comprimirFotoTreino, bytes);

String _comprimirFotoTreino(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > 15 * 1024 * 1024) {
    throw const FormatException('Escolha uma imagem de até 15 MB.');
  }
  img.Image? decodificada;
  try {
    decodificada = img.decodeImage(bytes);
  } catch (_) {
    throw const FormatException('Formato de imagem não reconhecido.');
  }
  if (decodificada == null) {
    throw const FormatException('Formato de imagem não reconhecido.');
  }
  var foto = img.bakeOrientation(decodificada);
  if (foto.width > 1280 || foto.height > 1280) {
    foto = img.copyResize(foto,
        width: foto.width >= foto.height ? 1280 : null,
        height: foto.height > foto.width ? 1280 : null);
  }
  for (final qualidade in [82, 70, 58, 45]) {
    final jpg = img.encodeJpg(foto, quality: qualidade);
    if (jpg.length <= maxBytesFotoTreino) return base64Encode(jpg);
  }
  foto = img.copyResize(foto,
      width: foto.width >= foto.height ? 800 : null,
      height: foto.height > foto.width ? 800 : null);
  final jpg = img.encodeJpg(foto, quality: 45);
  if (jpg.length > maxBytesFotoTreino) {
    throw const FormatException(
        'Não foi possível reduzir a foto. Escolha outra imagem.');
  }
  return base64Encode(jpg);
}

String? validarMidiasSessaoTreino(List<String> fotos, List<String> videos) {
  if (fotos.length > maxFotosTreino) return 'Adicione no máximo 3 fotos.';
  if (videos.length > maxVideosTreino) return 'Adicione no máximo 3 vídeos.';
  for (final foto in fotos) {
    try {
      final bytes = base64Decode(foto);
      if (bytes.length > maxBytesFotoTreino ||
          bytes.length < 3 ||
          bytes[0] != 255 ||
          bytes[1] != 216) {
        return 'Uma foto é inválida ou excede 150 KB. Selecione a imagem novamente.';
      }
    } catch (_) {
      return 'Uma foto é inválida. Selecione a imagem novamente.';
    }
  }
  for (final link in videos) {
    if (link.length > 2048 || validarLinkVideoExercicio(link) != null) {
      return 'Use links HTTPS de vídeo do YouTube ou de arquivo do Google Drive.';
    }
  }
  return null;
}
