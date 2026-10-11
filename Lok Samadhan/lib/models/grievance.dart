import 'department.dart';

enum GrievanceStatus {
  hitlReview,   // Low confidence AI classification, waiting for human review
  received,     // Successfully routed & received by department
  underReview,  // Assigned to field officer / under investigation
  inProgress,   // Repair / action work actively ongoing
  resolved,     // Grievance resolved and closed
  escalated,    // Overdue past SLA -> auto-escalated to higher authority
}

extension GrievanceStatusExtension on GrievanceStatus {
  String get labelEn {
    switch (this) {
      case GrievanceStatus.hitlReview:
        return 'HITL Review Pending';
      case GrievanceStatus.received:
        return 'Received';
      case GrievanceStatus.underReview:
        return 'Under Investigation';
      case GrievanceStatus.inProgress:
        return 'In Progress';
      case GrievanceStatus.resolved:
        return 'Resolved';
      case GrievanceStatus.escalated:
        return 'SLA Breached & Escalated';
    }
  }

  String get labelHi {
    switch (this) {
      case GrievanceStatus.hitlReview:
        return 'मानव समीक्षा लंबित';
      case GrievanceStatus.received:
        return 'प्राप्त हुई';
      case GrievanceStatus.underReview:
        return 'जांच जारी';
      case GrievanceStatus.inProgress:
        return 'कार्य प्रगति पर';
      case GrievanceStatus.resolved:
        return 'निस्तारित / हल';
      case GrievanceStatus.escalated:
        return 'समय-सीमा उल्लंघन (उच्च अधिकारी को प्रेषित)';
    }
  }

  String get labelGu {
    switch (this) {
      case GrievanceStatus.hitlReview:
        return 'માનવ સમીક્ષા બાકી';
      case GrievanceStatus.received:
        return 'મળેલ છે';
      case GrievanceStatus.underReview:
        return 'તપાસ ચાલુ છે';
      case GrievanceStatus.inProgress:
        return 'કામગીરી પ્રગતિમાં છે';
      case GrievanceStatus.resolved:
        return 'નિકાલ થયેલ / પૂર્ણ';
      case GrievanceStatus.escalated:
        return 'સમય-મર્યાદા ઉલ્લંઘન (ઉચ્ચ અધિકારીને મોકલેલ)';
    }
  }
}

enum UrgencyLevel { low, medium, high }

extension UrgencyLevelExtension on UrgencyLevel {
  String get labelEn {
    switch (this) {
      case UrgencyLevel.high:
        return 'HIGH URGENCY';
      case UrgencyLevel.medium:
        return 'MEDIUM URGENCY';
      case UrgencyLevel.low:
        return 'LOW URGENCY';
    }
  }

  String get labelHi {
    switch (this) {
      case UrgencyLevel.high:
        return 'उच्च प्राथमिकता';
      case UrgencyLevel.medium:
        return 'मध्यम प्राथमिकता';
      case UrgencyLevel.low:
        return 'सामान्य प्राथमिकता';
    }
  }

  String get labelGu {
    switch (this) {
      case UrgencyLevel.high:
        return 'ઉચ્ચ પ્રાથમિકતા';
      case UrgencyLevel.medium:
        return 'મધ્યમ પ્રાથમિકતા';
      case UrgencyLevel.low:
        return 'સામાન્ય પ્રાથમિકતા';
    }
  }
}

class GrievanceAuditStep {
  final DateTime timestamp;
  final String statusLabel;
  final String actor;
  final String description;

  const GrievanceAuditStep({
    required this.timestamp,
    required this.statusLabel,
    required this.actor,
    required this.description,
  });

