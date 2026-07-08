import 'package:flutter/material.dart';

import '../../core/colors/app_colors.dart';
import '../../core/radius/app_radius.dart';

class AppTextField extends StatelessWidget {
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;

  const AppTextField({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: AppColors.textSecondary),
        filled: true,
        fillColor: const Color(0xFF1B1B1B),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
