import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/department.dart';
import '../../models/image_verification_result.dart';
import '../../providers/grievance_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/rewards/gc_reward_dialog.dart';

class AiPhotoLodgeScreen extends StatefulWidget {
  const AiPhotoLodgeScreen({super.key});

  @override
  State<AiPhotoLodgeScreen> createState() => _AiPhotoLodgeScreenState();
}

class _AiPhotoLodgeScreenState extends State<AiPhotoLodgeScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  XFile? _capturedFile;
  DateTime? _captureTimestamp;
  String _imageSourceType = 'camera';

  bool _isAnalyzing = false;
  ImageVerificationResult? _verificationResult;
  DepartmentCategory? _selectedCategory;
  bool _isSubmitting = false;
  bool _allowManualReviewSubmission = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 1. Image Capture / Upload Logic with Format & Size Validation
  // ---------------------------------------------------------------------------
  Future<void> _pickImage(ImageSource source) async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    // Refresh live phone location right when camera or upload is triggered
    if (locationProvider.isGpsEnabled) {
      locationProvider.fetchRealLocation();
    }

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (file == null) return;

      // Validate file size and format
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        if (mounted) {
          _showErrorSnackBar('Selected file is empty or corrupted. Please pick another image.');
        }
        return;
      }

      // 10 MB maximum limit
      if (bytes.length > 10 * 1024 * 1024) {
        if (mounted) {
          _showErrorSnackBar('Image size exceeds 10 MB (${(bytes.length / (1024 * 1024)).toStringAsFixed(1)} MB). Please pick a smaller image.');
        }
        return;
      }

      final ext = file.name.split('.').last.toLowerCase();
      const validExtensions = ['jpg', 'jpeg', 'png', 'webp'];
      if (!validExtensions.contains(ext) && !file.mimeType.toString().contains('image')) {
        if (mounted) {
          _showErrorSnackBar('Unsupported image format ($ext). Please upload a JPEG, PNG, or WebP photo.');
        }
        return;
      }

      setState(() {
        _capturedFile = file;
        _captureTimestamp = DateTime.now();
        _imageSourceType = source == ImageSource.camera ? 'camera' : 'gallery';
        _verificationResult = null;
        _selectedCategory = null;
        _allowManualReviewSubmission = false;
        _titleController.clear();
        _descriptionController.clear();
      });

      // Automatically trigger image analysis
      _runImageVerification();
    } catch (e) {
      debugPrint('[AiPhotoLodgeScreen] Image pick error: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to access camera or files: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.warningRed,
        content: Text(
          message,
          style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _clearImage() {
    setState(() {
      _capturedFile = null;
      _verificationResult = null;
      _selectedCategory = null;
      _allowManualReviewSubmission = false;
      _titleController.clear();
      _descriptionController.clear();
    });
  }

  // ---------------------------------------------------------------------------
  // 2. AI Image Verification Workflow (Backend Vision + Authenticity Check)
  // ---------------------------------------------------------------------------
  Future<void> _runImageVerification() async {
    if (_capturedFile == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await ApiService().verifyImage(_capturedFile!);

      if (!mounted) return;

      setState(() {
        _verificationResult = result;
        _isAnalyzing = false;
      });

      if (result.isCivicIssue) {
        // Pre-fill detected title and description
        setState(() {
          _selectedCategory = result.categoryKey;
          _titleController.text = result.issueTitle;
          _descriptionController.text = result.description;
        });

        // If authenticity signals warning detected, show potential AI manipulation popup
        if (result.authenticityState == AuthenticityState.suspicious) {
          _showPotentialAiManipulationDialog(result);
        } else {
          // Show green success notification
          _showCivicProblemDetectedSnackBar(result);
        }
      } else {
        // No civic issue detected OR unable to verify
        if (result.isUncertain) {
          // Handled in UI card "Unable to Verify Image"
        } else if (result.isServiceConfigured) {
          _showNoCivicProblemDialog(result);
        }
      }
    } catch (e) {
      debugPrint('[AiPhotoLodgeScreen] Image verification error: $e');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _verificationResult = ImageVerificationResult.error('Image analysis request failed: $e');
        });
      }
    }
  }

  void _showCivicProblemDetectedSnackBar(ImageVerificationResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.emeraldPrimary,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Civic Problem Detected',
                    style: GoogleFonts.notoSans(fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  Text(
                    'Possible ${result.issueTitle.toLowerCase()} detected in the image. You can continue submitting your complaint.',
                    style: GoogleFonts.notoSans(fontSize: 11.5, color: Colors.white.withOpacity(0.95)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Warning Popup: No Civic Problem Detected (Selfie, food, animal, unrelated object)
  void _showNoCivicProblemDialog(ImageVerificationResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        actionsPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warningRedBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel, color: AppColors.warningRed, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No Civic Problem Detected',
                style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.warningRed),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This image does not appear to show a supported civic issue.',
              style: GoogleFonts.notoSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Please upload a clear picture of the actual problem, such as a pothole, garbage, water leakage, or damaged public infrastructure.',
              style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            if (result.rejectionReason != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  'Reason: ${result.rejectionReason}',
                  style: GoogleFonts.notoSans(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _clearImage();
            },
            child: Text('Cancel', style: GoogleFonts.notoSans(color: AppColors.textMuted)),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navyMedium,
              side: const BorderSide(color: AppColors.navyMedium),
            ),
            icon: const Icon(Icons.photo_library, size: 16),
            label: const Text('Upload Another Image'),
            onPressed: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.gallery);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronPrimary),
            icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
            label: const Text('Retake Photo', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.camera);
            },
          ),
        ],
      ),
    );
  }

  // Warning Popup: Potential AI-Generated or Manipulated Image
  void _showPotentialAiManipulationDialog(ImageVerificationResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        actionsPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.amberOrangeBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.amberOrange, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '⚠️ Potential AI-Generated or Manipulated Image',
                style: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.amberOrange),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This image shows signals associated with AI generation or manipulation. Please provide an original photograph of the actual civic issue if possible.',
              style: GoogleFonts.notoSans(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
            ),
            if (result.detectedSignals.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.amberOrangeBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.amberOrange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detected Manipulation Signals:',
                      style: GoogleFonts.notoSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.amberOrange),
                    ),
                    const SizedBox(height: 4),
                    ...result.detectedSignals.map((sig) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text('• $sig', style: GoogleFonts.notoSans(fontSize: 11, color: AppColors.textPrimary)),
                        )),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Note: You may submit for manual officer review if this is an authentic photograph.',
              style: GoogleFonts.notoSans(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.gallery);
            },
            child: const Text('Upload Original Image'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronPrimary),
            onPressed: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.camera);
            },
            child: const Text('Retake Photo', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amberOrange,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _allowManualReviewSubmission = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.amberOrange,
                  content: Text('Image flagged for Manual Forensic Review by Officer.'),
                ),
              );
            },
            child: const Text('Continue for Manual Review', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Complaint Submission with Live Authoritative Device GPS Geotagging
  // ---------------------------------------------------------------------------
  Future<void> _submitGrievance() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final grievanceProvider = Provider.of<GrievanceProvider>(context, listen: false);
    final rewardsProvider = Provider.of<RewardsProvider>(context, listen: false);

    if (_capturedFile == null) {
      _showErrorSnackBar('Please snap or upload an image first.');
      return;
    }

    if (_verificationResult == null || !_verificationResult!.isCivicIssue) {
      _showErrorSnackBar('Complaint submission requires a verified civic problem image.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. Acquire live fresh GPS location fix from citizen's device
      final gpsResult = await locationProvider.acquireFreshGps(context: context);

      if (!gpsResult.success) {
        setState(() {
          _isSubmitting = false;
        });

        // Prompt citizen with clear explanation and retry options
        _showGpsRequiredDialog(gpsResult.errorMessage ?? 'Unable to acquire current device location.');
        return;
      }

      final lat = gpsResult.latitude ?? locationProvider.latitude;
      final lon = gpsResult.longitude ?? locationProvider.longitude;
      final acc = gpsResult.accuracy ?? locationProvider.accuracy;
      final capAt = gpsResult.capturedAt ?? locationProvider.capturedAt ?? DateTime.now().toUtc();
      final villageWard = locationProvider.villageWard ??
          (locationProvider.isRealGpsAcquired ? locationProvider.statusMessage : 'Area Geotagged');
      final district = locationProvider.district ?? '';
      final state = locationProvider.state ?? '';

      final typedTitle = _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : _verificationResult!.issueTitle;

      final typedDescription = _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : _verificationResult!.description;

      final chosenCategory = _selectedCategory ?? _verificationResult!.categoryKey;
      final deptInfo = DepartmentInfo.getByCategory(chosenCategory);

      final verifStatus = _allowManualReviewSubmission
          ? 'flagged_manual_review'
          : 'verified_civic_issue';

      // 2. Lodge complaint with verification audit and live GPS coordinates
      final g = grievanceProvider.lodgePhotoGrievance(
        problemTitle: typedTitle,
        detailedDescription: typedDescription,
        category: chosenCategory,
        villageWard: villageWard,
        district: district,
        state: state,
        latitude: lat,
        longitude: lon,
        gpsAccuracyM: acc,
        locationCapturedAt: capAt,
        photoUrl: _capturedFile!.path,
        photoAnalysisSummary: typedDescription,
        citizenPhone: '+91 94140 88231',
        citizenName: 'Virendra Singh',
        imageVerificationStatus: verifStatus,
        imageCivicCategory: _verificationResult!.civicCategory,
        imageConfidenceScore: _verificationResult!.confidenceScore,
        imageAuthenticityStatus: _verificationResult!.authenticityStatus,
        imageAuthenticityDetails: _verificationResult!.authenticityStatement,
        imageDetectorInfo: _verificationResult!.detectorInfo,
        imageVerifiedAt: DateTime.now(),
        exifGpsLatitude: _verificationResult!.exifLatitude,
        exifGpsLongitude: _verificationResult!.exifLongitude,
      );

      setState(() {
        _isSubmitting = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.emeraldPrimary,
          content: Text('Verified Grievance ${g.id} registered & routed to ${deptInfo.nodalAuthority}!'),
        ),
      );

      // Award Grievance Coin for eligible complaint submission
      final award = await rewardsProvider.awardEligibleComplaint(
        g.id,
        description: 'Eligible Photo Complaint #${g.id}',
      );

      if (mounted) {
        if (award.success) {
          GcRewardDialog.show(context, award);
        }
        _clearImage();
      }
    } catch (e) {
      debugPrint('[AiPhotoLodgeScreen] Submit error: $e');
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        _showErrorSnackBar('Failed to submit grievance: $e');
      }
    }
  }

  void _showGpsRequiredDialog(String errorMsg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.location_off, color: AppColors.warningRed),
            const SizedBox(width: 8),
            Text('GPS Location Required', style: GoogleFonts.notoSans(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          '$errorMsg\n\nLok Samadhan requires your live device GPS location to attach verified coordinates to this complaint. Coordinates will not be fabricated.',
          style: GoogleFonts.notoSans(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronPrimary),
            icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
            label: const Text('Retry GPS Location', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(ctx);
              final locationProvider = Provider.of<LocationProvider>(context, listen: false);
              locationProvider.requestPermissionAndEnableGps();
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Build Screen UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.navyDark, AppColors.navyMedium],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.saffronPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Photo Civic Verification Portal',
                        style: GoogleFonts.notoSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Intelligent civic issue detection, authenticity analysis, and live GPS geotagging.',
                        style: GoogleFonts.notoSans(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Real Phone Location Status Card
          _buildGpsStatusCard(locationProvider),
          const SizedBox(height: 16),

          // Image Acquisition Action Buttons (Camera & Upload)
          Text(
            '1. Capture Photo or Upload Image (तस्वीर लें या अपलोड करें):',
            style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.saffronPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.camera_enhance, size: 20, color: Colors.white),
                  label: Text(
                    'CAPTURE CAMERA',
                    style: GoogleFonts.notoSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyMedium,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.photo_library, size: 20, color: Colors.white),
                  label: Text(
                    'UPLOAD IMAGE',
                    style: GoogleFonts.notoSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Photo Display Box with Live Dynamic GPS Stamp
          Text(
            '2. Image Preview & Watermark Stamp (फोटो पूर्वावलोकन):',
            style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),

          _buildImagePreviewBox(locationProvider),
          const SizedBox(height: 16),

          // AI Verification Results Section
          if (_capturedFile != null) ...[
            _buildVerificationStatusSection(),
            const SizedBox(height: 16),
          ],

          // Grievance Details & Submit Form (Only active when civic issue is verified)
          if (_capturedFile != null && _verificationResult != null && _verificationResult!.isCivicIssue) ...[
            _buildComplaintDetailsForm(),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. GPS Status Card Widget
  // ---------------------------------------------------------------------------
  Widget _buildGpsStatusCard(LocationProvider locationProvider) {
    return Card(
      color: locationProvider.isGpsEnabled
          ? (locationProvider.isRealGpsAcquired ? AppColors.emeraldBackground : AppColors.amberOrangeBg)
          : AppColors.warningRedBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: locationProvider.isGpsEnabled
              ? (locationProvider.isRealGpsAcquired ? AppColors.emeraldPrimary.withOpacity(0.4) : AppColors.amberOrange.withOpacity(0.4))
              : AppColors.warningRed.withOpacity(0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  locationProvider.isGpsEnabled ? Icons.my_location : Icons.location_off,
                  color: locationProvider.isGpsEnabled
                      ? (locationProvider.isRealGpsAcquired ? AppColors.emeraldPrimary : AppColors.amberOrange)
                      : AppColors.warningRed,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            locationProvider.isGpsEnabled
                                ? (locationProvider.isRealGpsAcquired ? 'LIVE DEVICE GPS LOCKED' : 'FETCHING LIVE GPS...')
                                : 'DEVICE GPS: OFF',
                            style: GoogleFonts.notoSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: locationProvider.isGpsEnabled
                                  ? (locationProvider.isRealGpsAcquired ? AppColors.emeraldPrimary : AppColors.amberOrange)
                                  : AppColors.warningRed,
                            ),
                          ),
                          if (locationProvider.isLocating) ...[
                            const SizedBox(width: 6),
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.emeraldPrimary),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locationProvider.statusMessage,
                        style: GoogleFonts.notoSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Refresh Phone GPS',
                  onPressed: () => locationProvider.fetchRealLocation(),
                ),
                Switch(
                  value: locationProvider.isGpsEnabled,
                  activeColor: AppColors.emeraldPrimary,
                  onChanged: (val) {
                    locationProvider.setGpsEnabled(val);
                  },
                ),
              ],
            ),
            if (!locationProvider.isRealGpsAcquired && locationProvider.isGpsEnabled) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.emeraldPrimary,
                    side: const BorderSide(color: AppColors.emeraldPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.gps_fixed, size: 16),
                  label: const Text('GRANT GPS PERMISSION / ENABLE LOCATION', style: TextStyle(fontSize: 11.5)),
                  onPressed: () => locationProvider.requestPermissionAndEnableGps(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Image Preview Box Widget
  // ---------------------------------------------------------------------------
  Widget _buildImagePreviewBox(LocationProvider locationProvider) {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _capturedFile != null ? AppColors.emeraldPrimary : AppColors.cardBorder,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          if (_capturedFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: kIsWeb
                  ? Image.network(
                      _capturedFile!.path,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      File(_capturedFile!.path),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: AppColors.saffronLight, size: 42),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Photo Captured Yet',
                    style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "CAPTURE CAMERA" or "UPLOAD IMAGE" above to begin.',
                    style: GoogleFonts.notoSans(fontSize: 11.5, color: Colors.white60),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // Loading overlay during AI analysis
          if (_isAnalyzing)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.saffronPrimary),
                    const SizedBox(height: 12),
                    Text(
                      'Analyzing Civic Issue & Authenticity...',
                      style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Detecting problem category, fraud signals & metadata forensics...',
                      style: GoogleFonts.notoSans(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),

          // Close / Clear Photo Button
          if (_capturedFile != null && !_isAnalyzing)
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.black.withOpacity(0.7),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  tooltip: 'Remove photo',
                  onPressed: _clearImage,
                ),
              ),
            ),

          // Source indicator tag
          if (_capturedFile != null)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    Icon(
                      _imageSourceType == 'camera' ? Icons.camera_alt : Icons.image,
                      size: 12,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _imageSourceType == 'camera' ? 'Camera Capture' : 'Gallery Upload',
                      style: GoogleFonts.notoSans(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

          // LIVE DYNAMIC GPS WATERMARK OVERLAY
          if (_capturedFile != null && locationProvider.isGpsEnabled)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.88),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                  border: Border(top: BorderSide(color: AppColors.emeraldPrimary.withOpacity(0.9), width: 2.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified, color: AppColors.emeraldPrimary, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'LIVE DEVICE GPS WATERMARK STAMP',
                          style: GoogleFonts.notoSans(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.emeraldPrimary, letterSpacing: 0.5),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('d MMM yyyy, h:mm:ss a').format(_captureTimestamp ?? DateTime.now()),
                          style: GoogleFonts.notoSans(fontSize: 9, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locationProvider.latitude != null && locationProvider.longitude != null
                          ? '📍 Lat: ${locationProvider.formattedLat} | Long: ${locationProvider.formattedLng}${locationProvider.formattedAccuracy.isNotEmpty ? " (${locationProvider.formattedAccuracy})" : ""}'
                          : '📍 GPS: Acquiring device coordinates...',
                      style: GoogleFonts.notoSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. AI Verification Findings Status Card
  // ---------------------------------------------------------------------------
  Widget _buildVerificationStatusSection() {
    if (_isAnalyzing) {
      return Card(
        color: AppColors.navyMedium.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.saffronPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Running AI Civic Problem Analysis & Authenticity Check...',
                  style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_verificationResult == null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.emeraldPrimary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.analytics_outlined, color: Colors.white, size: 18),
          label: Text('Analyze Image with AI', style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.w700)),
          onPressed: _runImageVerification,
        ),
      );
    }

    final res = _verificationResult!;

    // Visual state color tokens:
    // Green: supported civic problem detected
    // Orange: authenticity concern or uncertain result
    // Red: irrelevant image or a blocking validation error
    // Gray: analysis unavailable
    Color cardColor;
    Color borderColor;
    IconData icon;
    String statusTitle;

    switch (res.civicDetectionState) {
      case CivicDetectionState.civicProblemDetected:
        if (res.authenticityState == AuthenticityState.suspicious) {
          cardColor = AppColors.amberOrangeBg;
          borderColor = AppColors.amberOrange;
          icon = Icons.warning_amber_rounded;
          statusTitle = 'Civic Problem Detected (Authenticity Warning)';
        } else {
          cardColor = AppColors.emeraldBackground;
          borderColor = AppColors.emeraldPrimary;
          icon = Icons.check_circle_outline;
          statusTitle = 'Civic Problem Detected';
        }
        break;
      case CivicDetectionState.noCivicProblemDetected:
        cardColor = AppColors.warningRedBg;
        borderColor = AppColors.warningRed;
        icon = Icons.cancel_outlined;
        statusTitle = 'No Civic Problem Detected';
        break;
      case CivicDetectionState.unableToVerify:
        cardColor = AppColors.amberOrangeBg;
        borderColor = AppColors.amberOrange;
        icon = Icons.help_outline;
        statusTitle = 'Unable to Verify Image';
        break;
      case CivicDetectionState.serviceUnavailable:
        cardColor = Colors.grey.shade100;
        borderColor = Colors.grey.shade400;
        icon = Icons.cloud_off_outlined;
        statusTitle = 'AI Vision Service Unavailable';
        break;
    }

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor.withOpacity(0.6), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Row(
              children: [
                Icon(icon, color: borderColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusTitle,
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: borderColor,
                    ),
                  ),
                ),
                if (res.confidenceScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: borderColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${(res.confidenceScore! * 100).toStringAsFixed(0)}% Confidence',
                      style: GoogleFonts.notoSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: borderColor),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Description of visible issue
            Text(
              res.description.isNotEmpty ? res.description : 'Analysis concluded.',
              style: GoogleFonts.notoSans(fontSize: 12.5, color: AppColors.textPrimary, height: 1.35),
            ),

            if (res.uncertaintyOrLimitations != null) ...[
              const SizedBox(height: 6),
              Text(
                'Note: ${res.uncertaintyOrLimitations}',
                style: GoogleFonts.notoSans(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
              ),
            ],

            const Divider(height: 18),

            // Authenticity Status Card (Section 2)
            _buildAuthenticityDetailRow(res),

            // Optional EXIF GPS Reference Notice (Section 4)
            if (res.hasExifGps) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: AppColors.navyMedium),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Optional EXIF GPS metadata found in photo: (${res.exifLatitude?.toStringAsFixed(4)}°, ${res.exifLongitude?.toStringAsFixed(4)}°). Note: Submission uses your live device GPS.',
                        style: GoogleFonts.notoSans(fontSize: 10.5, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action Buttons for Re-take / Try again if rejected or uncertain
            if (!res.isCivicIssue) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retake Photo', style: TextStyle(fontSize: 12)),
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                      icon: const Icon(Icons.photo_library, size: 16),
                      label: const Text('Upload Another', style: TextStyle(fontSize: 12)),
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Authenticity Detail Row
  Widget _buildAuthenticityDetailRow(ImageVerificationResult res) {
    Color authColor;
    IconData authIcon;

    switch (res.authenticityState) {
      case AuthenticityState.likelyAuthentic:
        authColor = AppColors.emeraldPrimary;
        authIcon = Icons.verified_user_outlined;
        break;
      case AuthenticityState.suspicious:
        authColor = AppColors.warningRed;
        authIcon = Icons.warning_amber_rounded;
        break;
      case AuthenticityState.inconclusive:
        authColor = AppColors.amberOrange;
        authIcon = Icons.help_outline;
        break;
      case AuthenticityState.unavailable:
        authColor = Colors.grey.shade600;
        authIcon = Icons.info_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: authColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(authIcon, size: 16, color: authColor),
              const SizedBox(width: 6),
              Text(
                'AI-Generated / Manipulated Image Analysis:',
                style: GoogleFonts.notoSans(fontSize: 11, fontWeight: FontWeight.w700, color: authColor),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: authColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  res.authenticityStateLabel,
                  style: GoogleFonts.notoSans(fontSize: 10, fontWeight: FontWeight.w700, color: authColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            res.authenticityStatement,
            style: GoogleFonts.notoSans(fontSize: 11, color: AppColors.textPrimary, height: 1.3),
          ),
          if (res.detectorInfo.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Detector: ${res.detectorInfo}',
              style: GoogleFonts.notoSans(fontSize: 9.5, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 8. Complaint Details & Submit Form
  // ---------------------------------------------------------------------------
  Widget _buildComplaintDetailsForm() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_note, color: AppColors.saffronPrimary, size: 22),
                const SizedBox(width: 8),
                Text(
                  '3. Confirm Details & Submit (शिकायत का विवरण):',
                  style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const Divider(height: 20),

            // Category Confirmation / Adjustment Dropdown
            Text(
              'Detected Civic Category (विभाग पुष्टि करें):',
              style: GoogleFonts.notoSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DepartmentCategory>(
                  value: _selectedCategory ?? DepartmentCategory.generalPanchayat,
                  isExpanded: true,
                  items: DepartmentCategory.values.map((cat) {
                    final info = DepartmentInfo.getByCategory(cat);
                    return DropdownMenuItem<DepartmentCategory>(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(info.icon, size: 16, color: info.color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${info.nameEn} (${info.nameHi})',
                              style: GoogleFonts.notoSans(fontSize: 12.5, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (newCat) {
                    if (newCat != null) {
                      setState(() {
                        _selectedCategory = newCat;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Title Field
            Text(
              'Grievance Headline (समस्या का शीर्षक):',
              style: GoogleFonts.notoSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: GoogleFonts.notoSans(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Enter title...',
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
              ),
            ),
            const SizedBox(height: 14),

            // Description Field
            Text(
              'Detailed Description (समस्या का पूरा विवरण):',
              style: GoogleFonts.notoSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: GoogleFonts.notoSans(fontSize: 12.5, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Describe details, landmark, or hazard risk...',
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
              ),
            ),
            const SizedBox(height: 16),

            // One-tap Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.saffronPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send, size: 18, color: Colors.white),
                label: Text(
                  _isSubmitting
                      ? 'Geotagging & Submitting to Govt Office...'
                      : 'Submit Verified Photo Grievance to Govt Office',
                  style: GoogleFonts.notoSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                onPressed: _isSubmitting ? null : _submitGrievance,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
