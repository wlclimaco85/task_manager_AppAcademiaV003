import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/home_screen.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/email_verification_screeen.dart';
import 'package:task_manager_flutter/ui/screens/bottom_navbar_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _loginInProgress = false;

  // Usei as cores extraídas da sua logo:
  // Verde:  #005826  -> Color(0xFF005826)
  // Vermelho: #93070A -> Color(0xFF93070A)
  static const Color _logoGreen = Color(0xFF005826);
  static const Color _logoRed = Color(0xFF93070A);

  bool _obscurePassword = true;

  Future<void> login() async {
    setState(() => _loginInProgress = true);

    Map<String, dynamic> requestBody = {
      "email": _emailController.text.trim(),
      "password": _passwordController.text
    };
    final NetworkResponse response =
        await NetworkCaller().postRequest(ApiLinks.login, requestBody);

    setState(() => _loginInProgress = false);

    if (response.isSuccess) {
      LoginModel model = LoginModel.fromJson(response.body!);
      await AuthUtility.setUserInfo(model);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const BottomNavBarScreen()),
            (route) => false);
      }
    } else {
      if (mounted) {
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Incorrect email or password - ${ApiLinks.login}"),
          ),
        );
      }
    }
  }

  late AnimationController _animationController;

  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          });
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white70),
      labelStyle: const TextStyle(color: Colors.white),
      filled: false, // SEM fundo branco
      prefixIcon:
          prefixIcon != null ? Icon(prefixIcon, color: Colors.white) : null,
      suffixIcon: suffixIcon,
      // bordas vermelhas da logo
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _logoRed, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _logoRed, width: 2.5),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red.shade700, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _logoGreen, // fundo com a cor exata da logo
      body: Container(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 70,
                        bottom: 32,
                      ),
                      child: Image.asset(
                        "assets/images/Logo contabilidade_page-0001.jpg",
                        height: 260,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Campo Email (sem fundo branco, texto visível)
                                TextFormField(
                                  controller: _emailController,
                                  style: const TextStyle(color: Colors.white),
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _buildInputDecoration(
                                    hintText: "Email",
                                    prefixIcon: Icons.email,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter email";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Campo Senha (com eye toggle visível)
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _buildInputDecoration(
                                    hintText: "Password",
                                    prefixIcon: Icons.lock,
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.white, // ícone visível
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter password";
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _logoRed, // vermelho da logo
                              minimumSize: const Size.fromHeight(50),
                            ),
                            onPressed: _loginInProgress ? null : () => login(),
                            child: _loginInProgress
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Acessar',
                                    style: TextStyle(
                                      fontSize: 24,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 40),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const EmailVarificationScreeen()));
                              },
                              child: const Text(
                                "Esqueceu a Senha?",
                                style: TextStyle(
                                    color: Colors.white,
                                    letterSpacing: .7,
                                    fontSize: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
