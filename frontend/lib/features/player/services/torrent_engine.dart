import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef StartTorrentC = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> magnet);
typedef StartTorrentDart = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> magnet);

class TorrentEngine {
  late ffi.DynamicLibrary _lib;
  late StartTorrentDart _startTorrent;

  TorrentEngine() {
    _initializeLibrary();
  }

  void _initializeLibrary() {
    if (Platform.isAndroid || Platform.isLinux) {
      _lib = ffi.DynamicLibrary.open('libtorrent.so');
    } else if (Platform.isWindows) {
      _lib = ffi.DynamicLibrary.open('torrent.dll');
    } else {
      throw UnsupportedError('Unsupported OS for Torrent Engine');
    }

    _startTorrent = _lib.lookupFunction<StartTorrentC, StartTorrentDart>(
      'StartTorrent',
    );
  }

  /// Safely passes the magnet link to Go and returns the engine's response
  String startStreaming(String magnetLink) {
    final pointer = magnetLink.toNativeUtf8();
    final resultPointer = _startTorrent(pointer);
    final result = resultPointer.toDartString();

    malloc.free(pointer);

    return result;
  }
}