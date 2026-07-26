import 'package:flutter/material.dart';
import '../../../../core/colors/app_colors.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Your Library\nComing Soon",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textSecondary, // Replaced Colors.white54
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}