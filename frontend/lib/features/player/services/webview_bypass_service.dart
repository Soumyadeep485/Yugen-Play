import 'package:flutter/foundation.dart';

class WebviewBypassService {
  String _userAgent = '';
  String _cookies = '';

  /// Saves the Cloudflare bypass session from the WebView
  Future<void> saveSession({
    required String origin,
    required String cookies,
    required String userAgent,
  }) async {
    _cookies = cookies;
    _userAgent = userAgent;
    debugPrint('Bypass session saved for $origin');
  }

  /// Injects the stolen cookies & user-agent into outgoing HTTP requests
  Map<String, String> getBypassHeaders(String url) {
    if (_cookies.isEmpty && _userAgent.isEmpty) return {};

    return {
      if (_userAgent.isNotEmpty) 'User-Agent': _userAgent,
      if (_cookies.isNotEmpty) 'Cookie': _cookies,
    };
  }
}
