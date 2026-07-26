class TorrentRelease {
  final String fileName;
  final String releaseGroup;
  final String resolution;
  final String size;
  final int seeders;
  final int leechers;
  final String magnetLink;
  final String? directUrl; // Tosho HTTP Direct Mirror Link

  TorrentRelease({
    required this.fileName,
    required this.releaseGroup,
    required this.resolution,
    required this.size,
    required this.seeders,
    required this.leechers,
    required this.magnetLink,
    this.directUrl,
  });
}
