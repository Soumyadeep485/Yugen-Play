import 'package:flutter/material.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/radius/app_radius.dart';

class SearchInput extends StatelessWidget {
  const SearchInput({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: const TextStyle(color: AppColors.textPrimary), // Fixed
      decoration: InputDecoration(
        hintText: "Search anime...",
        hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8)), // Fixed
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary), // Fixed
        filled: true,
        fillColor: AppColors.card, // Fixed hardcoded hex

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}