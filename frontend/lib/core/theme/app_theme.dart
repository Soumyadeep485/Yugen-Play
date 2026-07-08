import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),

      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7B2FF7),
        brightness: Brightness.dark,
      ),

      useMaterial3: true,
    );
  }
}
