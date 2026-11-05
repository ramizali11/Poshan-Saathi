import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../data/mock_data.dart';
import 'storage/app_storage.dart';

class MealsDataService {
  MealsDataService._() {
    _refreshList();
  }
  static final MealsDataService instance = MealsDataService._();

  static const String _favoritesStorageKey = 'poshan_meal_favorites';
  static const String _customMealsStorageKey = 'poshan_custom_meals';

  final ValueNotifier<List<Meal>> mealsNotifier = ValueNotifier<List<Meal>>([]);
  final Set<String> _favoriteIds = {};
  final List<Meal> _customMeals = [];
  bool _isInitialized = false;

  List<Meal> get allMeals => mealsNotifier.value;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Load favorites
    try {
      final favJson = await AppStorage.instance.getString(_favoritesStorageKey);
      if (favJson != null && favJson.isNotEmpty) {
        final List list = jsonDecode(favJson) as List;
        _favoriteIds.addAll(list.map((e) => e.toString()));
      }
    } catch (e) {
      debugPrint('[MealsDataService] Error loading favorites: $e');
    }

    // Load custom meals
    try {
      final customJson = await AppStorage.instance.getString(_customMealsStorageKey);
      if (customJson != null && customJson.isNotEmpty) {
        final List list = jsonDecode(customJson) as List;
        _customMeals.addAll(list.map((item) => Meal.fromJson(item as Map<String, dynamic>)));
      }
    } catch (e) {
      debugPrint('[MealsDataService] Error loading custom meals: $e');
    }

    _refreshList();
  }

  void _refreshList() {
    final Map<String, Meal> mealMap = {};

    // 1. Built-in meals
    for (final meal in MockData.allMeals) {
      final isFav = _favoriteIds.contains(meal.id) || (meal.isFavorite && !_favoriteIds.contains('unfav_${meal.id}'));
      mealMap[meal.id] = meal.copyWith(isFavorite: isFav);
    }

    // 2. Custom meals (can override or append)
    for (final meal in _customMeals) {
      final isFav = _favoriteIds.contains(meal.id);
      mealMap[meal.id] = meal.copyWith(isFavorite: isFav);
    }

    mealsNotifier.value = mealMap.values.toList();
  }

  Future<void> toggleFavorite(String mealId) async {
    final isAlreadyFav = _favoriteIds.contains(mealId);
    if (isAlreadyFav) {
      _favoriteIds.remove(mealId);
      _favoriteIds.add('unfav_$mealId'); // Explicit unfavorite for default favorites
    } else {
      _favoriteIds.remove('unfav_$mealId');
      _favoriteIds.add(mealId);
    }

    try {
      await AppStorage.instance.setString(_favoritesStorageKey, jsonEncode(_favoriteIds.toList()));
    } catch (e) {
      debugPrint('[MealsDataService] Error persisting favorites: $e');
    }

    _refreshList();
  }

  Future<void> addCustomMeal(Meal newMeal) async {
    // Avoid duplicate id
    final id = newMeal.id.isEmpty
        ? 'custom_${DateTime.now().millisecondsSinceEpoch}'
        : newMeal.id;

    final meal = newMeal.copyWith(id: id);
    _customMeals.add(meal);

    try {
      final encoded = jsonEncode(_customMeals.map((m) => m.toJson()).toList());
      await AppStorage.instance.setString(_customMealsStorageKey, encoded);
    } catch (e) {
      debugPrint('[MealsDataService] Error saving custom meal: $e');
    }

    _refreshList();
  }

  List<Meal> filterMeals({
    String query = '',
    String category = 'All',
    String dietaryType = 'All',
    bool onlyFavorites = false,
  }) {
    final q = query.trim().toLowerCase();

    return allMeals.where((meal) {
      // Category filter
      if (category != 'All') {
        if (category == 'Healthy Options') {
          if (!meal.tags.any((t) => t.toLowerCase().contains('healthy') || t.toLowerCase().contains('immunity') || t.toLowerCase().contains('probiotic')) &&
              meal.category != 'Healthy Options') {
            return false;
          }
        } else if (meal.category.toLowerCase() != category.toLowerCase()) {
          return false;
        }
      }

      // Dietary filter
      if (dietaryType != 'All') {
        if (meal.dietaryType.toLowerCase() != dietaryType.toLowerCase()) {
          return false;
        }
      }

      // Favorites filter
      if (onlyFavorites && !meal.isFavorite) {
        return false;
      }

      // Query filter
      if (q.isNotEmpty) {
        final inTitle = meal.title.toLowerCase().contains(q);
        final inGujTitle = meal.gujaratiTitle.toLowerCase().contains(q);
        final inSubtitle = meal.subtitle.toLowerCase().contains(q);
        final inTags = meal.tags.any((t) => t.toLowerCase().contains(q));
        final inIngredients = meal.ingredients.any((i) => i.toLowerCase().contains(q));

        if (!inTitle && !inGujTitle && !inSubtitle && !inTags && !inIngredients) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}

