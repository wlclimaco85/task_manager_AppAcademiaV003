import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/services/recuperacao_senha_service.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/login_screen.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/reset_screen.dart';
import 'package:task_manager_flutter/ui/widgets/custom_button.dart';
import 'package:task_manager_flutter/ui/widgets/screen_background.dart';
import 'package:task_manager_flutter/ui/widgets/signup_button.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.email,
  });
  final String email;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpTEController = TextEditingController();
  bool _isLoading = false;
  final GlobalKey<FormState> _otpFormKey = GlobalKey<FormState>();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> otpVerify() async {
    _isLoading = true;
    setState(() {});

    final resultado = await RecuperacaoSenhaService.validarCodigo(
        widget.email, _otpTEController.text.trim());

    _isLoading = false;
    setState(() {});
    final BuildContext context = this.context;
    if (resultado.ok) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              email: widget.email,
              otp: _otpTEController.text.trim(),
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.mensagem),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: ScreenBackground(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                Text(
                  "VERIFICAÇÃO DO CÓDIGO",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  "Enviamos um código de 6 dígitos para o seu e-mail. Digite-o abaixo para continuar.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 16),
                Form(
                  key: _otpFormKey,
                  child: PinCodeTextField(
                    controller: _otpTEController,
                    appContext: context,
                    length: 6,
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    animationDuration: const Duration(milliseconds: 300),
                    enableActiveFill: true,
                    cursorColor: Colors.green,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(5),
                      fieldHeight: 50,
                      borderWidth: 0.5,
                      fieldWidth: 50,
                      inactiveFillColor: Colors.white,
                      inactiveColor: Colors.white,
                      activeColor: Colors.white,
                      selectedColor: Colors.green,
                      selectedFillColor: Colors.white,
                      activeFillColor: Colors.white,
                    ),
                  ),
                ),
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : CustomButton(
                        onPresse: () {
                          otpVerify();
                        },
                        labels: "Validar código",
                      ),
                const SizedBox(
                  height: 16,
                ),
                SignUpButton(
                  text: "Já tem conta?",
                  onPresse: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()));
                  },
                  buttonText: 'Entrar',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
