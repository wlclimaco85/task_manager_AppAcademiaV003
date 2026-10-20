import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:task_manager_flutter/data/constants/app_version.dart';

/// Plataforma do acesso enviada no login: WEB, WINDOWS ou MOBILE.
String plataformaDoAcesso() {
  if (kIsWeb) return 'WEB';
  if (Platform.isWindows) return 'WINDOWS';
  return 'MOBILE';
}

/// Campos extras do login que alimentam o registro de acessos do painel do dono.
Map<String, String> dadosDeAcessoLogin() => {
      'aplicacao': 'EU_ATLETA',
      'plataforma': plataformaDoAcesso(),
      'versaoApp': '$kAppVersaoNome+$kAppVersaoBuild',
    };
