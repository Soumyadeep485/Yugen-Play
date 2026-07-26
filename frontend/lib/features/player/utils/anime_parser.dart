class AnimeParser {
  static Map<String, dynamic> parse(String title) {
    final lowerTitle = title.toLowerCase();

    // 1. Extract Clean Resolution
    String resolution = 'Unknown';
    if (lowerTitle.contains('2160') || lowerTitle.contains('4k')) {
      resolution = '2160p';
    } else if (lowerTitle.contains('1080')) {
      resolution = '1080p';
    } else if (lowerTitle.contains('720')) {
      resolution = '720p';
    } else if (lowerTitle.contains('540')) {
      resolution = '540p';
    } else if (lowerTitle.contains('480')) {
      resolution = '480p';
    }

    // 2. Check for Batch / Season Packs
    bool isBatch =
        lowerTitle.contains('batch') ||
        lowerTitle.contains('season') ||
        lowerTitle.contains('complete') ||
        lowerTitle.contains('~');

    // 3. Extract the Exact Episode Number
    String? episode;

    // Primary Pass: Look for standard prefixes like "- 04", "e04", "ep04"
    final epRegex = RegExp(
      r'(?:e|ep|episode|-)\s*0*([1-9]\d*)\b',
      caseSensitive: false,
    );
    var match = epRegex.firstMatch(lowerTitle);

    if (match != null && match.group(1) != null) {
      episode = int.tryParse(match.group(1)!).toString();
    } else {
      // Secondary Pass: Look for standalone numbers, but ignore common codecs/resolutions
      final standaloneRegex = RegExp(r'\b0*([1-9]\d*)(?:v\d)?\b');
      final allMatches = standaloneRegex.allMatches(lowerTitle);

      for (final m in allMatches) {
        final str = m.group(1);
        if (str != null &&
            !['1080', '720', '480', '264', '265', '10'].contains(str)) {
          episode = int.tryParse(str)?.toString();
          break; // Grab the first valid standalone number
        }
      }
    }

    return {
      'resolution': resolution,
      'episode': episode,
      'isBatch': isBatch,
      'raw': title,
    };
  }
}
