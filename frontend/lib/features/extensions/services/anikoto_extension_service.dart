import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../player/models/stream_link.dart';
import '../../player/models/subtitle_track.dart';

class AnikotoExtensionService {
  static const String baseUrl = 'https://anikoto.cz';
  static final Map<String, String> _slugCache = {};

  Future<List<StreamLink>> extractStreams(String episodeId) async {
    List<StreamLink> collectedStreams = [];
    int subCount = 0;
    int dubCount = 0;
    const int maxPerType = 2;

    try {
      final parts = episodeId.split('-ep-');
      final rawTitle = parts.first.trim();
      final epNumber = parts.length > 1 ? parts.last : '1';
      String epUrl = '';

      String? baseSlug = _slugCache[rawTitle];

      if (baseSlug == null) {
        final searchQuery = rawTitle
            .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        final vrfQuery = _vrfEncrypt(searchQuery);
        final searchUrl =
            '$baseUrl/filter?keyword=${Uri.encodeComponent(searchQuery)}&vrf=$vrfQuery';

        final searchRes = await http.get(
          Uri.parse(searchUrl),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
            'Referer': '$baseUrl/',
          },
        );

        if (searchRes.statusCode != 200) return [];

        final slugMatches = RegExp(
          r'href="([^"]*/watch/[^"]+)"',
        ).allMatches(searchRes.body);

        if (slugMatches.isNotEmpty) {
          String? bestSlug;
          final targetSlug = rawTitle
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
              .replaceAll(RegExp(r'^-+|-+$'), '');

          for (final match in slugMatches) {
            String foundSlug = match.group(1)!;
            if (foundSlug.startsWith('http')) {
              foundSlug = Uri.parse(foundSlug).path;
            }
            foundSlug = foundSlug.replaceAll(RegExp(r'/ep-\d+.*'), '');

            final slugPart = foundSlug.split('/watch/').last;
            if (slugPart == targetSlug) {
              bestSlug = foundSlug;
              break;
            } else if (slugPart.startsWith('$targetSlug-')) {
              final remainder = slugPart.substring(targetSlug.length + 1);
              if (!remainder.contains('-') && remainder.length < 10) {
                bestSlug = foundSlug;
                break;
              }
            }
          }

          if (bestSlug == null) {
            String firstSlug = slugMatches.first.group(1)!;
            if (firstSlug.startsWith('http')) {
              firstSlug = Uri.parse(firstSlug).path;
            }
            bestSlug = firstSlug.replaceAll(RegExp(r'/ep-\d+.*'), '');
          }

          baseSlug = bestSlug;
          _slugCache[rawTitle] = baseSlug;
        } else {
          return [];
        }
      }

      epUrl = '$baseSlug/ep-$epNumber';
      final pageRes = await http.get(Uri.parse('$baseUrl$epUrl'));
      final animeIdMatch =
          RegExp(r'data-id="([^"]+)"').firstMatch(pageRes.body) ??
          RegExp(r'data-tip="([^"]+)"').firstMatch(pageRes.body);
      if (animeIdMatch == null) return [];

      final animeId = animeIdMatch.group(1)!;
      final vrf = _vrfEncrypt(animeId);
      final epListRes = await http.get(
        Uri.parse('$baseUrl/ajax/episode/list/$animeId?vrf=$vrf'),
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'Referer': '$baseUrl$epUrl',
        },
      );

      final epListJson = jsonDecode(epListRes.body);
      final epRegex = RegExp('data-num="$epNumber"[^>]*data-ids="([^"]+)"');
      final epMatch = epRegex.firstMatch(epListJson['result'] ?? '');
      if (epMatch == null) return [];

      final serverIdsStr = epMatch.group(1)!;
      final serverListRes = await http.get(
        Uri.parse('$baseUrl/ajax/server/list?servers=$serverIdsStr'),
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'Referer': '$baseUrl$epUrl',
        },
      );

      final serverMatches = RegExp(
        r'data-link-id="([^"]+)"[^>]*>([^<]+)<',
      ).allMatches(jsonDecode(serverListRes.body)['result'] ?? '');

      for (final match in serverMatches) {
        if (subCount >= maxPerType && dubCount >= maxPerType) break;

        final linkId = match.group(1)!;
        final serverName = match.group(2)!.trim();

        final embedRes = await http.get(
          Uri.parse('$baseUrl/ajax/server?get=$linkId'),
          headers: {
            'X-Requested-With': 'XMLHttpRequest',
            'Referer': '$baseUrl$epUrl',
          },
        );

        if (embedRes.statusCode != 200) continue;
        var embedUrl = jsonDecode(embedRes.body)['result']?['url']?.toString();

        if (embedUrl != null && embedUrl.isNotEmpty) {
          if (embedUrl.startsWith('//')) {
            embedUrl = 'https:$embedUrl';
          } else if (embedUrl.startsWith('/')) {embedUrl = '$baseUrl$embedUrl';
          }
          final isDub = embedUrl.toLowerCase().contains('/dub');
          if (isDub && dubCount >= maxPerType) continue;
          if (!isDub && subCount >= maxPerType) continue;

          final streams = await _extractFromPlayer(embedUrl, serverName, isDub);
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
    bool isDub,
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
        },
      );

      final dataIdMatch = RegExp(r'data-id="([^"]+)"').firstMatch(playerRes.body);

      if (dataIdMatch != null) {
        final dataId = dataIdMatch.group(1)!;
        final apiHeaders = {
          'X-Requested-With': 'XMLHttpRequest',
          'Referer': embedUrl,
          'Origin': 'https://$host',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        };

        if ((playerRes.headers['set-cookie'] ?? '').isNotEmpty) {
          apiHeaders['Cookie'] = playerRes.headers['set-cookie']!;
        }

        var apiUrl =
            'https://$host/stream/getSourcesNew?id=$dataId&id=$dataId';
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
        final List<SubtitleTrack> extractedSubtitles = [];

        List dynamicTracks = [];
        if (apiJson['tracks'] is List) {
          dynamicTracks = apiJson['tracks'];
        } else if (apiJson['result'] != null &&
            apiJson['result']['tracks'] is List) {
          dynamicTracks = apiJson['result']['tracks'];
        } else if (apiJson['subtitles'] is List) {
          dynamicTracks = apiJson['subtitles'];
        }

        for (var track in dynamicTracks) {
          if (track is! Map) continue;

          final kind = track['kind']?.toString().toLowerCase() ?? '';
          var fileUrl =
              track['file']?.toString() ?? track['url']?.toString() ?? '';

          if (fileUrl.isNotEmpty &&
              (kind == 'captions' || kind == 'subtitles')) {
            if (fileUrl.startsWith('/')) {
              fileUrl = 'https://$host$fileUrl';
            }

            final Map<String, dynamic> trackMap =
                Map<String, dynamic>.from(track);
            trackMap['url'] = fileUrl;
            trackMap['file'] = fileUrl;

            try {
              extractedSubtitles.add(SubtitleTrack.fromJson(trackMap));
            } catch (e) {
              debugPrint('🚨 [Subtitle Error]: $e');
            }
          }
        }

        debugPrint('Total Valid Subtitles Extracted: ${extractedSubtitles.length}');

        final parsedStreams = _parseSources(apiJson['sources']);
        if (parsedStreams.isNotEmpty) {
          final prefix = isDub ? 'DUB' : 'SUB';
          return [
            StreamLink(
              sourceName: serverName,
              quality: '$prefix - Auto - 1080P',
              url: parsedStreams.first.url,
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'Referer': 'https://$host/',
              },
              isHls: true,
              isM3U8: true,
              subtitles: extractedSubtitles,
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