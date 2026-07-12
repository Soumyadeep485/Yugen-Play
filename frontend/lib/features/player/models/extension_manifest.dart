class ExtensionManifest {
  final String id;
  final String name;
  final String version;
  final String scriptUrl;

  ExtensionManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.scriptUrl,
  });

  factory ExtensionManifest.fromJson(Map<String, dynamic> json) {
    return ExtensionManifest(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      version: json['version'] ?? '',
      scriptUrl: json['scriptUrl'] ?? '',
    );
  }
}
