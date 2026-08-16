import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      scaffoldBackgroundColor:
          const Color(0xffF4F9FC),

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),

      textTheme:
          GoogleFonts.poppinsTextTheme(),

      appBarTheme: const AppBarTheme(
        backgroundColor:
            Color(0xffF4F9FC),
        foregroundColor:
            Color(0xff0F172A),
        elevation: 0,
      ),

      cardColor: Colors.white,

      navigationBarTheme:
          const NavigationBarThemeData(
        backgroundColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor:
          const Color(0xff0F172A),

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),

      textTheme:
          GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor:
            Color(0xff0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      cardColor:
          const Color(0xff1E293B),

      navigationBarTheme:
          const NavigationBarThemeData(
        backgroundColor:
            Color(0xff1E293B),
      ),
    );
  }
}