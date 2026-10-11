import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/grievance.dart';
import '../../providers/grievance_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/time_utils.dart';
import '../../widgets/audio_wave_visualizer.dart';
import '../../widgets/confidence_badge.dart';
import '../../widgets/sla_countdown_badge.dart';
import 'package:url_launcher/url_launcher.dart';

class GrievanceDetailScreen extends StatefulWidget {
  final String grievanceId;

  const GrievanceDetailScreen({
    super.key,
    required this.grievanceId,
  });

  @override
  State<GrievanceDetailScreen> createState() => _GrievanceDetailScreenState();
}

class _GrievanceDetailScreenState extends State<GrievanceDetailScreen> {
  final TextEditingController _actionNoteController = TextEditingController();
  bool _isPlayingAudio = false;

  @override
  void dispose() {
    _actionNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grievanceProvider = Provider.of<GrievanceProvider>(context);
    final grievance = grievanceProvider.getGrievanceById(widget.grievanceId);

    if (grievance == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Grievance Details')),
        body: const Center(child: Text('Grievance not found.')),
      );
    }

    final dept = grievance.departmentInfo;
    final createdStr = TimeUtils.formatKolkataTime(grievance.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: Text('Grievance #${grievance.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Complaint details copied to clipboard / exported.')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Status & Department Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: dept.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(dept.icon, color: dept.color, size: 24),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SlaCountdownBadge(grievance: grievance),
                            const SizedBox(height: 4),
                            ConfidenceBadge(
                              score: grievance.aiConfidenceScore,
                              isHitlRequired: grievance.isHitlFallback,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      dept.nameEn,
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Nodal Authority: ${dept.nodalAuthority}',
                      style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const Divider(height: 20),

                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          'Citizen: ${grievance.citizenName} (${grievance.citizenPhone})',
                          style: GoogleFonts.notoSans(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          'Reported Area: ${grievance.villageWard}, ${grievance.block}, ${grievance.district}, ${grievance.state}',
                          style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          'Registered On: $createdStr',
                          style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Authoritative GPS Location Verification Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: grievance.hasValidGps ? AppColors.emeraldPrimary.withValues(alpha: 0.35) : AppColors.cardBorder,
                  width: 1.2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          grievance.hasValidGps ? Icons.gps_fixed : Icons.gps_off,
                          color: grievance.hasValidGps ? AppColors.emeraldPrimary : AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Authoritative GPS Coordinates',
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: grievance.hasValidGps
                                ? AppColors.emeraldPrimary.withValues(alpha: 0.12)
                                : AppColors.cardBorder.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            grievance.hasValidGps ? 'VERIFIED DEVICE GPS' : 'LOCATION UNAVAILABLE',
                            style: GoogleFonts.notoSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: grievance.hasValidGps ? AppColors.emeraldPrimary : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GPS Coordinates: ',
                                style: GoogleFonts.notoSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  grievance.formattedGps,
                                  style: GoogleFonts.notoSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: grievance.hasValidGps ? AppColors.emeraldPrimary : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (grievance.hasValidGps && grievance.formattedAccuracy.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  'Accuracy Radius: ',
                                  style: GoogleFonts.notoSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                Text(
                                  grievance.formattedAccuracy,
                                  style: GoogleFonts.notoSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Complaint ID: ',
                                style: GoogleFonts.notoSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                grievance.id,
                                style: GoogleFonts.notoSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (grievance.hasValidGps) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.open_in_new, size: 14),
                          label: const Text('View on OpenStreetMap'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navyMedium,
                            textStyle: GoogleFonts.notoSans(fontSize: 11.5, fontWeight: FontWeight.w600),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            side: const BorderSide(color: AppColors.cardBorder),
                          ),
                          onPressed: () async {
                            final mapUri = Uri.parse(
                              'https://www.openstreetmap.org/?mlat=${grievance.latitude}&mlon=${grievance.longitude}#map=16/${grievance.latitude}/${grievance.longitude}',
                            );
                            if (await canLaunchUrl(mapUri)) {
                              await launchUrl(mapUri, mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // AI Image Verification & Forensic Audit Card (For Photo Grievances)
            if (grievance.photoUrl != null) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: grievance.imageAuthenticityStatus == 'suspicious_manipulation'
                        ? AppColors.errorRed.withValues(alpha: 0.4)
                        : (grievance.imageVerificationStatus == 'flagged_manual_review'
                            ? AppColors.saffronPrimary.withValues(alpha: 0.5)
                            : AppColors.emeraldPrimary.withValues(alpha: 0.35)),
                    width: 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldPrimary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.camera_alt, color: AppColors.emeraldPrimary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Image Verification & Forensic Audit',
                                  style: GoogleFonts.notoSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Complaint: #${grievance.id}',
                                  style: GoogleFonts.notoSans(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildVerificationChip(grievance),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Image preview
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 210,
                          width: double.infinity,
                          color: Colors.black,
                          child: Stack(
                            children: [
                              kIsWeb || grievance.photoUrl!.startsWith('http')
                                  ? Image.network(
                                      grievance.photoUrl!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Center(
                                        child: Icon(Icons.broken_image, color: Colors.white54, size: 40),
                                      ),
                                    )
                                  : Image.file(
                                      File(grievance.photoUrl!),
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Center(
                                        child: Icon(Icons.image, color: Colors.white54, size: 40),
                                      ),
                                    ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.gps_fixed, color: AppColors.emeraldPrimary, size: 13),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          grievance.hasValidGps
                                              ? 'Authoritative GPS: ${grievance.formattedGps}${grievance.formattedAccuracy.isNotEmpty ? " (±${grievance.formattedAccuracy})" : ""}'
                                              : 'Location not available',
                                          style: GoogleFonts.notoSans(
                                            fontSize: 10.5,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Verification Summary Table / Card (Required Officer Dashboard Specification)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          children: [
                            _buildSummaryRow(
                              'Complaint ID',
                              grievance.id,
                              valueColor: AppColors.textPrimary,
                              isBold: true,
                            ),
                            const Divider(height: 12),
                            _buildSummaryRow(
                              'Detected Civic Issue',
                              grievance.imageCivicCategory ?? grievance.departmentInfo.nameEn,
                              valueColor: AppColors.emeraldDark,
                              isBold: true,
                            ),
                            const Divider(height: 12),
                            _buildSummaryRow(
                              'Civic Relevance',
                              grievance.imageVerificationStatus == 'no_civic_issue'
                                  ? 'Irrelevant / No Issue'
                                  : 'Relevant Civic Problem',
                              badgeColor: grievance.imageVerificationStatus == 'no_civic_issue'
                                  ? AppColors.errorRed
                                  : AppColors.emeraldPrimary,
                            ),
                            const Divider(height: 12),
                            _buildSummaryRow(
                              'Image Authenticity',
                              _formatAuthenticityLabel(grievance.imageAuthenticityStatus),
                              badgeColor: _getAuthenticityColor(grievance.imageAuthenticityStatus),
                            ),
                            const Divider(height: 12),
                            _buildSummaryRow(
                              'Confidence Score',
                              grievance.imageConfidenceScore != null
                                  ? '${(grievance.imageConfidenceScore! * 100).toStringAsFixed(0)}%'
                                  : 'N/A',
                              valueColor: AppColors.textPrimary,
                            ),
                            const Divider(height: 12),
                            _buildSummaryRow(
                              'Actual Saved GPS',
                              grievance.hasValidGps ? grievance.formattedGps : 'Unavailable',
                              valueColor: grievance.hasValidGps ? AppColors.emeraldPrimary : AppColors.textMuted,
                              isBold: grievance.hasValidGps,
                            ),
                            if (grievance.exifGpsLatitude != null && grievance.exifGpsLongitude != null) ...[
                              const Divider(height: 12),
                              _buildSummaryRow(
                                'Photo EXIF GPS',
                                '${grievance.exifGpsLatitude!.toStringAsFixed(4)}°, ${grievance.exifGpsLongitude!.toStringAsFixed(4)}° (Historical)',
                                valueColor: AppColors.textSecondary,
                              ),
                            ],
                            if (grievance.imageDetectorInfo != null) ...[
                              const Divider(height: 12),
                              _buildSummaryRow(
                                'Forensic Engine',
                                grievance.imageDetectorInfo!,
                                valueColor: AppColors.navyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Authenticity Details / Signals Box
                      if (grievance.imageAuthenticityDetails != null &&
                          grievance.imageAuthenticityDetails!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getAuthenticityBgColor(grievance.imageAuthenticityStatus),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getAuthenticityColor(grievance.imageAuthenticityStatus).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _getAuthenticityIcon(grievance.imageAuthenticityStatus),
                                size: 16,
                                color: _getAuthenticityColor(grievance.imageAuthenticityStatus),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  grievance.imageAuthenticityDetails!,
                                  style: GoogleFonts.notoSans(
                                    fontSize: 11.5,
                                    color: AppColors.textPrimary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Description
                      if (grievance.photoAnalysisSummary != null) ...[
                        Text(
                          'AI Vision Analysis & Problem Description:',
                          style: GoogleFonts.notoSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          grievance.photoAnalysisSummary!,
                          style: GoogleFonts.notoSans(
                            fontSize: 12.5,
                            color: AppColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Officer Manual Review Action Row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: Icon(
                                grievance.imageVerificationStatus == 'flagged_manual_review'
                                    ? Icons.flag
                                    : Icons.flag_outlined,
                                size: 16,
                                color: AppColors.saffronPrimary,
                              ),
                              label: Text(
                                grievance.imageVerificationStatus == 'flagged_manual_review'
                                    ? 'Flagged for Review (Edit Note)'
                                    : 'Flag for Manual Review',
                                style: GoogleFonts.notoSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.saffronPrimary,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.saffronPrimary),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _showFlagManualReviewDialog(context, grievance, grievanceProvider),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Voice Recording & Dialect Audio Player Card (For Voice Grievances)
            if (grievance.photoUrl == null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.mic, color: AppColors.saffronPrimary, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'Voice Recording (${grievance.spokenDialect})',
                                style: GoogleFonts.notoSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '00:12 Audio',
                            style: GoogleFonts.notoSans(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.navyDark,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isPlayingAudio ? Icons.pause_circle : Icons.play_circle,
                                color: AppColors.saffronLight,
                                size: 32,
                              ),
                              onPressed: () {
                                setState(() => _isPlayingAudio = !_isPlayingAudio);
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AudioWaveVisualizer(
                                amplitudes: _isPlayingAudio
                                    ? [0.4, 0.9, 0.6, 0.8, 0.3, 0.9, 0.5, 0.7, 0.9, 0.4, 0.8, 0.6]
                                    : List.generate(12, (i) => 0.1),
                                isRecording: _isPlayingAudio,
                                barColor: AppColors.saffronLight,
                                height: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'Dialect Transcript:',
                        style: GoogleFonts.notoSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                      ),
                      Text(
                        '"${grievance.rawSpeechText}"',
                        style: GoogleFonts.notoSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Standard English Translation:',
                        style: GoogleFonts.notoSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                      ),
                      Text(
                        grievance.translatedText,
                        style: GoogleFonts.notoSans(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Official Action & Status Update Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Officer Action & Status Update',
                      style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _actionNoteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Action Taken / Site Inspection Remarks',
                        hintText: 'e.g. Field inspection complete. Parts ordered.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyMedium),
                          icon: const Icon(Icons.manage_search, size: 16),
                          label: const Text('Under Investigation'),
                          onPressed: () {
                            grievanceProvider.updateGrievanceStatus(
                              grievanceId: grievance.id,
                              newStatus: GrievanceStatus.underReview,
                              officialNote: _actionNoteController.text,
                            );
                            _actionNoteController.clear();
                          },
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
                          icon: const Icon(Icons.engineering, size: 16),
                          label: const Text('In Progress'),
                          onPressed: () {
                            grievanceProvider.updateGrievanceStatus(
                              grievanceId: grievance.id,
                              newStatus: GrievanceStatus.inProgress,
                              officialNote: _actionNoteController.text,
                            );
                            _actionNoteController.clear();
                          },
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.emeraldPrimary),
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text('Resolve & Close'),
                          onPressed: () {
                            grievanceProvider.updateGrievanceStatus(
                              grievanceId: grievance.id,
                              newStatus: GrievanceStatus.resolved,
                              officialNote: _actionNoteController.text.isEmpty
                                  ? 'Field repair completed. Citizen notified via voice call & SMS.'
                                  : _actionNoteController.text,
                            );
                            _actionNoteController.clear();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Audit Log Timeline Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audit Log & Tracking Trail',
                      style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: grievance.auditLog.length,
                      itemBuilder: (context, index) {
                        final step = grievance.auditLog[index];
                        final timeStr = TimeUtils.formatKolkataTime(step.timestamp);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.radio_button_checked, size: 16, color: AppColors.saffronPrimary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(step.statusLabel, style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w700)),
                                        Text(timeStr, style: GoogleFonts.notoSans(fontSize: 10.5, color: AppColors.textMuted)),
                                      ],
                                    ),
                                    Text('By: ${step.actor}', style: GoogleFonts.notoSans(fontSize: 11, color: AppColors.navyMedium, fontWeight: FontWeight.w600)),
                                    Text(step.description, style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationChip(Grievance g) {
    if (g.imageVerificationStatus == 'flagged_manual_review') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.saffronPrimary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.saffronPrimary),
        ),
        child: Text(
          'FLAGGED REVIEW',
          style: GoogleFonts.notoSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.saffronPrimary),
        ),
      );
    }
    final isVerified = g.imageVerificationStatus == 'verified_civic_issue' ||
        g.imageVerificationStatus == 'VERIFIED_CIVIC_PROBLEM';
    final color = isVerified ? AppColors.emeraldPrimary : AppColors.errorRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        isVerified ? 'CIVIC VERIFIED' : 'UNVERIFIED',
        style: GoogleFonts.notoSans(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
    Color? badgeColor,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: GoogleFonts.notoSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: badgeColor != null
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      value,
                      style: GoogleFonts.notoSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: badgeColor),
                    ),
                  ),
                )
              : Text(
                  value,
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
        ),
      ],
    );
  }

  String _formatAuthenticityLabel(String? status) {
    switch (status) {
      case 'likely_authentic':
      case 'LIKELY_AUTHENTIC':
        return 'Likely Authentic (No AI evidence)';
      case 'suspicious_manipulation':
      case 'POTENTIALLY_AI_GENERATED':
        return '⚠️ Potential AI / Manipulated';
      case 'unable_to_determine':
      case 'UNABLE_TO_DETERMINE':
        return 'Inconclusive / Unable to Determine';
      case 'authenticity_unavailable':
      case 'AUTHENTICITY_UNAVAILABLE':
        return 'Authenticity Check Unavailable';
      default:
        return status ?? 'Likely Authentic';
    }
  }

  Color _getAuthenticityColor(String? status) {
    switch (status) {
      case 'likely_authentic':
      case 'LIKELY_AUTHENTIC':
        return AppColors.emeraldPrimary;
      case 'suspicious_manipulation':
      case 'POTENTIALLY_AI_GENERATED':
        return AppColors.errorRed;
      case 'unable_to_determine':
      case 'UNABLE_TO_DETERMINE':
        return AppColors.saffronPrimary;
      case 'authenticity_unavailable':
      case 'AUTHENTICITY_UNAVAILABLE':
      default:
        return AppColors.textMuted;
    }
  }

  Color _getAuthenticityBgColor(String? status) {
    return _getAuthenticityColor(status).withValues(alpha: 0.08);
  }

  IconData _getAuthenticityIcon(String? status) {
    switch (status) {
      case 'likely_authentic':
      case 'LIKELY_AUTHENTIC':
        return Icons.verified;
      case 'suspicious_manipulation':
      case 'POTENTIALLY_AI_GENERATED':
        return Icons.warning_amber_rounded;
      case 'unable_to_determine':
      case 'UNABLE_TO_DETERMINE':
        return Icons.help_outline;
      case 'authenticity_unavailable':
      case 'AUTHENTICITY_UNAVAILABLE':
      default:
        return Icons.info_outline;
    }
  }

  void _showFlagManualReviewDialog(
    BuildContext context,
    Grievance grievance,
    GrievanceProvider grievanceProvider,
  ) {
    final noteController = TextEditingController(
      text: grievance.hitlReviewerNotes ?? 'Image flagged by officer for manual field verification.',
    );
    String selectedReason = 'Suspected synthetic or manipulated image';
    final reasons = [
      'Suspected synthetic or manipulated image',
      'Inconclusive or blurry damage details',
      'Location mismatch with reported address',
      'Duplicate incident submitted across multiple wards',
      'Other physical inspection required',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.flag_rounded, color: AppColors.saffronPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Flag for Manual Review',
                  style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flag complaint #${grievance.id} for human officer verification. This routes the case for manual field inspection without automatically rejecting the citizen\'s grievance.',
                  style: GoogleFonts.notoSans(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Text(
                  'Review Reason:',
                  style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: reasons
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r, style: GoogleFonts.notoSans(fontSize: 12)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedReason = val);
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Officer Notes / Remarks:',
                  style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Additional details for field inspector...',
                    contentPadding: const EdgeInsets.all(10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saffronPrimary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.flag, size: 16),
              label: const Text('Confirm Flag'),
              onPressed: () async {
                Navigator.pop(ctx);
                final combinedNote = '$selectedReason. ${noteController.text.trim()}';
                final messenger = ScaffoldMessenger.of(context);
                await grievanceProvider.flagImageForManualReview(
                  grievance.id,
                  note: combinedNote,
                  verificationStatus: 'flagged_manual_review',
                );
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.saffronPrimary,
                      content: Text('Complaint #${grievance.id} flagged for manual review.'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
