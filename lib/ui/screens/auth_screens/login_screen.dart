import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/home_screen.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/grid_colors.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/email_verification_screeen.dart';
import 'package:task_manager_flutter/ui/screens/bottom_navbar_screen.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/wizard_aluno_screen.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/wizard_personal_screen.dart';

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
      hintStyle: const TextStyle(color: GridColors.textMuted),
      labelStyle: const TextStyle(color: GridColors.textPrimary),
      filled: true,
      fillColor: GridColors.inputBackground,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: GridColors.textSecondary) : null,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: GridColors.inputBorder, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: GridColors.primary, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: GridColors.error, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _showCriarContaBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: GridColors.background,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Como você deseja se cadastrar?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: GridColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _OpcaoCadastroTile(
                  icone: Icons.fitness_center,
                  titulo: 'Aluno',
                  descricao: 'Quero treinar',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const WizardAlunoScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _OpcaoCadastroTile(
                  icone: Icons.sports_gymnastics,
                  titulo: 'Personal',
                  descricao: 'Sou personal trainer',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const WizardPersonalScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _OpcaoCadastroTile(
                  icone: Icons.apartment,
                  titulo: 'Academia',
                  descricao: 'Tenho uma academia',
                  habilitado: false,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Em breve')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: GridColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Image.asset(
                "assets/images/logoforafitn1.png",
                height: 140,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              // App Name
              const Text(
                "AppAcademia Pro",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: GridColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Faça login para continuar",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: GridColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: GridColors.textPrimary),
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildInputDecoration(
                        hintText: "Email",
                        prefixIcon: Icons.email_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Por favor, insira o email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Senha
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: GridColors.textPrimary),
                      decoration: _buildInputDecoration(
                        hintText: "Senha",
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: GridColors.textSecondary,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Por favor, insira a senha";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Botão Acessar
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.primary,
                  foregroundColor: GridColors.buttonText,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: _loginInProgress
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          login();
                        }
                      },
                child: _loginInProgress
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: GridColors.buttonText,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Acessar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              // Botão Criar Conta
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: GridColors.primary, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _showCriarContaBottomSheet,
                child: const Text(
                  'Criar conta',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: GridColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Esqueceu a senha
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
                      color: GridColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpcaoCadastroTile extends StatelessWidget {
  const _OpcaoCadastroTile({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.onTap,
    this.habilitado = true,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final VoidCallback onTap;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final Color corIcone = habilitado ? GridColors.primary : GridColors.divider;
    final Color corTexto =
        habilitado ? GridColors.textPrimary : GridColors.textMuted;
    final Color corDesc =
        habilitado ? GridColors.textSecondary : GridColors.textMuted;

    return InkWell(
      onTap: habilitado ? onTap : () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Em breve')),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: GridColors.inputBorder),
          borderRadius: BorderRadius.circular(12),
          color: GridColors.card,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: habilitado
                    ? GridColors.primary.withOpacity(0.1)
                    : GridColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icone, size: 32, color: corIcone),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: corTexto,
                        ),
                      ),
                      if (!habilitado) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: GridColors.secondary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Em breve',
                            style: TextStyle(
                              color: GridColors.secondaryDark,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descricao,
                    style: TextStyle(
                      fontSize: 14,
                      color: corDesc,
                    ),
                  ),
                ],
              ),
            ),
            if (habilitado)
              const Icon(Icons.chevron_right, color: GridColors.textMuted),
          ],
        ),
      ),
    );
  }
}
