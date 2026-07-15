class PluginMeta {
  final String id;
  final String name;
  final String version;
  final String path;
  final bool enabled;

  PluginMeta({
    required this.id,
    required this.name,
    required this.version,
    required this.path,
    required this.enabled,
  });

  // Convert to Map for Hive storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'path': path,
      'enabled': enabled,
    };
  }

  // Create from Hive Map
  factory PluginMeta.fromMap(Map<dynamic, dynamic> map) {
    return PluginMeta(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      version: map['version'] ?? '1.0.0',
      path: map['path'] ?? '',
      enabled: map['enabled'] ?? true,
    );
  }
}
