import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/ui/screens/ForgotPasswordScreen_screens.dart';
import 'package:task_manager_flutter/ui/screens/SignUpScreen_screens.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';

class LoginPopup extends StatefulWidget {
  const LoginPopup({super.key});

  @override
  _LoginPopupState createState() => _LoginPopupState();
}

class _LoginPopupState extends State<LoginPopup> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? errorMessage; // Armazena mensagens de erro
  bool isLoading = false;

  Future<void> loginss(String username, String password) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    Map<String, dynamic> requestBody = {
      "email": username,
      "password": password,
    };

    try {
      final NetworkResponse response =
          await NetworkCaller().postRequest(ApiLinks.login, requestBody);

      setState(() {
        isLoading = false;
      });

      if (response.isSuccess) {
        LoginModel model = LoginModel.fromJson(response.body!);
        await AuthUtility.setUserInfo(model);

        if (mounted) {
          AuthUtility.userInfo?.token = model.token;
          Navigator.of(context).pop();
        }
      } else if (response.statusCode == 400) {
        setState(() {
          errorMessage = 'Senha ou usuário inválido';
        });
      } else {
        setState(() {
          errorMessage = 'Erro: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erro: $e';
      });
    }
  }

  Future<void> _submitLogin() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    if (username.isNotEmpty && password.isNotEmpty) {
      await loginss(username, password);
    } else {
      setState(() {
        errorMessage = 'Preencha os campos corretamente!';
      });
    }
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 231, 247, 233),
      title: const Text(
        'Login',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Usuário',
                labelStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: const Color.fromARGB(255, 128, 202, 132),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Senha',
                labelStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: const Color.fromARGB(255, 128, 202, 132),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 5),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton(
                  onPressed: _navigateToForgotPassword,
                  child: const Text(
                    'Esqueci a senha',
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: _navigateToSignUp,
                  child: const Text(
                    'Criar Novo Usuário',
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 128, 202, 132),
          ),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.white),
          ),
        ),
        if (isLoading)
          const CircularProgressIndicator()
        else
          ElevatedButton(
            onPressed: _submitLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 128, 202, 132),
            ),
            child: const Text(
              'Entrar',
              style: TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }
}
