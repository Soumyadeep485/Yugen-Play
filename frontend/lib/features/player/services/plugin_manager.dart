import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/plugin_meta.dart';
import '../models/stream_link.dart';
import '../data/extensions/js_runtime_provider.dart';

class PluginManager {
  final JsRuntimeProvider _jsProvider;

  PluginManager(this._jsProvider);

  Future<List<StreamLink>> execute(PluginMeta plugin, String targetUrl) async {
    if (!plugin.enabled) {
      throw Exception('Plugin ${plugin.id} is disabled.');
    }

    try {
      String jsContent;

      // 1. I/O Routing
      if (plugin.path.startsWith('assets/')) {
        jsContent = await rootBundle.loadString(plugin.path);
      } else {
        final file = File(plugin.path);
        if (!await file.exists()) {
          throw Exception('Local plugin file missing at path: ${plugin.path}');
        }
        jsContent = await file.readAsString();
      }

      // 2. Execute within the sandboxed JS runtime
      final result = await _jsProvider.evaluateScraper(jsContent, targetUrl);

      // 3. Serialize the raw payload
      final List<dynamic> parsed = jsonDecode(result);
      final List<StreamLink> validStreams = [];

      // 4. Schema Validation Loop (The Filter)
      for (final item in parsed) {
        if (item is! Map<String, dynamic>) {
          continue; // Drop immediately if not a JSON object
        }

        try {
          // Attempt to pass the item through the Ironclad Contract
          validStreams.add(StreamLink.fromMap(item));
        } catch (err) {
          // Log the bad data, but do not crash the app. Allow the loop to continue parsing the rest.
          debugPrint(
            '  [Schema Warning] Dropping malformed stream payload from ${plugin.name}: $err',
          );
        }
      }

      if (validStreams.isEmpty) {
        throw Exception(
          'Plugin executed, but zero valid stream links were extracted. Site layout may have changed.',
        );
      }

      return validStreams;
    } catch (e) {
      throw Exception('Plugin execution failed for ${plugin.name}: $e');
    }
  }
}
