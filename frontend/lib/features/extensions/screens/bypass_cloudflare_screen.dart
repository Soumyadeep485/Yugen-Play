import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../core/network/session_service.dart';

class BypassCloudflareScreen extends StatefulWidget {
  final String targetUrl;

  const BypassCloudflareScreen({super.key, required this.targetUrl});

  @override
  State<BypassCloudflareScreen> createState() => _BypassCloudflareScreenState();
}

class _BypassCloudflareScreenState extends State<BypassCloudflareScreen> {
  InAppWebViewController? _webViewController;
  bool _isSyncing = false;

  Future<void> _syncCookiesAndClose() async {
    setState(() => _isSyncing = true);
    try {
      final cookieManager = CookieManager.instance();
      final url = WebUri(widget.targetUrl);

      // Extract all cookies set by Cloudflare (cf_clearance, etc.)
      final cookies = await cookieManager.getCookies(url: url);
      final cookieString = cookies
          .map((c) => '${c.name}=${c.value}')
          .join('; ');

      // Extract real User-Agent from WebKit
      final userAgent =
          await _webViewController?.evaluateJavascript(
                source: 'navigator.userAgent',
              )
              as String?;

      if (userAgent != null && cookieString.isNotEmpty) {
        SessionService().updateSession(
          newUserAgent: userAgent.replaceAll('"', ''),
          newCookies: cookieString,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cookies & User-Agent synced successfully!'),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to extract cookies');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12131C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1F2B),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bypass Cloudflare', style: TextStyle(fontSize: 16)),
            Text(
              widget.targetUrl,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _isSyncing ? null : _syncCookiesAndClose,
            icon: _isSyncing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync, color: Colors.greenAccent),
            label: const Text(
              'Sync Cookies',
              style: TextStyle(color: Colors.greenAccent),
            ),
          ),
        ],
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.targetUrl)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          useShouldOverrideUrlLoading: true,
          userAgent:
              'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
        ),
        onWebViewCreated: (controller) => _webViewController = controller,
      ),
    );
  }
}
