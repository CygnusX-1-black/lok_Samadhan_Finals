import 'department.dart';
import 'grievance.dart';

enum MessageSender { user, bot }

class DraftGrievance {
  final String problemTitle;
  final String detailedDescription;
  final DepartmentCategory category;
  final UrgencyLevel urgency;
  final double confidenceScore;
  final String villageWard;
  final String block;
  final String district;
  final String state;
  final String citizenName;
  final String citizenPhone;
  final bool isHitl;

  const DraftGrievance({
    required this.problemTitle,
    required this.detailedDescription,
    required this.category,
    required this.urgency,
    required this.confidenceScore,
    required this.villageWard,
    required this.block,
    required this.district,
    required this.state,
    this.citizenName = 'Nagarik Citizen',
    this.citizenPhone = '+91 98765 43210',
    this.isHitl = false,
  });

  DraftGrievance copyWith({
    String? problemTitle,
    String? detailedDescription,
    DepartmentCategory? category,
    UrgencyLevel? urgency,
    double? confidenceScore,
    String? villageWard,
    String? block,
    String? district,
    String? state,
    String? citizenName,
    String? citizenPhone,
    bool? isHitl,
  }) {
    return DraftGrievance(
      problemTitle: problemTitle ?? this.problemTitle,
      detailedDescription: detailedDescription ?? this.detailedDescription,
      category: category ?? this.category,
      urgency: urgency ?? this.urgency,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      villageWard: villageWard ?? this.villageWard,
      block: block ?? this.block,
      district: district ?? this.district,
      state: state ?? this.state,
      citizenName: citizenName ?? this.citizenName,
      citizenPhone: citizenPhone ?? this.citizenPhone,
      isHitl: isHitl ?? this.isHitl,
    );
  }

  DepartmentInfo get departmentInfo => DepartmentInfo.getByCategory(category);
}

class ChatMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final DraftGrievance? draftGrievance;
  final Grievance? lodgedGrievance;
  final List<String>? quickChips;
  final bool isTyping;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.draftGrievance,
    this.lodgedGrievance,
    this.quickChips,
    this.isTyping = false,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    MessageSender? sender,
    DateTime? timestamp,
    DraftGrievance? draftGrievance,
    Grievance? lodgedGrievance,
    List<String>? quickChips,
    bool? isTyping,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      draftGrievance: draftGrievance ?? this.draftGrievance,
      lodgedGrievance: lodgedGrievance ?? this.lodgedGrievance,
      quickChips: quickChips ?? this.quickChips,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}
