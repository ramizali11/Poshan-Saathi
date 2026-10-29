class UserModel {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String role;
  final String language;
  final String state;
  final String district;
  final bool isVerified;
  final String? createdAt;
  final String? token;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    required this.language,
    required this.state,
    required this.district,
    this.isVerified = false,
    this.createdAt,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '1') ?? 1,
      name: json['name'] as String? ?? 'Parent',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'parent',
      language: json['language'] as String? ?? 'ગુજરાતી (Gujarati)',
      state: json['state'] as String? ?? 'Gujarat (ગુજરાત)',
      district: json['district'] as String? ?? 'Ahmedabad (અમદાવાદ)',
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      createdAt: json['created_at'] as String?,
      token: token ?? json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'language': language,
      'state': state,
      'district': district,
      'is_verified': isVerified,
      'created_at': createdAt,
      'token': token,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? role,
    String? language,
    String? state,
    String? district,
    bool? isVerified,
    String? createdAt,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      language: language ?? this.language,
      state: state ?? this.state,
      district: district ?? this.district,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      token: token ?? this.token,
    );
  }
}
