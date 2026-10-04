class UserAccount {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? token;
  final String? refreshToken;
  final String provider;
  final String? avatarUrl;
  final DateTime? createdAt;

  const UserAccount({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role = 'citizen',
    this.token,
    this.refreshToken,
    this.provider = 'supabase',
    this.avatarUrl,
    this.createdAt,
  });

  bool get isCitizen => role == 'citizen';
  bool get isOfficial => role == 'governmentOfficial' || role == 'admin';

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['fullName']?.toString() ?? 'Citizen',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'citizen',
      token: json['token']?.toString(),
      refreshToken: json['refreshToken']?.toString(),
      provider: json['provider']?.toString() ?? 'supabase',
      avatarUrl: json['avatarUrl']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'token': token,
      'refreshToken': refreshToken,
      'provider': provider,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  UserAccount copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? token,
    String? refreshToken,
    String? provider,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return UserAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      provider: provider ?? this.provider,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
