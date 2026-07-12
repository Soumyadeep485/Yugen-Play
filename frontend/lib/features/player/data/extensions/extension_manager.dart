import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import '../../models/extension_manifest.dart';
import 'js_runtime_provider.dart';

class ExtensionManager {
  final Dio _dio = Dio();
  final JsRuntimeProvider _jsRuntime;

  // We inject the runtime so the manager can mount the scripts it downloads
  ExtensionManager(this._jsRuntime);

  // Placeholder for the raw GitHub URL where your index.json will live
  final String _repoIndexUrl =
      'https://raw.githubusercontent.com/your-username/yugen-play-extensions/main/index.json';

  /// Pings the remote repository and parses the list of available extensions
  Future<List<ExtensionManifest>> fetchAvailableExtensions() async {
    try {
      final response = await _dio.get(_repoIndexUrl);

      // Assumes the JSON response has a root "extensions" array
      final List<dynamic> data = response.data['extensions'];
      return data.map((json) => ExtensionManifest.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Failed to sync extension repository: $e');
      return [];
    }
  }

  /// Downloads the raw .js script and caches it safely on the device
  Future<File?> downloadExtension(ExtensionManifest manifest) async {
    try {
      final dir = await getApplicationDocumentsDirectory();

      // Isolate the extensions in their own sub-directory
      final extensionsDir = Directory('${dir.path}/extensions');
      if (!await extensionsDir.exists()) {
        await extensionsDir.create(recursive: true);
      }

      final file = File('${extensionsDir.path}/${manifest.id}.js');

      // Download the raw JavaScript string directly to the file system
      await _dio.download(manifest.scriptUrl, file.path);
      debugPrint('Successfully downloaded extension: ${manifest.name}');

      return file;
    } catch (e) {
      debugPrint('Failed to download extension payload: $e');
      return null;
    }
  }

  /// Reads the cached file and mounts it into the QuickJS engine
  Future<bool> bootExtension(File scriptFile) async {
    if (!await scriptFile.exists()) {
      debugPrint('Cannot boot: Script file does not exist.');
      return false;
    }

    final scriptContent = await scriptFile.readAsString();
    return await _jsRuntime.loadScript(scriptContent);
  }
}
