class ExtensionManifest {
  final String name;
  final String path;
  final String version;

  ExtensionManifest({
    required this.name,
    required this.path,
    this.version = '1.0.0',
  });
}
