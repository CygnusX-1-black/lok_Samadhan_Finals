import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/department.dart';
import '../models/grievance.dart';
import '../models/reward_item.dart';
import '../models/reward_transaction.dart';
import '../models/reward_claim.dart';
import '../models/rewards_summary.dart';
import '../models/image_verification_result.dart';
import 'package:image_picker/image_picker.dart';

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

  /// 4. Lodge a new grievance with confirmed GC reward info
  Future<Map<String, dynamic>> lodgeGrievanceWithReward({
    String? id,
    String? userId,
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
    double? latitude,
    double? longitude,
    double? gpsAccuracyM,
    DateTime? locationCapturedAt,
    UrgencyLevel urgency = UrgencyLevel.medium,
    double? confidenceScore,
    bool isHitlFallback = false,
    String? hitlReviewerNotes,
    String? photoUrl,
    String? photoAnalysisSummary,
    String? imageVerificationStatus,
    String? imageCivicCategory,
    double? imageConfidenceScore,
    String? imageAuthenticityStatus,
    String? imageAuthenticityDetails,
    String? imageDetectorInfo,
    DateTime? imageVerifiedAt,
    double? exifGpsLatitude,
    double? exifGpsLongitude,
  }) async {
    try {
      final payload = {
        if (id != null) 'id': id,
        'userId': (userId != null && userId.isNotEmpty) ? userId : 'default_citizen',
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
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (gpsAccuracyM != null) 'gpsAccuracyM': gpsAccuracyM,
        if (locationCapturedAt != null) 'locationCapturedAt': locationCapturedAt.toIso8601String(),
        'urgency': urgency.name,
        if (confidenceScore != null) 'aiConfidenceScore': confidenceScore,
        'isHitlFallback': isHitlFallback,
        if (hitlReviewerNotes != null) 'hitlReviewerNotes': hitlReviewerNotes,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (photoAnalysisSummary != null) 'photoAnalysisSummary': photoAnalysisSummary,
        if (imageVerificationStatus != null) 'imageVerificationStatus': imageVerificationStatus,
        if (imageCivicCategory != null) 'imageCivicCategory': imageCivicCategory,
        if (imageConfidenceScore != null) 'imageConfidenceScore': imageConfidenceScore,
        if (imageAuthenticityStatus != null) 'imageAuthenticityStatus': imageAuthenticityStatus,
        if (imageAuthenticityDetails != null) 'imageAuthenticityDetails': imageAuthenticityDetails,
        if (imageDetectorInfo != null) 'imageDetectorInfo': imageDetectorInfo,
        if (imageVerifiedAt != null) 'imageVerifiedAt': imageVerifiedAt.toIso8601String(),
        if (exifGpsLatitude != null) 'exifGpsLatitude': exifGpsLatitude,
        if (exifGpsLongitude != null) 'exifGpsLongitude': exifGpsLongitude,
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
        final grievance = Grievance.fromJson(Map<String, dynamic>.from(body['data']));
        final rewardInfo = body['data']?['rewardInfo'];
        return {
          'success': true,
          'grievance': grievance,
          'rewardInfo': rewardInfo is Map ? Map<String, dynamic>.from(rewardInfo) : null,
        };
      } else {
        throw Exception('Failed to lodge grievance: HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] Error lodging grievance: $e');
      rethrow;
    }
  }

  /// Backward compatible alias returning Grievance object
  Future<Grievance> lodgeGrievance({
    String? id,
    String? userId,
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
    double? latitude,
    double? longitude,
    double? gpsAccuracyM,
    DateTime? locationCapturedAt,
    UrgencyLevel urgency = UrgencyLevel.medium,
    double? confidenceScore,
    bool isHitlFallback = false,
    String? hitlReviewerNotes,
    String? photoUrl,
    String? photoAnalysisSummary,
    String? imageVerificationStatus,
    String? imageCivicCategory,
    double? imageConfidenceScore,
    String? imageAuthenticityStatus,
    String? imageAuthenticityDetails,
    String? imageDetectorInfo,
    DateTime? imageVerifiedAt,
    double? exifGpsLatitude,
    double? exifGpsLongitude,
  }) async {
    final res = await lodgeGrievanceWithReward(
      id: id,
      userId: userId,
      rawSpeechText: rawSpeechText,
      translatedText: translatedText,
      citizenName: citizenName,
      citizenPhone: citizenPhone,
      spokenDialect: spokenDialect,
      departmentCategory: departmentCategory,
      villageWard: villageWard,
      block: block,
      district: district,
      state: state,
      latitude: latitude,
      longitude: longitude,
      gpsAccuracyM: gpsAccuracyM,
      locationCapturedAt: locationCapturedAt,
      urgency: urgency,
      confidenceScore: confidenceScore,
      isHitlFallback: isHitlFallback,
      hitlReviewerNotes: hitlReviewerNotes,
      photoUrl: photoUrl,
      photoAnalysisSummary: photoAnalysisSummary,
      imageVerificationStatus: imageVerificationStatus,
      imageCivicCategory: imageCivicCategory,
      imageConfidenceScore: imageConfidenceScore,
      imageAuthenticityStatus: imageAuthenticityStatus,
      imageAuthenticityDetails: imageAuthenticityDetails,
      imageDetectorInfo: imageDetectorInfo,
      imageVerifiedAt: imageVerifiedAt,
      exifGpsLatitude: exifGpsLatitude,
      exifGpsLongitude: exifGpsLongitude,
    );
    return res['grievance'] as Grievance;
  }

  /// 4b. Intelligent AI Image Verification (Civic Problem + AI Authenticity + EXIF GPS)
  Future<ImageVerificationResult> verifyImage(XFile file, {String? description}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/ai/verify-image');
      final bytes = await file.readAsBytes();
      final filename = file.name.isNotEmpty ? file.name : 'upload.jpg';
      final lowerName = filename.toLowerCase();

      String mime = 'image/jpeg';
      if (lowerName.endsWith('.png')) {
        mime = 'image/png';
      } else if (lowerName.endsWith('.webp')) {
        mime = 'image/webp';
      }

      // 1. Primary Strategy: Resilient JSON base64 payload (avoids browser multipart stream aborts)
      try {
        final base64String = base64Encode(bytes);
        final payload = {
          'imageBase64': base64String,
          'mimeType': mime,
          'filename': filename,
          if (description != null && description.isNotEmpty) 'description': description,
        };

        final response = await _client
            .post(uri, headers: _headers, body: jsonEncode(payload))
            .timeout(const Duration(seconds: 35));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          if (body['success'] == true && body['data'] != null) {
            return ImageVerificationResult.fromJson(Map<String, dynamic>.from(body['data']));
          }
        } else if (response.statusCode >= 400 && response.statusCode < 500) {
          final body = jsonDecode(response.body);
          return ImageVerificationResult.error(body['message']?.toString() ?? 'Verification returned code ${response.statusCode}');
        }
      } catch (jsonErr) {
        debugPrint('[ApiService] JSON verify-image attempt ($jsonErr), attempting multipart fallback...');
      }

      // 2. Secondary Strategy: Multipart request fallback
      final request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: filename,
      ));

      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return ImageVerificationResult.fromJson(Map<String, dynamic>.from(body['data']));
        }
      }

      try {
        final body = jsonDecode(response.body);
        return ImageVerificationResult.error(body['message']?.toString() ?? 'Verification returned code ${response.statusCode}');
      } catch (_) {
        return ImageVerificationResult.error('Image verification failed (HTTP ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('[ApiService] verifyImage error: $e');
      return ImageVerificationResult.error('Failed to communicate with image verification server: $e');
    }
  }

  /// 4c. Flag image for manual review (Official Action)
  Future<Grievance> flagImageForManualReview(
    String grievanceId, {
    String? note,
    String? verificationStatus,
    String? officerName,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/grievances/$grievanceId/flag-review');
      final payload = {
        'verificationStatus': verificationStatus ?? 'flagged_manual_review',
        if (note != null) 'note': note,
        if (officerName != null) 'officerName': officerName,
      };

      final response = await _client
          .patch(
            uri,
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return Grievance.fromJson(Map<String, dynamic>.from(body['data']));
      } else {
        throw Exception('Failed to flag image review: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ApiService] flagImageForManualReview error: $e');
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

  /// 13. Fetch Google OAuth URL (Backend with Direct Supabase Fallback)
  Future<String> getGoogleOAuthUrl({String? redirectTo}) async {
    final targetRedirect = redirectTo ?? (kIsWeb ? 'http://localhost:51241/' : 'http://localhost:8088');

    // 1. Attempt generation via Node.js backend if reachable
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/google-url').replace(
        queryParameters: {'redirectTo': targetRedirect},
      );
      final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final url = data['data']['url']?.toString();
          if (url != null && url.isNotEmpty) {
            return url;
          }
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Backend google-url not reachable ($e). Falling back to direct Supabase OAuth URL.');
    }

    // 2. Direct Supabase OAuth authorization URL (Guaranteed zero-failure fallback)
    final sbBase = ApiConfig.supabaseUrl;
    final encodedRedirect = Uri.encodeComponent(targetRedirect);
    return '$sbBase/auth/v1/authorize?provider=google&redirect_to=$encodedRedirect&prompt=select_account&access_type=offline';
  }

  /// 13b. Verify Google OAuth Access Token
  Future<Map<String, dynamic>> verifyGoogleAccessToken(String accessToken) async {
    // 1. Attempt verification via Node.js backend
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/google-verify');
      final response = await _client
          .post(uri, headers: _headers, body: jsonEncode({'accessToken': accessToken}))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Backend google-verify not reachable ($e). Verifying directly with Supabase.');
    }

    // 2. Direct Supabase Auth /user endpoint verification
    try {
      final sbUserUri = Uri.parse('${ApiConfig.supabaseUrl}/auth/v1/user');
      final res = await _client.get(
        sbUserUri,
        headers: {
          'Content-Type': 'application/json',
          'apikey': ApiConfig.supabaseAnonKey,
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(_timeout);

      if (res.statusCode == 200) {
        final u = jsonDecode(res.body);
        final meta = (u['user_metadata'] as Map<String, dynamic>?) ?? {};
        final email = u['email']?.toString() ?? '';
        final fullName = meta['full_name']?.toString() ??
            meta['name']?.toString() ??
            (email.isNotEmpty ? email.split('@')[0] : 'Citizen');
        final avatarUrl = meta['avatar_url']?.toString() ?? meta['picture']?.toString();

        return {
          'user': {
            'id': u['id']?.toString() ?? 'CIT-GOOG',
            'email': email,
            'name': fullName,
            'avatarUrl': avatarUrl,
            'role': 'citizen',
            'provider': 'google',
          },
          'token': accessToken,
          'message': 'Google authentication verified',
        };
      }
    } catch (sbErr) {
      debugPrint('[ApiService] Direct Supabase verification failed: $sbErr');
    }

    throw Exception('Google authentication verification failed. Please try again.');
  }

  /// 13c. Exchange OAuth Authorization Code (PKCE)
  Future<Map<String, dynamic>> exchangeAuthCode(String code) async {
    // 1. Attempt code exchange via Node.js backend
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/exchange-code');
      final response = await _client
          .post(uri, headers: _headers, body: jsonEncode({'code': code}))
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true && data['data'] != null) {
        return Map<String, dynamic>.from(data['data']);
      }
    } catch (e) {
      debugPrint('[ApiService] Backend exchange-code not reachable ($e). Attempting direct Supabase code exchange.');
    }

    // 2. Direct Supabase PKCE token exchange fallback
    try {
      final sbTokenUri = Uri.parse('${ApiConfig.supabaseUrl}/auth/v1/token?grant_type=authorization_code');
      final res = await _client.post(
        sbTokenUri,
        headers: {
          'Content-Type': 'application/json',
          'apikey': ApiConfig.supabaseAnonKey,
        },
        body: jsonEncode({'auth_code': code}),
      ).timeout(_timeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final user = data['user'] ?? {};
        final meta = (user['user_metadata'] as Map<String, dynamic>?) ?? {};
        final email = user['email']?.toString() ?? '';
        final fullName = meta['full_name']?.toString() ??
            meta['name']?.toString() ??
            (email.isNotEmpty ? email.split('@')[0] : 'Citizen');

        return {
          'user': {
            'id': user['id']?.toString() ?? 'CIT-GOOG',
            'email': email,
            'name': fullName,
            'avatarUrl': meta['avatar_url']?.toString() ?? meta['picture']?.toString(),
            'role': 'citizen',
            'provider': 'google',
          },
          'token': data['access_token'],
          'refreshToken': data['refresh_token'],
          'message': 'Google authentication code exchanged',
        };
      }
    } catch (sbErr) {
      debugPrint('[ApiService] Direct Supabase code exchange failed: $sbErr');
    }

    throw Exception('Failed to exchange authorization code. Please try again.');
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

  // =========================================================================
  // REWARDS & GRIEVANCE COIN (GC) API CLIENT
  // =========================================================================

  /// Fetch Reward Catalogue items
  Future<List<RewardItem>> fetchRewardCatalogue() async {
    try {
      final response = await _client.get(ApiConfig.rewardsCatalogueUri, headers: _headers).timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
          return (data['data'] as List).map((i) => RewardItem.fromJson(i)).toList();
        }
      }
    } catch (e) {
      debugPrint('[ApiService] fetchRewardCatalogue error: $e');
    }
    // Static fallback catalogue if offline
    return defaultFallbackCatalogue;
  }

  /// Default offline demo catalogue
  static const List<RewardItem> defaultFallbackCatalogue = [
    RewardItem(
      id: 'rew-flipkart-20',
      name: 'Flipkart Discount Voucher',
      description: 'Flat discount on your next shopping order across select electronics and fashion items.',
      cost: 20,
      category: 'shopping',
    ),
    RewardItem(
      id: 'rew-amazon-20',
      name: 'Amazon Discount Voucher',
      description: 'Instant balance benefit for pantry essentials, household goods, and utility bills.',
      cost: 20,
      category: 'shopping',
    ),
    RewardItem(
      id: 'rew-googleplay-50',
      name: 'Google Play Store Redeem Code',
      description: 'Digital credits for apps, books, movies, and developer tools on Google Play.',
      cost: 50,
      category: 'entertainment',
    ),
    RewardItem(
      id: 'rew-lenskart-30',
      name: 'Lenskart Voucher',
      description: 'Prescription eyeglasses and polarized sunglasses discount voucher.',
      cost: 30,
      category: 'health',
    ),
  ];

  /// Fetch User Rewards Summary & Balance
  Future<RewardsSummary?> fetchRewardsSummary(String userId) async {
    try {
      final response = await _client
          .get(ApiConfig.rewardsBalanceUri(userId), headers: _headers)
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          return RewardsSummary.fromJson(data['data']);
        }
      }
    } catch (e) {
      debugPrint('[ApiService] fetchRewardsSummary error: $e');
    }
    return null;
  }

  /// Award 1 Grievance Coin for an eligible complaint
  Future<Map<String, dynamic>> awardComplaintReward({
    required String userId,
    required String complaintId,
    String? description,
  }) async {
    try {
      final payload = jsonEncode({
        'userId': userId,
        'complaintId': complaintId,
        'description': description,
      });
      final response = await _client
          .post(ApiConfig.rewardsAwardUri, headers: _headers, body: payload)
          .timeout(const Duration(seconds: 3));
      if (response.body.trim().isEmpty) {
        return {'success': false, 'error': 'Empty response from server (HTTP ${response.statusCode})'};
      }
      final data = jsonDecode(response.body);
      return data is Map<String, dynamic> ? data : {'success': false, 'message': 'Invalid response'};
    } catch (e) {
      debugPrint('[ApiService] awardComplaintReward error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Redeem demo reward with strict balance validation
  Future<Map<String, dynamic>> redeemReward({
    required String userId,
    required String rewardId,
  }) async {
    try {
      final payload = jsonEncode({
        'userId': userId,
        'rewardId': rewardId,
      });
      final response = await _client
          .post(ApiConfig.rewardsRedeemUri, headers: _headers, body: payload)
          .timeout(const Duration(seconds: 3));
      if (response.body.trim().isEmpty) {
        return {'success': false, 'error': 'Empty response from server (HTTP ${response.statusCode})'};
      }
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data is Map<String, dynamic> ? data : {'success': true};
      } else {
        // Return 400 error details (including INSUFFICIENT_COINS)
        return data is Map<String, dynamic> ? data : {'success': false, 'message': 'Redemption failed'};
      }
    } catch (e) {
      debugPrint('[ApiService] redeemReward error: $e');
      return {'success': false, 'error': e.toString(), 'message': 'Network error while redeeming reward: $e'};
    }
  }

  /// Fetch GC Transactions
  Future<List<RewardTransaction>?> fetchRewardTransactions(String userId) async {
    try {
      final response = await _client.get(ApiConfig.rewardsTransactionsUri(userId), headers: _headers).timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
          return (data['data'] as List).map((i) => RewardTransaction.fromJson(i)).toList();
        }
      }
    } catch (e) {
      debugPrint('[ApiService] fetchRewardTransactions error: $e');
    }
    return null;
  }

  /// Fetch Claimed Demo Rewards
  Future<List<RewardClaim>?> fetchClaimedRewards(String userId) async {
    try {
      final response = await _client.get(ApiConfig.rewardsClaimsUri(userId), headers: _headers).timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
          return (data['data'] as List).map((i) => RewardClaim.fromJson(i)).toList();
        }
      }
    } catch (e) {
      debugPrint('[ApiService] fetchClaimedRewards error: $e');
    }
    return null;
  }
}
