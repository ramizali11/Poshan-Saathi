class ShoppingItem {
  final String id;
  final String name;
  final String quantity;
  final String category;
  final bool isCompleted;
  final String? sourceMealTitle;
  final DateTime createdAt;

  const ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.category,
    this.isCompleted = false,
    this.sourceMealTitle,
    required this.createdAt,
  });

  ShoppingItem copyWith({
    String? id,
    String? name,
    String? quantity,
    String? category,
    bool? isCompleted,
    String? sourceMealTitle,
    DateTime? createdAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      sourceMealTitle: sourceMealTitle ?? this.sourceMealTitle,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'category': category,
      'isCompleted': isCompleted,
      'sourceMealTitle': sourceMealTitle,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String? ?? 'item_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '1 unit',
      category: json['category'] as String? ?? 'Spices & Pantry',
      isCompleted: json['isCompleted'] as bool? ?? false,
      sourceMealTitle: json['sourceMealTitle'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ShoppingCategoryConstants {
  static const String vegetables = 'Vegetables & Greens';
  static const String fruits = 'Fruits';
  static const String dairy = 'Dairy & Healthy Fats';
  static const String grains = 'Grains & Millets';
  static const String protein = 'Pulses & Protein';
  static const String spicesPantry = 'Spices & Pantry';

  static const List<String> allCategories = [
    vegetables,
    fruits,
    dairy,
    grains,
    protein,
    spicesPantry,
  ];
}

