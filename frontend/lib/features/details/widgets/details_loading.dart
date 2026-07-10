import 'package:flutter/material.dart';

import '../../../core/colors/app_colors.dart';

class DetailsLoading extends StatefulWidget {
  const DetailsLoading({super.key});

  @override
  State<DetailsLoading> createState() => _DetailsLoadingState();
}

class _DetailsLoadingState extends State<DetailsLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget skeleton({double height = 20, double? width, double radius = 10}) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 0.8).animate(_controller),

      child: Container(
        width: width,
        height: height,

        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          skeleton(height: 420, radius: 0),

          Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                skeleton(width: 240, height: 32),

                const SizedBox(height: 12),

                skeleton(width: 160),

                const SizedBox(height: 24),

                Wrap(
                  spacing: 10,

                  children: [
                    skeleton(width: 70, height: 32),
                    skeleton(width: 80, height: 32),
                    skeleton(width: 90, height: 32),
                  ],
                ),

                const SizedBox(height: 30),

                skeleton(width: 120, height: 24),

                const SizedBox(height: 16),

                skeleton(),

                const SizedBox(height: 12),

                skeleton(),

                const SizedBox(height: 12),

                skeleton(),

                const SizedBox(height: 12),

                skeleton(width: 250),

                const SizedBox(height: 30),

                skeleton(width: 140, height: 24),

                const SizedBox(height: 18),

                skeleton(height: 70),

                const SizedBox(height: 14),

                skeleton(height: 70),

                const SizedBox(height: 14),

                skeleton(height: 70),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
