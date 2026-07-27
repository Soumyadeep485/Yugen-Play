/// Represents a single subtitle track for video playback.
class SubtitleTrack {
  final String id;
  final String label;
  final String url;
  final String language;
  final bool isDefault;

  const SubtitleTrack({
    required this.id,
    required this.label,
    required this.url,
    this.language = 'en',
    this.isDefault = false,
  });

  /// Fully safe factory parser that handles missing or null fields gracefully
  factory SubtitleTrack.fromJson(Map<String, dynamic> json) {
    final extractedUrl = (json['url'] ??
            json['file'] ??
            json['uri'] ??
            json['src'] ??
            '')
        .toString();

    final extractedLabel = (json['label'] ??
            json['title'] ??
            json['name'] ??
            'English')
        .toString();

    return SubtitleTrack(
      id: (json['id'] ?? json['label'] ?? 'sub_${DateTime.now().millisecondsSinceEpoch}')
          .toString(),
      label: extractedLabel.isEmpty ? 'English' : extractedLabel,
      url: extractedUrl,
      language: (json['language'] ?? json['lang'] ?? 'en').toString(),
      isDefault: json['isDefault'] == true || json['default'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'url': url,
      'file': url,
      'language': language,
      'isDefault': isDefault,
    };
  }

  @override
  String toString() => 'SubtitleTrack(label: $label, url: $url)';
}