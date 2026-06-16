// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';

class AuthUtility {
  // Mantém não-nullable com valor padrão para compatibilidade com código legado
  static LoginModel userInfo = LoginModel();

  static Future<void> setUserInfo(LoginModel model) async {
    SharedPreferences _sharedPreferences =
        await SharedPreferences.getInstance();
    await _sharedPreferences.setString("user_data", jsonEncode(model.toJson()));
    userInfo = model;
  }

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

  static Future<void> clearUserInfo() async {
    SharedPreferences _sharedPreferences =
        await SharedPreferences.getInstance();
    await _sharedPreferences.remove("user_data");
    userInfo = LoginModel();
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
