import 'package:task_manager_flutter/ui/screens/fitness/meu_perfil_screen.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/services/preferencia_tema_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/services/auth_service.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';
import 'package:task_manager_flutter/ui/widgets/authenticated_header_shell.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/ui/screens/splash_screens.dart';

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});
  static GlobalKey<NavigatorState> globalKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.poppinsTextTheme();

    return ValueListenableBuilder<TemaApp>(
      valueListenable: PreferenciaTema.tema,
      builder: (context, tema, _) => MaterialApp(
      navigatorKey: globalKey,
      builder: (context, child) => AuthenticatedHeaderShell(
        child: child ?? const SizedBox.shrink(),
        onEditar: () => globalKey.currentState?.push(MaterialPageRoute(builder: (_) => const MeuPerfilScreen())),
        onSair: () async {
          try {
            await AuthService().clearToken();
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('user_permissions');
            await AuthUtility.clearUserInfo();
            globalKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
          } catch (error, stack) {
            AppLogger.i.error('Falha ao encerrar sessão.', stack);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Não foi possível sair. Tente novamente.')));
            }
          }
        },
      ),
      debugShowCheckedModeBanner: false,
      title: "Eu Atleta",
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: fundoTemaClaro(tema),
        colorScheme: ColorScheme.fromSeed(
          seedColor: GridColors.primary,
          primary: GridColors.primary,
          secondary: GridColors.secondary,
          surface: GridColors.card,
          error: GridColors.error,
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: GridColors.card,
          foregroundColor: GridColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: GridColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: GridColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: GridColors.divider, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: GridColors.inputBackground,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          hintStyle: TextStyle(
            color: GridColors.textMuted,
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: GridColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: GridColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: GridColors.primary, width: 1.5),
          ),
        ),
        textTheme: baseTextTheme.copyWith(
          titleLarge: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: GridColors.textPrimary,
          ),
          titleMedium: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: GridColors.textPrimary,
          ),
          bodyMedium: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: GridColors.textPrimary,
          ),
          bodySmall: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: GridColors.textSecondary,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: GridColors.buttonBackground,
            foregroundColor: GridColors.buttonText,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: GridColors.primary,
            side: const BorderSide(color: GridColors.primary, width: 1.2),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      themeMode: PreferenciaTema.modoDe(tema),
      darkTheme: temaEscuro(),
      home: const SplashScreen(),
      ),
    );
  }

  static Color fundoTemaClaro(TemaApp tema) =>
      tema == TemaApp.branco ? Colors.white : GridColors.background;

  /// Tema escuro com fundo preto (opcao Preto no perfil).
  static ThemeData temaEscuro() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: GridColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF111827),
          surfaceContainerLow: const Color(0xFF18212F),
          surfaceContainer: const Color(0xFF1E293B),
          onSurface: const Color(0xFFF8FAFC),
          onSurfaceVariant: const Color(0xFFCBD5E1),
          outline: const Color(0xFF64748B),
          outlineVariant: const Color(0xFF334155),
        ),
        scaffoldBackgroundColor: Colors.black,
        cardColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF111827),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF18212F),
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: GridColors.primaryLight, width: 1.5),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF111827),
          indicatorColor: Color(0xFF064E3B),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF111827),
          modalBackgroundColor: Color(0xFF111827),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      );
}
