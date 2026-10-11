class RewardsSummary {
  final String userId;
  final int balance;
  final int totalEarned;
  final int totalRedeemed;
  final int eligibleComplaintsCount;
  final int rewardsRedeemedCount;
  final String earningRule;
  final String disclaimer;

  const RewardsSummary({
    required this.userId,
    required this.balance,
    required this.totalEarned,
    required this.totalRedeemed,
    required this.eligibleComplaintsCount,
    required this.rewardsRedeemedCount,
    this.earningRule = '1 GC per eligible complaint',
    this.disclaimer = 'Demo Rewards Only — No real vouchers, redeem codes, or monetary value are provided.',
  });

  factory RewardsSummary.initial({String userId = 'default_citizen'}) {
    return RewardsSummary(
      userId: userId,
      balance: 0,
      totalEarned: 0,
      totalRedeemed: 0,
      eligibleComplaintsCount: 0,
      rewardsRedeemedCount: 0,
    );
  }

  factory RewardsSummary.fromJson(Map<String, dynamic> json) {
    return RewardsSummary(
      userId: json['userId']?.toString() ?? 'default_citizen',
      balance: json['balance'] is int
          ? json['balance'] as int
          : int.tryParse(json['balance']?.toString() ?? '0') ?? 0,
      totalEarned: json['totalEarned'] is int
          ? json['totalEarned'] as int
          : int.tryParse(json['totalEarned']?.toString() ?? '0') ?? 0,
      totalRedeemed: json['totalRedeemed'] is int
          ? json['totalRedeemed'] as int
          : int.tryParse(json['totalRedeemed']?.toString() ?? '0') ?? 0,
      eligibleComplaintsCount: json['eligibleComplaintsCount'] is int
          ? json['eligibleComplaintsCount'] as int
          : int.tryParse(json['eligibleComplaintsCount']?.toString() ?? '0') ?? 0,
      rewardsRedeemedCount: json['rewardsRedeemedCount'] is int
          ? json['rewardsRedeemedCount'] as int
          : int.tryParse(json['rewardsRedeemedCount']?.toString() ?? '0') ?? 0,
      earningRule: json['earningRule']?.toString() ?? '1 GC per eligible complaint',
      disclaimer: json['disclaimer']?.toString() ??
          'Demo Rewards Only — No real vouchers, redeem codes, or monetary value are provided.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'balance': balance,
      'totalEarned': totalEarned,
      'totalRedeemed': totalRedeemed,
      'eligibleComplaintsCount': eligibleComplaintsCount,
      'rewardsRedeemedCount': rewardsRedeemedCount,
      'earningRule': earningRule,
      'disclaimer': disclaimer,
    };
  }

  RewardsSummary copyWith({
    String? userId,
    int? balance,
    int? totalEarned,
    int? totalRedeemed,
    int? eligibleComplaintsCount,
    int? rewardsRedeemedCount,
    String? earningRule,
    String? disclaimer,
  }) {
    return RewardsSummary(
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      totalEarned: totalEarned ?? this.totalEarned,
      totalRedeemed: totalRedeemed ?? this.totalRedeemed,
      eligibleComplaintsCount: eligibleComplaintsCount ?? this.eligibleComplaintsCount,
      rewardsRedeemedCount: rewardsRedeemedCount ?? this.rewardsRedeemedCount,
      earningRule: earningRule ?? this.earningRule,
      disclaimer: disclaimer ?? this.disclaimer,
    );
  }
}
