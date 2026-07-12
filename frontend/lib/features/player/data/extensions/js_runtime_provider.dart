import 'package:flutter/foundation.dart';
import 'package:flutter_js/flutter_js.dart';

class JsRuntimeProvider {
  late JavascriptRuntime _runtime;
  bool _isInitialized = false;

  /// Boots up the JavaScript engine (QuickJS on Android, JSCore on iOS)
  void initialize() {
    if (_isInitialized) return;

    try {
      _runtime = getJavascriptRuntime();
      _isInitialized = true;
      debugPrint('JS Runtime initialized successfully.');
    } catch (e) {
      debugPrint('CRITICAL: Failed to initialize JS Runtime: $e');
    }
  }

  /// Loads a raw JavaScript string (the scraper) into the engine's memory
  Future<bool> loadScript(String scriptContent) async {
    if (!_isInitialized) initialize();

    try {
      final result = _runtime.evaluate(scriptContent);
      if (result.isError) {
        debugPrint('Error evaluating script: ${result.stringResult}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Exception while loading script: $e');
      return false;
    }
  }

  /// Calls a specific function inside the loaded JavaScript (e.g., 'extractStreams')
  Future<dynamic> callFunction(String functionName, List<dynamic> args) async {
    if (!_isInitialized) {
      throw Exception("JS Runtime is not initialized.");
    }

    try {
      // Format the arguments so they can be injected into the JS string
      final formattedArgs = args
          .map((arg) {
            if (arg is String) return '"$arg"';
            return arg;
          })
          .join(', ');

      // Construct the JS execution string
      final jsCommand = '$functionName($formattedArgs);';

      final JsEvalResult result = await _runtime.evaluateAsync(jsCommand);

      if (result.isError) {
        debugPrint('JS Execution Error: ${result.stringResult}');
        return null;
      }

      // Return the raw result (usually a JSON string that we will parse in Dart)
      return result.stringResult;
    } catch (e) {
      debugPrint('Exception executing JS function $functionName: $e');
      return null;
    }
  }

  /// Always clean up the engine to prevent memory leaks when destroying the player
  void dispose() {
    if (_isInitialized) {
      _runtime.dispose();
      _isInitialized = false;
    }
  }
}
