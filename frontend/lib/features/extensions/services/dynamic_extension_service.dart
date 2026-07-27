import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:http/http.dart' as http;

import '../../player/models/stream_link.dart';

class DynamicExtensionService {
  // Your clean, hash-free Gist URL
  final String gistBaseUrl =
      'https://gist.githubusercontent.com/Soumyadeep485/6de7b5cb3cc57043f9b9e2e969ea9a27/raw/anikoto.js';

  /// Fetches the latest JS script from Gist, executes the extraction in QuickJS,
  /// and returns a ready-to-play [StreamLink] with headers attached.
  Future<StreamLink?> extractDynamicStream({
    required String embedUrl,
    required String cipherText,
  }) async {
    JavascriptRuntime? jsRuntime;

    try {
      // 1. Fetch fresh JS script with timestamp parameter to bypass GitHub CDN caching
      final freshScriptUrl =
          '$gistBaseUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      debugPrint('🔎 [DynamicEngine] Fetching script from Gist...');

      final scriptResponse = await http.get(
        Uri.parse(freshScriptUrl),
        headers: const {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        },
      );

      if (scriptResponse.statusCode != 200) {
        throw Exception(
          'Failed to load Gist script (HTTP Status: ${scriptResponse.statusCode})',
        );
      }

      final jsCode = scriptResponse.body;

      // 2. Fetch the embed HTML page using Dart HTTP client
      debugPrint('🔎 [DynamicEngine] Fetching target embed page: $embedUrl');
      final embedResponse = await http.get(
        Uri.parse(embedUrl),
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          'Referer': 'https://anikoto.cz/',
        },
      );

      final rawHtml = embedResponse.body;

      // 3. Initialize the QuickJS engine
      jsRuntime = getJavascriptRuntime();
      jsRuntime.evaluate(jsCode);

      // 🛑 THE FIX: Use jsonEncode to safely escape the HTML into a JS string
      final safeHtml = jsonEncode(rawHtml);
      final jsCommand = "extractVidPlayUrl($safeHtml, '$cipherText');";

      final jsResult = jsRuntime.evaluate(jsCommand);

      // 🛑 SAFTEY CHECK: Don't try to JSON decode a JS error message!
      if (jsResult.isError) {
        debugPrint(
          '🚨 [DynamicEngine] JS Eval Error: ${jsResult.stringResult}',
        );
        return null;
      }

      Map<String, dynamic> resultData;
      try {
        resultData = jsonDecode(jsResult.stringResult);
      } catch (e) {
        debugPrint(
          '🚨 [DynamicEngine] JSON Decode Error: $e \nResult was: ${jsResult.stringResult}',
        );
        return null;
      }

      if (resultData['success'] == true) {
        debugPrint(
          '🔥 [DynamicEngine] Successfully extracted URL: ${resultData['streamUrl']}',
        );

        final Map<String, String> headers = resultData['headers'] != null
            ? Map<String, String>.from(resultData['headers'])
            : {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
                'Referer': 'https://vidtube.site/',
              };

        return StreamLink(
          sourceName: 'VidPlay (Dynamic Gist)',
          quality: 'Auto - 1080P',
          url: resultData['streamUrl'],
          isHls: true,
          isM3U8: true,
          headers: headers,
        );
      } else {
        debugPrint(
          '🚨 [DynamicEngine] JS Extraction Error: ${resultData['error']}',
        );
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('🚨 [DynamicEngine] Exception caught: $e');
      debugPrint(stackTrace.toString());
      return null;
    } finally {
      // Prevent memory leaks by disposing runtime
      jsRuntime?.dispose();
    }
  }
}
