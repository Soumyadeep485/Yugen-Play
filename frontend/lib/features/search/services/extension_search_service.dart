import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../player/data/extensions/js_runtime_provider.dart';
import '../../../shared/models/anime.dart';
import '../../player/services/extension_updater_service.dart';

class ExtensionSearchService {
  final JsRuntimeProvider _jsProvider;
  final ExtensionUpdaterService _updaterService;

  bool _isEngineReady = false;

  // Inject dependencies cleanly through the constructor
  ExtensionSearchService(this._jsProvider, this._updaterService);

  final String _remoteGistUrl =
      'https://gist.githubusercontent.com/Soumyadeep485/0e3b19e8bddace2097b9c6a25c309cb8/raw/0df35ccb07d027797c86cc862a98d481f9b74c52/mock_gogo.js';

  Future<void> _ensureEngineReady() async {
    if (_isEngineReady) return;
    _jsProvider.initialize();

    // 1. Attempt to trigger an OTA download of the latest script
    final downloadedPath = await _updaterService.downloadExtension(
      'gogo_live',
      _remoteGistUrl,
    );

    String? scriptContent;
    if (downloadedPath != null) {
      // 2. Read the freshly downloaded file from the device storage
      scriptContent = await _updaterService.readLocalExtension('gogo_live');
    } else {
      debugPrint('  Network failed, attempting to load cached extension...');
      scriptContent = await _updaterService.readLocalExtension('gogo_live');
    }

    if (scriptContent != null) {
      // 3. Inject the live code into the JS VM
      await _jsProvider.loadScript(scriptContent);
      _isEngineReady = true;
      debugPrint('  Live Extension Engine primed and ready.');
    } else {
      throw Exception(
        "CRITICAL: Failed to load extension from network or local cache.",
      );
    }
  }

  Future<List<Anime>> searchViaExtension(String query) async {
    await _ensureEngineReady();
    final String? jsonResponse = await _jsProvider.callFunction('searchAnime', [
      query,
    ]);

    if (jsonResponse == null) return [];
    final List<dynamic> decoded = jsonDecode(jsonResponse);

    return decoded.map((item) {
      final mockGraphQlData = {
        'id': item['url'].hashCode,
        'title': {
          'romaji': item['title'],
          'english': item['title'],
          'native': item['title'],
        },
        'coverImage': {
          'large': item['cover'],
          'extraLarge': item['cover'],
          'medium': item['cover'],
        },
        'format': 'TV',
        'status': 'FINISHED',
        'episodes': 12,
      };
      return Anime.fromGraphQL(mockGraphQlData);
    }).toList();
  }
}
