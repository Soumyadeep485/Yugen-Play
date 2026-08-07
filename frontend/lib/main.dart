import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🚀 REQUIRED FOR D-PAD MAPPING
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/device_type.dart';
import 'package:frontend/database/database.dart';
import 'package:frontend/features/player/services/extension_manager.dart';
import 'package:frontend/features/player/services/js_runtime_provider.dart';
import 'package:media_kit/media_kit.dart';
import 'features/main/presentation/screens/root_screen.dart';
import 'features/tv/presentation/screens/tv_root_screen.dart';
import 'core/storage/hive_service.dart';
import 'service_locator.dart';
import 'src/rust/frb_generated.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Isar DB
  await initIsar();

  // 1. Core initializations needed for basic app launch
  await DeviceType.init();
  await HiveService.initialize();
  MediaKit.ensureInitialized();
  await RustLib.init();

  // 2. Setup Service Locator
  setupServiceLocator();

  // 3. Mount UI immediately (Removed the blocking await from here!)
  runApp(const ProviderScope(child: YugenPlayApp()));

  // 4. DEFER EXTENSIONS: Load installed extensions AFTER the app UI mounts
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      final jsRuntime = locator<JsRuntimeProvider>();
      jsRuntime.init(); 
      
      final extensionManager = locator<ExtensionManager>();
      await extensionManager.loadInstalledExtensions();

      // 🗑️ Removed the fake URL installer block completely!
      
    } catch (e) {
      debugPrint("🚨 Startup Engine Error: $e");
    }
  });
}

class YugenPlayApp extends StatelessWidget {
  const YugenPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🚀 THE GLOBAL D-PAD WRAPPER
    // This intercepts weird TV remote keys and forces them to act as a physical screen tap
    return Shortcuts(
      // 🚀 FIX: Changed to ShortcutActivator and SingleActivator
      shortcuts: <ShortcutActivator, Intent>{
        ...WidgetsApp.defaultShortcuts,
        const SingleActivator(LogicalKeyboardKey.select): const ActivateIntent(), // MediaTek / Skyworth Fix
        const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(), // Standard Android TV
        const SingleActivator(LogicalKeyboardKey.numpadEnter): const ActivateIntent(), // Generic Remotes
        const SingleActivator(LogicalKeyboardKey.gameButtonA): const ActivateIntent(), // Bluetooth Controllers
      },
      child: MaterialApp(
        // ... rest of your code ...
        title: 'Yugen Play',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: DeviceType.isTv ? const TvRootScreen() : const RootScreen(),
      ),
    );
  }
}