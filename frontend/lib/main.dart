import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'app/app.dart';
import 'core/storage/hive_service.dart';
import 'features/player/data/registry/plugin_registry.dart';
import 'service_locator.dart';

Future<void> main() async {
  // Wrap the entire application in a secure Zone to catch silent native layer crashes
  runZonedGuarded(
    () async {
      debugPrint('  1. Booting main() sequence...');
      WidgetsFlutterBinding.ensureInitialized();
      // Inside your main() function before runApp()
      await Hive.initFlutter();
      await Hive.openBox(
        'extension_settings',
      ); // The persistent storage for our toggles

      // Catch UI-level Flutter errors
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('FLUTTER UI ERROR: ${details.exception}');
      };

      debugPrint('  2. Widgets bound. Initializing MediaKit...');
      // Initialize the libmpv backend required for HLS streaming
      MediaKit.ensureInitialized();

      debugPrint('  3. MediaKit ready. Initializing Hive Flutter...');
      await Hive.initFlutter();

      debugPrint('  4. Hive Flutter ready. Initializing HiveService...');
      await HiveService.initialize();

      debugPrint('  5. HiveService ready. Setting up dependency locator...');
      setupLocator();

      debugPrint('  6. Locator ready. Booting PluginRegistry...');
      await locator<PluginRegistry>().init();

      debugPrint('  7. ALL SYSTEMS GO. Launching UI...');
      runApp(const YugenPlayApp());
    },
    (error, stackTrace) {
      // This will catch any fatal errors thrown by the media_kit C++ engine
      debugPrint('CRITICAL UNHANDLED EXCEPTION: $error');
      debugPrint(stackTrace.toString());
    },
  );
}
