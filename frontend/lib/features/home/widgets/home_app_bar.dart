import 'package:flutter/material.dart';

import '../../../core/colors/app_colors.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),

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
            onPressed: () {},

            icon: const Icon(
              Icons.search_rounded,
              color: AppColors.textPrimary,
            ),
          ),

          IconButton(
            onPressed: () {},

            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
