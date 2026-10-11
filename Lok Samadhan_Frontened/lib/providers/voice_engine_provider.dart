import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../models/department.dart';
import '../models/grievance.dart';
import '../services/api_service.dart';
import 'language_provider.dart';

enum VoiceEngineState {
  idle,
  recording,
  processingAIspeech,
  processedSuccess,
  error,
}

class RecognizedSpeechResult {
  final String rawSpeechText;
  final String translatedEnglishText;
  final DepartmentCategory category;
  final String villageWard;
  final String block;
  final String district;
  final String state;
  final UrgencyLevel urgency;
  final double confidenceScore;
  final bool isHitlRequired;

  RecognizedSpeechResult({
    required this.rawSpeechText,
    required this.translatedEnglishText,
    required this.category,
    required this.villageWard,
    required this.block,
    required this.district,
    required this.state,
    required this.urgency,
    required this.confidenceScore,
    required this.isHitlRequired,
  });
}

class VoiceEngineProvider with ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();

  VoiceEngineState _state = VoiceEngineState.idle;
  List<double> _waveAmplitudes = List.generate(24, (index) => 0.1);
  Timer? _waveTimer;
  Timer? _processingTimer;

  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  String _liveSpokenWords = '';
  bool _isSpeechInitialized = false;
  bool _isListeningRealTime = false;

  RecognizedSpeechResult? _lastResult;
  bool _isSpeakingTts = false;

  VoiceEngineProvider() {
    _initSpeechToText();
  }

  VoiceEngineState get state => _state;
  List<double> get waveAmplitudes => _waveAmplitudes;
  int get recordingSeconds => _recordingSeconds;
  String get liveSpokenWords => _liveSpokenWords;
  bool get isListeningRealTime => _isListeningRealTime;
  RecognizedSpeechResult? get lastResult => _lastResult;
  bool get isSpeakingTts => _isSpeakingTts;

  Future<void> _initSpeechToText() async {
    try {
      _isSpeechInitialized = await _speechToText.initialize(
        onError: (val) => debugPrint('SpeechToText error: $val'),
        onStatus: (val) => debugPrint('SpeechToText status: $val'),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('SpeechToText init error: $e');
    }
  }

  Future<void> startRecording(String dialectId) async {
    _state = VoiceEngineState.recording;
    _recordingSeconds = 0;
    _liveSpokenWords = '';
    _lastResult = null;
    notifyListeners();

    // Start timer & audio visualizer waves
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _recordingSeconds++;
      notifyListeners();
    });

    _waveTimer?.cancel();
    final random = Random();
    _waveTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      _waveAmplitudes = List.generate(24, (index) => 0.2 + random.nextDouble() * 0.8);
      notifyListeners();
    });

    // Launch Real-Time Speech Recognition via microphone
    try {
      if (!_isSpeechInitialized) {
        _isSpeechInitialized = await _speechToText.initialize();
      }

      if (_isSpeechInitialized) {
        _isListeningRealTime = true;
        final speechLocale = LanguageProvider.getSpeechLocale(dialectId);
        await _speechToText.listen(
          onResult: (result) {
            _liveSpokenWords = result.recognizedWords;
            notifyListeners();
          },
          listenFor: const Duration(seconds: 40),
          pauseFor: const Duration(seconds: 4),
          localeId: speechLocale,
          partialResults: true,
          cancelOnError: false,
        );
      }
    } catch (e) {
      debugPrint('Live microphone speech listen error: $e');
    }
  }

  Future<void> stopRecordingAndProcess({
    required String dialectId,
    bool forceLowConfidence = false,
  }) async {
    _recordingTimer?.cancel();
    _waveTimer?.cancel();
    _waveAmplitudes = List.generate(24, (index) => 0.05);

    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
    } catch (e) {
      debugPrint('Stop speech error: $e');
    }
    _isListeningRealTime = false;

    _state = VoiceEngineState.processingAIspeech;
    notifyListeners();

    _processingTimer?.cancel();
    _processingTimer = Timer(const Duration(milliseconds: 600), () async {
      final hasRealText = _liveSpokenWords.trim().isNotEmpty;
      final speechToAnalyze = hasRealText ? _liveSpokenWords.trim() : _getFallbackTextForDialect(dialectId);

      // Call Gemma 4 / Gemini API via backend
      try {
        final aiMap = await ApiService().classifyGrievance(speechToAnalyze);
        if (aiMap != null && aiMap['departmentCategory'] != null) {
          final cat = parseDepartmentCategory(aiMap['departmentCategory']?.toString());
          final urgency = parseUrgencyLevel(aiMap['urgency']?.toString());
          final conf = (aiMap['confidenceScore'] as num?)?.toDouble() ?? 0.95;
          final isHitl = aiMap['isHitlRequired'] == true || forceLowConfidence || conf < 0.85;
          final loc = (aiMap['extractedLocation'] is Map)
              ? Map<String, dynamic>.from(aiMap['extractedLocation'])
              : null;

          _lastResult = RecognizedSpeechResult(
            rawSpeechText: speechToAnalyze,
            translatedEnglishText: aiMap['translatedText']?.toString() ?? speechToAnalyze,
            category: cat,
            villageWard: loc?['villageWard']?.toString() ?? 'Local Ward',
            block: loc?['block']?.toString() ?? 'Local Block',
            district: loc?['district']?.toString() ?? 'Ahmedabad',
            state: loc?['state']?.toString() ?? 'Gujarat',
            urgency: urgency,
            confidenceScore: forceLowConfidence ? 0.62 : conf,
            isHitlRequired: isHitl,
          );
          _state = VoiceEngineState.processedSuccess;
          notifyListeners();
          return;
        }
      } catch (e) {
        debugPrint('[VoiceEngineProvider] Backend Gemma AI error: $e');
      }

      // Local rule-based fallback
      _lastResult = _processRealOrSampleSpeech(dialectId, _liveSpokenWords, forceLowConfidence);
      _state = VoiceEngineState.processedSuccess;
      notifyListeners();
    });
  }

  void resetEngine() {
    _recordingTimer?.cancel();
    _waveTimer?.cancel();
    _processingTimer?.cancel();
    if (_speechToText.isListening) {
      _speechToText.stop();
    }
    _state = VoiceEngineState.idle;
    _recordingSeconds = 0;
    _liveSpokenWords = '';
    _lastResult = null;
    _isSpeakingTts = false;
    _waveAmplitudes = List.generate(24, (index) => 0.1);
    notifyListeners();
  }

  void simulateTtsReadback(VoidCallback onComplete) {
    _isSpeakingTts = true;
    notifyListeners();

    Timer(const Duration(seconds: 3), () {
      _isSpeakingTts = false;
      notifyListeners();
      onComplete();
    });
  }

  RecognizedSpeechResult _processRealOrSampleSpeech(String dialectId, String realSpeech, bool forceLowConfidence) {
    final hasRealText = realSpeech.trim().isNotEmpty;
    final finalSpeechText = hasRealText ? realSpeech.trim() : _getFallbackTextForDialect(dialectId);

    // AI Intent Classifier & Nodal Office Mapper
    final lower = finalSpeechText.toLowerCase();

    DepartmentCategory category = DepartmentCategory.electricity;
    String englishTrans = 'Reported grievance regarding $finalSpeechText.';

    if (lower.contains('water') ||
        lower.contains('pani') ||
        lower.contains('पाइप') ||
        lower.contains('पानी') ||
        lower.contains('चापाकल') ||
        lower.contains('પાણી') ||
        lower.contains('નળ') ||
        lower.contains('પાઇપ') ||
        lower.contains('હેન્ડપંપ') ||
        lower.contains('બોરવેલ')) {
      category = DepartmentCategory.waterSupply;
      englishTrans = 'Grievance regarding drinking water pipeline/handpump issue: "$finalSpeechText"';
    } else if (lower.contains('road') ||
        lower.contains('sadak') ||
        lower.contains('सड़क') ||
        lower.contains('पॉटहोल') ||
        lower.contains('रास्ता') ||
        lower.contains('રસ્તો') ||
        lower.contains('માર્ગ') ||
        lower.contains('ખાડો') ||
        lower.contains('ખાડા') ||
        lower.contains('પુલ') ||
        lower.contains('રોડ')) {
      category = DepartmentCategory.roadsInfrastructure;
      englishTrans = 'Grievance regarding road pavement damage/pothole: "$finalSpeechText"';
    } else if (lower.contains('ration') ||
        lower.contains('dealer') ||
        lower.contains('राशन') ||
        lower.contains('डीलर') ||
        lower.contains('રાશન') ||
        lower.contains('અનાજ') ||
        lower.contains('સસ્તા અનાજ') ||
        lower.contains('દુકાનદાર')) {
      category = DepartmentCategory.pdsRation;
      englishTrans = 'Grievance regarding PDS grain quota / ration dealer: "$finalSpeechText"';
    } else if (lower.contains('light') ||
        lower.contains('bijli') ||
        lower.contains('बिजली') ||
        lower.contains('तार') ||
        lower.contains('ट्रांसफॉर्मर') ||
        lower.contains('વીજળી') ||
        lower.contains('લાઈટ') ||
        lower.contains('વાયર') ||
        lower.contains('થાંભલો') ||
        lower.contains('કરંટ') ||
        lower.contains('ટ્રાન્સફોર્મર')) {
      category = DepartmentCategory.electricity;
      englishTrans = 'Grievance regarding power supply outage/transformer hazard: "$finalSpeechText"';
    } else if (lower.contains('कचरा') ||
        lower.contains('सफाई') ||
        lower.contains('નાલી') ||
        lower.contains('કચરો') ||
        lower.contains('ગટર') ||
        lower.contains('ગંદકી') ||
        lower.contains('સફાઈ') ||
        lower.contains('નાળું')) {
      category = DepartmentCategory.sanitationHealth;
      englishTrans = 'Grievance regarding public health and sanitation: "$finalSpeechText"';
    } else {
      category = DepartmentCategory.generalPanchayat;
      englishTrans = 'Grievance registered via live voice input: "$finalSpeechText"';
    }

    final isGujarati = dialectId == 'gujarati' ||
        lower.contains('પાણી') ||
        lower.contains('રસ્તો') ||
        lower.contains('વીજળી') ||
        lower.contains('અમારા');

    return RecognizedSpeechResult(
      rawSpeechText: finalSpeechText,
      translatedEnglishText: englishTrans,
      category: category,
      villageWard: isGujarati ? 'Sanand Village, Ward 3' : 'Live Citizen Location',
      block: isGujarati ? 'Sanand Taluka' : 'Local Sadar Block',
      district: isGujarati ? 'Ahmedabad' : 'Bhojpur',
      state: isGujarati ? 'Gujarat' : 'Bihar',
      urgency: UrgencyLevel.high,
      confidenceScore: forceLowConfidence ? 0.68 : (hasRealText ? 0.98 : 0.92),
      isHitlRequired: forceLowConfidence ? true : false,
    );
  }

  String _getFallbackTextForDialect(String dialectId) {
    switch (dialectId) {
      case 'gujarati':
        return 'અમારા ગામમાં પીવાના પાણીની પાઇપલાઇન તૂટી ગઈ છે, ૨ અઠવાડિયાથી પાણી નથી આવતું. સાણંદ તાલુકો, અમદાવાદ.';
      case 'bhojpuri':
        return 'हमार टोला के चापाकल दु हफ्ता से बिगड़ल बा, पीने के पानी ना आवत बा। रामपुर वार्ड 4।';
      case 'marwari':
        return 'म्हारा गांव रो हैण्डपम्प दो हफ्ता स्यूं खराब है, पाणी कोनी आवे। बीकानेर।';
      case 'bengali':
        return 'আমাদের গ্রামের মেইন রোডের ইলেকট্রিক ট্রান্সফর্মার পুড়ে গেছে, ৩ দিন ধরে কারেন্ট নেই।';
      case 'tamil':
        return 'எங்கள் கிராமத்து பிரதான சாலையில் பெரிய பள்ளம் உள்ளது, மழை நீரால் போக்குவரத்து பாதிப்பு.';
      default:
        return 'हमारे गांव में बिजली का तार टूट कर सड़क पर गिरा हुआ है, तुरंत ठीक करें। ब्लॉक सदर।';
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _waveTimer?.cancel();
    _processingTimer?.cancel();
    if (_speechToText.isListening) {
      _speechToText.stop();
    }
    super.dispose();
  }
}
