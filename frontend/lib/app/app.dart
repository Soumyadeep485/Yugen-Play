import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../features/splash/splash_screen.dart';

class YugenPlayApp extends StatelessWidget {
  const YugenPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yugen Play',
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
