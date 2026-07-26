import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../service_locator.dart';
import '../models/extension_manifest.dart';
import 'js_runtime_provider.dart';

class ExtensionManager {
  // Grab the JS engine and our HTTP client
  final JsRuntimeProvider _jsRuntime = locator<JsRuntimeProvider>();
  final Dio _dio = Dio();

  List<ExtensionManifest> installedExtensions = [];

  /// Initializes the manager, reads local storage, and injects saved JS files into the engine
  Future<void> loadInstalledExtensions() async {
    try {
      final directory = await _getExtensionDirectory();

      // If the folder doesn't exist yet, just create it and bail out early.
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        debugPrint('📁 Created extensions directory.');
        return;
      }

      final List<FileSystemEntity> files = directory.listSync();
      installedExtensions.clear();

      for (var file in files) {
        if (file is File && file.path.endsWith('.js')) {
          final jsContent = await file.readAsString();

          // Inject the raw JS code into the V8/QuickJS Engine
          _jsRuntime.evaluateScript(jsContent);

          final fileName = file.path.split(Platform.pathSeparator).last;
          debugPrint('🔌 Loaded extension into runtime: $fileName');

          installedExtensions.add(
            ExtensionManifest(
              name: fileName.replaceAll('.js', ''),
              path: file.path,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('🚨 What a mess. Failed to load local extensions: $e');
    }
  }

  /// Downloads a JS scraper from a remote URL and saves it to local storage
  Future<bool> installExtension(String name, String downloadUrl) async {
    try {
      debugPrint('⬇️ Downloading extension: $name from $downloadUrl');

      final response = await _dio.get(downloadUrl);

      if (response.statusCode != 200 || response.data == null) {
        debugPrint('❌ Server rejected the download. Typical.');
        return false;
      }

      final jsContent = response.data.toString();

      // Save it directly to device storage
      final directory = await _getExtensionDirectory();
      final file = File('${directory.path}/$name.js');
      await file.writeAsString(jsContent);

      // Immediately evaluate it so it's ready to use without restarting the entire app
      _jsRuntime.evaluateScript(jsContent);

      installedExtensions.add(ExtensionManifest(name: name, path: file.path));
      debugPrint('✅ Successfully installed and loaded $name');

      return true;
    } catch (e) {
      debugPrint('🚨 Complete failure installing extension $name: $e');
      return false;
    }
  }

  /// Deletes an extension from storage and removes it from the active list
  Future<bool> uninstallExtension(String name) async {
    try {
      final directory = await _getExtensionDirectory();
      final file = File('${directory.path}/$name.js');

      if (await file.exists()) {
        await file.delete();
        installedExtensions.removeWhere((ext) => ext.name == name);
        debugPrint('🗑️ Deleted extension: $name');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint(
        '🚨 Failed to delete extension. It is probably a ghost file now: $e',
      );
      return false;
    }
  }

  /// Helper to get the isolated app directory
  Future<Directory> _getExtensionDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/extensions');
  }
}
