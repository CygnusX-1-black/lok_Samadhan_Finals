import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/department.dart';
import '../../providers/grievance_provider.dart';
import '../../providers/location_provider.dart';
import '../../theme/app_colors.dart';

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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _openCameraHardware() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    if (!locationProvider.isGpsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.warningRed,
          content: Text(
            'Please turn ON Phone Location (GPS) before taking a photo.',
            style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    // Refresh live phone location right when camera is launched
    locationProvider.fetchRealLocation();

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null) {
        setState(() {
          _capturedFile = photo;
          _captureTimestamp = DateTime.now();
          _titleController.clear();
          _descriptionController.clear();
        });

        // Re-query GPS to ensure exact location at timestamp of photo capture
        locationProvider.fetchRealLocation();
      }
    } catch (e) {
      debugPrint('Native camera error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.warningRed,
            content: Text('Camera Access Error: $e. Please allow camera permission in phone settings.'),
          ),
        );
      }
    }
  }

  DepartmentCategory _classifyDepartment(String title, String desc) {
    final text = '$title $desc'.toLowerCase();
    if (text.contains('water') || text.contains('pani') || text.contains('पानी') || text.contains('पाइप') || text.contains('चापाकल') || text.contains('जल')) {
      return DepartmentCategory.waterSupply;
    } else if (text.contains('road') || text.contains('sadak') || text.contains('सड़क') || text.contains('पॉटहोल') || text.contains('गड्ढा') || text.contains('bridge')) {
      return DepartmentCategory.roadsInfrastructure;
    } else if (text.contains('ration') || text.contains('dealer') || text.contains('राशन') || text.contains('कोटा') || text.contains('चावल')) {
      return DepartmentCategory.pdsRation;
    } else if (text.contains('drain') || text.contains('safai') || text.contains('कचरा') || text.contains('नाली') || text.contains('गंदगी') || text.contains('सफाई')) {
      return DepartmentCategory.sanitationHealth;
    } else if (text.contains('light') || text.contains('bijli') || text.contains('बिजली') || text.contains('तार') || text.contains('ट्रांसफॉर्मर') || text.contains('current')) {
      return DepartmentCategory.electricity;
    }
    return DepartmentCategory.generalPanchayat;
  }

  @override
  Widget build(BuildContext context) {
    final grievanceProvider = Provider.of<GrievanceProvider>(context);
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
                        'Real Mobile Camera & Live GPS Lodge',
                        style: GoogleFonts.notoSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Takes real-time photo with phone camera & stamps live phone GPS coordinates.',
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

          // Real Phone Location Status Card & Permission Trigger
          Card(
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
                                      ? (locationProvider.isRealGpsAcquired ? 'REAL PHONE GPS LOCKED' : 'FETCHING PHONE GPS...')
                                      : 'PHONE LOCATION (GPS): OFF',
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
          ),
          const SizedBox(height: 16),

          // 1. Mobile Camera Launch Button
          Text(
            '1. Snap Field Photo with Mobile Camera (कैमरा खोलें):',
            style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saffronPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.camera_enhance, size: 22, color: Colors.white),
              label: Text(
                'OPEN MOBILE CAMERA (कैमरा से तस्वीर लें)',
                style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              onPressed: _openCameraHardware,
            ),
          ),
          const SizedBox(height: 16),

          // 2. REAL CAPTURED PHOTO DISPLAY BOX WITH LIVE DYNAMIC GPS STAMP
          Text(
            '2. Captured Photo Preview & Live Phone GPS Stamp:',
            style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),

          Container(
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
                // Render Real Photo captured by mobile camera
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
                  // Placeholder before camera trigger
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
                          'Tap "OPEN MOBILE CAMERA" above to snap real incident photo.',
                          style: GoogleFonts.notoSans(fontSize: 11.5, color: Colors.white60),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                // REAL STAMPED LIVE DYNAMIC GPS WATERMARK OVERLAY (On top of real photo)
                if (_capturedFile != null && locationProvider.isGpsEnabled)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
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
                              const Icon(Icons.verified, color: AppColors.emeraldPrimary, size: 15),
                              const SizedBox(width: 6),
                              Text(
                                'REAL PHONE GPS WATERMARK STAMP',
                                style: GoogleFonts.notoSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.emeraldPrimary, letterSpacing: 0.5),
                              ),
                              const Spacer(),
                              Text(
                                DateFormat('d MMM yyyy, h:mm:ss a').format(_captureTimestamp ?? DateTime.now()),
                                style: GoogleFonts.notoSans(fontSize: 9.5, color: Colors.white70),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            locationProvider.latitude != null && locationProvider.longitude != null
                                ? '📍 Lat: ${locationProvider.formattedLat} | Long: ${locationProvider.formattedLng}'
                                : '📍 GPS: Locating phone coordinates...',
                            style: GoogleFonts.notoSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          Text(
                            locationProvider.statusMessage,
                            style: GoogleFonts.notoSans(fontSize: 11, color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. EDITABLE GRIEVANCE DETAILS (Title & Description only - Backend auto-analyzes department)
          if (_capturedFile != null) ...[
            Card(
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
                          'Grievance Details (शिकायत का विवरण लिखें)',
                          style: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Title Field
                    Text(
                      'Grievance Title (समस्या का शीर्षक):',
                      style: GoogleFonts.notoSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _titleController,
                      style: GoogleFonts.notoSans(fontSize: 13.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Enter title (e.g. Broken water pipe, Road damaged, Transformer issue)...',
                        hintStyle: GoogleFonts.notoSans(fontSize: 12, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.saffronPrimary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Description Field
                    Text(
                      'Detailed Description (समस्या का पूरा विवरण लिखें):',
                      style: GoogleFonts.notoSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      style: GoogleFonts.notoSans(fontSize: 13, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Describe the problem in detail (location landmark, since how many days, hazard risk)...',
                        hintStyle: GoogleFonts.notoSans(fontSize: 12, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.saffronPrimary, width: 1.5),
                        ),
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
                        ),
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text('Submit Photo Grievance to Govt Office'),
                        onPressed: () {
                          final typedTitle = _titleController.text.trim().isNotEmpty
                              ? _titleController.text.trim()
                              : 'Citizen Photo Grievance';

                          final typedDescription = _descriptionController.text.trim().isNotEmpty
                              ? _descriptionController.text.trim()
                              : 'Field photo grievance lodged with live GPS location stamp.';

                          final autoCategory = _classifyDepartment(typedTitle, typedDescription);
                          final deptInfo = DepartmentInfo.getByCategory(autoCategory);

                          final g = grievanceProvider.lodgePhotoGrievance(
                            problemTitle: typedTitle,
                            detailedDescription: typedDescription,
                            category: autoCategory,
                            villageWard: locationProvider.statusMessage,
                            district: 'Bhojpur',
                            state: 'Bihar',
                            latitude: locationProvider.latitude ?? 25.5941,
                            longitude: locationProvider.longitude ?? 85.1376,
                            photoUrl: _capturedFile!.path,
                            photoAnalysisSummary: typedDescription,
                            citizenPhone: '+91 94140 88231',
                            citizenName: 'Virendra Singh',
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.emeraldPrimary,
                              content: Text('GPS Watermarked Grievance ${g.id} submitted & routed to ${deptInfo.nodalAuthority}!'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
