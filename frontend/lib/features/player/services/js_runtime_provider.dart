import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_js/flutter_js.dart';

import '../../../../core/network/interceptors/user_agent_interceptor.dart';

class JsRuntimeProvider {
  late JavascriptRuntime _runtime;
  late Dio _dio;
  bool _isInitialized = false;

  JsRuntimeProvider() {
    // Setup a dedicated Dio client with our Cloudflare bypass interceptor
    _dio = Dio();
    _dio.interceptors.add(UserAgentInterceptor());
    _initEngine();
  }

  void _initEngine() {
    try {
      _runtime = getJavascriptRuntime();

      _runtime.evaluate('''
        var console = {
          log: function(msg) { sendMessage('consoleLog', JSON.stringify(msg)); },
          error: function(msg) { sendMessage('consoleError', JSON.stringify(msg)); }
        };
      ''');

      _runtime.onMessage(
        'consoleLog',
        (dynamic args) => debugPrint('🔵 [JS]: $args'),
      );
      _runtime.onMessage(
        'consoleError',
        (dynamic args) => debugPrint('🔴 [JS Error]: $args'),
      );

      _injectAsyncHttpBridge();

      _isInitialized = true;
      debugPrint("✅ JS Runtime Engine initialized with Async Support.");
    } catch (e) {
      debugPrint("❌ Failed to initialize JS Runtime: $e");
    }
  }

  void _injectAsyncHttpBridge() {
    // 1. Listen for the JS trigger
    _runtime.onMessage('dartFetch', (dynamic args) {
      final Map<String, dynamic> request = jsonDecode(args as String);
      final int id = request['id'];
      final String url = request['url'];
      final String method = request['method'] ?? 'GET';

      // Fire the network call asynchronously so we don't block the JS thread
      _performAsyncFetch(id, url, method);
      return null;
    });

    // 2. Inject the Promise-based fetch function into the JS context
    _runtime.evaluate('''
      var _fetchCallbacks = {};
      var _fetchId = 0;

      function nativeFetch(url, options = {}) {
        return new Promise((resolve, reject) => {
          const id = ++_fetchId;
          _fetchCallbacks[id] = { resolve, reject };
          sendMessage('dartFetch', JSON.stringify({ id: id, url: url, method: options.method || 'GET' }));
        });
      }

      function resolveFetch(id, data, isError) {
        if (_fetchCallbacks[id]) {
          if (isError) {
            _fetchCallbacks[id].reject(data);
          } else {
            _fetchCallbacks[id].resolve(data);
          }
          delete _fetchCallbacks[id];
        }
      }
    ''');
  }

  Future<void> _performAsyncFetch(int id, String url, String method) async {
    try {
      debugPrint('🌐 [JS Bridge] Fetching real data from: $url');
      final response = await _dio.request(
        url,
        options: Options(method: method),
      );

      final responseData = response.data is String
          ? response.data
          : jsonEncode(response.data);

      // Base64 encode the HTML/JSON so stray quotes and newlines don't crash the evaluator
      final base64Data = base64Encode(utf8.encode(responseData));

      _runtime.evaluate('''
        try {
          const decoded = decodeURIComponent(escape(atob('$base64Data')));
          resolveFetch($id, decoded, false);
        } catch(e) {
          resolveFetch($id, "Base64 Decode Error: " + e.message, true);
        }
      ''');
    } catch (e) {
      debugPrint('⚠️ [JS Bridge] Network Error: $e');
      _runtime.evaluate(
        "resolveFetch($id, '${e.toString().replaceAll("'", "\\'")}', true);",
      );
    }
  }

  void evaluateScript(String script) {
    if (!_isInitialized) return;
    final result = _runtime.evaluate(script);
    if (result.isError) debugPrint("❌ JS Error: ${result.stringResult}");
  }

  /// Evaluates an asynchronous JS function and awaits the Promise resolution in Dart
  Future<dynamic> callAsyncFunction(
    String functionName,
    List<dynamic> args,
  ) async {
    if (!_isInitialized) return null;

    final completer = Completer<dynamic>();
    final callId = DateTime.now().millisecondsSinceEpoch.toString();

    // Setup a one-time listener to catch the promise resolution
    _runtime.onMessage('resolveAsync_$callId', (dynamic result) {
      if (!completer.isCompleted) completer.complete(result);
    });

    final argsString = jsonEncode(args);

    // Wrap the call in an async IIFE
    final script =
        '''
      (async function() {
        try {
          const result = await $functionName.apply(null, $argsString);
          sendMessage('resolveAsync_$callId', JSON.stringify(result));
        } catch (error) {
          sendMessage('resolveAsync_$callId', JSON.stringify({ error: error.toString() }));
        }
      })();
    ''';

    _runtime.evaluate(script);

    // If the JS hangs, we don't want the UI to spin forever
    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => jsonEncode({'error': 'JS Execution Timed Out'}),
    );
  }

  void dispose() {
    _runtime.dispose();
  }
}
