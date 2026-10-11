class RewardItem {
  final String id;
  final String name;
  final String description;
  final int cost;
  final String category;
  final bool isDemo;
  final bool isActive;
  final String statusLabel;

  const RewardItem({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    this.category = 'voucher',
    this.isDemo = true,
    this.isActive = true,
    this.statusLabel = 'Available',
  });

  factory RewardItem.fromJson(Map<String, dynamic> json) {
    return RewardItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      cost: json['cost'] is int ? json['cost'] as int : int.tryParse(json['cost']?.toString() ?? '0') ?? 0,
      category: json['category']?.toString() ?? 'voucher',
      isDemo: json['isDemo'] == true || json['is_demo'] == true,
      isActive: json['isActive'] != false && json['is_active'] != false,
      statusLabel: json['statusLabel']?.toString() ?? 'Available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cost': cost,
      'category': category,
      'isDemo': isDemo,
      'isActive': isActive,
      'statusLabel': statusLabel,
    };
  }
}
