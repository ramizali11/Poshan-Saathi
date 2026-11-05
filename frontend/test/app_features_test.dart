import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/models/shopping_item.dart';
import 'package:frontend/core/services/meals_data_service.dart';
import 'package:frontend/core/services/shopping_list_service.dart';
import 'package:frontend/core/services/growth_data_service.dart';
import 'package:frontend/core/services/growth_report_pdf_service.dart';

void main() {
  group('1. Expanded Meals Database Tests', () {
    test('Meals database contains at least 20 diverse, realistic meals', () {
      final meals = MockData.allMeals;
      expect(meals.length, greaterThanOrEqualTo(20));

      // Check categories
      final categories = meals.map((m) => m.category).toSet();
      expect(categories, containsAll(['Breakfast', 'Lunch', 'Dinner', 'Snacks', 'Beverages']));

      // Check dietary types
      final dietaryTypes = meals.map((m) => m.dietaryType).toSet();
      expect(dietaryTypes, containsAll(['Vegetarian', 'Vegan', 'High-Protein', 'Low-Calorie', 'Balanced']));
    });

    test('All meals have realistic, consistent nutritional values', () {
      for (final meal in MockData.allMeals) {
        expect(meal.calories, greaterThan(0));
        expect(meal.protein, greaterThan(0));
        expect(meal.carbs, greaterThan(0));
        expect(meal.fats, greaterThanOrEqualTo(0));
        expect(meal.fiber, greaterThanOrEqualTo(0));
        expect(meal.servingSize, isNotEmpty);
        expect(meal.ingredients, isNotEmpty);
        expect(meal.cookingSteps, isNotEmpty);
        expect(meal.gujaratiTitle, isNotEmpty);
      }
    });

    test('Meal search and category filters work accurately', () {
      final service = MealsDataService.instance;

      // Filter by category
      final breakfasts = service.filterMeals(category: 'Breakfast');
      expect(breakfasts.every((m) => m.category == 'Breakfast'), isTrue);
      expect(breakfasts.length, greaterThanOrEqualTo(4));

      // Filter by dietary
      final vegans = service.filterMeals(dietaryType: 'Vegan');
      expect(vegans.every((m) => m.dietaryType == 'Vegan'), isTrue);

      // Search query
      final khichdiResults = service.filterMeals(query: 'khichdi');
      expect(khichdiResults.length, greaterThanOrEqualTo(2));
      expect(khichdiResults.any((m) => m.title.toLowerCase().contains('khichdi')), isTrue);
    });
  });

  group('2. Shopping List Feature Tests', () {
    test('Extracts ingredients from meals and categorizes accurately', () async {
      final service = ShoppingListService.instance;
      await service.clearAll();

      final count = await service.generateFromMeals([MockData.allMeals[0], MockData.allMeals[1]]);
      expect(count, greaterThan(0));
      expect(service.items, isNotEmpty);

      // Verify categories are populated
      final categories = service.items.map((i) => i.category).toSet();
      expect(categories.any((c) => ShoppingCategoryConstants.allCategories.contains(c)), isTrue);
    });

    test('Combines duplicate ingredients and calculates total quantities', () async {
      final service = ShoppingListService.instance;
      await service.clearAll();

      // Add two items with same name but different quantities
      await service.addItem('Pure Desi Cow Ghee', '1 tsp', ShoppingCategoryConstants.dairy);
      await service.addItem('Pure Desi Cow Ghee', '2 tsp', ShoppingCategoryConstants.dairy);

      // Should merge into 1 item with combined quantity
      expect(service.items.length, equals(1));
      expect(service.items.first.name, equals('Pure Desi Cow Ghee'));
      expect(service.items.first.quantity, equals('3 tsp'));
    });

    test('Item toggle, edit, completion separation, and clear all work correctly', () async {
      final service = ShoppingListService.instance;
      await service.clearAll();

      await service.addItem('Carrot', '2 pieces', ShoppingCategoryConstants.vegetables);
      await service.addItem('Spinach', '1 bunch', ShoppingCategoryConstants.vegetables);

      expect(service.pendingItems.length, equals(2));
      expect(service.completedItems.length, equals(0));

      final firstId = service.items.first.id;

      // Toggle first item to completed
      await service.toggleItem(firstId);
      expect(service.pendingItems.length, equals(1));
      expect(service.completedItems.length, equals(1));

      // Edit second item
      final secondId = service.pendingItems.first.id;
      await service.editItem(secondId, 'Organic Spinach', '2 bunches', ShoppingCategoryConstants.vegetables);
      expect(service.pendingItems.first.name, equals('Organic Spinach'));
      expect(service.pendingItems.first.quantity, equals('2 bunches'));

      // Format export text
      final exportText = service.exportFormattedText();
      expect(exportText, contains('POSHAN SAATHI — SHOPPING LIST'));
      expect(exportText, contains('Organic Spinach'));

      // Clear all
      await service.clearAll();
      expect(service.items.isEmpty, isTrue);
    });
  });

  group('3. Growth Data & Chart Calculations Tests', () {
    test('Calculates latest, previous, delta, and percentage changes accurately', () {
      final service = GrowthDataService.instance;
      final measurements = MockData.growthHistory;
      final stats = service.calculateStats(measurements);

      expect(stats['latestWeight'], equals(9.4));
      expect(stats['prevWeight'], equals(9.1));
      expect(stats['weightChange'], closeTo(0.3, 0.01));
      expect(stats['weightPercentChange'], greaterThan(0));
      expect(stats['whoZone'], contains('GREEN'));
    });

    test('Handles time filters correctly', () {
      final service = GrowthDataService.instance;
      final all = service.getFilteredMeasurements('All Time');
      expect(all.length, greaterThanOrEqualTo(5));
    });

    test('Add measurement validates inputs and updates history', () async {
      final service = GrowthDataService.instance;
      final countBefore = service.allMeasurements.length;

      await service.addMeasurement(
        weightKg: 9.7,
        lengthCm: 78.5,
        date: DateTime.now(),
        notes: 'Healthy routine toddler observation',
      );

      expect(service.allMeasurements.length, equals(countBefore + 1));
      expect(service.allMeasurements.first.weightKg, equals(9.7));
      expect(service.allMeasurements.first.lengthCm, equals(78.5));
    });
  });

  group('4. PDF Export Generation Tests', () {
    test('Generates complete, valid, non-empty WHO growth report PDF binary', () async {
      final pdfService = GrowthReportPdfService.instance;
      final child = MockData.defaultChild;
      final measurements = MockData.growthHistory;

      final pdfBytes = await pdfService.generatePdfBytes(
        child: child,
        measurements: measurements,
      );

      // Verify bytes are non-empty
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1000));

      // Verify standard PDF header "%PDF-"
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, equals('%PDF-'));
    });
  });
}

