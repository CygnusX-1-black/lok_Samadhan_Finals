class RewardTransaction {
  final String id;
  final String userId;
  final String type; // 'earned' | 'redeemed'
  final int amount; // e.g. +1 or -20
  final String description;
  final String? referenceId;
  final int balanceAfter;
  final DateTime createdAt;

  const RewardTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    this.referenceId,
    required this.balanceAfter,
    required this.createdAt,
  });

  bool get isEarned => type.toLowerCase() == 'earned' || amount > 0;

  factory RewardTransaction.fromJson(Map<String, dynamic> json) {
    return RewardTransaction(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      type: json['type']?.toString() ?? (json['amount'] is num && (json['amount'] as num) < 0 ? 'redeemed' : 'earned'),
      amount: json['amount'] is int
          ? json['amount'] as int
          : int.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      description: json['description']?.toString() ?? 'Grievance Coin Transaction',
      referenceId: json['referenceId']?.toString() ?? json['reference_id']?.toString(),
      balanceAfter: json['balanceAfter'] is int
          ? json['balanceAfter'] as int
          : json['balance_after'] is int
              ? json['balance_after'] as int
              : int.tryParse(json['balanceAfter']?.toString() ?? json['balance_after']?.toString() ?? '0') ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'amount': amount,
      'description': description,
      'referenceId': referenceId,
      'balanceAfter': balanceAfter,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
