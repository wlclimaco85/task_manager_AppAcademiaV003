import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tema escolhido pelo usuario no perfil.
/// padrao = o visual atual do app; branco e barby = claros; preto = escuro.
enum TemaApp { padrao, branco, preto, barby }

/// Preferencia de tema guardada no aparelho (nao depende de conta nem de servidor).
class PreferenciaTema {
  PreferenciaTema._();

  static const String _chave = 'tema_app_v1';

  /// Escutado pelo MaterialApp: trocar aqui troca o tema de todo o app na hora.
  static final ValueNotifier<TemaApp> tema = ValueNotifier<TemaApp>(TemaApp.padrao);

  static ThemeMode modoDe(TemaApp escolhido) {
    return switch (escolhido) {
      // Padrao = layout atual do app (claro). Nao segue o modo escuro do aparelho.
      TemaApp.padrao => ThemeMode.light,
      TemaApp.branco => ThemeMode.light,
      TemaApp.preto => ThemeMode.dark,
      TemaApp.barby => ThemeMode.light,
    };
  }

  /// Le o tema salvo. Valor desconhecido ou ausente cai no padrao.
  static TemaApp lerSalvo(String? valor) {
    for (final t in TemaApp.values) {
      if (t.name == valor) return t;
    }
    return TemaApp.padrao;
  }

  /// Carrega a escolha salva. Chamar uma vez antes de runApp.
  static Future<void> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    tema.value = lerSalvo(prefs.getString(_chave));
  }

  static Future<void> definir(TemaApp escolhido) async {
    tema.value = escolhido;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chave, escolhido.name);
  }
}