  factory GrievanceAuditStep.fromJson(Map<String, dynamic> json) {
    return GrievanceAuditStep(
      timestamp: json['timestamp'] != null
          ? (DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now())
          : DateTime.now(),
      statusLabel: json['statusLabel']?.toString() ?? json['status_label']?.toString() ?? 'Status Update',
      actor: json['actor']?.toString() ?? 'System',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'statusLabel': statusLabel,
    'actor': actor,
    'description': description,
  };
}

DepartmentCategory parseDepartmentCategory(String? value) {
  if (value == null) return DepartmentCategory.generalPanchayat;
  for (final cat in DepartmentCategory.values) {
    if (cat.name.toLowerCase() == value.toLowerCase()) {
      return cat;
    }
  }
  return DepartmentCategory.generalPanchayat;
}

UrgencyLevel parseUrgencyLevel(String? value) {
  if (value == null) return UrgencyLevel.medium;
  for (final u in UrgencyLevel.values) {
    if (u.name.toLowerCase() == value.toLowerCase()) {
      return u;
    }
  }
  return UrgencyLevel.medium;
}

GrievanceStatus parseGrievanceStatus(String? value) {
  if (value == null) return GrievanceStatus.received;
  for (final s in GrievanceStatus.values) {
    if (s.name.toLowerCase() == value.toLowerCase()) {
      return s;
    }
  }
  return GrievanceStatus.received;
}

class Grievance {
  final String id;
  final String citizenPhone;
  final String citizenName;
  final String spokenDialect;
  final String rawSpeechText;
  final String translatedText;
  final DepartmentCategory departmentCategory;
  final String villageWard;
  final String block;
  final String district;
  final String state;
  final double? latitude;
  final double? longitude;
  final double? gpsAccuracyM;
  final DateTime? locationCapturedAt;
  final String? photoUrl;
  final String? photoAnalysisSummary;
  final String? imageVerificationStatus;
  final String? imageCivicCategory;
  final double? imageConfidenceScore;
  final String? imageAuthenticityStatus;
  final String? imageAuthenticityDetails;
  final String? imageDetectorInfo;
  final DateTime? imageVerifiedAt;
  final double? exifGpsLatitude;
  final double? exifGpsLongitude;
  final UrgencyLevel urgency;
  final double aiConfidenceScore;
  GrievanceStatus status;
  bool isHitlFallback;
  String? hitlReviewerNotes;
  final DateTime createdAt;
  final DateTime dueDate;
  String? resolutionNote;
  DateTime? resolutionTimestamp;
  int escalationLevel;
  final List<GrievanceAuditStep> auditLog;

  Grievance({
    required this.id,
    required this.citizenPhone,
    required this.citizenName,
    required this.spokenDialect,
    required this.rawSpeechText,
    required this.translatedText,
    required this.departmentCategory,
    required this.villageWard,
    required this.block,
    required this.district,
    required this.state,
    this.latitude,
    this.longitude,
    this.gpsAccuracyM,
    this.locationCapturedAt,
    this.photoUrl,
    this.photoAnalysisSummary,
    this.imageVerificationStatus,
    this.imageCivicCategory,
    this.imageConfidenceScore,
    this.imageAuthenticityStatus,
    this.imageAuthenticityDetails,
    this.imageDetectorInfo,
    this.imageVerifiedAt,
    this.exifGpsLatitude,
    this.exifGpsLongitude,
    required this.urgency,
    required this.aiConfidenceScore,
    required this.status,
    this.isHitlFallback = false,
    this.hitlReviewerNotes,
    required this.createdAt,
    required this.dueDate,
    this.resolutionNote,
    this.resolutionTimestamp,
    this.escalationLevel = 0,
    required this.auditLog,
  });

