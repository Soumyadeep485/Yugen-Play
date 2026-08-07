import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class JsRuntimeProvider {
  HeadlessInAppWebView? _headlessWebView;
  final Dio _dio = Dio();
  bool _isInitialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  final Map<int, Completer<String>> _pendingCalls = {};
  int _callIdCounter = 0;

  void init() {
    _initEngine();
  }

  Future<void> _initEngine() async {
    if (_isInitialized) return;

    _headlessWebView = HeadlessInAppWebView(
      initialData: InAppWebViewInitialData(data: "<!DOCTYPE html><html><body></body></html>"),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
      ),
      onWebViewCreated: (controller) {
        debugPrint("✅ [WebView] Headless engine created. Registering Dart Bridge...");

        // 1. The Upgraded Network Handler (Now accepts custom headers!)
        controller.addJavaScriptHandler(handlerName: 'dartFetch', callback: (args) async {
          try {
            String url = args[0];
            
            // Extract headers if JS provided them
            Map<String, String> customHeaders = {};
            if (args.length > 1 && args[1] != null) {
              customHeaders = Map<String, String>.from(args[1] as Map);
            }
            
            debugPrint("🌐 [Dart Fetch] Requesting: $url");
            
            final response = await _dio.get(
              url,
              options: Options(
                responseType: ResponseType.plain,
                validateStatus: (status) => true,
                headers: {
                  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
                  ...customHeaders, // 🚀 Inject JS headers here!
                },
              ),
            );
            
            debugPrint("✅ [Dart Fetch] Success! Size: ${response.data.toString().length} bytes");
            return response.data.toString(); 
          } catch (e) {
            debugPrint("🚨 [Dart Fetch] Error: $e");
            throw Exception(e.toString());
          }
        });

        // 2. The Result Handler
        controller.addJavaScriptHandler(handlerName: 'jsCallResult', callback: (args) {
          try {
            final int callId = args[0];
            final String resultPayload = args[1];
            
            if (_pendingCalls.containsKey(callId)) {
              _pendingCalls[callId]!.complete(resultPayload);
              _pendingCalls.remove(callId);
            }
          } catch (e) {
            debugPrint('🚨 [JS Bridge] jsCallResult error: $e');
          }
        });
      },
      onConsoleMessage: (controller, consoleMessage) {
        debugPrint("🔵 [WebView JS]: ${consoleMessage.message}");
      },
      onLoadStop: (controller, url) async {
        debugPrint("✅ [WebView] Base DOM loaded. Injecting polyfills...");
        
        // 🚀 Polyfill updated to pass headers to Dart
        await controller.evaluateJavascript(source: '''
          window.nativeFetch = async function(url, headers = {}) {
            return await window.flutter_inappwebview.callHandler('dartFetch', url, headers);
          };
        ''');
        
        if (!_initCompleter.isCompleted) {
          _initCompleter.complete();
        }
        _isInitialized = true;
        debugPrint("✅ [WebView] JS Runtime is ready for action!");
      },
    );

    await _headlessWebView?.run();
  }

  Future<void> evaluateScript(String script) async {
    await _initCompleter.future;
    await _headlessWebView?.webViewController?.evaluateJavascript(source: script);
  }

  Future<dynamic> callAsyncFunction(String functionName, List<dynamic> args) async {
    await _initCompleter.future;

    final int callId = ++_callIdCounter;
    final completer = Completer<String>();
    _pendingCalls[callId] = completer;

    final String argsJson = jsonEncode(args);
    
    final String script = '''
      (async function() {
        try {
          const fn = $functionName;
          if (typeof fn !== 'function') throw new Error("$functionName is not a function");
          
          const result = await fn.apply(null, $argsJson);
          const payload = JSON.stringify({ "success": true, "data": result });
          
          window.flutter_inappwebview.callHandler('jsCallResult', $callId, payload);
        } catch (err) {
          const payload = JSON.stringify({ "success": false, "error": String(err) });
          window.flutter_inappwebview.callHandler('jsCallResult', $callId, payload);
        }
      })();
    ''';

    debugPrint("⚙️ [WebView] Executing $functionName (ID: $callId)...");
    
    _headlessWebView?.webViewController?.evaluateJavascript(source: script);
    
    final String finalResult = await completer.future;
    
    try {
      final Map<String, dynamic> parsed = jsonDecode(finalResult);
      
      if (parsed['success'] == true) {
         debugPrint("✅ [WebView] Execution successful!");
         return jsonEncode(parsed['data']); 
      } else {
         debugPrint("🚨 [WebView] Extension Error: \${parsed['error']}");
         return jsonEncode({ "error": parsed['error'] });
      }
    } catch (e) {
      debugPrint("🚨 [WebView] Engine Crash: $e");
      return jsonEncode({ "error": e.toString() });
    }
  }
}