import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static bool _isInitialized = false;
  static String? _customBaseUrl;

  /// Initialize environment configuration
  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      await dotenv.load(fileName: '.env');
      debugPrint('[ApiConfig] Loaded configuration from .env');
    } catch (_) {
      try {
        await dotenv.load(fileName: 'assets/.env');
        debugPrint('[ApiConfig] Loaded configuration from assets/.env');
      } catch (e) {
        debugPrint('[ApiConfig] No .env file found in assets, using fallback environment defaults: $e');
      }
    }
    _isInitialized = true;
  }

  /// Override the API base URL at runtime (useful for connecting to phone via LAN IP or Tunnel)
  static void setCustomBaseUrl(String? url) {
    if (url != null && url.trim().isNotEmpty) {
      String clean = url.trim();
      if (!clean.endsWith('/api') && !clean.endsWith('/api/')) {
        if (clean.endsWith('/')) {
          clean = '${clean}api';
        } else {
          clean = '$clean/api';
        }
      }
      _customBaseUrl = clean;
    } else {
      _customBaseUrl = null;
    }
  }

  /// Get the current active API base URL
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }

    // 1. Check dart-define
    const dartDefineUrl = String.fromEnvironment('API_BASE_URL');
    if (dartDefineUrl.isNotEmpty) {
      return dartDefineUrl;
    }

    // 2. Check dotenv
    if (dotenv.isInitialized) {
      final envUrl = dotenv.env['API_BASE_URL'];
      if (envUrl != null && envUrl.trim().isNotEmpty) {
        return envUrl.trim();
      }
    }

    // 3. Smart platform defaults
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Primary mobile Wi-Fi LAN IP for physical device
      return 'http://10.90.141.134:5000/api';
    } else {
      return 'http://localhost:5000/api';
    }
  }

  /// Base host without /api
  static String get hostUrl {
    final base = baseUrl;
    if (base.endsWith('/api')) {
      return base.substring(0, base.length - 4);
    }
    return base;
  }

  static String get supabaseUrl =>
      (dotenv.isInitialized ? dotenv.env['SUPABASE_URL'] : null) ?? 'https://phkjucynruuqaxbgytrz.supabase.co';

  static String get supabaseAnonKey =>
      (dotenv.isInitialized ? dotenv.env['SUPABASE_ANON_KEY'] : null) ?? '';

  // REST API Endpoints
  static Uri get healthUri => Uri.parse('$baseUrl/health');
  static Uri get grievancesUri => Uri.parse('$baseUrl/grievances');
  static Uri grievanceDetailUri(String id) => Uri.parse('$baseUrl/grievances/$id');
  static Uri grievanceStatusUri(String id) => Uri.parse('$baseUrl/grievances/$id/status');
  static Uri get statsUri => Uri.parse('$baseUrl/grievances/stats');
  static Uri get classifyUri => Uri.parse('$baseUrl/ai/classify');
  static Uri get chatUri => Uri.parse('$baseUrl/ai/chat');
  static Uri get departmentsUri => Uri.parse('$baseUrl/departments');
  static Uri reverseGeocodeUri(double lat, double lng) =>
      Uri.parse('$baseUrl/maps/reverse-geocode?lat=$lat&lng=$lng');
}
