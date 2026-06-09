import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/login_screen.dart';
import 'package:task_manager_flutter/ui/screens/bottom_navbar_screen.dart';
import 'package:task_manager_flutter/ui/utils/assets_utils.dart';
import 'package:task_manager_flutter/ui/widgets/screen_background.dart';

class GridColors {
  static const Color primary = Color(0xFF5937B2);
  static const Color secondary = Color(0xFFFA903A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF241B3F);
  static const Color error = Color(0xFFD32F2F);
  static const Color divider = Color(0xFFBDBDBD);
  static const Color card = Color(0xFFFFFFFF);
  static const Color filterBackground = Color(0xFFEFEFEF);
  static const Color background = Color(0xFF5937B2);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    navigateToLogin();
  }

  void navigateToLogin() {
    Future.delayed(const Duration(seconds: 3)).then((_) async {
      if (mounted) {
        final bool loggedIn = await AuthUtility.isUserLoggedIn();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                loggedIn ? const BottomNavBarScreen() : const LoginScreen(),
          ),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo JPG - Corrigido
              Image.asset(
                AssetsUtils.logoJPG,
                width: 90,
                height: 90,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback se a imagem não carregar
                  return const Icon(
                    Icons.apps,
                    size: 90,
                    color: GridColors.textPrimary,
                  );
                },
              ),

              const SizedBox(height: 40),

              // Texto "Carregando..."
              const Text(
                'Carregando...',
                style: TextStyle(
                  color: GridColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 20),

              // Indicador de loading
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    GridColors.textPrimary,
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
