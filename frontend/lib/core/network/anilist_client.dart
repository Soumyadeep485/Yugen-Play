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
          // Spoofing a standard desktop browser to bypass Cloudflare's bot protection
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Origin': 'https://anilist.co',
          'Referer': 'https://anilist.co/',
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
        // Now prints the actual response data so Cloudflare errors don't hide
        debugPrint('Network Error [${e.response?.statusCode}]: ${e.message}\nResponse Data: ${e.response?.data}');
      }
      return null;
    } catch (e) {
      debugPrint('Unknown Error: $e');
      return null;
    }
  }
}