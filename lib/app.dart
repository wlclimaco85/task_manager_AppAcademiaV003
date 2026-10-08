import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/ui/screens/splash_screens.dart';

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});
  static GlobalKey<NavigatorState> globalKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.poppinsTextTheme();

    return MaterialApp(
      navigatorKey: globalKey,
      debugShowCheckedModeBanner: false,
      title: "AppAcademia Pro",
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: GridColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: GridColors.primary,
          primary: GridColors.primary,
          secondary: GridColors.secondary,
          surface: GridColors.card,
          error: GridColors.error,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
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
        cardTheme: CardTheme(
          color: GridColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: GridColors.divider, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: GridColors.inputBackground,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          hintStyle: const TextStyle(
            color: GridColors.textMuted,
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: GridColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: GridColors.inputBorder),
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
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
