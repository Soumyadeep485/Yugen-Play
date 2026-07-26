import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../player/models/stream_link.dart';

class AnikotoExtensionService {
  static const String baseUrl = 'https://anikoto.cz';

  Future<List<StreamLink>> extractStreams(String episodeId) async {
    List<StreamLink> collectedStreams = [];
    int subCount = 0;
    int dubCount = 0;
    const int maxPerType = 2; // Stop after collecting 2 Sub and 2 Dub streams

    try {
      final parts = episodeId.split('-ep-');
      final rawTitle = parts.first.trim();
      final epNumber = parts.length > 1 ? parts.last : '1';

      String epUrl = '';

      // PHASE 1: Slug Resolution
      if (rawTitle.contains(' ') ||
          !RegExp(r'^[a-z0-9\-]+$').hasMatch(rawTitle.toLowerCase())) {
        debugPrint('🔎 [Anikoto] Formatting title slug for: "$rawTitle"');

        final vrfQuery = _vrfEncrypt(rawTitle);
        final searchUrl =
            '$baseUrl/filter?keyword=${Uri.encodeComponent(rawTitle)}&vrf=$vrfQuery';

        final searchRes = await http.get(
          Uri.parse(searchUrl),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
            'Referer': '$baseUrl/',
          },
        );

        if (searchRes.statusCode != 200) return [];

        final slugMatch = RegExp(
          r'href="([^"]*/watch/[^"]+)"',
        ).firstMatch(searchRes.body);
        if (slugMatch != null) {
          var baseSlug = slugMatch.group(1)!.split('?').first;
          if (baseSlug.startsWith('http')) {
            baseSlug = Uri.parse(baseSlug).path;
          }
          baseSlug = baseSlug.replaceAll(RegExp(r'/ep-\d+.*'), '');
          epUrl = '$baseSlug/ep-$epNumber';
        } else {
          return [];
        }
      } else {
        epUrl = '/watch/$rawTitle/ep-$epNumber';
      }

      // PHASE 2: Fetch Episode Page & ID
      final pageRes = await http.get(Uri.parse('$baseUrl$epUrl'));
      final animeIdMatch =
          RegExp(r'data-id="([^"]+)"').firstMatch(pageRes.body) ??
          RegExp(r'data-tip="([^"]+)"').firstMatch(pageRes.body);

      if (animeIdMatch == null) return [];
      final animeId = animeIdMatch.group(1)!;

      // PHASE 3: Fetch Episode List
      final vrf = _vrfEncrypt(animeId);
      final epListRes = await http.get(
        Uri.parse('$baseUrl/ajax/episode/list/$animeId?vrf=$vrf'),
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'Referer': '$baseUrl$epUrl',
        },
      );

      final epListJson = jsonDecode(epListRes.body);
      final epListHtml = epListJson['result'] ?? '';

      final epRegex = RegExp('data-num="$epNumber"[^>]*data-ids="([^"]+)"');
      final epMatch = epRegex.firstMatch(epListHtml);
      if (epMatch == null) return [];
      final serverIdsStr = epMatch.group(1)!;

