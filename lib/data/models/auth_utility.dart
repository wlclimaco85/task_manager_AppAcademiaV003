// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';

class AuthUtility {
  // Mantém não-nullable com valor padrão para compatibilidade com código legado
  static final ValueNotifier<LoginModel> session = ValueNotifier(LoginModel());
  static LoginModel get userInfo => session.value;
  static set userInfo(LoginModel model) => session.value = model;

  static Future<void> _gravacao = Future.value();
  static Future<void> _serializar(Future<void> Function() operacao) {
    final proxima = _gravacao.then((_) => operacao());
    _gravacao =
        proxima.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return proxima;
  }

  static Future<void> setUserInfo(LoginModel model,
          {LoginModel? sessaoEsperada}) =>
      _serializar(() async {
        final prefs = await SharedPreferences.getInstance();
        if (sessaoEsperada != null && !identical(userInfo, sessaoEsperada)) {
          throw StateError('A conta mudou. Abra o perfil novamente.');
        }
        if (!await prefs.setString("user_data", jsonEncode(model.toJson()))) {
          throw StateError('Não foi possível salvar a sessão neste aparelho.');
        }
        if (sessaoEsperada != null && !identical(userInfo, sessaoEsperada)) {
          final atual = userInfo;
          if (atual.token == null || atual.token!.isEmpty) {
            await prefs.remove("user_data");
          } else {
            await prefs.setString("user_data", jsonEncode(atual.toJson()));
          }
          throw StateError('A conta mudou. Abra o perfil novamente.');
        }
        userInfo = model;
      });

  static Future<LoginModel?> getUserInfo() async {
    try {
      SharedPreferences _sharedPreferences =
          await SharedPreferences.getInstance();
      String? value = _sharedPreferences.getString("user_data");
      if (value == null) return null;
      return LoginModel.fromJson(jsonDecode(value));
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearUserInfo() {
    userInfo = LoginModel();
    return _serializar(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("user_data");
    });
  }

  static Future<bool> isUserLoggedIn() async {
    SharedPreferences _sharedPreferences =
        await SharedPreferences.getInstance();
    bool isLogin = _sharedPreferences.containsKey("user_data");
    if (isLogin) {
      final info = await getUserInfo();
      if (info != null) {
        userInfo = info;
      } else {
        // Storage existe mas o JSON está corrompido / falhou o parse.
        // Não dá pra afirmar login válido — o token em cache pode ser de uma
        // sessão anterior. Força reautenticação.
        userInfo = LoginModel();
        isLogin = false;
      }
    } else {
      userInfo = LoginModel();
    }
    return isLogin && userInfo.token != null;
  }
}
