import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme {
    return GoogleFonts.poppinsTextTheme(
      const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.bold),

        headlineLarge: TextStyle(fontWeight: FontWeight.bold),

        titleLarge: TextStyle(fontWeight: FontWeight.w600),

        bodyLarge: TextStyle(fontWeight: FontWeight.w400),

        bodyMedium: TextStyle(fontWeight: FontWeight.w400),
      ),
    );
  }
}
