import 'package:flutter/material.dart';

import '../../../../core/colors/app_colors.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Release Calendar')),
      body: const Center(
        child: Text(
          'Release Calendar View',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
