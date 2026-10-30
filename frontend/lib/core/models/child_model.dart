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

  /// Calculates human-readable age from Date of Birth
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

