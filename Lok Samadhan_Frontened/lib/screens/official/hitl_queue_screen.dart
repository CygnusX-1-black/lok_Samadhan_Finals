import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/department.dart';
import '../../models/grievance.dart';
import '../../providers/grievance_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/audio_wave_visualizer.dart';

class HitlQueueScreen extends StatefulWidget {
  const HitlQueueScreen({super.key});

  @override
  State<HitlQueueScreen> createState() => _HitlQueueScreenState();
}

class _HitlQueueScreenState extends State<HitlQueueScreen> {
  DepartmentCategory? _correctedCategory;
  final TextEditingController _notesController = TextEditingController();
  bool _isPlayingAudio = false;

  @override
  Widget build(BuildContext context) {
    final grievanceProvider = Provider.of<GrievanceProvider>(context);
    final hitlQueue = grievanceProvider.hitlReviewQueue;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.purpleHitlBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.purpleHitl.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_outlined, color: AppColors.purpleHitl, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Human-in-the-Loop (HITL) Fallback Queue',
                        style: GoogleFonts.notoSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.purpleHitl,
                        ),
                      ),
                      Text(
                        'Safety net queue for speech inputs with < 85% AI confidence score.',
                        style: GoogleFonts.notoSans(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.purpleHitl,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${hitlQueue.length} Pending',
                    style: GoogleFonts.notoSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: hitlQueue.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified, size: 54, color: AppColors.emeraldPrimary),
                        const SizedBox(height: 12),
                        Text(
                          'No Low-Confidence Grievances Pending Review',
                          style: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'AI classification confidence is operating at 93.4% accuracy.',
                          style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: hitlQueue.length,
                    itemBuilder: (context, index) {
                      final g = hitlQueue[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Grievance ID: ${g.id} • ${g.spokenDialect}',
                                    style: GoogleFonts.notoSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.purpleHitl,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.purpleHitlBg,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.purpleHitl.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      'AI Score: ${(g.aiConfidenceScore * 100).toStringAsFixed(0)}%',
                                      style: GoogleFonts.notoSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.purpleHitl,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Audio Player Box
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.navyDark,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        _isPlayingAudio ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                        color: AppColors.saffronLight,
                                        size: 28,
                                      ),
                                      onPressed: () {
                                        setState(() => _isPlayingAudio = !_isPlayingAudio);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: AudioWaveVisualizer(
                                        amplitudes: _isPlayingAudio
                                            ? [0.3, 0.8, 0.5, 0.9, 0.4, 0.7, 0.9, 0.4, 0.6, 0.8]
                                            : List.generate(10, (i) => 0.1),
                                        isRecording: _isPlayingAudio,
                                        barColor: AppColors.saffronLight,
                                        height: 24,
                                      ),
                                    ),
                                    Text(
                                      '00:08 / 00:14',
                                      style: GoogleFonts.notoSans(fontSize: 10, color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              Text(
                                'Raw Transcribed Dialect Speech:',
                                style: GoogleFonts.notoSans(fontSize: 11, color: AppColors.textMuted),
                              ),
                              Text(
                                '"${g.rawSpeechText}"',
                                style: GoogleFonts.notoSans(fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'English Translation: ${g.translatedText}',
                                style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 12),

                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.purpleHitl,
                                ),
                                icon: const Icon(Icons.check_circle_outline, size: 16),
                                label: const Text('Review & Dispatch to Department'),
                                onPressed: () {
                                  _showReviewModal(context, g);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showReviewModal(BuildContext context, Grievance g) {
    final grievanceProvider = Provider.of<GrievanceProvider>(context, listen: false);
    _correctedCategory = g.departmentCategory;
    _notesController.text = 'Dialect audio verified by human officer. Confirmed department mapping.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HITL Verification: ${g.id}',
                    style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text('Verify dialect transcription and set correct nodal department.', style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.textSecondary)),
                  const Divider(height: 20),

                  Text('Select Target Department:', style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<DepartmentCategory>(
                    value: _correctedCategory,
                    items: DepartmentInfo.allDepartments.map((dept) {
                      return DropdownMenuItem(
                        value: dept.category,
                        child: Text('${dept.code} - ${dept.nameEn}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setModalState(() => _correctedCategory = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Human Reviewer Verification Notes',
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.emeraldPrimary),
                          child: const Text('Approve & Dispatch'),
                          onPressed: () {
                            grievanceProvider.resolveHitlQueueItem(
                              grievanceId: g.id,
                              approvedCategory: _correctedCategory ?? g.departmentCategory,
                              officerComment: _notesController.text,
                            );
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.emeraldPrimary,
                                content: Text('Grievance ${g.id} dispatched successfully!'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
