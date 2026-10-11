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

    // 1. Web browser always connects to localhost:5000/api
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }

    // 2. Check dart-define
    const dartDefineUrl = String.fromEnvironment('API_BASE_URL');
    if (dartDefineUrl.isNotEmpty) {
      return dartDefineUrl;
    }

    // 3. Check dotenv
    if (dotenv.isInitialized) {
      final envUrl = dotenv.env['API_BASE_URL'];
      if (envUrl != null && envUrl.trim().isNotEmpty) {
        return envUrl.trim();
      }
    }

    // 4. Platform defaults
    if (defaultTargetPlatform == TargetPlatform.android) {
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

  static String get supabaseAnonKey {
    if (dotenv.isInitialized) {
      final key = dotenv.env['SUPABASE_ANON_KEY'];
      if (key != null && key.trim().isNotEmpty) return key.trim();
    }
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBoa2p1Y3lucnV1cWF4Ymd5dHJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEwOTI2NDUsImV4cCI6MjEwNjY2ODY0NX0.pLUArzOLD6BOK_jHjhfk0wCBXH263Df44XRHVIxzQAI';
  }

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

  // Rewards System Endpoints
  static Uri get rewardsCatalogueUri => Uri.parse('$baseUrl/rewards/catalogue');
  static Uri rewardsBalanceUri([String? userId]) =>
      Uri.parse(userId != null ? '$baseUrl/rewards/balance?userId=$userId' : '$baseUrl/rewards/balance');
  static Uri get rewardsAwardUri => Uri.parse('$baseUrl/rewards/award');
  static Uri get rewardsRedeemUri => Uri.parse('$baseUrl/rewards/redeem');
  static Uri rewardsTransactionsUri([String? userId]) =>
      Uri.parse(userId != null ? '$baseUrl/rewards/transactions?userId=$userId' : '$baseUrl/rewards/transactions');
  static Uri rewardsClaimsUri([String? userId]) =>
      Uri.parse(userId != null ? '$baseUrl/rewards/claims?userId=$userId' : '$baseUrl/rewards/claims');
}
