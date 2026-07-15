import 'package:dio/dio.dart';
import 'interceptors/ua_interceptor.dart';

class AppNetworkClient {
  late final Dio _dio;

  AppNetworkClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );

    // Attach our global interceptors
    _dio.interceptors.addAll([
      UserAgentInterceptor(),
      // Future location for the WebviewBypassInterceptor
    ]);
  }

  /// Exposes the secure pre-configured Dio instance to other clients
  Dio get dio => _dio;
}
