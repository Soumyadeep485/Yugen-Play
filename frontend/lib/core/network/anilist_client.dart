import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AniListClient {
  static const String _baseUrl = 'https://graphql.anilist.co';
  late final Dio _dio;

  AniListClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: false, error: true),
      );
    }
  }

  /// Executes a GraphQL query against the AniList API.
  Future<Map<String, dynamic>?> query({
    required String queryString,
    Map<String, dynamic>? variables,
  }) async {
    try {
      final requestData = <String, dynamic>{'query': queryString};

      if (variables != null) {
        requestData['variables'] = variables;
      }

      final response = await _dio.post('', data: requestData);

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        debugPrint(
          'AniList API Error: ${response.statusCode} - ${response.data}',
        );
        return null;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        debugPrint(
          'CRITICAL: You hit the AniList Rate Limit (90 requests/min). Slow down.',
        );
      } else {
        debugPrint('Network Error: ${e.message}');
      }
      return null;
    } catch (e) {
      debugPrint('Unknown Error: $e');
      return null;
    }
  }
}