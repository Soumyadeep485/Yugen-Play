import 'package:flutter/material.dart';
import '../../../../core/colors/app_colors.dart';

class ListScreen extends StatelessWidget {
  const ListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Anime List\nComing Soon",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textSecondary, // Purged Colors.white54
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}