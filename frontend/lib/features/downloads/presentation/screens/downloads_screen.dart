import 'package:flutter/material.dart';
import '../../../../core/colors/app_colors.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Replaced Color(0xFF0D0D0F)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Downloads",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_done_rounded,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.2), // Replaced raw white opacity
            ),
            const SizedBox(height: 20),
            const Text(
              "No Downloads Yet",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Episodes you download will appear here\nfor offline viewing.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary, // Replaced Colors.white54
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}