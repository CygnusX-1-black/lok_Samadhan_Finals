import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/department.dart';
import '../models/grievance.dart';
import '../providers/voice_engine_provider.dart';
import '../theme/app_colors.dart';
import 'audio_wave_visualizer.dart';
import 'confidence_badge.dart';

class VoiceReadbackDialog extends StatefulWidget {
  final RecognizedSpeechResult result;
  final String dialectName;
  final Function(String citizenName, String citizenPhone) onConfirm;

  const VoiceReadbackDialog({
    super.key,
    required this.result,
    required this.dialectName,
    required this.onConfirm,
  });

  @override
  State<VoiceReadbackDialog> createState() => _VoiceReadbackDialogState();
}

class _VoiceReadbackDialogState extends State<VoiceReadbackDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  bool _isPlayingAudioReadback = false;

  @override
  void initState() {
    super.initState();
    final isGuj = widget.dialectName.toLowerCase().contains('gujarati') || widget.dialectName.contains('ગુજરાતી');
    _nameController = TextEditingController(text: isGuj ? 'Hasmukhbhai Patel' : 'Rameshwar Mahato');
    _phoneController = TextEditingController(text: isGuj ? '+91 98250 12345' : '+91 98351 44102');
    _startTtsPlayback();
  }

  void _startTtsPlayback() {
    setState(() => _isPlayingAudioReadback = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isPlayingAudioReadback = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dept = DepartmentInfo.getByCategory(widget.result.category);
    final isGuj = widget.dialectName.toLowerCase().contains('gujarati') || widget.dialectName.contains('ગુજરાતી');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Tag: Confirmation Readback
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.saffronBackground,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volume_up_outlined, color: AppColors.saffronPrimary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGuj ? 'ફરિયાદ પુષ્ટિ (Confirmation Readback)' : 'शिकायत पुष्टि (Confirmation Readback)',
                          style: GoogleFonts.notoSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'AI Synthesized Voice Read-back',
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Audio Visualizer Readback Wave
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.navyDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isPlayingAudioReadback ? Icons.graphic_eq : Icons.check_circle_outline,
                          color: AppColors.saffronLight,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isPlayingAudioReadback
                                ? (isGuj
                                    ? 'Speaking in ${widget.dialectName}: "તમારી ફરિયાદ ${dept.nameGu} માં નોંધવામાં આવી રહી છે..."'
                                    : 'Speaking in ${widget.dialectName}: "Aapki shikayat ${dept.nameHi} mein darj ki ja rahi hai..."')
                                : (isGuj ? 'અવાજ પઠન પૂર્ણ થયું (Voice prompt readback completed).' : 'Voice prompt readback completed.'),
                            style: GoogleFonts.notoSans(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AudioWaveVisualizer(
                      amplitudes: _isPlayingAudioReadback
                          ? [0.3, 0.7, 0.4, 0.9, 0.6, 0.8, 0.3, 0.9, 0.5, 0.8, 0.4, 0.7, 0.5, 0.9, 0.6, 0.3]
                          : List.generate(16, (i) => 0.1),
                      isRecording: _isPlayingAudioReadback,
                      barColor: AppColors.saffronLight,
                      height: 28,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Extracted NLP Summary Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'NLP Extracted Metadata',
                          style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                        ),
                        ConfidenceBadge(
                          score: widget.result.confidenceScore,
                          isHitlRequired: widget.result.isHitlRequired,
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    _buildMetaItem('Department / विभाग', '${dept.nameEn}\n(${dept.nameHi})', dept.icon, dept.color),
                    const SizedBox(height: 8),
                    _buildMetaItem('Location / स्थान', widget.result.villageWard, Icons.location_on_outlined, AppColors.navyMedium),
                    const SizedBox(height: 8),
                    _buildMetaItem('Urgency / प्राथमिकता', widget.result.urgency.labelEn, Icons.priority_high, AppColors.warningRed),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Optional Citizen Details
              Text(
                'Citizen Information (Caller ID)',
                style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Caller Name (Optional)',
                  prefixIcon: Icon(Icons.person_outline, size: 18),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (for SMS Tracking)',
                  prefixIcon: Icon(Icons.phone_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Re-record'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.saffronPrimary,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onConfirm(_nameController.text, _phoneController.text);
                      },
                      child: Text(isGuj ? 'Confirm (હા / પુષ્ટિ)' : 'Confirm (हाँ)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItem(String label, String value, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.notoSans(fontSize: 10.5, color: AppColors.textMuted)),
              Text(value, style: GoogleFonts.notoSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
