import 'package:flutter/material.dart';
import '../../../../core/colors/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Fixed hardcoded 0xFF0D0D0F
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Notifications",
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
              Icons.notifications_off_rounded,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.2), // Fixed hardcoded white opacity
            ),
            const SizedBox(height: 20),
            const Text(
              "No Notifications",
              style: TextStyle(
                color: AppColors.textPrimary, // Fixed
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You're all caught up! New episode\nalerts and updates will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary, // Fixed hardcoded white54
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