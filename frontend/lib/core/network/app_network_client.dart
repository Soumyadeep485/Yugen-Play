import 'package:dio/dio.dart';
import 'interceptors/user_agent_interceptor.dart';

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

    _dio.interceptors.addAll([
      UserAgentInterceptor(),
    ]);
  }

  Dio get dio => _dio;
}