import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'features/player/models/stream_link.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/storage/hive_service.dart';
import 'package:media_kit/media_kit.dart';
import 'features/player/data/extensions/js_runtime_provider.dart';
import 'features/player/services/webview_bypass_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Boot up the JS Sandbox Engine
  final jsProvider = JsRuntimeProvider();
  jsProvider.initialize();

  // 2. Initialize Core Services
  MediaKit.ensureInitialized();
  await HiveService.initialize();

  // 3. Run the JS Smoke Tests
  const testScript = '''
    function verifySandbox(a, b) {
      return (a + b).toString();
    }
  ''';

  try {
    // --- Contract Test ---
    final mockScript = await rootBundle.loadString(
      'assets/extensions/mock_gogo.js',
    );
    final loadedMock = await jsProvider.loadScript(mockScript);

    if (loadedMock) {
      final String? jsonResult = await jsProvider.callFunction(
        'extractStreams',
        ['https://gogoanime/category/overlord-ii-episode-1'],
      );

      if (jsonResult != null) {
        final List<dynamic> decoded = jsonDecode(jsonResult);
        final links = decoded.map((item) => StreamLink.fromJson(item)).toList();

        debugPrint('🧪 CONTRACT TEST SUCCESS!');
        debugPrint('🚀 Extracted Stream Link: ${links.first.url}');
      }
    }
  } catch (e) {
    debugPrint('🧪 CONTRACT TEST FAILED: $e');
  }

  // --- Basic Sandbox Test ---
  final loadedSandbox = await jsProvider.loadScript(testScript);
  if (loadedSandbox) {
    final result = await jsProvider.callFunction('verifySandbox', [40, 2]);
    debugPrint('🧪 JS SANDBOX TEST RESULT: $result (Expected: 42)');
  }

  // 4. Headless Cloudflare Bypass Test
  debugPrint('🤖 Initiating Headless Cloudflare Bypass Test...');

  // 🌟 FIX: Instantiate the service before calling it
  final bypassService = WebviewBypassService();

  final headers = await bypassService.getBypassedHeaders(
    'https://nowsecure.nl',
  );

  if (headers != null) {
    debugPrint('🛡️ BYPASS SUCCESS!');
    debugPrint('🍪 Extracted Cookies: ${headers['Cookie']}');
    debugPrint('🕵️ Spoofed User-Agent: ${headers['User-Agent']}');
  } else {
    debugPrint('❌ BYPASS FAILED: Could not resolve headers.');
  }

  // Clean up the headless browser process so it doesn't eat memory
  bypassService.dispose();

  // 5. Boot the UI (Must always be outside the if-block)
  runApp(const YugenPlayApp());
}
