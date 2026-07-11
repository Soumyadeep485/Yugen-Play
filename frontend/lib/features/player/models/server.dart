import '../data/streaming_source.dart';

/// Represents a streaming server exposed by a media provider.
///
/// A server is responsible for resolving one or more playable
/// [StreamLink] objects for a specific episode.
///
/// This model intentionally contains only server metadata.
/// Playback capabilities such as subtitles, audio tracks,
/// and available qualities belong to [StreamLink].
///
/// Examples:
/// - Vidstream
/// - MegaCloud
/// - Filemoon
/// - MP4Upload
class Server {
  const Server({
    required this.id,
    required this.name,
    required this.source,
    this.priority = 0,
  });

  /// Unique server identifier within the provider.
  final String id;

  /// Human-readable server name.
  final String name;

  /// Media provider that owns this server.
  final StreamingSource source;

  /// Server priority.
  ///
  /// Higher values indicate a more preferred server.
  final int priority;

  /// Returns a modified copy of this server.
  Server copyWith({
    String? id,
    String? name,
    StreamingSource? source,
    int? priority,
  }) {
    return Server(
      id: id ?? this.id,
      name: name ?? this.name,
      source: source ?? this.source,
      priority: priority ?? this.priority,
    );
  }

  /// Converts this server into JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'source': source.toJson(),
      'priority': priority,
    };
  }

  /// Creates a server from JSON.
  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      id: json['id'] as String,
      name: json['name'] as String,
      source: StreamingSource.fromKey(json['source'] as String),
      priority: json['priority'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'Server('
        'id: $id, '
        'name: $name, '
        'source: ${source.displayName}, '
        'priority: $priority'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is Server &&
        other.id == id &&
        other.name == name &&
        other.source == source &&
        other.priority == priority;
  }

  @override
  int get hashCode => Object.hash(id, name, source, priority);
}
