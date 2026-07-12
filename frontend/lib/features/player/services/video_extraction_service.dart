import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/stream_link.dart';
import '../data/extensions/js_runtime_provider.dart';

class VideoExtractionService {
  final JsRuntimeProvider _jsProvider;

  // We pass in the already-initialized JS engine so we don't boot it twice
  VideoExtractionService(this._jsProvider);

  /// Extracts playable video streams (like .m3u8) using the JS extension
  Future<List<StreamLink>> getPlayableStreams(String episodeUrl) async {
    try {
      debugPrint('🎬 Requesting streams from JS Engine for: $episodeUrl');

      // Call the extension's extraction function
      final String? jsonResponse = await _jsProvider.callFunction(
        'extractStreams',
        [episodeUrl],
      );

      if (jsonResponse == null) {
        debugPrint('❌ JS Engine returned null for streams.');
        return [];
      }

      // Parse the JSON string back into our strongly-typed Dart models
      final List<dynamic> decoded = jsonDecode(jsonResponse);
      final List<StreamLink> links = decoded
          .map((item) => StreamLink.fromJson(item))
          .toList();

      debugPrint('✅ Extracted ${links.length} stream(s) successfully.');
      return links;
    } catch (e) {
      debugPrint('❌ Error extracting streams: $e');
      return [];
    }
  }
}
