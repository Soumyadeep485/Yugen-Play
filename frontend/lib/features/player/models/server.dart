import '../data/streaming_source.dart';

/// Represents a streaming server exposed by a media provider.
class Server {
  const Server({
    required this.id,
    required this.name,
    required this.url,
    required this.source,
    this.priority = 0,
  });

  final String id;
  final String name;
  final String url;
  final StreamingSource source;
  final int priority;

  Server copyWith({
    String? id,
    String? name,
    StreamingSource? source,
    int? priority,
    String? url,
  }) {
    return Server(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      source: source ?? this.source,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url, // <-- ADDED
      'source': source.toJson(),
      'priority': priority,
    };
  }

  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String? ?? '',
      source: StreamingSource.fromKey(json['source'] as String),
      priority: json['priority'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'Server('
        'id: $id, '
        'name: $name, '
        'url: $url, ' // <-- ADDED
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
        other.url == url && // <-- ADDED
        other.source == source &&
        other.priority == priority;
  }

  @override
  int get hashCode => Object.hash(id, name, url, source, priority); // <-- ADDED
}
