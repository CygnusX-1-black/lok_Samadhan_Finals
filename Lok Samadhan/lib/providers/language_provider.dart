import 'package:flutter/material.dart';

class DialectOption {
  final String id;
  final String nameNative;
  final String nameEnglish;
  final String region;
  final String sampleAudioPhrase;
  final String flagSymbol;

  const DialectOption({
    required this.id,
    required this.nameNative,
    required this.nameEnglish,
    required this.region,
    required this.sampleAudioPhrase,
    required this.flagSymbol,
  });
}

class LanguageProvider with ChangeNotifier {
  static const List<DialectOption> availableDialects = [
    DialectOption(
      id: 'bhojpuri',
      nameNative: 'भोजपुरी (Bhojpuri)',
      nameEnglish: 'Bhojpuri',
      region: 'Bihar / Eastern UP',
      sampleAudioPhrase: 'हमार टोला के चापाकल दु हफ्ता से बिगड़ल बा, पानी ना आवत बा।',
      flagSymbol: '🏛️',
    ),
    DialectOption(
      id: 'marwari',
      nameNative: 'मारवाड़ी (Marwari)',
      nameEnglish: 'Marwari',
      region: 'Rajasthan',
      sampleAudioPhrase: 'म्हारा गांव रो हैण्डपम्प दो हफ्ता स्यूं खराब है, पाणी कोनी आवे।',
      flagSymbol: '🐪',
    ),
    DialectOption(
      id: 'hindi',
      nameNative: 'हिंदी (Hindi)',
      nameEnglish: 'Hindi',
      region: 'North & Central India',
      sampleAudioPhrase: 'हमारे गांव का हैंडपंप 2 हफ्ते से खराब है, पीने का पानी नहीं आ रहा है।',
      flagSymbol: '🇮🇳',
    ),
    DialectOption(
      id: 'gujarati',
      nameNative: 'ગુજરાતી (Gujarati)',
      nameEnglish: 'Gujarati',
      region: 'Gujarat',
      sampleAudioPhrase: 'અમારા ગામમાં પીવાના પાણીની પાઇપલાઇન તૂટી ગઈ છે, ૨ અઠવાડિયાથી પાણી નથી આવતું.',
      flagSymbol: '🦁',
    ),
    DialectOption(
      id: 'santali',
      nameNative: 'ᱥᱟᱱᱛᱟᱲᱤ (Santali)',
      nameEnglish: 'Santali',
      region: 'Jharkhand / Odisha / WB',
      sampleAudioPhrase: 'ᱟᱞᱮ ᱟᱛᱳ ᱨᱮᱱᱟᱜ ᱫᱟ elements ᱦᱮᱸᱰᱯᱟᱢᱯ ᱵᱟᱹᱲᱤᱡ ᱟᱠᱟᱱᱟ।',
      flagSymbol: '🏹',
    ),
    DialectOption(
      id: 'bengali',
      nameNative: 'বাংলা (Bengali)',
      nameEnglish: 'Bengali',
      region: 'West Bengal / Tripura',
      sampleAudioPhrase: 'আমাদের গ্রামের কল ২ সপ্তাহ ধরে খারাপ, পানীয় জল পাওয়া যাচ্ছে না।',
      flagSymbol: '🌊',
    ),
    DialectOption(
      id: 'tamil',
      nameNative: 'தமிழ் (Tamil)',
      nameEnglish: 'Tamil',
      region: 'Tamil Nadu / Puducherry',
      sampleAudioPhrase: 'எங்கள் கிராமத்தில் குடிநீர் கைபம்ப் 2 வாரமாக பழுதாகி உள்ளது.',
      flagSymbol: '🌴',
    ),
    DialectOption(
      id: 'marathi',
      nameNative: 'मराठी (Marathi)',
      nameEnglish: 'Marathi',
      region: 'Maharashtra',
      sampleAudioPhrase: 'आमच्या गावातील हातपंप २ आठवड्यांपासून बंद आहे, पिण्याचे पाणी नाही.',
      flagSymbol: '🚩',
    ),
    DialectOption(
      id: 'english',
      nameNative: 'English (Indian)',
      nameEnglish: 'English',
      region: 'Pan-India',
      sampleAudioPhrase: 'Our village handpump has been broken for 2 weeks, no drinking water.',
      flagSymbol: '🌐',
    ),
  ];

  DialectOption _selectedDialect = availableDialects.first; // Default dialect

  DialectOption get selectedDialect => _selectedDialect;
  bool get isGujarati => _selectedDialect.id == 'gujarati';
  bool get isHindi => _selectedDialect.id == 'hindi';

  void setDialect(DialectOption dialect) {
    _selectedDialect = dialect;
    notifyListeners();
  }

  void setDialectById(String id) {
    _selectedDialect = availableDialects.firstWhere(
      (d) => d.id == id,
      orElse: () => availableDialects.first,
    );
    notifyListeners();
  }

  /// Maps dialect to SpeechToText recognition locale ID
  static String getSpeechLocale(String dialectId) {
    switch (dialectId) {
      case 'gujarati':
        return 'gu_IN';
      case 'hindi':
      case 'bhojpuri':
      case 'marwari':
        return 'hi_IN';
      case 'bengali':
        return 'bn_IN';
      case 'tamil':
        return 'ta_IN';
      case 'marathi':
        return 'mr_IN';
      case 'santali':
        return 'sat_IN';
      case 'english':
      default:
        return 'en_IN';
    }
  }

  /// Helper for reactive text localization
  String localize({
    required String en,
    String? hi,
    String? gu,
  }) {
    if (isGujarati && gu != null) return gu;
    if (isHindi && hi != null) return hi;
    return hi ?? en;
  }
}
