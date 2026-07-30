import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/device_type.dart';
import 'package:frontend/features/player/services/extension_manager.dart';
import 'package:media_kit/media_kit.dart';
import 'features/main/presentation/screens/root_screen.dart';
import 'features/tv/presentation/screens/tv_root_screen.dart';
import 'app/yugen_play_app.dart';
import 'core/storage/hive_service.dart';
import 'service_locator.dart';
import 'src/rust/frb_generated.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Core initializations needed for basic app launch
  await DeviceType.init();
  await HiveService.initialize();
  MediaKit.ensureInitialized();
  await RustLib.init();

  // 2. Setup Service Locator
  setupServiceLocator();

  // 3. Mount UI immediately
  runApp(const ProviderScope(child: YugenPlayApp()));

  // 4. DEFER EXTENSIONS: Load installed extensions AFTER the app UI mounts
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final extensionManager = locator<ExtensionManager>();
    await extensionManager.loadInstalledExtensions();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yugen Play',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: DeviceType.isTv ? const TvRootScreen() : const RootScreen(),
    );
  }
}