import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cronet_http/cronet_http.dart';

class LocalStreamProxy {
  static final LocalStreamProxy _instance = LocalStreamProxy._internal();
  factory LocalStreamProxy() => _instance;
  LocalStreamProxy._internal();

  HttpServer? _server;
  http.Client? _client;

  int get port => _server?.port ?? 8080;
  bool get isRunning => _server != null;

  Future<void> start() async {
    if (_server != null) return;
    try {
      if (Platform.isAndroid) {
        final engine = CronetEngine.build();
        _client = CronetClient.fromCronetEngine(engine);
        debugPrint('✅ [LocalProxy] Cronet Engine Initialized');
      } else {
        _client = http.Client();
      }

      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server!.listen(_handleRequest);
      debugPrint('🚀 [LocalProxy] Started on http://127.0.0.1:$port');
    } catch (e) {
      debugPrint('🚨 [LocalProxy] FATAL: $e');
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _client?.close();
    _client = null;
    debugPrint('🛑 [LocalProxy] Stopped.');
  }

  String getProxyUrl(String originalUrl, Map<String, String> headers) {
    if (!isRunning) return originalUrl;
    final u = Uri.encodeComponent(originalUrl);
    final h = Uri.encodeComponent(jsonEncode(headers));
    return 'http://127.0.0.1:$port/proxy?u=$u&h=$h';
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final targetUrl = request.uri.queryParameters['u'];
    final hStr = request.uri.queryParameters['h'];

    if (targetUrl == null || targetUrl.isEmpty) {
      request.response.statusCode = HttpStatus.badRequest;
      return request.response.close();
    }

    try {
      Map<String, String> headers = {};
      if (hStr != null && hStr.isNotEmpty) {
        try {
          headers = Map<String, String>.from(jsonDecode(hStr));
        } catch (_) {}
      }

      // 🚀 SAFEGUARD 2: AUTO-REBUILD MISSING HEADERS
      // If the local database drops the stream headers, forcefully re-inject the spoofed domains
      if (!headers.keys.any((k) => k.toLowerCase() == 'referer')) {
        if (targetUrl.contains('vidtub') || targetUrl.contains('vidtube')) {
          headers['Referer'] = 'https://vidtube.site/';
          headers['Origin'] = 'https://vidtube.site';
        } else if (targetUrl.contains('megap') || targetUrl.contains('akirax') || targetUrl.contains('shiora')) {
          headers['Referer'] = 'https://megaplay.buzz/';
          headers['Origin'] = 'https://megaplay.buzz';
        } else if (targetUrl.contains('rabbit')) {
          headers['Referer'] = 'https://rabbitstream.net/';
          headers['Origin'] = 'https://rabbitstream.net';
        }
      }

      if (!headers.keys.any((k) => k.toLowerCase() == 'user-agent')) {
        headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';
      }
      if (!headers.keys.any((k) => k.toLowerCase() == 'accept')) {
        headers['Accept'] = '*/*';
      }

      headers.remove('Host');
      headers.remove('host');
      headers.remove('Accept-Encoding');

      final response = await _client!.get(Uri.parse(targetUrl), headers: headers);

      request.response.statusCode = response.statusCode;

      if (response.statusCode != 200 && response.statusCode != 206) {
        request.response.add(response.bodyBytes);
        return;
      }

      final contentType = response.headers['content-type'] ?? 'application/octet-stream';
      request.response.headers.contentType = ContentType.parse(contentType);
      request.response.headers.add('Access-Control-Allow-Origin', '*'); 

      if (targetUrl.contains('.m3u8') || contentType.contains('mpegurl')) {
        final body = utf8.decode(response.bodyBytes, allowMalformed: true);
        final lines = body.split('\n');
        final rewrittenLines = <String>[];
        final baseUrl = Uri.parse(targetUrl);

        for (var line in lines) {
          line = line.trim();
          if (line.isEmpty) continue;
          
          if (line.startsWith('#')) {
            // Hijack Embedded Subtitles hidden inside #EXT-X-MEDIA tags!
            if (line.contains('URI="')) {
              final RegExp uriRegex = RegExp(r'URI="([^"]+)"');
              line = line.replaceAllMapped(uriRegex, (match) {
                final originalUri = match.group(1);
                if (originalUri != null) {
                  final resolvedUri = baseUrl.resolve(originalUri).toString();
                  final proxiedUri = getProxyUrl(resolvedUri, headers);
                  return 'URI="$proxiedUri"';
                }
                return match.group(0)!;
              });
            }
            rewrittenLines.add(line);
          } else {
            // Proxy standard video chunks (.ts files) and sub-playlists
            final resolvedUri = baseUrl.resolve(line).toString();
            final proxyUri = getProxyUrl(resolvedUri, headers);
            rewrittenLines.add(proxyUri);
          }
        }
        request.response.write(rewrittenLines.join('\n'));
      } else {
        request.response.add(response.bodyBytes);
      }
    } catch (e) {
      debugPrint('🔥 [LocalProxy] CRASH: $e');
      request.response.statusCode = HttpStatus.internalServerError;
    } finally {
      await request.response.close();
    }
  }
}