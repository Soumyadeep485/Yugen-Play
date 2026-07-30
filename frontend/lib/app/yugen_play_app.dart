import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/device_type.dart';
import '../features/main/presentation/screens/root_screen.dart';
import '../features/tv/presentation/screens/tv_root_screen.dart';

class YugenPlayApp extends StatelessWidget {
  const YugenPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('B. App build() called');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yugen Play',
      theme: AppTheme.darkTheme,
      // 📺 Traffic Switcher: TV gets TvRootScreen, Mobile gets RootScreen
      home: DeviceType.isTv ? const TvRootScreen() : const RootScreen(),
    );
  }
}