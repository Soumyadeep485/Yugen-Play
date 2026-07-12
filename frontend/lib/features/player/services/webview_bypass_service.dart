import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebviewBypassService {
  HeadlessInAppWebView? _headlessWebView;

  /// Holds the resolved cookies and User-Agent after a successful bypass
  Map<String, String> _resolvedHeaders = {};

  /// Attempts to bypass Cloudflare and return the valid HTTP headers
  Future<Map<String, String>?> getBypassedHeaders(String targetUrl) async {
    final completer = Completer<Map<String, String>?>();

    _headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(targetUrl)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        // Mimic a standard mobile browser to avoid immediate red flags
        userAgent:
            "Mozilla/5.0 (Linux; Android 13; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36",
      ),
      onLoadStop: (controller, url) async {
        debugPrint('WebView finished loading: $url');

        // Wait a few seconds for Cloudflare's JS challenge to execute and redirect
        await Future.delayed(const Duration(seconds: 5));

        // Extract the raw HTML to check if we are still stuck on a challenge page
        final html =
            await controller.evaluateJavascript(
                  source: "document.documentElement.outerHTML;",
                )
                as String?;

        if (html != null &&
            (html.contains('cf-browser-verification') ||
                html.contains('Just a moment...'))) {
          debugPrint(
            'WARNING: Cloudflare bypass failed. Still stuck on challenge page.',
          );
          completer.complete(null);
          return;
        }

        // 1. Extract the valid User-Agent
        final userAgent =
            await controller.evaluateJavascript(source: "navigator.userAgent;")
                as String;

        // 2. Extract the session cookies securely
        CookieManager cookieManager = CookieManager.instance();
        List<Cookie> cookies = await cookieManager.getCookies(url: url!);

        String cookieString = cookies
            .map((c) => '${c.name}=${c.value}')
            .join('; ');

        _resolvedHeaders = {'User-Agent': userAgent, 'Cookie': cookieString};

        debugPrint(
          'SUCCESS: Cloudflare challenge bypassed. Cookies intercepted.',
        );

        if (!completer.isCompleted) {
          completer.complete(_resolvedHeaders);
        }
      },
      // Updated to ignore background asset failures
      onReceivedError: (controller, request, error) {
        // Only abort if the MAIN page fails to load.
        // Ignore background scripts blocked by the network gateway.
        if (request.isForMainFrame == true) {
          debugPrint(
            'CRITICAL: WebView Main Frame Error: ${error.description}',
          );
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        } else {
          // It's just a blocked background asset, we can safely ignore it
          debugPrint('Notice: Ignored subresource error: ${error.description}');
        }
      },
    );

    // Boot the invisible browser process
    await _headlessWebView?.run();

    // Timeout the request after 15 seconds to prevent memory leaks
    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        debugPrint('CRITICAL: Cloudflare bypass timed out.');
        _headlessWebView?.dispose();
        return null;
      },
    );
  }

  /// Clean up the background process when done
  void dispose() {
    _headlessWebView?.dispose();
    _headlessWebView = null;
  }
}
