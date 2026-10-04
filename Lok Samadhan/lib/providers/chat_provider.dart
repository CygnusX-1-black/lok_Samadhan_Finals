import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/department.dart';
import '../models/grievance.dart';
import 'grievance_provider.dart';
import 'location_provider.dart';

class ChatProvider with ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  DraftGrievance? _activeDraft;

  ChatProvider() {
    _initWelcomeConversation();
  }

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;
  DraftGrievance? get activeDraft => _activeDraft;

  void _initWelcomeConversation() {
    _messages.clear();
    _activeDraft = null;
    _isTyping = false;

    _messages.add(
      ChatMessage(
        id: 'welcome-1',
        text: 'Namaskar! 🙏 I am your Lok Samadhan AI Grievance Assistant.\n\n'
            'You can describe any civic issue (drinking water, electricity, broken roads, ration, sanitation, safety) '
            'in Gujarati (ગુજરાતી), Hindi, English, or any local dialect. I will automatically identify the right department, assign standard SLA, and track it with real GPS.',
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
        quickChips: const [
          '💧 Drinking Water Handpump (પીવાનું પાણી)',
          '⚡ Power Outage / Wire Spark (વીજળી)',
          '🛣️ Broken Road & Potholes (રસ્તો/ખાડા)',
          '🌾 Ration Card / Dealer Issue (રાશન)',
          '🗑️ Waste & Drain Clogged (કચરો/ગટર)',
          '🔍 Track Existing Complaint (સ્થિતિ)',
        ],
      ),
    );
  }

  void resetConversation() {
    _initWelcomeConversation();
    notifyListeners();
  }

  Future<void> sendMessage(
    String text, {
    required GrievanceProvider grievanceProvider,
    required LocationProvider locationProvider,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    // 1. Add user message
    _messages.add(
      ChatMessage(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        text: cleanText,
        sender: MessageSender.user,
        timestamp: DateTime.now(),
      ),
    );
    _isTyping = true;
    notifyListeners();

    // 2. Simulate AI NLP processing delay
    await Future.delayed(const Duration(milliseconds: 700));

    // 3. Check for specific user actions / intents
    final lower = cleanText.toLowerCase();

    // Action A: User clicks or types "Confirm & Lodge"
    if (lower.contains('confirm') || lower.contains('पुष्टि') || lower.contains('મંજૂર') || lower.contains('પુષ્ટિ') || lower == '✅ confirm & lodge') {
      if (_activeDraft != null) {
        await confirmAndLodge(
          grievanceProvider: grievanceProvider,
          locationProvider: locationProvider,
        );
        return;
      }
    }

    // Action B: User cancels active draft
    if (lower.contains('cancel') || lower.contains('रद्द') || lower.contains('રદ્દ') || lower == '❌ cancel') {
      _activeDraft = null;
      _isTyping = false;
      _messages.add(
        ChatMessage(
          id: 'bot-${DateTime.now().millisecondsSinceEpoch}',
          text: 'Complaint draft cancelled. How else can I help you? You can describe any other problem or check status.',
          sender: MessageSender.bot,
          timestamp: DateTime.now(),
          quickChips: const [
            '💧 Water Issue',
            '⚡ Electricity Issue',
            '🛣️ Road Issue',
            '🔍 Check Status',
          ],
        ),
      );
      notifyListeners();
      return;
    }

    // Action C: Check / Track Existing Complaint
    final ticketRegex = RegExp(r'(LS|SV)-\d{4}-\d{5}', caseSensitive: false);
    final match = ticketRegex.firstMatch(cleanText);

    if (match != null || lower.contains('track') || lower.contains('status') || lower.contains('स्थिति') || lower.contains('સ્થિતિ')) {
      final ticketId = match?.group(0)?.toUpperCase();

      if (ticketId != null) {
        final g = grievanceProvider.getGrievanceById(ticketId);
        _isTyping = false;

        if (g != null) {
          final dept = g.departmentInfo;
          _messages.add(
            ChatMessage(
              id: 'bot-${DateTime.now().millisecondsSinceEpoch}',
              text: '📋 **Complaint Status Found for $ticketId**:\n\n'
                  '• **Department**: ${dept.nameEn} (${dept.nameHi})\n'
                  '• **Current Status**: [${g.status.labelEn} / ${g.status.labelHi}]\n'
                  '• **Reported Issue**: "${g.rawSpeechText}"\n'
                  '• **Location**: ${g.villageWard}, ${g.district}\n'
                  '• **SLA Window**: ${g.isSlaBreached ? "⚠️ SLA Breached (Auto-Escalated)" : "${g.remainingSlaDuration.inHours} hours remaining"}\n'
                  '• **Latest Action**: ${g.auditLog.isNotEmpty ? g.auditLog.last.statusLabel : "Under review"}',
              sender: MessageSender.bot,
              timestamp: DateTime.now(),
              quickChips: const [
                '➕ Lodge New Complaint',
                '💧 Water Issue',
                '⚡ Electricity Issue',
              ],
            ),
          );
        } else {
          _messages.add(
            ChatMessage(
              id: 'bot-${DateTime.now().millisecondsSinceEpoch}',
              text: '🔍 Complaint ID **$ticketId** was not found in the local registry. Please verify the ID number or search under the "Track Status" tab.',
              sender: MessageSender.bot,
              timestamp: DateTime.now(),
              quickChips: const [
                '➕ Lodge New Complaint',
                '🔍 Try Another ID',
              ],
            ),
          );
        }
        notifyListeners();
        return;
      } else if (lower.contains('track') || lower.contains('status') || lower.contains('स्थिति')) {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            id: 'bot-${DateTime.now().millisecondsSinceEpoch}',
            text: 'To check your complaint status, please send your Complaint ID (e.g. `LS-2026-89412`), or tap "Track Status" in the bottom menu.',
            sender: MessageSender.bot,
            timestamp: DateTime.now(),
            quickChips: const [
              'LS-2026-89412',
              'LS-2026-99201',
              '➕ Lodge New Complaint',
            ],
          ),
        );
        notifyListeners();
        return;
      }
    }

    // Action D: Process complaint via Multi-Lingual NLP Classifier
    final draft = _classifyGrievanceFromText(cleanText, locationProvider);
    _activeDraft = draft;
    _isTyping = false;

    _messages.add(
      ChatMessage(
        id: 'bot-${DateTime.now().millisecondsSinceEpoch}',
        text: 'I have analyzed your complaint and auto-routed it to **${draft.departmentInfo.nameEn}**.\n\n'
            'Please review the drafted complaint details below and tap **Confirm & Lodge** to submit it with verified GPS.',
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
        draftGrievance: draft,
        quickChips: const [
          '✅ Confirm & Lodge',
          '❌ Cancel',
        ],
      ),
    );
    notifyListeners();
  }

  Future<Grievance?> confirmAndLodge({
    required GrievanceProvider grievanceProvider,
    required LocationProvider locationProvider,
  }) async {
    if (_activeDraft == null) return null;

    final draft = _activeDraft!;
    _isTyping = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final lat = locationProvider.latitude ?? 25.5941;
    final lng = locationProvider.longitude ?? 85.1376;

    final newGrievance = grievanceProvider.lodgeChatGrievance(
      problemTitle: draft.problemTitle,
      detailedDescription: draft.detailedDescription,
      category: draft.category,
      villageWard: draft.villageWard,
      block: draft.block,
      district: draft.district,
      state: draft.state,
      latitude: lat,
      longitude: lng,
      citizenPhone: draft.citizenPhone,
      citizenName: draft.citizenName,
      urgency: draft.urgency,
      confidenceScore: draft.confidenceScore,
      isHitlRequired: draft.isHitl,
    );

    _activeDraft = null;
    _isTyping = false;

    _messages.add(
      ChatMessage(
        id: 'bot-${DateTime.now().millisecondsSinceEpoch}',
        text: '🎉 **Grievance Lodged Successfully!**\n\n'
            'Your grievance reference number is **${newGrievance.id}**.\n'
            'An SMS confirmation has been dispatched to ${newGrievance.citizenPhone}. You can track real-time resolution progress anytime.',
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
        lodgedGrievance: newGrievance,
        quickChips: const [
          '➕ Lodge Another Complaint',
          '📋 View My Grievances',
          '🔍 Track Status',
        ],
      ),
    );

    notifyListeners();
    return newGrievance;
  }

  DraftGrievance _classifyGrievanceFromText(String text, LocationProvider locationProvider) {
    final lower = text.toLowerCase();

    DepartmentCategory category = DepartmentCategory.generalPanchayat;
    String problemTitle = text;
    UrgencyLevel urgency = UrgencyLevel.medium;
    double confidenceScore = 0.95;
    bool isHitl = false;

    // Check for High Urgency Keywords
    if (lower.contains('urgent') ||
        lower.contains('emergency') ||
        lower.contains('fire') ||
        lower.contains('blast') ||
        lower.contains('spark') ||
        lower.contains('hazard') ||
        lower.contains('danger') ||
        lower.contains('accident') ||
        lower.contains('आग') ||
        lower.contains('खतरा') ||
        lower.contains('तुरंत') ||
        lower.contains('हादसा') ||
        lower.contains('તાત્કાલિક') ||
        lower.contains('ઇમરજન્સી') ||
        lower.contains('જોખમ') ||
        lower.contains('ખતરો') ||
        lower.contains('અકસ્માત')) {
      urgency = UrgencyLevel.high;
    }

    // Water Supply & Sanitation
    if (lower.contains('water') ||
        lower.contains('pani') ||
        lower.contains('paani') ||
        lower.contains('handpump') ||
        lower.contains('pipe') ||
        lower.contains('leakage') ||
        lower.contains('jal') ||
        lower.contains('nal') ||
        lower.contains('tap') ||
        lower.contains('चापाकल') ||
        lower.contains('पानी') ||
        lower.contains('नल') ||
        lower.contains('पाइप') ||
        lower.contains('जल') ||
        lower.contains('પાણી') ||
        lower.contains('નળ') ||
        lower.contains('પાઇપ') ||
        lower.contains('હેન્ડપંપ') ||
        lower.contains('બોરવેલ')) {
      category = DepartmentCategory.waterSupply;
      problemTitle = 'Drinking Water Supply / Handpump Malfunction: $text';
      confidenceScore = 0.96;
    }
    // Electricity Distribution
    else if (lower.contains('electricity') ||
        lower.contains('power') ||
        lower.contains('light') ||
        lower.contains('bijli') ||
        lower.contains('transformer') ||
        lower.contains('wire') ||
        lower.contains('pole') ||
        lower.contains('voltage') ||
        lower.contains('current') ||
        lower.contains('बिजली') ||
        lower.contains('तार') ||
        lower.contains('ट्रांसफार्मर') ||
        lower.contains('करंट') ||
        lower.contains('વીજળી') ||
        lower.contains('લાઈટ') ||
        lower.contains('કરંટ') ||
        lower.contains('વાયર') ||
        lower.contains('થાંભલો') ||
        lower.contains('ટ્રાન્સફોર્મર')) {
      category = DepartmentCategory.electricity;
      problemTitle = 'Electricity Outage / Line Fault: $text';
      confidenceScore = 0.97;
      if (lower.contains('wire') || lower.contains('तार') || lower.contains('transformer') || lower.contains('વાયર')) {
        urgency = UrgencyLevel.high;
      }
    }
    // Roads & Infrastructure
    else if (lower.contains('road') ||
        lower.contains('pothole') ||
        lower.contains('sadak') ||
        lower.contains('gaddha') ||
        lower.contains('rasta') ||
        lower.contains('bridge') ||
        lower.contains('pul') ||
        lower.contains('सड़क') ||
        lower.contains('गड्ढा') ||
        lower.contains('रास्ता') ||
        lower.contains('पुल') ||
        lower.contains('રસ્તો') ||
        lower.contains('માર્ગ') ||
        lower.contains('ખાડો') ||
        lower.contains('ખાડા') ||
        lower.contains('પુલ') ||
        lower.contains('રોડ')) {
      category = DepartmentCategory.roadsInfrastructure;
      problemTitle = 'Damaged Road Pavement / Pothole: $text';
      confidenceScore = 0.94;
    }
    // Public Health & Sanitation / Waste
    else if (lower.contains('garbage') ||
        lower.contains('waste') ||
        lower.contains('kachra') ||
        lower.contains('drain') ||
        lower.contains('sewer') ||
        lower.contains('naali') ||
        lower.contains('safai') ||
        lower.contains('hospital') ||
        lower.contains('dengue') ||
        lower.contains('कचरा') ||
        lower.contains('सफाई') ||
        lower.contains('नाली') ||
        lower.contains('गंदगी') ||
        lower.contains('કચરો') ||
        lower.contains('ગટર') ||
        lower.contains('ગંદકી') ||
        lower.contains('સફાઈ') ||
        lower.contains('નાળું')) {
      category = DepartmentCategory.sanitationHealth;
      problemTitle = 'Sanitation & Solid Waste Issue: $text';
      confidenceScore = 0.93;
    }
    // PDS Ration
    else if (lower.contains('ration') ||
        lower.contains('rashan') ||
        lower.contains('pds') ||
        lower.contains('dealer') ||
        lower.contains('kotedar') ||
        lower.contains('grain') ||
        lower.contains('wheat') ||
        lower.contains('rice') ||
        lower.contains('राशन') ||
        lower.contains('कोटेदार') ||
        lower.contains('डीलर') ||
        lower.contains('अनाज') ||
        lower.contains('રાશન') ||
        lower.contains('અનાજ') ||
        lower.contains('સસ્તા અનાજ') ||
        lower.contains('દુકાનદાર')) {
      category = DepartmentCategory.pdsRation;
      problemTitle = 'PDS Fair Price Ration Grievance: $text';
      confidenceScore = 0.95;
    }
    // Social Welfare & Pension
    else if (lower.contains('pension') ||
        lower.contains('welfare') ||
        lower.contains('vidhwa') ||
        lower.contains('vridha') ||
        lower.contains('subsidy') ||
        lower.contains('पेंशन') ||
        lower.contains('कल्याण') ||
        lower.contains('પેન્શન') ||
        lower.contains('સહાય') ||
        lower.contains('વિધવા') ||
        lower.contains('વૃદ્ધ')) {
      category = DepartmentCategory.pensionsWelfare;
      problemTitle = 'Social Welfare Scheme / Pension Query: $text';
      confidenceScore = 0.91;
    }
    // Police & Safety
    else if (lower.contains('police') ||
        lower.contains('theft') ||
        lower.contains('crime') ||
        lower.contains('safety') ||
        lower.contains('harassment') ||
        lower.contains('chori') ||
        lower.contains('सुरक्षा') ||
        lower.contains('पुलिस') ||
        lower.contains('चोरी') ||
        lower.contains('પોલીસ') ||
        lower.contains('ચોરી') ||
        lower.contains('ઝઘડો') ||
        lower.contains('સુરક્ષા')) {
      category = DepartmentCategory.policeLawOrder;
      problemTitle = 'Public Safety & Police Assistance: $text';
      urgency = UrgencyLevel.high;
      confidenceScore = 0.94;
    }
    // General / Unknown fallback
    else {
      category = DepartmentCategory.generalPanchayat;
      problemTitle = 'Civic Grievance: $text';
      confidenceScore = 0.78; // Flags HITL review if low confidence
      isHitl = true;
    }

    final isGujaratiText = lower.contains('પાણી') ||
        lower.contains('વીજળી') ||
        lower.contains('રસ્તો') ||
        lower.contains('કચરો') ||
        lower.contains('અમારા') ||
        lower.contains('ગામ');

    final locationStr = locationProvider.isRealGpsAcquired
        ? locationProvider.statusMessage
        : (isGujaratiText ? 'Ward 3, Sanand Taluka, Gujarat' : 'Ward 4, Bhojpur Sadar, Bihar');

    return DraftGrievance(
      problemTitle: problemTitle,
      detailedDescription: text,
      category: category,
      urgency: urgency,
      confidenceScore: confidenceScore,
      villageWard: locationStr,
      block: isGujaratiText ? 'Sanand Taluka' : 'Bhojpur Sadar',
      district: isGujaratiText ? 'Ahmedabad' : 'Bhojpur',
      state: isGujaratiText ? 'Gujarat' : 'Bihar',
      citizenName: 'Nagarik Citizen',
      citizenPhone: '+91 98351 44102',
      isHitl: isHitl,
    );
  }
}