  factory Grievance.fromJson(Map<String, dynamic> json) {
    final catStr = json['departmentCategory']?.toString() ?? json['department_category']?.toString() ?? 'generalPanchayat';
    final category = DepartmentCategory.values.firstWhere(
      (e) => e.name == catStr,
      orElse: () => DepartmentCategory.generalPanchayat,
    );

    final urgStr = json['urgency']?.toString() ?? 'medium';
    final urgency = UrgencyLevel.values.firstWhere(
      (e) => e.name == urgStr,
      orElse: () => UrgencyLevel.medium,
    );

    final statStr = json['status']?.toString() ?? 'received';
    final status = GrievanceStatus.values.firstWhere(
      (e) => e.name == statStr,
      orElse: () => GrievanceStatus.received,
    );

    final rawLogs = json['auditLog'] ?? json['grievance_audit_logs'] ?? [];
    final List<GrievanceAuditStep> auditLog = (rawLogs is List)
        ? rawLogs.map((e) => GrievanceAuditStep.fromJson(Map<String, dynamic>.from(e))).toList()
        : [];

    return Grievance(
      id: json['id']?.toString() ?? '',
      citizenPhone: json['citizenPhone']?.toString() ?? json['citizen_phone']?.toString() ?? '',
      citizenName: json['citizenName']?.toString() ?? json['citizen_name']?.toString() ?? '',
      spokenDialect: json['spokenDialect']?.toString() ?? json['spoken_dialect']?.toString() ?? 'Hindi',
      rawSpeechText: json['rawSpeechText']?.toString() ?? json['raw_speech_text']?.toString() ?? '',
      translatedText: json['translatedText']?.toString() ?? json['translated_text']?.toString() ?? '',
      departmentCategory: category,
      villageWard: json['villageWard']?.toString() ?? json['village_ward']?.toString() ?? '',
      block: json['block']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? (json['lat'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble() ?? (json['lon'] as num?)?.toDouble() ?? (json['lng'] as num?)?.toDouble(),
      gpsAccuracyM: (json['gpsAccuracyM'] as num?)?.toDouble() ?? (json['gps_accuracy_m'] as num?)?.toDouble(),
      locationCapturedAt: json['locationCapturedAt'] != null || json['location_captured_at'] != null
          ? DateTime.tryParse(json['locationCapturedAt']?.toString() ?? json['location_captured_at']?.toString() ?? '')
          : null,
      photoUrl: json['photoUrl']?.toString() ?? json['photo_url']?.toString(),
      photoAnalysisSummary: json['photoAnalysisSummary']?.toString() ?? json['photo_analysis_summary']?.toString(),
      imageVerificationStatus: json['imageVerificationStatus']?.toString() ?? json['image_verification_status']?.toString(),
      imageCivicCategory: json['imageCivicCategory']?.toString() ?? json['image_civic_category']?.toString(),
      imageConfidenceScore: (json['imageConfidenceScore'] as num?)?.toDouble() ?? (json['image_confidence_score'] as num?)?.toDouble(),
      imageAuthenticityStatus: json['imageAuthenticityStatus']?.toString() ?? json['image_authenticity_status']?.toString(),
      imageAuthenticityDetails: json['imageAuthenticityDetails']?.toString() ?? json['image_authenticity_details']?.toString(),
      imageDetectorInfo: json['imageDetectorInfo']?.toString() ?? json['image_detector_info']?.toString(),
      imageVerifiedAt: json['imageVerifiedAt'] != null || json['image_verified_at'] != null
          ? DateTime.tryParse(json['imageVerifiedAt']?.toString() ?? json['image_verified_at']?.toString() ?? '')
          : null,
      exifGpsLatitude: (json['exifGpsLatitude'] as num?)?.toDouble() ?? (json['exif_gps_latitude'] as num?)?.toDouble(),
      exifGpsLongitude: (json['exifGpsLongitude'] as num?)?.toDouble() ?? (json['exif_gps_longitude'] as num?)?.toDouble(),
      urgency: urgency,
      aiConfidenceScore: (json['aiConfidenceScore'] as num?)?.toDouble() ?? 0.90,
      status: status,
      isHitlFallback: json['isHitlFallback'] == true || json['is_hitl_fallback'] == true,
      hitlReviewerNotes: json['hitlReviewerNotes']?.toString() ?? json['hitl_reviewer_notes']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.now(),
      dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? json['due_date']?.toString() ?? '') ?? DateTime.now().add(const Duration(hours: 48)),
      resolutionNote: json['resolutionNote']?.toString() ?? json['resolution_note']?.toString(),
      resolutionTimestamp: json['resolutionTimestamp'] != null ? DateTime.tryParse(json['resolutionTimestamp'].toString()) : null,
      escalationLevel: (json['escalationLevel'] as num?)?.toInt() ?? 0,
      auditLog: auditLog,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'citizenPhone': citizenPhone,
    'citizenName': citizenName,
    'spokenDialect': spokenDialect,
    'rawSpeechText': rawSpeechText,
    'translatedText': translatedText,
    'departmentCategory': departmentCategory.name,
    'villageWard': villageWard,
    'block': block,
    'district': district,
    'state': state,
    'latitude': latitude,
    'longitude': longitude,
    'gpsAccuracyM': gpsAccuracyM,
    'locationCapturedAt': locationCapturedAt?.toIso8601String(),
    'photoUrl': photoUrl,
    'photoAnalysisSummary': photoAnalysisSummary,
    'imageVerificationStatus': imageVerificationStatus,
    'imageCivicCategory': imageCivicCategory,
    'imageConfidenceScore': imageConfidenceScore,
    'imageAuthenticityStatus': imageAuthenticityStatus,
    'imageAuthenticityDetails': imageAuthenticityDetails,
    'imageDetectorInfo': imageDetectorInfo,
    'imageVerifiedAt': imageVerifiedAt?.toIso8601String(),
    'exifGpsLatitude': exifGpsLatitude,
    'exifGpsLongitude': exifGpsLongitude,
    'urgency': urgency.name,
    'aiConfidenceScore': aiConfidenceScore,
    'status': status.name,
    'isHitlFallback': isHitlFallback,
    'hitlReviewerNotes': hitlReviewerNotes,
    'createdAt': createdAt.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'resolutionNote': resolutionNote,
    'resolutionTimestamp': resolutionTimestamp?.toIso8601String(),
    'escalationLevel': escalationLevel,
    'auditLog': auditLog.map((e) => e.toJson()).toList(),
  };

  bool get hasValidGps =>
      latitude != null &&
      longitude != null &&
      !(latitude == 0.0 && longitude == 0.0);

  String get formattedGps {
    if (!hasValidGps) return 'Location not available';
    final lat = latitude!;
    final lon = longitude!;
    final latDir = lat >= 0 ? 'N' : 'S';
    final lonDir = lon >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(4)}° $latDir, ${lon.abs().toStringAsFixed(4)}° $lonDir';
  }

  String get formattedAccuracy {
    if (gpsAccuracyM != null && gpsAccuracyM! > 0) {
      return '±${gpsAccuracyM!.toStringAsFixed(0)} meters';
    }
    return '';
  }

  bool get isSlaBreached {
    if (status == GrievanceStatus.resolved) return false;
    return DateTime.now().isAfter(dueDate);
  }

  Duration get remainingSlaDuration {
    if (status == GrievanceStatus.resolved) return Duration.zero;
    final diff = dueDate.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  DepartmentInfo get departmentInfo => DepartmentInfo.getByCategory(departmentCategory);

  Grievance copyWith({
    GrievanceStatus? status,
    DepartmentCategory? departmentCategory,
    bool? isHitlFallback,
    String? hitlReviewerNotes,
    String? resolutionNote,
    DateTime? resolutionTimestamp,
    int? escalationLevel,
    List<GrievanceAuditStep>? auditLog,
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
    double? latitude,
    double? longitude,
    double? gpsAccuracyM,
    DateTime? locationCapturedAt,
  }) {
    return Grievance(
      id: id,
      citizenPhone: citizenPhone,
      citizenName: citizenName,
      spokenDialect: spokenDialect,
      rawSpeechText: rawSpeechText,
      translatedText: translatedText,
      departmentCategory: departmentCategory ?? this.departmentCategory,
      villageWard: villageWard,
      block: block,
      district: district,
      state: state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gpsAccuracyM: gpsAccuracyM ?? this.gpsAccuracyM,
      locationCapturedAt: locationCapturedAt ?? this.locationCapturedAt,
      photoUrl: photoUrl ?? this.photoUrl,
      photoAnalysisSummary: photoAnalysisSummary ?? this.photoAnalysisSummary,
      imageVerificationStatus: imageVerificationStatus ?? this.imageVerificationStatus,
      imageCivicCategory: imageCivicCategory ?? this.imageCivicCategory,
      imageConfidenceScore: imageConfidenceScore ?? this.imageConfidenceScore,
      imageAuthenticityStatus: imageAuthenticityStatus ?? this.imageAuthenticityStatus,
      imageAuthenticityDetails: imageAuthenticityDetails ?? this.imageAuthenticityDetails,
      imageDetectorInfo: imageDetectorInfo ?? this.imageDetectorInfo,
      imageVerifiedAt: imageVerifiedAt ?? this.imageVerifiedAt,
      exifGpsLatitude: exifGpsLatitude ?? this.exifGpsLatitude,
      exifGpsLongitude: exifGpsLongitude ?? this.exifGpsLongitude,
      urgency: urgency,
      aiConfidenceScore: aiConfidenceScore,
      status: status ?? this.status,
      isHitlFallback: isHitlFallback ?? this.isHitlFallback,
      hitlReviewerNotes: hitlReviewerNotes ?? this.hitlReviewerNotes,
      createdAt: createdAt,
      dueDate: dueDate,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      resolutionTimestamp: resolutionTimestamp ?? this.resolutionTimestamp,
      escalationLevel: escalationLevel ?? this.escalationLevel,
      auditLog: auditLog ?? this.auditLog,
    );
  }
}
