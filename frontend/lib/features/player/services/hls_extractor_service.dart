import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/stream_link.dart';

class HlsExtractorService {
  final Dio _dio;

  HlsExtractorService(this._dio);

  /// Parses an HLS master playlist (.m3u8) and extracts quality variant streams.
  Future<List<StreamLink>> extractStreamVariants(String masterUrl) async {
    final List<StreamLink> variants = [];

    try {
      final response = await _dio.get(
        masterUrl,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final String content = response.data.toString();
        final List<String> lines = content.split('\n');

        String? currentQualityLabel;

        for (int i = 0; i < lines.length; i++) {
          final line = lines[i].trim();

          // Check for stream info header
          if (line.startsWith('#EXT-X-STREAM-INF:')) {
            // 1. Extract resolution height (e.g. RESOLUTION=1920x1080 -> 1080p)
            final resMatch = RegExp(r'RESOLUTION=(\d+x\d+)').firstMatch(line);
            if (resMatch != null) {
              final dimensions = resMatch.group(1)!;
              final height = dimensions.split('x').last;
              currentQualityLabel = '${height}p';
            } else {
              // 2. Fallback to bandwidth calculation
              final bwMatch = RegExp(r'BANDWIDTH=(\d+)').firstMatch(line);
              if (bwMatch != null) {
                final bw = int.tryParse(bwMatch.group(1)!) ?? 0;
                if (bw > 3000000) {
                  currentQualityLabel = '1080p';
                } else if (bw > 1500000) {
                  currentQualityLabel = '720p';
                } else if (bw > 800000) {
                  currentQualityLabel = '480p';
                } else {
                  currentQualityLabel = '360p';
                }
              }
            }
          } else if (line.isNotEmpty && !line.startsWith('#')) {
            // Line is a stream variant URL
            String variantUrl = line;

            // Resolve relative URLs against the master playlist URL
            if (!variantUrl.startsWith('http://') &&
                !variantUrl.startsWith('https://')) {
              final baseUri = Uri.parse(masterUrl);
              variantUrl = baseUri.resolve(variantUrl).toString();
            }

            variants.add(
              StreamLink(
                sourceName: 'HLS Stream',
                quality: currentQualityLabel ?? 'Auto Quality',
                url: variantUrl,
                isHls: true,
                isM3U8: true,
              ),
            );

            currentQualityLabel = null;
          }
        }
      }
    } catch (e) {
      debugPrint("HlsExtractorService network/parsing error: $e");
    }

    // Fallback: If no sub-variants were parsed (or if it's a media playlist rather than a master playlist),
    // return the master URL directly.
    if (variants.isEmpty) {
      variants.add(
        StreamLink(
          sourceName: 'HLS Direct',
          quality: 'Auto Quality',
          url: masterUrl,
          isHls: true,
          isM3U8: true,
        ),
      );
    }

    return variants;
  }
}
