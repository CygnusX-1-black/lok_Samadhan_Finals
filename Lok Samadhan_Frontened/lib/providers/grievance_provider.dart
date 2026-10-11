import 'dart:math';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../data/mock_grievances_data.dart';
import '../models/department.dart';
import '../models/grievance.dart';
import '../models/user_role.dart';
import '../services/api_service.dart';

class SmsNotification {
  final String id;
  final String grievanceId;
  final String phone;
  final String textMessage;
  final DateTime timestamp;
  bool isRead;

  SmsNotification({
    required this.id,
    required this.grievanceId,
    required this.phone,
    required this.textMessage,
    required this.timestamp,
    this.isRead = false,
  });
}

class GrievanceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  UserPersona _currentPersona = UserPersona.citizen;

  // Dynamic Grievances List initialized with regional mock data (or synced from backend)
  final List<Grievance> _grievances = MockGrievancesData.getInitialGrievances();
  final List<SmsNotification> _smsNotifications = [];

  // Backend Connectivity & Sync State
  bool _isBackendConnected = false;
  bool _isLoadingBackend = false;
  String? _backendError;
  String _databaseMode = 'in-memory';
  String? _aiProvider;
  DateTime? _lastSyncTime;

  String _searchQuery = '';
  DepartmentCategory? _filterDepartment;
  GrievanceStatus? _filterStatus;
  bool _filterOnlySlaBreached = false;

  GrievanceProvider() {
    initBackendConnection();
  }

  bool get isBackendConnected => _isBackendConnected;
  bool get isLoadingBackend => _isLoadingBackend;
  bool get isLoadingFromBackend => _isLoadingBackend;
  String? get backendError => _backendError;
  String get databaseMode => _databaseMode;
  String? get aiProvider => _aiProvider;
  DateTime? get lastSyncTime => _lastSyncTime;
  String get activeBackendUrl => ApiConfig.baseUrl;

  /// Check health and fetch remote grievances from backend
  Future<void> initBackendConnection() async {
    try {
      final health = await _apiService.checkHealth();
      if (health.isConnected) {
        _isBackendConnected = true;
        _databaseMode = health.databaseMode ?? 'supabase';
        _aiProvider = health.aiProvider;
        _backendError = null;
        notifyListeners();
        await syncGrievancesFromBackend();
      } else {
        _isBackendConnected = false;
        _backendError = health.error ?? 'Backend offline';
        notifyListeners();
      }
    } catch (e) {
      _isBackendConnected = false;
      _backendError = e.toString();
      notifyListeners();
    }
  }

  /// Sync all grievances from backend database (Supabase)
  Future<void> syncGrievancesFromBackend() async {
    _isLoadingBackend = true;
    notifyListeners();
    try {
      final remoteList = await _apiService.fetchGrievances();
      if (remoteList.isNotEmpty) {
        _grievances.clear();
        _grievances.addAll(remoteList);
        _lastSyncTime = DateTime.now();
        _isBackendConnected = true;
        _backendError = null;
        debugPrint('[GrievanceProvider] Connected to Supabase / Backend! Loaded ${_grievances.length} grievances.');
      }
    } catch (e) {
      debugPrint('[GrievanceProvider] Backend sync failed: $e');
      _backendError = e.toString();
    } finally {
      _isLoadingBackend = false;
      notifyListeners();
    }
  }

  /// Alias for backward compatibility
  Future<void> loadGrievancesFromBackend() => syncGrievancesFromBackend();

  Future<void> refreshAll() async {
    await initBackendConnection();
  }

  UserPersona get currentPersona => _currentPersona;
  List<Grievance> get grievances => _grievances;
  List<SmsNotification> get smsNotifications => _smsNotifications;

  String get searchQuery => _searchQuery;
  DepartmentCategory? get filterDepartment => _filterDepartment;
  GrievanceStatus? get filterStatus => _filterStatus;
  bool get filterOnlySlaBreached => _filterOnlySlaBreached;

  // Filtered grievances for dashboard / list views
  List<Grievance> get filteredGrievances {
    return _grievances.where((g) {
      if (_filterDepartment != null && g.departmentCategory != _filterDepartment) {
        return false;
      }
      if (_filterStatus != null && g.status != _filterStatus) {
        return false;
      }
      if (_filterOnlySlaBreached && !g.isSlaBreached) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchId = g.id.toLowerCase().contains(query);
        final matchName = g.citizenName.toLowerCase().contains(query);
        final matchPhone = g.citizenPhone.toLowerCase().contains(query);
        final matchLoc = g.villageWard.toLowerCase().contains(query);
        final matchText = g.rawSpeechText.toLowerCase().contains(query) || g.translatedText.toLowerCase().contains(query);
        if (!matchId && !matchName && !matchPhone && !matchLoc && !matchText) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // HITL Queue specific list
  List<Grievance> get hitlReviewQueue {
    return _grievances.where((g) => g.status == GrievanceStatus.hitlReview || g.isHitlFallback).toList();
  }

  // Statistics & KPI Metrics
  int get totalCount => _grievances.length;
  int get hitlCount => hitlReviewQueue.length;
  int get resolvedCount => _grievances.where((g) => g.status == GrievanceStatus.resolved).length;
  int get inProgressCount => _grievances.where((g) => g.status == GrievanceStatus.inProgress || g.status == GrievanceStatus.underReview).length;
  int get slaBreachedCount => _grievances.where((g) => g.isSlaBreached).length;

  double get resolutionPercentage => totalCount == 0 ? 0.0 : (resolvedCount / totalCount) * 100;
  double get autoRoutingAccuracy => 93.4;

  void switchPersona(UserPersona newPersona) {
    _currentPersona = newPersona;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterDepartment(DepartmentCategory? cat) {
    _filterDepartment = cat;
    notifyListeners();
  }

  void setFilterStatus(GrievanceStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  void toggleFilterSlaBreached() {
    _filterOnlySlaBreached = !_filterOnlySlaBreached;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterDepartment = null;
    _filterStatus = null;
    _filterOnlySlaBreached = false;
    notifyListeners();
  }

  // Lodge a new Voice Grievance
  Grievance lodgeNewVoiceGrievance({
    required dynamic aiResult,
    required String citizenName,
    required String citizenPhone,
    required String dialectName,
    double? latitude,
    double? longitude,
    double? gpsAccuracyM,
    DateTime? locationCapturedAt,
  }) {
    final randomId = 'LS-2026-${(10000 + Random().nextInt(89999))}';
    final now = DateTime.now();
    final deptInfo = DepartmentInfo.getByCategory(aiResult.category);
    final dueDate = now.add(Duration(hours: deptInfo.defaultSlaHours));

    final isHitl = aiResult.isHitlRequired || aiResult.confidenceScore < 0.85;
    final initialStatus = isHitl ? GrievanceStatus.hitlReview : GrievanceStatus.received;

    final hasGps = latitude != null && longitude != null && !(latitude == 0 && longitude == 0);
    final latDir = hasGps ? (latitude >= 0 ? 'N' : 'S') : '';
    final lonDir = hasGps ? (longitude >= 0 ? 'E' : 'W') : '';
    final gpsDesc = hasGps
        ? 'GPS: Lat ${latitude.abs().toStringAsFixed(4)}° $latDir, Long ${longitude.abs().toStringAsFixed(4)}° $lonDir${gpsAccuracyM != null ? " (Accuracy: ±${gpsAccuracyM.toStringAsFixed(0)}m)" : ""}'
        : 'GPS: Location not available';

    final newGrievance = Grievance(
      id: randomId,
      citizenPhone: citizenPhone,
      citizenName: citizenName.isEmpty ? 'Nagarik Citizen' : citizenName,
      spokenDialect: dialectName,
      rawSpeechText: aiResult.rawSpeechText,
      translatedText: aiResult.translatedEnglishText,
      departmentCategory: aiResult.category,
      villageWard: aiResult.villageWard,
      block: aiResult.block,
      district: aiResult.district,
      state: aiResult.state,
      latitude: latitude,
      longitude: longitude,
      gpsAccuracyM: gpsAccuracyM,
      locationCapturedAt: locationCapturedAt ?? now.toUtc(),
      urgency: aiResult.urgency,
      aiConfidenceScore: aiResult.confidenceScore,
      status: initialStatus,
      isHitlFallback: isHitl,
      hitlReviewerNotes: isHitl ? 'Low confidence score. Queued for human verification.' : null,
      createdAt: now,
      dueDate: dueDate,
      auditLog: [
        GrievanceAuditStep(
          timestamp: now,
          statusLabel: isHitl ? 'Voice Recorded -> HITL Queued' : 'Voice Recorded -> Auto-Routed',
          actor: 'Lok Samadhan NLP AI Engine',
          description: isHitl
              ? 'Speech registered. $gpsDesc. Queued for review.'
              : 'Speech registered. $gpsDesc. Dispatched to ${deptInfo.nameEn} queue.',
        ),
      ],
    );

    _grievances.insert(0, newGrievance);

    _sendSmsNotification(
      grievanceId: randomId,
      phone: citizenPhone,
      textMessage: isHitl
          ? 'Lok Samadhan: Aapki shikayat ID $randomId darj ho gayi hai. Hamare adhikari iski samiksha kar rahe hain.'
          : 'Lok Samadhan: Aapki shikayat ID $randomId ${deptInfo.nameHi} mein bhej di gayi hai. SLA samay: ${deptInfo.defaultSlaHours} ghante.',
    );

    notifyListeners();

    // Async sync to Backend Database (Supabase)
    _apiService.lodgeGrievance(
      id: randomId,
      userId: 'default_citizen',
      rawSpeechText: newGrievance.rawSpeechText,
      translatedText: newGrievance.translatedText,
      citizenName: newGrievance.citizenName,
      citizenPhone: newGrievance.citizenPhone,
      spokenDialect: newGrievance.spokenDialect,
      departmentCategory: newGrievance.departmentCategory,
      villageWard: newGrievance.villageWard,
      block: newGrievance.block,
      district: newGrievance.district,
      state: newGrievance.state,
      latitude: latitude,
      longitude: longitude,
      gpsAccuracyM: gpsAccuracyM,
      locationCapturedAt: locationCapturedAt ?? now.toUtc(),
      urgency: newGrievance.urgency,
      confidenceScore: newGrievance.aiConfidenceScore,
      isHitlFallback: isHitl,
      hitlReviewerNotes: newGrievance.hitlReviewerNotes,
    ).then((saved) {
        final idx = _grievances.indexWhere((g) => g.id == randomId);
        if (idx != -1) {
          _grievances[idx] = saved;
          notifyListeners();
        }
      }).catchError((err) {
        debugPrint('[GrievanceProvider] Backend sync error: $err');
      });

    return newGrievance;
  }

  // Lodge a new AI Photo Grievance
  Grievance lodgePhotoGrievance({
    required String problemTitle,
    required String detailedDescription,
    required DepartmentCategory category,
    required String villageWard,
    required String district,
    required String state,
    double? latitude,
    double? longitude,
    double? gpsAccuracyM,
    DateTime? locationCapturedAt,
    required String photoUrl,
    required String photoAnalysisSummary,
    required String citizenPhone,
    required String citizenName,
    String? imageVerificationStatus,
    String? imageCivicCategory,
    double? imageConfidenceScore,
    String? imageAuthenticityStatus,
    String? imageAuthenticityDetails,
    String? imageDetectorInfo,
    DateTime? imageVerifiedAt,
    double? exifGpsLatitude,
    double? exifGpsLongitude,
  }) {
    final randomId = 'LS-2026-${(10000 + Random().nextInt(89999))}';
    final now = DateTime.now();
    final deptInfo = DepartmentInfo.getByCategory(category);
    final dueDate = now.add(Duration(hours: deptInfo.defaultSlaHours));

    final hasGps = latitude != null && longitude != null && !(latitude == 0 && longitude == 0);
    final latDir = hasGps ? (latitude >= 0 ? 'N' : 'S') : '';
    final lonDir = hasGps ? (longitude >= 0 ? 'E' : 'W') : '';
    final gpsDesc = hasGps
        ? 'Device Submission GPS: Lat ${latitude.abs().toStringAsFixed(4)}° $latDir, Long ${longitude.abs().toStringAsFixed(4)}° $lonDir${gpsAccuracyM != null ? " (Accuracy: ±${gpsAccuracyM.toStringAsFixed(0)}m)" : ""}'
        : 'Photo captured without verified GPS';

    final isSuspiciousAuth = imageAuthenticityStatus == 'suspicious_manipulation' || imageVerificationStatus == 'flagged_manual_review';
    final initialStatus = isSuspiciousAuth ? GrievanceStatus.hitlReview : GrievanceStatus.received;

    final newGrievance = Grievance(
      id: randomId,
      citizenPhone: citizenPhone,
      citizenName: citizenName.isEmpty ? 'Nagarik Citizen' : citizenName,
      spokenDialect: 'AI Photo Multimodal Vision',
      rawSpeechText: '[Photo Grievance] $problemTitle',
      translatedText: detailedDescription,
      departmentCategory: category,
      villageWard: villageWard,
      block: district.isNotEmpty ? '$district Sadar' : 'Area Sadar',
      district: district,
      state: state,
      latitude: latitude,
      longitude: longitude,
      gpsAccuracyM: gpsAccuracyM,
      locationCapturedAt: locationCapturedAt ?? now.toUtc(),
      photoUrl: photoUrl,
      photoAnalysisSummary: photoAnalysisSummary,
      imageVerificationStatus: imageVerificationStatus ?? 'verified_civic_issue',
      imageCivicCategory: imageCivicCategory ?? category.name,
      imageConfidenceScore: imageConfidenceScore ?? 0.95,
      imageAuthenticityStatus: imageAuthenticityStatus ?? 'likely_authentic',
      imageAuthenticityDetails: imageAuthenticityDetails,
      imageDetectorInfo: imageDetectorInfo ?? 'Lok Samadhan AI Sentinel v2.0',
      imageVerifiedAt: imageVerifiedAt ?? now,
      exifGpsLatitude: exifGpsLatitude,
      exifGpsLongitude: exifGpsLongitude,
      urgency: UrgencyLevel.high,
      aiConfidenceScore: imageConfidenceScore ?? 0.97,
      status: initialStatus,
      isHitlFallback: isSuspiciousAuth,
      hitlReviewerNotes: isSuspiciousAuth ? 'Flagged for image verification review.' : null,
      createdAt: now,
      dueDate: dueDate,
      auditLog: [
        GrievanceAuditStep(
          timestamp: now,
          statusLabel: 'Photo Captured & AI Verified',
          actor: 'Lok Samadhan Multimodal Vision Engine',
          description: '$gpsDesc. Civic issue verified: $problemTitle. Authenticity: ${imageAuthenticityStatus ?? "Checked"}. Auto-routed to ${deptInfo.nameEn} Office.',
        ),
      ],
    );

    _grievances.insert(0, newGrievance);

    _sendSmsNotification(
      grievanceId: randomId,
      phone: citizenPhone,
      textMessage: 'Lok Samadhan Photo Lodge: Grievance $randomId regarding $problemTitle has been routed directly to ${deptInfo.nameHi} Office.',
    );

    notifyListeners();

    // Async sync to Backend Database (Supabase)
    _apiService.lodgeGrievance(
      id: randomId,
      userId: 'default_citizen',
      rawSpeechText: newGrievance.rawSpeechText,
      translatedText: newGrievance.translatedText,
      citizenName: newGrievance.citizenName,
      citizenPhone: newGrievance.citizenPhone,
      spokenDialect: newGrievance.spokenDialect,
      departmentCategory: newGrievance.departmentCategory,
      villageWard: newGrievance.villageWard,
      block: newGrievance.block,
      district: newGrievance.district,
      state: newGrievance.state,
      latitude: latitude,
      longitude: longitude,
      gpsAccuracyM: gpsAccuracyM,
      locationCapturedAt: locationCapturedAt ?? now.toUtc(),
      urgency: newGrievance.urgency,
      confidenceScore: newGrievance.aiConfidenceScore,
      photoUrl: photoUrl,
      photoAnalysisSummary: photoAnalysisSummary,
      imageVerificationStatus: newGrievance.imageVerificationStatus,
      imageCivicCategory: newGrievance.imageCivicCategory,
      imageConfidenceScore: newGrievance.imageConfidenceScore,
      imageAuthenticityStatus: newGrievance.imageAuthenticityStatus,
      imageAuthenticityDetails: newGrievance.imageAuthenticityDetails,
      imageDetectorInfo: newGrievance.imageDetectorInfo,
      imageVerifiedAt: newGrievance.imageVerifiedAt,
      exifGpsLatitude: newGrievance.exifGpsLatitude,
      exifGpsLongitude: newGrievance.exifGpsLongitude,
    ).then((saved) {
      final idx = _grievances.indexWhere((g) => g.id == randomId);
      if (idx != -1) {
        _grievances[idx] = saved;
        notifyListeners();
      }
    }).catchError((err) {
      debugPrint('[GrievanceProvider] Backend photo sync error: $err');
    });

    return newGrievance;
  }

  /// Officer action to flag image for manual review
  Future<void> flagImageForManualReview(String grievanceId, {String? note, String? verificationStatus}) async {
    final idx = _grievances.indexWhere((g) => g.id == grievanceId);
    if (idx != -1) {
      final existing = _grievances[idx];
      final updated = existing.copyWith(
        imageVerificationStatus: verificationStatus ?? 'flagged_manual_review',
        isHitlFallback: true,
        hitlReviewerNotes: note ?? 'Flagged for image verification review.',
        auditLog: [
          ...existing.auditLog,
          GrievanceAuditStep(
            timestamp: DateTime.now(),
            statusLabel: 'Image Verification Flagged',
            actor: 'Official Reviewer',
            description: note ?? 'Officer flagged image for on-site manual inspection.',
          ),
        ],
      );
      _grievances[idx] = updated;
      notifyListeners();

      try {
        await _apiService.flagImageForManualReview(grievanceId, note: note, verificationStatus: verificationStatus);
      } catch (e) {
        debugPrint('[GrievanceProvider] flagImageForManualReview remote sync note: $e');
      }
    }
  }

  // Lodge a new Interactive Chat Grievance
  Grievance lodgeChatGrievance({
    required String problemTitle,
    required String detailedDescription,
    required DepartmentCategory category,
    required String villageWard,
    required String block,
    required String district,
    required String state,
    double? latitude,
    double? longitude,
    double? gpsAccuracyM,
    DateTime? locationCapturedAt,
    required String citizenPhone,
    required String citizenName,
    UrgencyLevel urgency = UrgencyLevel.medium,
    double confidenceScore = 0.95,
    bool isHitlRequired = false,
  }) {
    final randomId = 'LS-2026-${(10000 + Random().nextInt(89999))}';
    final now = DateTime.now();
    final deptInfo = DepartmentInfo.getByCategory(category);
    final dueDate = now.add(Duration(hours: deptInfo.defaultSlaHours));
    final isHitl = isHitlRequired || confidenceScore < 0.85;
    final initialStatus = isHitl ? GrievanceStatus.hitlReview : GrievanceStatus.received;

    final hasGps = latitude != null && longitude != null && !(latitude == 0 && longitude == 0);
    final latDir = hasGps ? (latitude >= 0 ? 'N' : 'S') : '';
    final lonDir = hasGps ? (longitude >= 0 ? 'E' : 'W') : '';
    final gpsDesc = hasGps
        ? 'GPS: Lat ${latitude.abs().toStringAsFixed(4)}° $latDir, Long ${longitude.abs().toStringAsFixed(4)}° $lonDir${gpsAccuracyM != null ? " (Accuracy: ±${gpsAccuracyM.toStringAsFixed(0)}m)" : ""}'
        : 'GPS: Location not available';

    final newGrievance = Grievance(
      id: randomId,
      citizenPhone: citizenPhone.isEmpty ? '+91 98765 43210' : citizenPhone,
      citizenName: citizenName.isEmpty ? 'Nagarik Citizen' : citizenName,
      spokenDialect: 'AI Chatbot (शिकायत चैट)',
      rawSpeechText: '[Chat Assistant] $problemTitle',
      translatedText: detailedDescription,
      departmentCategory: category,
      villageWard: villageWard,
      block: block,
      district: district,
      state: state,
      latitude: latitude,
      longitude: longitude,
      gpsAccuracyM: gpsAccuracyM,
      locationCapturedAt: locationCapturedAt ?? now.toUtc(),
      urgency: urgency,
      aiConfidenceScore: confidenceScore,
      status: initialStatus,
      isHitlFallback: isHitl,
      hitlReviewerNotes: isHitl ? 'Flagged by AI Chat assistant for manual review.' : null,
      createdAt: now,
      dueDate: dueDate,
      auditLog: [
        GrievanceAuditStep(
          timestamp: now,
          statusLabel: isHitl ? 'Chat Grievance -> HITL Queued' : 'Chat Grievance Registered & Auto-Routed',
          actor: 'Lok Samadhan AI Chat Gateway',
          description: '$gpsDesc. Intent classified via Chatbot NLP router.',
        ),
        GrievanceAuditStep(
          timestamp: now,
          statusLabel: 'Dispatched to Department Queue',
          actor: 'Lok Samadhan NLP Router',
          description: 'Assigned to ${deptInfo.nameEn} queue. Standard SLA: ${deptInfo.defaultSlaHours} Hours.',
        ),
      ],
    );

    _grievances.insert(0, newGrievance);

    _sendSmsNotification(
      grievanceId: randomId,
      phone: newGrievance.citizenPhone,
      textMessage: isHitl
          ? 'Lok Samadhan Chat: Aapki shikayat ID $randomId darj ho gayi hai. Hamare adhikari iski samiksha kar rahe hain.'
          : 'Lok Samadhan Chat: Aapki shikayat ID $randomId ${deptInfo.nameHi} mein darj ho gayi hai. SLA: ${deptInfo.defaultSlaHours} ghante.',
    );

    notifyListeners();

    // Async sync to Backend Database (Supabase)
    _apiService.lodgeGrievance(
      id: randomId,
      userId: 'default_citizen',
      rawSpeechText: newGrievance.rawSpeechText,
      translatedText: newGrievance.translatedText,
      citizenName: newGrievance.citizenName,
      citizenPhone: newGrievance.citizenPhone,
      spokenDialect: newGrievance.spokenDialect,
      departmentCategory: newGrievance.departmentCategory,
      villageWard: newGrievance.villageWard,
      block: newGrievance.block,
      district: newGrievance.district,
      state: newGrievance.state,
      latitude: latitude,
      longitude: longitude,
      gpsAccuracyM: gpsAccuracyM,
      locationCapturedAt: locationCapturedAt ?? now.toUtc(),
      urgency: urgency,
      confidenceScore: confidenceScore,
      isHitlFallback: isHitl,
    ).then((saved) {
        final idx = _grievances.indexWhere((g) => g.id == randomId);
        if (idx != -1) {
          _grievances[idx] = saved;
          notifyListeners();
        }
      }).catchError((err) {
        debugPrint('[GrievanceProvider] Backend chat sync error: $err');
      });

    return newGrievance;
  }

  // Update Grievance Status from Official Dashboard
  void updateGrievanceStatus({
    required String grievanceId,
    required GrievanceStatus newStatus,
    String? officialNote,
  }) {
    final index = _grievances.indexWhere((g) => g.id == grievanceId);
    if (index != -1) {
      final g = _grievances[index];
      final now = DateTime.now();

      final updatedAudit = List<GrievanceAuditStep>.from(g.auditLog)
        ..add(GrievanceAuditStep(
          timestamp: now,
          statusLabel: 'Status Updated: ${newStatus.labelEn}',
          actor: 'Government Official / Nodal Officer',
          description: officialNote ?? 'Status changed to ${newStatus.labelEn}.',
        ));

      final updated = g.copyWith(
        status: newStatus,
        resolutionNote: newStatus == GrievanceStatus.resolved ? officialNote ?? 'Grievance resolved successfully.' : g.resolutionNote,
        resolutionTimestamp: newStatus == GrievanceStatus.resolved ? now : g.resolutionTimestamp,
        auditLog: updatedAudit,
      );

      _grievances[index] = updated;


      _sendSmsNotification(
        grievanceId: g.id,
        phone: g.citizenPhone,
        textMessage: 'Lok Samadhan Update: Grievance $grievanceId status is now [${newStatus.labelHi}]. ${officialNote ?? ""}',
      );

      notifyListeners();

      if (_isBackendConnected) {
        _apiService.updateGrievanceStatus(
          grievanceId: grievanceId,
          newStatus: newStatus,
          note: officialNote,
        ).then((_) {}).catchError((err) {
          debugPrint('[GrievanceProvider] Backend status update error: $err');
          return g;
        });
      }
    }
  }

  // Approve / Reclassify HITL Queue Grievance
  void resolveHitlQueueItem({
    required String grievanceId,
    required DepartmentCategory approvedCategory,
    required String officerComment,
  }) {
    final index = _grievances.indexWhere((g) => g.id == grievanceId);
    if (index != -1) {
      final g = _grievances[index];
      final now = DateTime.now();
      final deptInfo = DepartmentInfo.getByCategory(approvedCategory);

      final updatedAudit = List<GrievanceAuditStep>.from(g.auditLog)
        ..add(GrievanceAuditStep(
          timestamp: now,
          statusLabel: 'HITL Verified & Dispatched',
          actor: 'Human Review Officer (Call Center / Panchayat Agent)',
          description: 'Verified dialect audio. Department assigned: ${deptInfo.nameEn}. Notes: $officerComment',
        ));

      final updated = g.copyWith(
        departmentCategory: approvedCategory,
        status: GrievanceStatus.received,
        isHitlFallback: false,
        hitlReviewerNotes: officerComment,
        auditLog: updatedAudit,
      );

      _grievances[index] = updated;


      _sendSmsNotification(
        grievanceId: g.id,
        phone: g.citizenPhone,
        textMessage: 'Lok Samadhan Verification: Aapki shikayat ID ${g.id} samiksha ke baad ${deptInfo.nameHi} ko bhej di gayi hai.',
      );

      notifyListeners();

      if (_isBackendConnected) {
        _apiService.updateGrievanceStatus(
          grievanceId: grievanceId,
          newStatus: GrievanceStatus.received,
          note: officerComment,
          approvedCategory: approvedCategory,
        ).then((_) {}).catchError((err) {
          debugPrint('[GrievanceProvider] Backend HITL update error: $err');
          return g;
        });
      }
    }
  }

  Grievance? getGrievanceById(String id) {
    try {
      return _grievances.firstWhere(
        (g) => g.id.toLowerCase().trim() == id.toLowerCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }

  void _sendSmsNotification({
    required String grievanceId,
    required String phone,
    required String textMessage,
  }) {
    _smsNotifications.insert(
      0,
      SmsNotification(
        id: 'SMS-${Random().nextInt(99999)}',
        grievanceId: grievanceId,
        phone: phone,
        textMessage: textMessage,
        timestamp: DateTime.now(),
      ),
    );
  }

  void markSmsAsRead(String smsId) {
    final index = _smsNotifications.indexWhere((s) => s.id == smsId);
    if (index != -1) {
      _smsNotifications[index].isRead = true;
      notifyListeners();
    }
  }
}
