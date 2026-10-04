import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/department.dart';
import '../models/grievance.dart';

class BackendHealthResult {
  final bool isConnected;
  final String status;
  final String? databaseMode;
  final String? aiProvider;
  final String? aiModel;
  final String? error;

  BackendHealthResult({
    required this.isConnected,
    this.status = 'offline',
    this.databaseMode,
    this.aiProvider,
    this.aiModel,
    this.error,
  });
}

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();
  final Duration _timeout = const Duration(seconds: 8);

  /// Active Base URL configured via ApiConfig
  static String get baseUrl => ApiConfig.baseUrl;

  /// Custom Base URL override
  static void setCustomBaseUrl(String url) {
    ApiConfig.setCustomBaseUrl(url);
    debugPrint('[ApiService] Updated Base URL to: ${ApiConfig.baseUrl}');
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// 1. Health check with detailed diagnostics
  Future<BackendHealthResult> checkHealth() async {
    try {
      final response = await _client
          .get(ApiConfig.healthUri, headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return BackendHealthResult(
          isConnected: true,
          status: data['status']?.toString() ?? 'healthy',
          databaseMode: data['databaseMode']?.toString(),
          aiProvider: data['aiProvider']?.toString(),
          aiModel: data['aiModel']?.toString(),
        );
      }
      return BackendHealthResult(
        isConnected: false,
        error: 'Status ${response.statusCode}: ${response.reasonPhrase}',
      );
    } catch (e) {
      debugPrint('[ApiService] Health check failed: $e');
      return BackendHealthResult(
        isConnected: false,
        error: e.toString(),
      );
    }
  }

  /// 2. Fetch all grievances from backend (Supabase/DB) with optional filters
  Future<List<Grievance>> fetchGrievances({
    DepartmentCategory? department,
    String? departmentCategory,
    GrievanceStatus? status,
    String? urgency,
    String? district,
    String? citizenPhone,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (department != null) {
        queryParams['departmentCategory'] = department.name;
      } else if (departmentCategory != null && departmentCategory.isNotEmpty) {
        queryParams['departmentCategory'] = departmentCategory;
      }
      if (status != null) {
        queryParams['status'] = status.name;
      }
      if (urgency != null && urgency.isNotEmpty) queryParams['urgency'] = urgency;
      if (district != null && district.isNotEmpty) queryParams['district'] = district;
      if (citizenPhone != null && citizenPhone.isNotEmpty) queryParams['citizenPhone'] = citizenPhone;
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = queryParams.isEmpty
          ? ApiConfig.grievancesUri
          : ApiConfig.grievancesUri.replace(queryParameters: queryParams);

      final response = await _client.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = (body['data'] as List? ?? []);
        return list.map((item) => Grievance.fromJson(Map<String, dynamic>.from(item))).toList();
      } else {
        throw Exception('Failed to fetch grievances: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ApiService] Error fetching grievances: $e');
      rethrow;
    }
  }

  /// 3. Fetch single grievance by ID
  Future<Grievance?> getGrievanceById(String id) async {
    try {
      final response = await _client
          .get(ApiConfig.grievanceDetailUri(id), headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['data'] != null) {
          return Grievance.fromJson(Map<String, dynamic>.from(body['data']));
        }
      }
      return null;
    } catch (e) {
      debugPrint('[ApiService] Error getting grievance $id: $e');
      return null;
    }
  }

  /// Backward compatible alias for getGrievanceById
  Future<Grievance?> fetchGrievanceById(String id) => getGrievanceById(id);

  /// 4. Lodge a new grievance to the backend database (Supabase)
  Future<Grievance> lodgeGrievance({
    required String rawSpeechText,
    String? translatedText,
    required String citizenName,
    required String citizenPhone,
    required String spokenDialect,
    DepartmentCategory? departmentCategory,
    String? villageWard,
    String? block,
    String? district,
    String? state,
    double latitude = 25.5941,
    double longitude = 85.1376,
    UrgencyLevel urgency = UrgencyLevel.medium,
    double? confidenceScore,
    bool isHitlFallback = false,
    String? hitlReviewerNotes,
    String? photoUrl,
    String? photoAnalysisSummary,
  }) async {
    try {
      final payload = {
        'rawSpeechText': rawSpeechText,
        'translatedText': translatedText,
        'citizenName': citizenName.isEmpty ? 'Nagarik Citizen' : citizenName,
        'citizenPhone': citizenPhone,
        'spokenDialect': spokenDialect,
        if (departmentCategory != null) 'departmentCategory': departmentCategory.name,
        'villageWard': villageWard ?? '',
        'block': block ?? '',
        'district': district ?? '',
        'state': state ?? '',
        'latitude': latitude,
        'longitude': longitude,
        'urgency': urgency.name,
        if (confidenceScore != null) 'aiConfidenceScore': confidenceScore,
        'isHitlFallback': isHitlFallback,
        if (hitlReviewerNotes != null) 'hitlReviewerNotes': hitlReviewerNotes,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (photoAnalysisSummary != null) 'photoAnalysisSummary': photoAnalysisSummary,
      };

      final response = await _client
          .post(
            ApiConfig.grievancesUri,
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return Grievance.fromJson(Map<String, dynamic>.from(body['data']));
      } else {
        throw Exception('Failed to lodge grievance: HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] Error lodging grievance: $e');
      rethrow;
    }
  }

  /// 5. Update grievance status (official action)
  Future<Grievance> updateGrievanceStatus({
    required String grievanceId,
    required GrievanceStatus newStatus,
    String? note,
    String? officerId,
    String? officerName,
    DepartmentCategory? approvedCategory,
  }) async {
    try {
      final payload = {
        'status': newStatus.name,
        if (note != null) 'note': note,
        if (officerId != null) 'officerId': officerId,
        if (officerName != null) 'officerName': officerName,
        if (approvedCategory != null) 'approvedCategory': approvedCategory.name,
      };

      final response = await _client
          .patch(
            ApiConfig.grievanceStatusUri(grievanceId),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return Grievance.fromJson(Map<String, dynamic>.from(body['data']));
      } else {
        throw Exception('Failed to update status: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ApiService] Error updating status for $grievanceId: $e');
      rethrow;
    }
  }

  /// 6. Auto-escalate grievance past SLA
  Future<Grievance?> escalateGrievance({
    required String grievanceId,
    String? reason,
    String? actor,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/grievances/$grievanceId/escalate');
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({
              'reason': reason ?? 'SLA Breached - Auto Escalation',
              'actor': actor ?? 'Lok Samadhan SLA Sentinel',
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Grievance.fromJson(Map<String, dynamic>.from(data['data']));
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Escalate error: $e');
    }
    return null;
  }

  /// 7. AI Classification using Gemma / Gemini API via backend
  Future<Map<String, dynamic>?> classifyGrievance(
    String text, {
    String? district,
    String? state,
    Map<String, dynamic>? locationHint,
  }) async {
    try {
      final payload = {
        'text': text,
        'locationHint': locationHint ?? {
          if (district != null) 'district': district,
          if (state != null) 'state': state,
        }
      };

      final response = await _client
          .post(
            ApiConfig.classifyUri,
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return Map<String, dynamic>.from(body['data'] ?? {});
      }
      return null;
    } catch (e) {
      debugPrint('[ApiService] AI Classify error: $e');
      return null;
    }
  }

  /// Backward compatible alias for classifyGrievance
  Future<Map<String, dynamic>?> classifyWithAI(
    String text, {
    Map<String, dynamic>? locationHint,
  }) =>
      classifyGrievance(text, locationHint: locationHint);

  /// 8. AI Chat Assistant via backend
  Future<Map<String, dynamic>?> chatWithAi({
    required String message,
    List<Map<String, dynamic>>? history,
    Map<String, dynamic>? activeDraft,
  }) async {
    try {
      final payload = {
        'message': message,
        'history': history ?? [],
        'activeDraft': activeDraft,
      };

      final response = await _client
          .post(
            ApiConfig.chatUri,
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return Map<String, dynamic>.from(body['data'] ?? {});
      }
      return null;
    } catch (e) {
      debugPrint('[ApiService] AI Chat error: $e');
      return null;
    }
  }

  /// Backward compatible alias for chatWithAi
  Future<Map<String, dynamic>?> chatWithAI(
    String message, {
    List<Map<String, dynamic>>? history,
    Map<String, dynamic>? activeDraft,
  }) =>
      chatWithAi(message: message, history: history, activeDraft: activeDraft);

  /// 9. OpenStreetMap Reverse Geocode
  Future<Map<String, dynamic>?> reverseGeocode(double latitude, double longitude) async {
    try {
      final uri = ApiConfig.reverseGeocodeUri(latitude, longitude);
      final response = await _client.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Reverse geocode error: $e');
    }
    return null;
  }

  /// 10. Fetch Dashboard Stats
  Future<Map<String, dynamic>?> fetchStats() async {
    try {
      final response = await _client.get(ApiConfig.statsUri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Fetch stats error: $e');
    }
    return null;
  }

  /// 11. Register new citizen account (Supabase Auth)
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/register');
    final response = await _client
        .post(
          uri,
          headers: _headers,
          body: jsonEncode({
            'fullName': fullName,
            'email': email,
            'password': password,
          }),
        )
        .timeout(_timeout);

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (data['success'] == true) {
        return Map<String, dynamic>.from(data['data']);
      }
    }
    throw Exception(data['message'] ?? 'Registration failed (HTTP ${response.statusCode})');
  }

  /// 12. Login with email and password (Supabase Auth)
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/login');
    final response = await _client
        .post(
          uri,
          headers: _headers,
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        )
        .timeout(_timeout);

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data['success'] == true) {
        return Map<String, dynamic>.from(data['data']);
      }
    }
    throw Exception(data['message'] ?? 'Login failed. Please check your credentials.');
  }

  /// 13. Fetch Google OAuth URL
  Future<String?> getGoogleOAuthUrl({String? redirectTo}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/google-url').replace(
        queryParameters: redirectTo != null ? {'redirectTo': redirectTo} : null,
      );
      final response = await _client.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data']['url']?.toString();
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Google OAuth URL error: $e');
    }
    return null;
  }

  /// 14. Forgot password reset
  Future<String> forgotPassword(String email) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/forgot-password');
    final response = await _client
        .post(uri, headers: _headers, body: jsonEncode({'email': email}))
        .timeout(_timeout);

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['message'] ?? 'Password reset link sent to your email.';
    }
    throw Exception(data['message'] ?? 'Failed to send password reset request.');
  }

  /// 15. Verify current session
  Future<Map<String, dynamic>?> getCurrentUser(String token) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/me');
      final response = await _client.get(
        uri,
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']['user']);
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Session verification error: $e');
    }
    return null;
  }

  /// 16. Logout
  Future<void> logout() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/logout');
      await _client.post(uri, headers: _headers).timeout(const Duration(seconds: 4));
    } catch (e) {
      // Ignore
    }
  }

  /// 17. Demo accounts
  Future<List<Map<String, dynamic>>> getDemoAccounts() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/demo-accounts');
      final response = await _client.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Demo accounts fetch error: $e');
    }
    return [];
  }
}
