import 'package:dio/dio.dart';

class UserAgentInterceptor extends Interceptor {
  // A standard modern Android user agent string to protect out-of-the-box calls
  static const String _defaultUserAgent =
      'Mozilla/5.0 (Linux; Android 13; SM-S911B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // If headers don't already contain a custom User-Agent set by a specific scraper, inject the default one
    if (!options.headers.containsKey('User-Agent')) {
      options.headers['User-Agent'] = _defaultUserAgent;
    }

    // Standardize browser acceptance headers
    options.headers['Accept'] = 'application/json, text/html, */*';

    super.onRequest(options, handler);
  }
}
