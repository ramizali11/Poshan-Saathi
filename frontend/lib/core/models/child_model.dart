class ChildModel {
  final int id;
  final int parentId;
  final String name;
  final String dob; // YYYY-MM-DD
  final double? weight;
  final String gender; // 'Boy', 'Girl', 'Other'
  final String? createdAt;
  final String? updatedAt;

  const ChildModel({
    required this.id,
    required this.parentId,
    required this.name,
    required this.dob,
    this.weight,
    required this.gender,
    this.createdAt,
    this.updatedAt,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      parentId: json['parent_id'] is int
          ? json['parent_id'] as int
          : (int.tryParse(json['parent_id']?.toString() ?? '') ??
             int.tryParse(json['user_id']?.toString() ?? '0') ?? 0),
      name: json['name'] as String? ?? '',
      dob: json['dob'] as String? ?? '',
      weight: json['weight'] != null
          ? (json['weight'] is num ? (json['weight'] as num).toDouble() : double.tryParse(json['weight'].toString()))
          : (json['current_weight_kg'] != null
              ? (json['current_weight_kg'] is num
                  ? (json['current_weight_kg'] as num).toDouble()
                  : double.tryParse(json['current_weight_kg'].toString()))
              : null),
      gender: json['gender'] as String? ?? 'Boy',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'name': name,
      'dob': dob,
      'weight': weight,
      'gender': gender,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  bool get hasWeight => weight != null && weight! > 0;
  String get weightDisplay => hasWeight ? '${weight!.toStringAsFixed(1)} kg' : 'Not added';

  String get shortInitials {
    if (name.trim().isEmpty) return 'C';
    final parts = name.trim().split(' ');
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  ChildModel copyWith({
    int? id,
    int? parentId,
    String? name,
    String? dob,
    double? weight,
    String? gender,
    String? createdAt,
    String? updatedAt,
  }) {
    return ChildModel(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculates human-readable age from Date of Birth
  /// Calculates child's age in full months
  int get computedAgeMonths {
    try {
      final birthDate = DateTime.parse(dob);
      final today = DateTime.now();
      int months = (today.year - birthDate.year) * 12 + (today.month - birthDate.month);
      if (today.day < birthDate.day) {
        months -= 1;
      }
      return months.clamp(0, 240);
    } catch (_) {
      return 0;
    }
  }

  String get ageDisplay {
    try {
      final birthDate = DateTime.parse(dob);
      final today = DateTime.now();

      int years = today.year - birthDate.year;
      int months = today.month - birthDate.month;
      int days = today.day - birthDate.day;

      if (days < 0) {
        months -= 1;
      }
      if (months < 0) {
        years -= 1;
        months += 12;
      }

      if (years > 0) {
        return months > 0 ? '$years yr $months mo' : '$years yr old';
      } else if (months > 0) {
        return '$months month${months > 1 ? 's' : ''} old';
      } else {
        final totalDays = today.difference(birthDate).inDays;
        return '$totalDays day${totalDays > 1 ? 's' : ''} old';
      }
    } catch (_) {
      return '';
    }
  }
}

