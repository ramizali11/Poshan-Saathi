import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../data/mock_data.dart';
import '../models/shopping_item.dart';
import 'storage/app_storage.dart';

class ShoppingListService {
  ShoppingListService._();
  static final ShoppingListService instance = ShoppingListService._();

  static const String _storageKey = 'poshan_shopping_list_items';

  final ValueNotifier<List<ShoppingItem>> itemsNotifier = ValueNotifier<List<ShoppingItem>>([]);
  bool _isInitialized = false;

  List<ShoppingItem> get items => itemsNotifier.value;
  List<ShoppingItem> get pendingItems => items.where((i) => !i.isCompleted).toList();
  List<ShoppingItem> get completedItems => items.where((i) => i.isCompleted).toList();

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      final jsonStr = await AppStorage.instance.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List list = jsonDecode(jsonStr) as List;
        itemsNotifier.value = list
            .map((item) => ShoppingItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        // Seed default starter grocery items for toddler stage if empty
        generateFromMeals(MockData.todayMeals, isInitialSeed: true);
      }
    } catch (e) {
      debugPrint('[ShoppingListService] Error loading shopping list: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final encoded = jsonEncode(items.map((i) => i.toJson()).toList());
      await AppStorage.instance.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('[ShoppingListService] Error persisting shopping list: $e');
    }
  }

  Future<void> addItem(String name, String quantity, String category, {String? sourceMeal}) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    // Check if item already exists (case-insensitive)
    final existingIndex = items.indexWhere(
      (i) => i.name.toLowerCase() == cleanName.toLowerCase() && !i.isCompleted,
    );

    if (existingIndex >= 0) {
      // Combine quantity
      final existing = items[existingIndex];
      final combinedQty = _combineQuantities(existing.quantity, quantity);
      final updated = existing.copyWith(quantity: combinedQty);
      final list = List<ShoppingItem>.from(items);
      list[existingIndex] = updated;
      itemsNotifier.value = list;
    } else {
      final newItem = ShoppingItem(
        id: 'item_${DateTime.now().microsecondsSinceEpoch}',
        name: cleanName,
        quantity: quantity.trim().isEmpty ? '1 unit' : quantity.trim(),
        category: category,
        isCompleted: false,
        sourceMealTitle: sourceMeal,
        createdAt: DateTime.now(),
      );
      itemsNotifier.value = [newItem, ...items];
    }

    await _persist();
  }

  Future<void> editItem(String id, String newName, String newQuantity, String newCategory) async {
    final list = List<ShoppingItem>.from(items);
    final idx = list.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      list[idx] = list[idx].copyWith(
        name: newName.trim(),
        quantity: newQuantity.trim(),
        category: newCategory,
      );
      itemsNotifier.value = list;
      await _persist();
    }
  }

  Future<void> toggleItem(String id) async {
    final list = List<ShoppingItem>.from(items);
    final idx = list.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      list[idx] = list[idx].copyWith(isCompleted: !list[idx].isCompleted);
      itemsNotifier.value = list;
      await _persist();
    }
  }

  Future<void> removeItem(String id) async {
    final list = List<ShoppingItem>.from(items);
    list.removeWhere((i) => i.id == id);
    itemsNotifier.value = list;
    await _persist();
  }

  Future<void> clearCompleted() async {
    final list = List<ShoppingItem>.from(items);
    list.removeWhere((i) => i.isCompleted);
    itemsNotifier.value = list;
    await _persist();
  }

  Future<void> clearAll() async {
    itemsNotifier.value = [];
    await _persist();
  }

  /// Automatically extract ingredients from meals, categorize, and merge duplicates
  Future<int> generateFromMeals(List<Meal> meals, {bool isInitialSeed = false}) async {
    int addedCount = 0;
    final Map<String, ShoppingItem> workingMap = {};

    // Populate existing non-completed items into working map
    for (final item in items) {
      if (!item.isCompleted) {
        workingMap[item.name.toLowerCase()] = item;
      }
    }

    for (final meal in meals) {
      for (final rawIngredient in meal.ingredients) {
        final parsed = _parseRawIngredient(rawIngredient, meal.title);
        final key = parsed.name.toLowerCase();

        if (workingMap.containsKey(key)) {
          final existing = workingMap[key]!;
          final combinedQty = _combineQuantities(existing.quantity, parsed.quantity);
          workingMap[key] = existing.copyWith(quantity: combinedQty);
        } else {
          workingMap[key] = parsed;
          addedCount++;
        }
      }
    }

    final List<ShoppingItem> result = [
      ...workingMap.values,
      ...items.where((i) => i.isCompleted),
    ];

    itemsNotifier.value = result;
    await _persist();
    return addedCount;
  }

  ShoppingItem _parseRawIngredient(String raw, String sourceMeal) {
    // E.g. "Yellow moong dal (પીળી મગની દાળ) Pre-soaked 15m — 2 tbsp"
    // E.g. "Sprouted Ragi Flour (2 tbsp)"
    // E.g. "Pure Desi Cow Ghee (ગાયનું ઘી) — 1 tsp"
    String name = raw;
    String quantity = '1 portion';

    // Extract quantity if after '—' or in parentheses
    if (raw.contains('—')) {
      final parts = raw.split('—');
      name = parts[0].trim();
      quantity = parts[1].trim();
    } else if (raw.contains('(') && raw.contains(')')) {
      final match = RegExp(r'\(([^)]+)\)').firstMatch(raw);
      if (match != null) {
        final inside = match.group(1) ?? '';
        // If inside has numbers/units, treat as quantity
        if (RegExp(r'\d').hasMatch(inside)) {
          quantity = inside.trim();
          name = raw.replaceAll(RegExp(r'\([^)]+\)'), '').trim();
        }
      }
    }

    // Clean up name by removing Gujarati parentheticals if any
    name = name.replaceAll(RegExp(r'\([^)]*[\u0A80-\u0AFF][^)]*\)'), '').trim();
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

    final category = _detectCategory(name);

    return ShoppingItem(
      id: 'item_${DateTime.now().microsecondsSinceEpoch}_${name.hashCode.abs()}',
      name: name,
      quantity: quantity,
      category: category,
      isCompleted: false,
      sourceMealTitle: sourceMeal,
      createdAt: DateTime.now(),
    );
  }

  String _detectCategory(String name) {
    final lower = name.toLowerCase();

    // Vegetables
    if (lower.contains('spinach') ||
        lower.contains('palak') ||
        lower.contains('carrot') ||
        lower.contains('dudhi') ||
        lower.contains('gourd') ||
        lower.contains('pumpkin') ||
        lower.contains('beet') ||
        lower.contains('methi') ||
        lower.contains('pea') ||
        lower.contains('tomato') ||
        lower.contains('coriander') ||
        lower.contains('mint') ||
        lower.contains('sweet potato')) {
      return ShoppingCategoryConstants.vegetables;
    }

    // Fruits
    if (lower.contains('papaya') ||
        lower.contains('banana') ||
        lower.contains('apple') ||
        lower.contains('lemon') ||
        lower.contains('coconut') ||
        lower.contains('fruit')) {
      return ShoppingCategoryConstants.fruits;
    }

    // Dairy & Fats
    if (lower.contains('ghee') ||
        lower.contains('milk') ||
        lower.contains('curd') ||
        lower.contains('buttermilk') ||
        lower.contains('chaas') ||
        lower.contains('paneer') ||
        lower.contains('oil') ||
        lower.contains('butter')) {
      return ShoppingCategoryConstants.dairy;
    }

    // Grains & Millets
    if (lower.contains('rice') ||
        lower.contains('ragi') ||
        lower.contains('bajra') ||
        lower.contains('sooji') ||
        lower.contains('semolina') ||
        lower.contains('oats') ||
        lower.contains('dalia') ||
        lower.contains('wheat') ||
        lower.contains('poha') ||
        lower.contains('barley') ||
        lower.contains('flour') ||
        lower.contains('roti') ||
        lower.contains('idli')) {
      return ShoppingCategoryConstants.grains;
    }

    // Protein & Pulses
    if (lower.contains('moong') ||
        lower.contains('dal') ||
        lower.contains('masoor') ||
        lower.contains('sattu') ||
        lower.contains('chana') ||
        lower.contains('lentil') ||
        lower.contains('walnut') ||
        lower.contains('makhana') ||
        lower.contains('chia') ||
        lower.contains('sprout') ||
        lower.contains('urad')) {
      return ShoppingCategoryConstants.protein;
    }

    return ShoppingCategoryConstants.spicesPantry;
  }

  String _combineQuantities(String q1, String q2) {
    // Try to parse numeric portions if matching units
    try {
      final num1Match = RegExp(r'([\d\.\/]+)\s*([a-zA-Z]+)?').firstMatch(q1);
      final num2Match = RegExp(r'([\d\.\/]+)\s*([a-zA-Z]+)?').firstMatch(q2);

      if (num1Match != null && num2Match != null) {
        final unit1 = num1Match.group(2) ?? '';
        final unit2 = num2Match.group(2) ?? '';

        if (unit1.toLowerCase() == unit2.toLowerCase() && unit1.isNotEmpty) {
          final val1 = _parseFraction(num1Match.group(1) ?? '1');
          final val2 = _parseFraction(num2Match.group(1) ?? '1');
          final sum = val1 + val2;
          final formatted = sum == sum.roundToDouble()
              ? sum.toInt().toString()
              : sum.toStringAsFixed(1);
          return '$formatted $unit1';
        }
      }
    } catch (_) {}

    return '$q1 + $q2';
  }

  double _parseFraction(String str) {
    if (str.contains('/')) {
      final parts = str.split('/');
      final num = double.tryParse(parts[0]) ?? 1.0;
      final den = double.tryParse(parts[1]) ?? 1.0;
      return den == 0 ? num : num / den;
    }
    return double.tryParse(str) ?? 1.0;
  }

  String exportFormattedText() {
    final buffer = StringBuffer();
    buffer.writeln('🛒 POSHAN SAATHI — SHOPPING LIST (કરિયાણાની યાદી)');
    buffer.writeln('Generated for: Aarav Shah (14 months)');
    buffer.writeln('Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
    buffer.writeln('------------------------------------------');

    for (final cat in ShoppingCategoryConstants.allCategories) {
      final catItems = pendingItems.where((i) => i.category == cat).toList();
      if (catItems.isNotEmpty) {
        buffer.writeln('\n[$cat]');
        for (final item in catItems) {
          buffer.writeln(' • [ ] ${item.name} (${item.quantity})');
        }
      }
    }

    if (completedItems.isNotEmpty) {
      buffer.writeln('\n[PURCHASED / COMPLETED]');
      for (final item in completedItems) {
        buffer.writeln(' • [✓] ${item.name} (${item.quantity})');
      }
    }

    buffer.writeln('\n------------------------------------------');
    buffer.writeln('Shared via Poshan Saathi Maternal & Child Health App');
    return buffer.toString();
  }
}

