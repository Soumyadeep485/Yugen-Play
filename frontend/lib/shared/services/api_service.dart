import 'package:http/http.dart' as http;

import '../api/api_constants.dart';

class ApiService {
  Future<http.Response> get(String endpoint) {
    return http.get(Uri.parse("${ApiConstants.baseUrl}$endpoint"));
  }
}
