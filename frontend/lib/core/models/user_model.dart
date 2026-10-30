class UserModel {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String role;
  final String? language;
  final String? state;
  final String? district;
  final String? dob;
  final String? gender;
  final String? address;
  final String? city;
  final String? pinCode;
  final String? avatarUrl;
  final String? authProvider;
  final bool isVerified;
  final bool isProfileComplete;
  final int onboardingStep;
  final String? createdAt;
  final String? token;

  const UserModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.role = 'parent',
    this.language,
    this.state,
    this.district,
    this.dob,
    this.gender,
    this.address,
    this.city,
    this.pinCode,
    this.avatarUrl,
    this.authProvider = 'local',
    this.isVerified = false,
    this.isProfileComplete = false,
    this.onboardingStep = 0,
    this.createdAt,
    this.token,
  });

  static String? sanitizePhone(dynamic raw) {
    if (raw == null) return null;
    final str = raw.toString().trim();
    if (str.isEmpty ||
        str.startsWith('g_') ||
        str.startsWith('a_') ||
        str.startsWith('sub_') ||
        str.startsWith('id_')) {
      return null;
    }
    final digits = str.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return digits;
    }
    return null;
  }

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '1') ?? 1,
      name: json['name'] as String? ?? 'User',
      phone: sanitizePhone(json['phone']),
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'parent',
      language: json['language'] as String?,
      state: json['state'] as String?,
      district: json['district'] as String?,
      dob: (json['dob'] ?? json['date_of_birth']) as String?,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      pinCode: (json['pin_code'] ?? json['pinCode']) as String?,
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl'] ?? json['picture']) as String?,
      authProvider: (json['auth_provider'] ?? json['authProvider']) as String? ?? 'local',
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      isProfileComplete: json['is_profile_complete'] == true || json['is_profile_complete'] == 1 || json['isProfileComplete'] == true,
      onboardingStep: json['onboarding_step'] is int
          ? json['onboarding_step'] as int
          : (int.tryParse(json['onboarding_step']?.toString() ?? '') ??
             int.tryParse(json['onboardingStep']?.toString() ?? '0') ?? 0),
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
      'dob': dob,
      'gender': gender,
      'address': address,
      'city': city,
      'pin_code': pinCode,
      'avatar_url': avatarUrl,
      'auth_provider': authProvider,
      'is_verified': isVerified,
      'is_profile_complete': isProfileComplete,
      'onboarding_step': onboardingStep,
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
    String? dob,
    String? gender,
    String? address,
    String? city,
    String? pinCode,
    String? avatarUrl,
    String? authProvider,
    bool? isVerified,
    bool? isProfileComplete,
    int? onboardingStep,
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
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      city: city ?? this.city,
      pinCode: pinCode ?? this.pinCode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      authProvider: authProvider ?? this.authProvider,
      isVerified: isVerified ?? this.isVerified,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      createdAt: createdAt ?? this.createdAt,
      token: token ?? this.token,
    );
  }
}
