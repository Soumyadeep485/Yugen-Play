import 'package:flutter_js/flutter_js.dart';
import 'package:flutter/foundation.dart';

class JsRuntimeProvider {
  late JavascriptRuntime _runtime;
  bool _isInitialized = false;

  JsRuntimeProvider() {
    _runtime = getJavascriptRuntime();
    _isInitialized = true;
  }

  void initialize() {
    if (_isInitialized) return;
    try {
      _runtime = getJavascriptRuntime();
      _isInitialized = true;
      debugPrint('✅ JS Runtime initialized.');
    } catch (e) {
      debugPrint('🚨 CRITICAL: Failed to initialize JS Runtime: $e');
    }
  }

  Future<bool> loadScript(String scriptContent) async {
    if (!_isInitialized) initialize();
    try {
      final result = _runtime.evaluate(scriptContent);
      if (result.isError) {
        debugPrint('❌ JS Compile Error: ${result.stringResult}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('❌ JS Exception while loading: $e');
      return false;
    }
  }

  Future<String?> callFunction(String functionName, List<dynamic> args) async {
    if (!_isInitialized) throw Exception("Sandbox not initialized.");
    try {
      final formattedArgs = args
          .map((arg) => arg is String ? '"$arg"' : arg)
          .join(', ');
      final jsCommand = '$functionName($formattedArgs);';

      final JsEvalResult result = await _runtime.evaluateAsync(jsCommand);

      if (result.isError) {
        debugPrint('❌ JS Execution Error: ${result.stringResult}');
        return null;
      }
      return result.stringResult;
    } catch (e) {
      debugPrint('❌ Sandbox Exception executing $functionName: $e');
      return null;
    }
  }

  Future<String> evaluateScraper(String jsContent, String targetUrl) async {
    try {
      // 1. Load the raw plugin script into the sandbox
      _runtime.evaluate(jsContent);

      // 2. Execute the standard `extract()` function defined in all your plugins
      final result = _runtime.evaluate("extract('$targetUrl')");

      // 3. Return the serialized JSON string payload
      return result.stringResult;
    } catch (e) {
      throw Exception('JavaScript Engine Crash: $e');
    }
  }

  void dispose() {
    if (_isInitialized) {
      _runtime.dispose();
      _isInitialized = false;
    }
  }
}
