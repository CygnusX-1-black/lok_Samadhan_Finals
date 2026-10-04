import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/grievance.dart';
import '../../providers/grievance_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/audio_wave_visualizer.dart';
import '../../widgets/confidence_badge.dart';
import '../../widgets/sla_countdown_badge.dart';

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
    final createdStr = DateFormat('d MMMM yyyy, h:mm a').format(grievance.createdAt);

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
                          'Location: ${grievance.villageWard}, ${grievance.block}, ${grievance.district}, ${grievance.state}',
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

            // Captured Photo Card (If grievance has attached image)
            if (grievance.photoUrl != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.camera_alt, color: AppColors.saffronPrimary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Field Incident Photo & GPS Stamp',
                            style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 200,
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
                                    )
                                  : Image.file(
                                      File(grievance.photoUrl!),
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified, color: AppColors.emeraldPrimary, size: 13),
                                      const SizedBox(width: 4),
                                      Text(
                                        'GPS: Lat ${grievance.latitude.toStringAsFixed(4)}° N, Long ${grievance.longitude.toStringAsFixed(4)}° E',
                                        style: GoogleFonts.notoSans(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (grievance.photoAnalysisSummary != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'AI Vision Analysis & Description:',
                          style: GoogleFonts.notoSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                        ),
                        Text(
                          grievance.photoAnalysisSummary!,
                          style: GoogleFonts.notoSans(fontSize: 12.5, color: AppColors.textPrimary),
                        ),
                      ],
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
                        final timeStr = DateFormat('d MMM, h:mm a').format(step.timestamp);
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
}
