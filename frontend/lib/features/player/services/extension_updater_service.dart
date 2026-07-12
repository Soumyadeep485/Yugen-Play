import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class ExtensionUpdaterService {
  final Dio _dio = Dio();

  /// Downloads a JS extension from a remote URL and saves it to internal app storage.
  /// Returns the absolute path of the downloaded file, or null if it fails.
  Future<String?> downloadExtension(String name, String remoteUrl) async {
    try {
      debugPrint('⬇️ Initiating OTA update for extension: $name');

      // Locate the secure application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final extensionDir = Directory('${directory.path}/extensions');

      // Create the directory if it doesn't exist
      if (!await extensionDir.exists()) {
        await extensionDir.create(recursive: true);
      }

      final filePath = '${extensionDir.path}/$name.js';

      // Execute the download
      await _dio.download(
        remoteUrl,
        filePath,
        options: Options(
          // Ensure we don't hit cached files during active development
          headers: {'Cache-Control': 'no-cache'},
        ),
      );

      debugPrint('✅ OTA update complete. Saved to: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('❌ OTA update failed for $name: $e');
      return null;
    }
  }

  /// Reads a locally stored extension from the device file system
  Future<String?> readLocalExtension(String name) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/extensions/$name.js');

      if (await file.exists()) {
        return await file.readAsString();
      } else {
        debugPrint('⚠️ Local extension artifact not found: $name');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error reading local extension artifact: $e');
      return null;
    }
  }
}
