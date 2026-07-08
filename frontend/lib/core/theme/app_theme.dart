import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../typography/app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,

      useMaterial3: true,

      scaffoldBackgroundColor: AppColors.background,

      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: AppColors.primary,
      ),

      textTheme: AppTypography.textTheme,
    );
  }
}
