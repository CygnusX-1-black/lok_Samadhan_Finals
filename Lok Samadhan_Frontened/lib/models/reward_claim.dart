class RewardClaim {
  final String id;
  final String userId;
  final String rewardId;
  final String rewardName;
  final int coinsDeducted;
  final String status;
  final DateTime createdAt;

  const RewardClaim({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.rewardName,
    required this.coinsDeducted,
    this.status = 'Demo Claimed',
    required this.createdAt,
  });

  factory RewardClaim.fromJson(Map<String, dynamic> json) {
    return RewardClaim(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      rewardId: json['rewardId']?.toString() ?? json['reward_id']?.toString() ?? '',
      rewardName: json['rewardName']?.toString() ?? json['reward_name']?.toString() ?? 'Demo Voucher',
      coinsDeducted: json['coinsDeducted'] is int
          ? json['coinsDeducted'] as int
          : json['coins_deducted'] is int
              ? json['coins_deducted'] as int
              : int.tryParse(json['coinsDeducted']?.toString() ?? json['coins_deducted']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'Demo Claimed',
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
      'rewardId': rewardId,
      'rewardName': rewardName,
      'coinsDeducted': coinsDeducted,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
