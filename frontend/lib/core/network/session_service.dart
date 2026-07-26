import 'package:flutter/foundation.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  String? userAgent;
  String? cookies;

  bool get hasValidSession => cookies != null && cookies!.isNotEmpty;

  void updateSession({
    required String newUserAgent,
    required String newCookies,
  }) {
    userAgent = newUserAgent;
    cookies = newCookies;
    debugPrint('✅ [SessionService] Synced User-Agent: $userAgent');
    debugPrint('✅ [SessionService] Synced Cookies: $cookies');
  }
}
