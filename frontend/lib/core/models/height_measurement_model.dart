class HeightMeasurementModel {
  final int id;
  final int childId;
  final int parentId;
  final double heightCm;
  final String measurementDate; // YYYY-MM-DD
  final String notes;
  final String createdAt;
  final String updatedAt;
  final double? diffFromPrevious; // in cm, e.g. +1.5

  const HeightMeasurementModel({
    required this.id,
    required this.childId,
    required this.parentId,
    required this.heightCm,
    required this.measurementDate,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
    this.diffFromPrevious,
  });

  factory HeightMeasurementModel.fromJson(Map<String, dynamic> json) {
    return HeightMeasurementModel(
      id: json['id'] as int? ?? 0,
      childId: json['child_id'] as int? ?? 0,
      parentId: json['parent_id'] as int? ?? 0,
      heightCm: (json['height_cm'] as num?)?.toDouble() ?? 0.0,
      measurementDate: json['measurement_date'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      diffFromPrevious: (json['diff_from_previous'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'child_id': childId,
      'parent_id': parentId,
      'height_cm': heightCm,
      'measurement_date': measurementDate,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'diff_from_previous': diffFromPrevious,
    };
  }

  String get heightDisplay => heightCm.toStringAsFixed(1);

  String get diffDisplay {
    if (diffFromPrevious == null) return '—';
    if (diffFromPrevious! > 0) return '+${diffFromPrevious!.toStringAsFixed(1)} cm';
    if (diffFromPrevious! < 0) return '${diffFromPrevious!.toStringAsFixed(1)} cm';
    return '0.0 cm';
  }

  bool get isPositiveGrowth => (diffFromPrevious ?? 0) > 0;
}

