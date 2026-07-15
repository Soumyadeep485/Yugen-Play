import 'dart:io';
import 'package:flutter/foundation.dart';
import 'js_runtime_provider.dart';

class ExtensionManager {
  final JsRuntimeProvider _jsRuntime;

  // We inject the runtime provider cleanly via the constructor
  ExtensionManager(this._jsRuntime);

  /// Reads a cached script file from disk and boots it safely into the isolated QuickJS sandbox
  Future<bool> bootExtension(File scriptFile) async {
    try {
      if (!await scriptFile.exists()) {
        debugPrint(
          '  Runtime Error: Cannot boot extension. Script file does not exist at path: ${scriptFile.path}',
        );
        return false;
      }

      final scriptContent = await scriptFile.readAsString();
      final isLoaded = await _jsRuntime.loadScript(scriptContent);

      if (isLoaded) {
        debugPrint(
          '  Extension Runtime: Successfully booted execution context for ${scriptFile.path.split('/').last}',
        );
      }
      return isLoaded;
    } catch (e) {
      debugPrint('  Extension Runtime Exception during boot phase: $e');
      return false;
    }
  }

  /// Evaluates a scraper target directly via the underlying VM wrapper
  Future<String> executeScraperDirectly(
    String jsContent,
    String targetUrl,
  ) async {
    return await _jsRuntime.evaluateScraper(jsContent, targetUrl);
  }
}
