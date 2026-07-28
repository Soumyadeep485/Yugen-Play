import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/player/services/extension_manager.dart';
// 🛑 Add the MediaKit import
import 'package:media_kit/media_kit.dart';

import 'app/yugen_play_app.dart';
import 'core/storage/hive_service.dart';
import 'service_locator.dart';
import 'src/rust/frb_generated.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive Local Storage
  await HiveService.initialize();
  
  // 🛑 Initialize MediaKit BEFORE anything else tries to use it
  MediaKit.ensureInitialized();

  // Initialize the Rust native bridge library
  await RustLib.init();

  // Setup GetIt Service Locator
  setupServiceLocator();

  // Inside your main init function or Splash Screen:
  final extensionManager = locator<ExtensionManager>();
  await extensionManager.loadInstalledExtensions();

  runApp(const ProviderScope(child: YugenPlayApp()));
}
