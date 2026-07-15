import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart'; // Kept purely for checking DioException states if needed
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/network/extension_client.dart'; // Import your new client
import '../models/plugin_meta.dart';
import '../data/registry/plugin_registry.dart';

class ExtensionService {
  final ExtensionClient _extensionClient;
  final PluginRegistry _registry;

  // Inject the ExtensionClient along with the registry
  ExtensionService(this._extensionClient, this._registry);

  Future<List<Map<String, dynamic>>> fetchManifest(String manifestUrl) async {
    try {
      debugPrint('  Fetching extension manifest from: $manifestUrl');

      // Consume the shared network client instead of a direct Dio call
      final response = await _extensionClient.getManifest(manifestUrl);

      if (response.statusCode == 200) {
        final dynamic rawData = response.data;
        final Map<String, dynamic> jsonData = (rawData is String)
            ? jsonDecode(rawData)
            : rawData as Map<String, dynamic>;
        final List<dynamic> data = jsonData['plugins'];
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Invalid response from manifest server.');
    } catch (e) {
      debugPrint('  Network routing failed: $e');
      throw Exception('Failed to fetch extensions manifest: $e');
    }
  }

  /// Downloads the raw JS payload, provisions it locally, and updates the database.
  Future<void> installPlugin(Map<String, dynamic> pluginData) async {
    try {
      final String id = pluginData['id'];
      final String downloadUrl = pluginData['url'];
      final String name = pluginData['name'];
      final String version = pluginData['version'];

      debugPrint('  Starting provision for: $name (v$version)');

      // Define the secure local sandbox path
      final appDir = await getApplicationDocumentsDirectory();
      final extensionDir = Directory('${appDir.path}/extensions');
      if (!await extensionDir.exists()) {
        await extensionDir.create(recursive: true);
      }
      final file = File('${extensionDir.path}/$id.js');

      // Execute download through the centralized extension client channel
      await _extensionClient.downloadExtensionPayload(
        downloadUrl: downloadUrl,
        savePath: file.path,
      );

      debugPrint('  Wrote payload to isolated storage: ${file.path}');

      // Register the new absolute path into the local Hive state
      final newPlugin = PluginMeta(
        id: id,
        name: name,
        version: version,
        path: file.path,
        enabled: true,
      );
      await _registry.savePlugin(newPlugin);
      debugPrint('  Installation and database sync complete for $name.');
    } catch (e) {
      if (e is DioException) {
        debugPrint('  Dio Error: ${e.message}');
        debugPrint('  Status Code: ${e.response?.statusCode}');
        debugPrint('  Response: ${e.response?.data}');
      }
      debugPrint('  Network routing failed: $e');
      throw Exception('Failed to install plugin: $e');
    }
  }

  /// Removes the script from disk and purges the database record.
  Future<void> uninstallPlugin(PluginMeta plugin) async {
    if (!plugin.path.startsWith('assets/')) {
      final file = File(plugin.path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _registry.removePlugin(plugin.id);
    debugPrint('  Extension purged: ${plugin.id}');
  }
}
