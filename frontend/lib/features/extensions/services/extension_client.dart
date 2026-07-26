import 'package:dio/dio.dart';
import '../../../core/network/app_network_client.dart';

class ExtensionClient {
  final AppNetworkClient _networkClient;

  ExtensionClient(this._networkClient);

  Dio get _dio => _networkClient.dio;

  Future<Response<dynamic>> getManifest(String url) async {
    return await _dio.get(url);
  }

  Future<Response> downloadExtensionPayload({
    required String downloadUrl,
    required String savePath,
    Options? options,
  }) async {
    return await _dio.download(downloadUrl, savePath, options: options);
  }
}