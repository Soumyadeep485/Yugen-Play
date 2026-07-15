import 'package:dio/dio.dart';
import 'app_network_client.dart';

class ExtensionClient {
  final AppNetworkClient _networkClient;

  ExtensionClient(this._networkClient);

  /// Accesses the pre-configured shared Dio instance
  Dio get _dio => _networkClient.dio;

  /// Fetches raw JSON map data directly from a repository URL
  Future<Response<dynamic>> getManifest(String url) async {
    return await _dio.get(url);
  }

  /// Streams a file download directly to a local device path
  Future<Response> downloadExtensionPayload({
    required String downloadUrl,
    required String savePath,
    Options? options,
  }) async {
    return await _dio.download(downloadUrl, savePath, options: options);
  }
}
