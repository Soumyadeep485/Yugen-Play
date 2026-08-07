class ExtensionManifest {
  final String name;
  final String pkgName;
  final String author;
  final String version;
  final String baseUrl;
  final String iconUrl;
  final String localPath;

  ExtensionManifest({
    required this.name,
    required this.pkgName,
    required this.author,
    required this.version,
    required this.baseUrl,
    required this.iconUrl,
    required this.localPath,
  });

  // Easy conversion from your GitHub repository index.json
  factory ExtensionManifest.fromJson(Map<String, dynamic> json, String localPath) {
    return ExtensionManifest(
      name: json['name'] ?? 'Unknown',
      pkgName: json['pkg'] ?? 'unknown',
      author: json['author'] ?? 'Unknown',
      version: json['version'] ?? '1.0.0',
      baseUrl: json['baseUrl'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
      localPath: localPath,
    );
  }
}