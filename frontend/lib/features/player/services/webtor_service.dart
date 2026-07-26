import 'package:flutter/foundation.dart';

class WebTorService {
  Future<String?> getStreamUrl(String infoHash) async {
    try {
      debugPrint("Initializing WebTor stream for Hash: $infoHash");

      // NOTE: WebTor frequently changes their public proxy node domains.
      // You will eventually need to parse the JSON response from their API
      // to dynamically grab the correct active node.
      return 'https://eu-webtor.cf/magnet/$infoHash/download';
    } catch (e) {
      debugPrint("WebTor error: $e");
      return null;
    }
  }
}