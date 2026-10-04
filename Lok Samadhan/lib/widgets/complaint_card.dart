import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/grievance.dart';
import '../theme/app_colors.dart';
import 'confidence_badge.dart';
import 'sla_countdown_badge.dart';

class ComplaintCard extends StatelessWidget {
  final Grievance grievance;
  final VoidCallback onTap;
  final Widget? trailingAction;
  final bool showConfidence;

  const ComplaintCard({
    super.key,
    required this.grievance,
    required this.onTap,
    this.trailingAction,
    this.showConfidence = false,
  });

  @override
  Widget build(BuildContext context) {
    final dept = grievance.departmentInfo;
    final timeStr = DateFormat('d MMM yyyy, h:mm a').format(grievance.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Dept Icon + Category Name + ID
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: dept.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(dept.icon, size: 20, color: dept.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dept.nameEn,
                          style: GoogleFonts.notoSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'ID: ${grievance.id} • ${grievance.spokenDialect}',
                          style: GoogleFonts.notoSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildStatusChip(grievance.status),
                ],
              ),
              const SizedBox(height: 10),

              // Attached Photo Thumbnail (If grievance has captured image)
              if (grievance.photoUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 150,
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
                                  child: Icon(Icons.broken_image, color: Colors.white54, size: 36),
                                ),
                              )
                            : Image.file(
                                File(grievance.photoUrl!),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Center(
                                  child: Icon(Icons.image, color: Colors.white54, size: 36),
                                ),
                              ),
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified, color: AppColors.emeraldPrimary, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  'GPS: ${grievance.latitude.toStringAsFixed(4)}° N, ${grievance.longitude.toStringAsFixed(4)}° E',
                                  style: GoogleFonts.notoSans(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Transcribed Speech / Photo Summary Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          grievance.photoUrl != null ? Icons.camera_alt_outlined : Icons.mic_none,
                          size: 14,
                          color: AppColors.saffronPrimary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            grievance.photoUrl != null
                                ? 'Description / AI Analysis:'
                                : 'Dialect Speech (${grievance.spokenDialect}):',
                            style: GoogleFonts.notoSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      grievance.translatedText.isNotEmpty
                          ? grievance.translatedText
                          : (grievance.photoAnalysisSummary ?? '"${grievance.rawSpeechText}"'),
                      style: GoogleFonts.notoSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Location + GPS Coordinates Row
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.emeraldPrimary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${grievance.villageWard}, ${grievance.district} (GPS: ${grievance.latitude.toStringAsFixed(2)}°, ${grievance.longitude.toStringAsFixed(2)}°)',
                      style: GoogleFonts.notoSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeStr,
                    style: GoogleFonts.notoSans(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Badges Row: Confidence Score (officers only) + SLA Countdown
              Row(
                children: [
                  if (showConfidence) ...[
                    ConfidenceBadge(
                      score: grievance.aiConfidenceScore,
                      isHitlRequired: grievance.isHitlFallback,
                      showToCitizen: false,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(child: SlaCountdownBadge(grievance: grievance)),
                  const Spacer(),
                  if (trailingAction != null) trailingAction!,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(GrievanceStatus status) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case GrievanceStatus.hitlReview:
        bg = AppColors.purpleHitlBg;
        fg = AppColors.purpleHitl;
        icon = Icons.psychology_outlined;
        break;
      case GrievanceStatus.received:
        bg = AppColors.navyDark.withOpacity(0.08);
        fg = AppColors.navyMedium;
        icon = Icons.inbox_outlined;
        break;
      case GrievanceStatus.underReview:
        bg = AppColors.amberOrangeBg;
        fg = AppColors.amberOrange;
        icon = Icons.manage_search_outlined;
        break;
      case GrievanceStatus.inProgress:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        icon = Icons.engineering_outlined;
        break;
      case GrievanceStatus.resolved:
        bg = AppColors.emeraldBackground;
        fg = AppColors.emeraldPrimary;
        icon = Icons.check_circle_outline;
        break;
      case GrievanceStatus.escalated:
        bg = AppColors.warningRedBg;
        fg = AppColors.warningRed;
        icon = Icons.error_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            status.labelEn,
            style: GoogleFonts.notoSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
