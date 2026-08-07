import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:frontend/database/kv_helper.dart'; // Ensure this matches your pubspec package name

class SourceMapper {
  static String? _currentMappingToken;

  /// Lightweight normalization (trim and lowercase)
  static String _normalizeLight(String title) {
    return title.trim().toLowerCase();
  }

  /// Heavy normalization (strips punctuation, extra spaces, and the word "season")
  static String _normalizeHeavy(String title) {
    String normalized = title.replaceAll(
      RegExp(r'\bseason\s*', caseSensitive: false), 
      '',
    );
    return normalized
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
        .trim()
        .toLowerCase();
  }

  static bool _isInvalidTitle(String? title) {
    final value = (title ?? '').trim().toLowerCase();
    return value.isEmpty || value == '?' || value == '??' || value == 'null';
  }

  /// Pulls season number using 4 sequential regex patterns
  static int? _extractSeasonNumber(String title) {
    final patterns = [
      RegExp(r'\b(\d+)(?:th|st|nd|rd)?\s*season\b', caseSensitive: false),
      RegExp(r'\bseason\s*(\d+)\b', caseSensitive: false),
      RegExp(r'\s(\d+)\b(?!\s*[a-zA-Z])'),
      RegExp(r'\b(\d+)(nd|rd|th|st)\b'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(title);
      if (match != null && match.group(1) != null) {
        return int.tryParse(match.group(1)!);
      }
    }
    return null;
  }

  /// Calculates weighted match confidence score between 0.0 and 1.0
  static double calculateMatchScore(
    String sourceTitle,
    String targetTitle,
    int? sourceSeason,
    int? targetSeason,
  ) {
    if (sourceTitle.isEmpty) return 0.0;

    final tst = tokenSetRatio(sourceTitle, targetTitle) / 100.0;
    final pr = partialRatio(sourceTitle, targetTitle) / 100.0;
    final r = ratio(sourceTitle, targetTitle) / 100.0;

    // Weighted average: TokenSet (40%), Partial (30%), Ratio (30%)
    double score = (tst * 0.4) + (pr * 0.3) + (r * 0.3);

    // Apply season bonuses or penalties
    if (targetSeason != null && sourceSeason != null) {
      score += (targetSeason == sourceSeason) ? 0.3 : -0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Interrupts ongoing mapping loops when the user navigates away
  static void interruptMapping() {
    _currentMappingToken = "interrupted_${DateTime.now().millisecondsSinceEpoch}";
  }

  /// Cascading multi-stage search sequence
  static Future<T?> mapMedia<T extends Object>({
    required String mediaId,
    required List<String> titles,
    required List<String> synonyms,
    required Future<List<T>> Function(String query) searchExtension,
    required String Function(T item) getTitleFromItem,
    void Function(String status)? onStatusUpdate,
  }) async {
    final mappingToken = DateTime.now().millisecondsSinceEpoch.toString();
    _currentMappingToken = mappingToken;

    bool isInterrupted() => _currentMappingToken != mappingToken;

    String englishTitle = titles.isNotEmpty ? titles[0].trim() : '';
    String romajiTitle = titles.length > 1 ? titles[1].trim() : '';

    if (_isInvalidTitle(englishTitle)) englishTitle = '';
    if (_isInvalidTitle(romajiTitle)) romajiTitle = '';

    if (englishTitle.isEmpty && romajiTitle.isNotEmpty) englishTitle = romajiTitle;
    if (romajiTitle.isEmpty && englishTitle.isNotEmpty) romajiTitle = englishTitle;

    onStatusUpdate?.call("Searching: ${englishTitle.isNotEmpty ? englishTitle : romajiTitle}");

    double bestScore = 0.0;
    T? bestMatch;
    List<T> fallbackResults = [];

    // Helper closure to search and evaluate candidates
    Future<void> executeSearch(String query, String displayTitle, bool isHeavy) async {
      if (isInterrupted() || bestScore >= 0.98) return;

      onStatusUpdate?.call("Searching: $displayTitle");
      final results = await searchExtension(query);

      if (results.isEmpty || isInterrupted()) return;

      final allTargetTitles = {
        if (englishTitle.isNotEmpty) englishTitle,
        if (romajiTitle.isNotEmpty) romajiTitle,
        ...synonyms.take(3),
      }.toList();

      for (final result in results) {
        if (isInterrupted()) return;

        final resultTitle = getTitleFromItem(result);
        onStatusUpdate?.call("Evaluating: $resultTitle");

        final resultSeason = _extractSeasonNumber(resultTitle);

        for (final targetTitle in allTargetTitles) {
          final normalizedTarget = isHeavy ? _normalizeHeavy(targetTitle) : _normalizeLight(targetTitle);
          final normalizedResult = isHeavy ? _normalizeHeavy(resultTitle) : _normalizeLight(resultTitle);

          final score = calculateMatchScore(
            normalizedResult,
            normalizedTarget,
            resultSeason,
            _extractSeasonNumber(targetTitle),
          );

          if (score > bestScore) {
            bestScore = score;
            bestMatch = result;
            fallbackResults = results;
          }
          if (bestScore >= 0.98) break;
        }
        if (bestScore >= 0.98) break;
      }
    }

    // Stage 1: Check if there's a saved custom title match
    final savedTitle = DynamicKeys.stickySource.get<String?>(mediaId);
    if (savedTitle != null && savedTitle.isNotEmpty) {
      await executeSearch(savedTitle, savedTitle, false);
      if (bestScore >= 0.7 && bestMatch != null) {
        onStatusUpdate?.call("Found: ${getTitleFromItem(bestMatch!)}");
        return bestMatch;
      }
    }

    // Stage 2: Primary English Title Search
    if (englishTitle.isNotEmpty) {
      await executeSearch(englishTitle, englishTitle, false);
      if (isInterrupted()) return null;
      if (bestScore >= 0.98) {
        onStatusUpdate?.call("Found: ${getTitleFromItem(bestMatch!)}");
        return bestMatch;
      }
    }

    // Stage 3: Romaji Title Fallback
    if (bestScore < 0.95 && romajiTitle.isNotEmpty && _normalizeLight(romajiTitle) != _normalizeLight(englishTitle)) {
      await executeSearch(romajiTitle, romajiTitle, false);
      if (isInterrupted()) return null;
      if (bestScore >= 0.98) {
        onStatusUpdate?.call("Found: ${getTitleFromItem(bestMatch!)}");
        return bestMatch;
      }
    }

    // Stage 4: Synonyms Fallback
    if (bestScore < 0.9 && synonyms.isNotEmpty) {
      for (final synonym in synonyms.take(3)) {
        if (isInterrupted() || bestScore >= 0.95) break;
        if (_isInvalidTitle(synonym)) continue;
        await executeSearch(synonym, synonym, false);
      }
      if (isInterrupted()) return null;
      if (bestScore >= 0.98) {
        onStatusUpdate?.call("Found: ${getTitleFromItem(bestMatch!)}");
        return bestMatch;
      }
    }

    // Stage 5: Heavy Normalization Fallback (Strip Punctuation & "Season")
    if (bestScore < 0.7) {
      if (englishTitle.isNotEmpty) {
        await executeSearch(_normalizeHeavy(englishTitle), englishTitle, true);
      }
      if (bestScore < 0.8 && romajiTitle.isNotEmpty) {
        await executeSearch(_normalizeHeavy(romajiTitle), romajiTitle, true);
      }
    }

    // Final Evaluation
    if (bestScore >= 0.7 && bestMatch != null) {
      onStatusUpdate?.call("Found: ${getTitleFromItem(bestMatch!)}");
      return bestMatch;
    }

    onStatusUpdate?.call(fallbackResults.isNotEmpty ? "Found (Fallback)" : "No Match Found");
    return fallbackResults.isNotEmpty ? fallbackResults.first : null;
  }
}