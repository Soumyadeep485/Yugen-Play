import 'dart:ui';
import 'package:flutter/material.dart';
import '../../search/search_screen.dart';
import '../../../core/colors/app_colors.dart';
import '../../settings/screens/extension_manager_screen.dart';
import '../../notifications/screens/notifications_screen.dart'; // Adjust path if needed

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          // 40% opacity over your dark background for a frosted look
          color: const Color(0xFF0D0D0F).withValues(alpha: 0.6),
          padding: EdgeInsets.only(
            top:
                MediaQuery.paddingOf(context).top +
                12, // Respect safe area here instead
            bottom: 12,
            left: 20,
            right: 20,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.primary,
                size: 34,
              ),
              const SizedBox(width: 12),
              Text(
                "Yugen Play",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),

              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                },
                icon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textPrimary,
                ),
              ),

              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExtensionManagerScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.extension_rounded,
                  color: AppColors.textPrimary,
                ),
              ),

              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
