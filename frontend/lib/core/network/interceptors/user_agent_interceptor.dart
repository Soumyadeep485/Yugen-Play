import 'package:dio/dio.dart';

import '../session_service.dart';

class UserAgentInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = SessionService();

    if (session.userAgent != null) {
      options.headers['User-Agent'] = session.userAgent;
    } else {
      options.headers['User-Agent'] =
          'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';
    }

    if (session.cookies != null) {
      options.headers['Cookie'] = session.cookies;
    }

    options.headers['Accept'] = '*/*';
    options.headers['Accept-Language'] = 'en-US,en;q=0.9';

    super.onRequest(options, handler);
  }
}