      // PHASE 4: Fetch Server List
      final serverListRes = await http.get(
        Uri.parse('$baseUrl/ajax/server/list?servers=$serverIdsStr'),
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'Referer': '$baseUrl$epUrl',
        },
      );
      final serverListJson = jsonDecode(serverListRes.body);
      final serverListHtml = serverListJson['result'] ?? '';

      final serverMatches = RegExp(
        r'data-link-id="([^"]+)"[^>]*>([^<]+)<',
      ).allMatches(serverListHtml);

      for (final match in serverMatches) {
        if (subCount >= maxPerType && dubCount >= maxPerType) {
          debugPrint(
            '🛑 [Anikoto] Reached target limit ($maxPerType Sub, $maxPerType Dub). Stopping search.',
          );
          break;
        }

        final linkId = match.group(1)!;
        final serverName = match.group(2)!.trim();

        // PHASE 5: Get Embed Link
        final embedRes = await http.get(
          Uri.parse('$baseUrl/ajax/server?get=$linkId'),
          headers: {
            'X-Requested-With': 'XMLHttpRequest',
            'Referer': '$baseUrl$epUrl',
          },
        );

        if (embedRes.statusCode != 200) continue;

        final embedJson = jsonDecode(embedRes.body);
        var embedUrl = embedJson['result']?['url']?.toString();

        if (embedUrl != null && embedUrl.isNotEmpty) {
          if (embedUrl.startsWith('//')) {
            embedUrl = 'https:$embedUrl';
          } else if (embedUrl.startsWith('/')) {
            embedUrl = '$baseUrl$embedUrl';
          }

          final isDub = embedUrl.toLowerCase().contains('/dub');
          if (isDub && dubCount >= maxPerType) continue;
          if (!isDub && subCount >= maxPerType) continue;

          // Attempt Dart Extraction first
          final streams = await _extractFromPlayer(embedUrl, serverName);

          for (var stream in streams) {
            if (stream.quality.contains('DUB') && dubCount < maxPerType) {
              collectedStreams.add(stream);
              dubCount++;
            } else if (!stream.quality.contains('DUB') &&
                subCount < maxPerType) {
              collectedStreams.add(stream);
              subCount++;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('🚨 [Anikoto] Master Scraper Error: $e');
    }

    return collectedStreams;
  }

  Future<List<StreamLink>> _extractFromPlayer(
    String embedUrl,
    String serverName,
  ) async {
    try {
      final uri = Uri.parse(embedUrl);
      final host = uri.host;

      String streamType = '';
      if (uri.pathSegments.isNotEmpty) {
        final lastSegment = uri.pathSegments.last.toLowerCase();
        if (['sub', 'dub', 'hsub'].contains(lastSegment)) {
          streamType = lastSegment;
        }
      }

      final playerRes = await http.get(
        uri,
        headers: {
          'Referer': '$baseUrl/',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
        },
      );

      final playerHtml = playerRes.body;
      final String cookies = playerRes.headers['set-cookie'] ?? '';

      final dataIdMatch = RegExp(r'data-id="([^"]+)"').firstMatch(playerHtml);

      if (dataIdMatch != null) {
        final dataId = dataIdMatch.group(1)!;

        final apiHeaders = {
          'X-Requested-With': 'XMLHttpRequest',
          'Referer': embedUrl,
          'Origin': 'https://$host',
          'Accept': '*/*',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        };

        if (cookies.isNotEmpty) {
          apiHeaders['Cookie'] = cookies;
        }

        var apiUrl = 'https://$host/stream/getSourcesNew?id=$dataId&id=$dataId';
        if (streamType.isNotEmpty) {
          apiUrl += '&type=$streamType&type=$streamType';
        }

        var apiRes = await http.get(Uri.parse(apiUrl), headers: apiHeaders);

        if (apiRes.statusCode != 200 ||
            apiRes.body.isEmpty ||
            apiRes.body.contains('error')) {
          apiUrl = 'https://$host/stream/getSources?id=$dataId&id=$dataId';
          apiRes = await http.get(Uri.parse(apiUrl), headers: apiHeaders);
        }

        final Map<String, dynamic> apiJson = jsonDecode(apiRes.body);
        final parsedStreams = _parseSources(apiJson['sources']);

        if (parsedStreams.isNotEmpty) {
          final prefix = streamType.isNotEmpty
              ? streamType.toUpperCase()
              : 'SUB';
          final streamUrl = parsedStreams.first.url;
          debugPrint('🔥 [Anikoto] MASTER M3U8 FOUND: $streamUrl');

          return [
            StreamLink(
              sourceName: serverName, // Cleaned up prefix
              quality: '$prefix - Auto - 1080P',
              url: streamUrl,
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
                'Referer': 'https://$host/',
              },
              isHls: true,
              isM3U8: true,
            ),
          ];
        } else {
          debugPrint(
            '🚨 [Anikoto] Internal API returned empty sources for $serverName',
          );
        }
      } else {
        final jsM3u8Match = RegExp(
          r'file\s*:\s*["'
          "'"
          r'](https?://[^"'
          "'"
          r']+\.m3u8[^"'
          "'"
          r']*)["'
          "'"
          r']',
        ).firstMatch(playerHtml);
        if (jsM3u8Match != null) {
          final directM3u8 = jsM3u8Match.group(1)!;
          final prefix = streamType.isNotEmpty
              ? streamType.toUpperCase()
              : 'SUB';
          return [
            StreamLink(
              sourceName: serverName, // Cleaned up prefix
              quality: '$prefix - Auto - 1080P',
              url: directM3u8,
              isHls: true,
              isM3U8: true,
            ),
          ];
        }
      }
    } catch (e) {
      debugPrint('🚨 [Anikoto] Extractor Error for $serverName: $e');
    }
    return [];
  }

  List<StreamLink> _parseSources(dynamic sourcesData) {
    final List<StreamLink> sources = [];

    if (sourcesData == null) return sources;

    if (sourcesData is Map<String, dynamic>) {
      final fileUrl = sourcesData['file'] as String?;
      if (fileUrl != null && fileUrl.isNotEmpty) {
        sources.add(
          StreamLink(
            sourceName: 'Extracted',
            quality: 'auto',
            url: fileUrl,
            isHls: true,
            isM3U8: true,
          ),
        );
      }
    } else if (sourcesData is List) {
      for (final item in sourcesData) {
        if (item is Map<String, dynamic>) {
          final fileUrl = item['file'] as String?;
          if (fileUrl != null && fileUrl.isNotEmpty) {
            sources.add(
              StreamLink(
                sourceName: 'Extracted',
                quality: item['type'] ?? item['label'] ?? 'auto',
                url: fileUrl,
                isHls: true,
                isM3U8: true,
              ),
            );
          }
        }
      }
    }
    return sources;
  }

  // =========================================================================
  // WEBSITE VRF FUNCTIONS (Required for navigating Anikoto's AJAX menus)
  // =========================================================================

  String _vrfEncrypt(String input) {
    String vrf = input;
    vrf = _exchange(vrf, "AP6GeR8H0lwUz1", "UAz8Gwl10P6ReH");
    vrf = _rc4Encrypt("ItFKjuWokn4ZpB", vrf);
    vrf = _rc4Encrypt("fOyt97QWFB3", vrf);
    vrf = _exchange(vrf, "1majSlPQd2M5", "da1l2jSmP5QM");
    vrf = _exchange(vrf, "CPYvHj09Au3", "0jHA9CPYu3v");
    vrf = vrf.split('').reversed.join('');
    vrf = _rc4Encrypt("736y1uTJpBLUX", vrf);
    vrf = base64Url.encode(utf8.encode(vrf)).replaceAll('=', '');
    return Uri.encodeComponent(vrf);
  }

  String _exchange(String input, String key1, String key2) {
    StringBuffer sb = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      int idx = key1.indexOf(input[i]);
      if (idx != -1) {
        sb.write(key2[idx]);
      } else {
        sb.write(input[i]);
      }
    }
    return sb.toString();
  }

  String _rc4Encrypt(String keyStr, String input) {
    List<int> key = utf8.encode(keyStr);
    List<int> data = utf8.encode(input);
    List<int> s = List.generate(256, (i) => i);
    int j = 0;

    for (int i = 0; i < 256; i++) {
      j = (j + s[i] + key[i % key.length]) % 256;
      int temp = s[i];
      s[i] = s[j];
      s[j] = temp;
    }

    int i = 0;
    j = 0;
    List<int> out = [];
    for (int k = 0; k < data.length; k++) {
      i = (i + 1) % 256;
      j = (j + s[i]) % 256;
      int temp = s[i];
      s[i] = s[j];
      s[j] = temp;
      out.add(data[k] ^ s[(s[i] + s[j]) % 256]);
    }

    return base64Url.encode(out).replaceAll('=', '');
  }
}
