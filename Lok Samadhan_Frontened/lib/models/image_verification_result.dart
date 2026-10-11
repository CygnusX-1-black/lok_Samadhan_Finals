import 'department.dart';

enum CivicDetectionState {
  civicProblemDetected,
  noCivicProblemDetected,
  unableToVerify,
  serviceUnavailable,
}

enum AuthenticityState {
  likelyAuthentic,
  suspicious,
  inconclusive,
  unavailable,
}

class ImageVerificationResult {
  final bool success;
  final bool isCivicIssue;
  final String civicCategory;
  final DepartmentCategory categoryKey;
  final String issueTitle;
  final String description;
  final double? confidenceScore;
  final String? severity;
  final String? uncertaintyOrLimitations;
  final bool isUncertain;
  final String? rejectionReason;

  // Authenticity Analysis
  final AuthenticityState authenticityState;
  final String authenticityStatus;
  final String authenticityStateLabel;
  final String authenticityStatement;
  final double? authenticityConfidence;
  final List<String> signalsChecked;
  final List<String> detectedSignals;
  final String detectorInfo;

  // EXIF Metadata
  final bool hasExifGps;
  final double? exifLatitude;
  final double? exifLongitude;
  final String? exifTimestamp;
  final String? cameraMake;
  final String? cameraModel;

  // Overall workflow summary
  final String overallStatus;
  final bool canProceedToSubmit;
  final bool requiresManualReview;
  final bool isServiceConfigured;
  final String? errorMessage;

  const ImageVerificationResult({
    required this.success,
    required this.isCivicIssue,
    required this.civicCategory,
    required this.categoryKey,
    required this.issueTitle,
    required this.description,
    this.confidenceScore,
    this.severity,
    this.uncertaintyOrLimitations,
    required this.isUncertain,
    this.rejectionReason,
    required this.authenticityState,
    required this.authenticityStatus,
    required this.authenticityStateLabel,
    required this.authenticityStatement,
    this.authenticityConfidence,
    this.signalsChecked = const [],
    this.detectedSignals = const [],
    required this.detectorInfo,
    this.hasExifGps = false,
    this.exifLatitude,
    this.exifLongitude,
    this.exifTimestamp,
    this.cameraMake,
    this.cameraModel,
    required this.overallStatus,
    required this.canProceedToSubmit,
    required this.requiresManualReview,
    this.isServiceConfigured = true,
    this.errorMessage,
  });

  CivicDetectionState get civicDetectionState {
    if (!isServiceConfigured) return CivicDetectionState.serviceUnavailable;
    if (isUncertain) return CivicDetectionState.unableToVerify;
    if (isCivicIssue) return CivicDetectionState.civicProblemDetected;
    return CivicDetectionState.noCivicProblemDetected;
  }

  factory ImageVerificationResult.fromJson(Map<String, dynamic> data) {
    final civic = data['civicDetection'] is Map ? Map<String, dynamic>.from(data['civicDetection']) : {};
    final auth = data['authenticityAnalysis'] is Map ? Map<String, dynamic>.from(data['authenticityAnalysis']) : {};
    final exif = data['exifMetadata'] is Map ? Map<String, dynamic>.from(data['exifMetadata']) : {};
    final summary = data['verificationSummary'] is Map ? Map<String, dynamic>.from(data['verificationSummary']) : {};

    final isCivic = civic['isCivicIssue'] == true;
    final catStr = civic['category']?.toString() ?? 'none';
    final parsedCat = DepartmentCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == catStr.toLowerCase(),
      orElse: () => DepartmentCategory.generalPanchayat,
    );

    final authStatusStr = auth['status']?.toString() ?? 'UNAVAILABLE';
    AuthenticityState parsedAuthState;
    switch (authStatusStr) {
      case 'LIKELY_AUTHENTIC':
        parsedAuthState = AuthenticityState.likelyAuthentic;
        break;
      case 'SUSPICIOUS':
        parsedAuthState = AuthenticityState.suspicious;
        break;
      case 'INCONCLUSIVE':
        parsedAuthState = AuthenticityState.inconclusive;
        break;
      default:
        parsedAuthState = AuthenticityState.unavailable;
    }

    final rawSignals = auth['signalsChecked'] is List ? List<String>.from(auth['signalsChecked']) : <String>[];
    final detectedSignals = auth['detectedSignals'] is List ? List<String>.from(auth['detectedSignals']) : <String>[];

    final isServConfig = civic['serviceConfigured'] != false;

    return ImageVerificationResult(
      success: data['success'] != false,
      isCivicIssue: isCivic,
      civicCategory: catStr,
      categoryKey: parsedCat,
      issueTitle: civic['issueTitle']?.toString() ?? (isCivic ? 'Civic Problem Detected' : 'No Civic Issue'),
      description: civic['description']?.toString() ?? '',
      confidenceScore: (civic['confidenceScore'] as num?)?.toDouble(),
      severity: civic['severity']?.toString() ?? 'medium',
      uncertaintyOrLimitations: civic['uncertaintyOrLimitations']?.toString(),
      isUncertain: civic['isUncertain'] == true,
      rejectionReason: civic['rejectionReason']?.toString(),
      authenticityState: parsedAuthState,
      authenticityStatus: authStatusStr,
      authenticityStateLabel: auth['stateLabel']?.toString() ?? 'Authenticity Check Unavailable',
      authenticityStatement: auth['statement']?.toString() ?? 'No authenticity statement provided.',
      authenticityConfidence: (auth['confidenceScore'] as num?)?.toDouble(),
      signalsChecked: rawSignals,
      detectedSignals: detectedSignals,
      detectorInfo: auth['detectorInfo']?.toString() ?? 'Forensic Metadata Scanner',
      hasExifGps: exif['hasExifGps'] == true,
      exifLatitude: (exif['latitude'] as num?)?.toDouble(),
      exifLongitude: (exif['longitude'] as num?)?.toDouble(),
      exifTimestamp: exif['timestamp']?.toString(),
      cameraMake: exif['cameraMake']?.toString(),
      cameraModel: exif['cameraModel']?.toString(),
      overallStatus: summary['status']?.toString() ?? 'UNKNOWN',
      canProceedToSubmit: summary['canProceedToSubmit'] == true,
      requiresManualReview: summary['requiresManualReview'] == true,
      isServiceConfigured: isServConfig,
      errorMessage: data['validationError']?.toString() ?? (isServConfig ? null : civic['description']?.toString()),
    );
  }

  factory ImageVerificationResult.error(String message) {
    return ImageVerificationResult(
      success: false,
      isCivicIssue: false,
      civicCategory: 'none',
      categoryKey: DepartmentCategory.generalPanchayat,
      issueTitle: 'Verification Service Error',
      description: message,
      confidenceScore: null,
      isUncertain: true,
      rejectionReason: message,
      authenticityState: AuthenticityState.unavailable,
      authenticityStatus: 'UNAVAILABLE',
      authenticityStateLabel: 'Authenticity Check Unavailable',
      authenticityStatement: 'Unable to communicate with verification backend: $message',
      detectorInfo: 'Local Diagnostic Client',
      overallStatus: 'ERROR',
      canProceedToSubmit: false,
      requiresManualReview: false,
      isServiceConfigured: false,
      errorMessage: message,
    );
  }
}
