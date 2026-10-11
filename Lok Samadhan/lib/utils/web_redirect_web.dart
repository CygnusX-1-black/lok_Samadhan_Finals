// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void openUrlInBrowser(String url) {
  html.window.location.assign(url);
}

String getCurrentWebOrigin() {
  try {
    return html.window.location.origin;
  } catch (e) {
    return 'http://localhost:8088';
  }
}

String getCurrentWebPath() {
  try {
    return html.window.location.pathname ?? '/';
  } catch (e) {
    return '/';
  }
}

/// Parses Supabase OAuth callback parameters from URL fragment and search parameters
Map<String, String> getWebAuthParams() {
  final Map<String, String> params = {};
  try {
    final hash = html.window.location.hash;
    final search = html.window.location.search ?? '';

    // 1. Parse fragment parameters (#access_token=...&refresh_token=... or #error=...)
    if (hash.isNotEmpty) {
      final cleanHash = hash.startsWith('#') ? hash.substring(1) : hash;
      final queryPart = cleanHash.contains('?')
          ? cleanHash.split('?')[1]
          : (cleanHash.contains('=') ? cleanHash : '');

      if (queryPart.isNotEmpty) {
        final pairs = queryPart.split('&');
        for (final pair in pairs) {
          final kv = pair.split('=');
          if (kv.length >= 2) {
            params[Uri.decodeComponent(kv[0])] = Uri.decodeComponent(kv.sublist(1).join('='));
          }
        }
      }
    }

    // 2. Parse query parameters (?code=... or ?error=...)
    if (search.isNotEmpty) {
      final cleanSearch = search.startsWith('?') ? search.substring(1) : search;
      final pairs = cleanSearch.split('&');
      for (final pair in pairs) {
        final kv = pair.split('=');
        if (kv.length >= 2) {
          params[Uri.decodeComponent(kv[0])] = Uri.decodeComponent(kv.sublist(1).join('='));
        }
      }
    }
  } catch (e) {
    // Ignore extraction failure
  }
  return params;
}

/// Cleans OAuth tokens and error codes from the browser address bar without triggering a page reload
void cleanWebAuthUrl() {
  try {
    final currentPath = html.window.location.pathname ?? '/';
    html.window.history.replaceState(null, html.document.title, currentPath);
  } catch (e) {
    // Ignore
  }
}
