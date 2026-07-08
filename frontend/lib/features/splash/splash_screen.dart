import 'package:flutter/material.dart';
import '../../core/colors/app_colors.dart';
import '../../core/spacing/app_spacing.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    print("Splash Screen Started");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_circle_fill_rounded,
              size: 100,
              color: AppColors.primary,
            ),

            SizedBox(height: AppSpacing.lg),

            Text(
              "Yugen Play",
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 12),

            Text(
              "Watch Beyond Limits",
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
