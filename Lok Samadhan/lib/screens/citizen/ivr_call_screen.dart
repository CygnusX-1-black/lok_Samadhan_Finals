import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/grievance.dart';
import '../../providers/grievance_provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/audio_wave_visualizer.dart';

class IvrCallScreen extends StatefulWidget {
  const IvrCallScreen({super.key});

  @override
  State<IvrCallScreen> createState() => _IvrCallScreenState();
}

class _IvrCallScreenState extends State<IvrCallScreen> {
  bool _isCallActive = false;
  int _callDurationSeconds = 0;
  Timer? _callTimer;
  String _ivrPromptText = 'Toll-Free Lok Samadhan IVR Gateway Ready (1800-724-2992)';
  String _enteredDtmfKeys = '';
  List<double> _ivrWave = List.generate(24, (i) => 0.1);
  Timer? _waveTimer;

  void _startCall() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isGuj = langProvider.isGujarati;
    setState(() {
      _isCallActive = true;
      _callDurationSeconds = 0;
      _enteredDtmfKeys = '';
      _ivrPromptText = isGuj
          ? 'નમસ્કાર! લોક સમાધાન પોર્ટલમાં આપનું સ્વાગત છે. અવાજ દ્વારા ફરિયાદ માટે 1 દબાવો, સ્થિતિ તપાસવા માટે 2 દબાવો, ગુજરાતી માટે 0 દબાવો.'
          : 'Namaskar! Lok Samadhan mein aapka swagat hai. Apni bhasha chunein ya bolkar shikayat darj karein. Press 1 for Voice Lodge, Press 2 for Status Check, Press 0 for Gujarati.';
    });

    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() => _callDurationSeconds++);
      }
    });

    _waveTimer?.cancel();
    _waveTimer = Timer.periodic(const Duration(milliseconds: 150), (t) {
      if (mounted && _isCallActive) {
        setState(() {
          _ivrWave = List.generate(24, (i) => 0.2 + (i % 5) * 0.15);
        });
      }
    });
  }

  void _endCall() {
    _callTimer?.cancel();
    _waveTimer?.cancel();
    setState(() {
      _isCallActive = false;
      _ivrPromptText = 'Call Ended. Total Call Duration: ${_callDurationSeconds}s.';
      _ivrWave = List.generate(24, (i) => 0.05);
    });
  }

  void _pressDtmfKey(String key) {
    if (!_isCallActive) return;
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    setState(() {
      _enteredDtmfKeys += key;
    });

    if (key == '1') {
      final isGuj = langProvider.isGujarati;
      setState(() {
        _ivrPromptText = isGuj
            ? 'તમે ફરિયાદ નોંધણી પસંદ કરી છે. બીપ પછી તમારી ફરિયાદ બોલો: "અમારા ગામમાં પીવાના પાણીની પાઇપલાઇન..."'
            : 'Aapne Grievance Lodging chuna hai. Beep ke baad apni shikayat bole: "Hamare gaon mein..."';
      });
    } else if (key == '2') {
      final grievanceProvider = Provider.of<GrievanceProvider>(context, listen: false);
      final sample = grievanceProvider.grievances.first;
      final isGuj = langProvider.isGujarati;
      setState(() {
        _ivrPromptText = isGuj
            ? 'ફરિયાદ સ્થિતિ ${sample.id}: આપની ફરિયાદ ${sample.departmentInfo.nameGu} માં છે. વર્તમાન સ્થિતિ: [${sample.status.labelGu}].'
            : 'Status Readback for ${sample.id}: Aapki shikayat ${sample.departmentInfo.nameHi} mein hai. Vartaman sthiti: [${sample.status.labelHi}].';
      });
    } else if (key == '0') {
      langProvider.setDialectById('gujarati');
      setState(() {
        _ivrPromptText = 'તમે ગુજરાતી ભાષા પસંદ કરી છે (Gujarati Selected). બીપ પછી તમારી ફરિયાદ બોલો અથવા ફરિયાદ નોંધવા 1 દબાવો.';
      });
    } else if (key == '4') {
      langProvider.setDialectById('hindi');
      setState(() {
        _ivrPromptText = 'आपने हिंदी भाषा चुनी है। बीप के बाद अपनी शिकायत बताएं या शिकायत दर्ज करने के लिए 1 दबाएं।';
      });
    } else if (key == '5') {
      langProvider.setDialectById('bhojpuri');
      setState(() {
        _ivrPromptText = 'रउआ भोजपुरी भाषा चुनले बानी। बीप के बाद आपन समस्या बताईं।';
      });
    } else if (key == '6') {
      langProvider.setDialectById('marwari');
      setState(() {
        _ivrPromptText = 'थां मारवाड़ी भाषा चुनी है। बीप रे बाद आपरी समस्या बताओ।';
      });
    } else if (key == '7') {
      langProvider.setDialectById('santali');
      setState(() {
        _ivrPromptText = 'ᱟᱢ ᱥᱟᱱᱛᱟᱲᱤ ᱯᱟᱹᱨᱥᱤ ᱮᱢ ᱵᱟᱪᱷᱟᱣ ᱠᱮᱫᱟ।';
      });
    } else if (key == '8') {
      langProvider.setDialectById('bengali');
      setState(() {
        _ivrPromptText = 'আপনি বাংলা ভাষা নির্বাচন করেছেন। বিপ এর পরে আপনার অভিযোগ বলুন।';
      });
    } else if (key == '9') {
      langProvider.setDialectById('tamil');
      setState(() {
        _ivrPromptText = 'நீங்கள் தமிழ் மொழியைத் தேர்ந்தெடுத்துள்ளீர்கள். பீப் ஒலிக்குப் பிறகு உங்கள் புகாரைக் கூறவும்.';
      });
    }
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _waveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Banner explanation
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone_in_talk_outlined, color: AppColors.saffronPrimary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Feature Phone Telephony Simulator (IVR Call)',
                        style: GoogleFonts.notoSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Simulates toll-free 1800 voice call experience for non-smartphone users.',
                        style: GoogleFonts.notoSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Phone Device Frame Simulation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.navyDark,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Toll free number header
                Text(
                  'TOLL FREE: 1800-SAMADHAN (1800-724292)',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.saffronLight,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),

                // Call state & duration
                Text(
                  _isCallActive
                      ? 'CALL IN PROGRESS • 00:${_callDurationSeconds.toString().padLeft(2, '0')}'
                      : 'READY TO DIAL',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _isCallActive ? AppColors.emeraldLight : Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),

                // IVR Audio Waveform
                AudioWaveVisualizer(
                  amplitudes: _ivrWave,
                  isRecording: _isCallActive,
                  barColor: AppColors.saffronLight,
                  height: 36,
                ),
                const SizedBox(height: 16),

                // Spoken IVR Prompt Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.record_voice_over, color: AppColors.saffronLight, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'IVR Voice Response (${languageProvider.selectedDialect.nameEnglish}):',
                            style: GoogleFonts.notoSans(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _ivrPromptText,
                        style: GoogleFonts.notoSans(
                          fontSize: 13,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                      if (_enteredDtmfKeys.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'DTMF Pressed: $_enteredDtmfKeys',
                          style: GoogleFonts.notoSans(
                            fontSize: 11,
                            color: AppColors.saffronLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Dialpad Grid (1-9, *, 0, #)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 1.6,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    _buildDialKey('1', 'Voice Lodge'),
                    _buildDialKey('2', 'Check Status'),
                    _buildDialKey('3', 'Agent Fallback'),
                    _buildDialKey('4', 'Hindi'),
                    _buildDialKey('5', 'Bhojpuri'),
                    _buildDialKey('6', 'Marwari'),
                    _buildDialKey('7', 'Santali'),
                    _buildDialKey('8', 'Bengali'),
                    _buildDialKey('9', 'Tamil'),
                    _buildDialKey('*', ''),
                    _buildDialKey('0', 'Gujarati'),
                    _buildDialKey('#', ''),
                  ],
                ),
                const SizedBox(height: 20),

                // Call / Hangup Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (!_isCallActive)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emeraldPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        ),
                        icon: const Icon(Icons.call, size: 20),
                        label: const Text('DIAL IVR (कॉल करें)'),
                        onPressed: _startCall,
                      )
                    else
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warningRed,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        ),
                        icon: const Icon(Icons.call_end, size: 20),
                        label: const Text('END CALL (कॉल समाप्त)'),
                        onPressed: _endCall,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialKey(String digit, String subtext) {
    return InkWell(
      onTap: () => _pressDtmfKey(digit),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              digit,
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            if (subtext.isNotEmpty)
              Text(
                subtext,
                style: GoogleFonts.notoSans(
                  fontSize: 9,
                  color: Colors.white60,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
