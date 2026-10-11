import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/department.dart';
import '../../providers/grievance_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/voice_engine_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/audio_wave_visualizer.dart';
import '../../widgets/confidence_badge.dart';
import '../../widgets/sms_notification_sheet.dart';
import '../../widgets/voice_readback_dialog.dart';
import '../../providers/rewards_provider.dart';
import '../../widgets/rewards/gc_reward_dialog.dart';

class VoiceLodgeScreen extends StatefulWidget {
  const VoiceLodgeScreen({super.key});

  @override
  State<VoiceLodgeScreen> createState() => _VoiceLodgeScreenState();
}

class _VoiceLodgeScreenState extends State<VoiceLodgeScreen> {
  bool _forceHitlTest = false;

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final voiceEngine = Provider.of<VoiceEngineProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);
    final selectedDialect = languageProvider.selectedDialect;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner: Voice First Banner
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageProvider.isGujarati ? 'બોલીને તમારી ફરિયાદ નોંધાવો' : 'बोलकर अपनी समस्या दर्ज करें',
                        style: GoogleFonts.notoSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-Time Live Voice ASR Engine • Speak in your language',
                        style: GoogleFonts.notoSans(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.sms_outlined, color: AppColors.saffronLight),
                  onPressed: () => SmsNotificationSheet.show(context),
                  tooltip: 'View SMS Notifications',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Mandatory App-Wide Real Location Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: locationProvider.isRealGpsAcquired ? AppColors.emeraldBackground : AppColors.amberOrangeBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: locationProvider.isRealGpsAcquired
                    ? AppColors.emeraldPrimary.withOpacity(0.3)
                    : AppColors.amberOrange.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  locationProvider.isRealGpsAcquired ? Icons.my_location : Icons.location_searching,
                  size: 18,
                  color: locationProvider.isRealGpsAcquired ? AppColors.emeraldPrimary : AppColors.amberOrange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    locationProvider.statusMessage,
                    style: GoogleFonts.notoSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16),
                  onPressed: () => locationProvider.fetchRealLocation(),
                  tooltip: 'Refresh Phone Location',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Step 1: Select Language / Dialect
          Row(
            children: [
              Expanded(
                child: Text(
                  languageProvider.isGujarati
                      ? '૧. તમારી ભાષા / બોલી પસંદ કરો (Select Dialect):'
                      : '1. अपनी भाषा / बोली चुनें (Select Dialect):',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'HITL Mode:',
                    style: GoogleFonts.notoSans(fontSize: 10, color: AppColors.textMuted),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _forceHitlTest,
                      activeColor: AppColors.purpleHitl,
                      onChanged: (val) => setState(() => _forceHitlTest = val),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Horizontal Dialects Scroll
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: LanguageProvider.availableDialects.length,
              separatorBuilder: (c, i) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final d = LanguageProvider.availableDialects[index];
                final isSelected = d.id == selectedDialect.id;

                return ChoiceChip(
                  avatar: Text(d.flagSymbol, style: const TextStyle(fontSize: 13)),
                  label: Text(d.nameNative),
                  selected: isSelected,
                  selectedColor: AppColors.saffronPrimary,
                  labelStyle: GoogleFonts.notoSans(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12.5,
                  ),
                  onSelected: (val) {
                    if (val) {
                      languageProvider.setDialect(d);
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Main Voice Recording Container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: voiceEngine.state == VoiceEngineState.recording
                    ? AppColors.saffronPrimary
                    : AppColors.cardBorder,
                width: voiceEngine.state == VoiceEngineState.recording ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Hint Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Speak in ${selectedDialect.nameEnglish}: "${selectedDialect.sampleAudioPhrase}"',
                          style: GoogleFonts.notoSans(
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Recording Status & Live Speech Wave Visualizer
                if (voiceEngine.state == VoiceEngineState.recording) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.warningRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LISTENING LIVE IN ${selectedDialect.nameNative.toUpperCase()}...',
                        style: GoogleFonts.notoSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.saffronPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '00:${voiceEngine.recordingSeconds.toString().padLeft(2, '0')} sec',
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AudioWaveVisualizer(
                    amplitudes: voiceEngine.waveAmplitudes,
                    isRecording: true,
                    height: 50,
                  ),
                  const SizedBox(height: 16),

                  // REAL-TIME LIVE SPOKEN SPEECH TRANSCRIPT BOX
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.navyDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.saffronLight.withOpacity(0.6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.record_voice_over, color: AppColors.saffronLight, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'REAL-TIME LIVE SPEECH TRANSCRIPT (आपकी आवाज़):',
                              style: GoogleFonts.notoSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.saffronLight,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          voiceEngine.liveSpokenWords.isNotEmpty
                              ? '"${voiceEngine.liveSpokenWords}"'
                              : 'Listening to your voice... Speak now in microphone.',
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontStyle: voiceEngine.liveSpokenWords.isEmpty ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else if (voiceEngine.state == VoiceEngineState.processingAIspeech) ...[
                  const CircularProgressIndicator(color: AppColors.saffronPrimary),
                  const SizedBox(height: 16),
                  Text(
                    'Processing Live Speech & Machine Translation...',
                    style: GoogleFonts.notoSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navyMedium,
                    ),
                  ),
                  Text(
                    'Categorizing Department via NLP Intent Classifier',
                    style: GoogleFonts.notoSans(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  Text(
                    'Tap microphone below & speak your complaint in ${selectedDialect.nameEnglish}',
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Big Mic Button
                GestureDetector(
                  onTap: () {
                    if (voiceEngine.state == VoiceEngineState.idle) {
                      locationProvider.fetchRealLocation();
                      voiceEngine.startRecording(selectedDialect.id);
                    } else if (voiceEngine.state == VoiceEngineState.recording) {
                      voiceEngine.stopRecordingAndProcess(
                        dialectId: selectedDialect.id,
                        forceLowConfidence: _forceHitlTest,
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: voiceEngine.state == VoiceEngineState.recording
                          ? AppColors.saffronPrimary
                          : AppColors.navyDark,
                      boxShadow: [
                        BoxShadow(
                          color: (voiceEngine.state == VoiceEngineState.recording
                                  ? AppColors.saffronPrimary
                                  : AppColors.navyDark)
                              .withOpacity(0.35),
                          blurRadius: 16,
                          spreadRadius: voiceEngine.state == VoiceEngineState.recording ? 6 : 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      voiceEngine.state == VoiceEngineState.recording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  voiceEngine.state == VoiceEngineState.recording
                      ? 'TAP TO STOP RECORDING (माइक बंद करें)'
                      : 'TAP TO SPEAK (बोलें)',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Processed AI Result & Confirmation Card
          if (voiceEngine.state == VoiceEngineState.processedSuccess && voiceEngine.lastResult != null) ...[
            const SizedBox(height: 24),
            _buildAiExtractionCard(context, voiceEngine.lastResult!, selectedDialect.nameNative),
          ],
        ],
      ),
    );
  }

  Widget _buildAiExtractionCard(
    BuildContext context,
    RecognizedSpeechResult result,
    String dialectName,
  ) {
    final dept = DepartmentInfo.getByCategory(result.category);
    final voiceEngine = Provider.of<VoiceEngineProvider>(context, listen: false);
    final grievanceProvider = Provider.of<GrievanceProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    return Card(
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
                    const Icon(Icons.auto_awesome, color: AppColors.saffronPrimary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'AI Speech & Intent Processing',
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                ConfidenceBadge(
                  score: result.confidenceScore,
                  isHitlRequired: result.isHitlRequired,
                  showToCitizen: false,
                ),
              ],
            ),
            const Divider(height: 20),

            // Transcribed Dialect Text
            Text(
              'Recognized Real-Time Speech ($dialectName):',
              style: GoogleFonts.notoSans(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 2),
            Text(
              '"${result.rawSpeechText}"',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // Machine Translation
            Text(
              'English Machine Translation:',
              style: GoogleFonts.notoSans(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 2),
            Text(
              result.translatedEnglishText,
              style: GoogleFonts.notoSans(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),

            // Mapped Department Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: dept.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: dept.color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(dept.icon, color: dept.color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-Routed Department:',
                          style: GoogleFonts.notoSans(fontSize: 10.5, color: AppColors.textMuted),
                        ),
                        Text(
                          dept.nameEn,
                          style: GoogleFonts.notoSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Real GPS: ${locationProvider.statusMessage}',
                          style: GoogleFonts.notoSans(fontSize: 11, color: dept.color, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Try Again'),
                    onPressed: () => voiceEngine.resetEngine(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(languageProvider.isGujarati ? 'સબમિટ કરો (પુષ્ટિ)' : 'Submit (पुष्टि करें)'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => VoiceReadbackDialog(
                          result: result,
                          dialectName: dialectName,
                          onConfirm: (name, phone) async {
                            final gpsResult = await locationProvider.acquireFreshGps(context: context);
                            final lat = gpsResult.latitude ?? locationProvider.latitude;
                            final lon = gpsResult.longitude ?? locationProvider.longitude;
                            final acc = gpsResult.accuracy ?? locationProvider.accuracy;
                            final capAt = gpsResult.capturedAt ?? locationProvider.capturedAt ?? DateTime.now().toUtc();

                            final grievance = grievanceProvider.lodgeNewVoiceGrievance(
                              aiResult: result,
                              citizenName: name,
                              citizenPhone: phone,
                              dialectName: dialectName,
                              latitude: lat,
                              longitude: lon,
                              gpsAccuracyM: acc,
                              locationCapturedAt: capAt,
                            );
                            voiceEngine.resetEngine();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.emeraldPrimary,
                                content: Text(
                                  'Voice Grievance ${grievance.id} lodged with real GPS! Track via SMS.',
                                  style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ),
                            );

                            // Award Grievance Coin for eligible complaint submission
                            final rewardsProvider = Provider.of<RewardsProvider>(context, listen: false);
                            final award = await rewardsProvider.awardEligibleComplaint(
                              grievance.id,
                              description: 'Eligible Voice Complaint #${grievance.id}',
                            );
                            if (context.mounted) {
                              if (award.success) {
                                GcRewardDialog.show(context, award);
                              } else if (award.alreadyAwarded) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(award.message.isNotEmpty
                                        ? award.message
                                        : 'Complaint #${grievance.id} has already been awarded coins.'),
                                    backgroundColor: Colors.amber.shade800,
                                  ),
                                );
                              }
                            }
                          },
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
  }
}
