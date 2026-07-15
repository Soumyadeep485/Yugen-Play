import 'package:flutter/foundation.dart';

class CustomProvider {
  // Legacy provider stub.
  // All active extraction is now handled dynamically via PluginManager and JS extensions.

  Future<List<dynamic>> extract() async {
    debugPrint(
      '⚠️ Warning: Call to deprecated CustomProvider. Use PluginManager instead.',
    );
    return [];
  }
}
