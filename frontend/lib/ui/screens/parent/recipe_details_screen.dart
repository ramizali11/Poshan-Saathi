import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/data/mock_data.dart';
import '../../../core/services/shopping_list_service.dart';
import '../../../core/services/meals_data_service.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final Meal? meal;

  const RecipeDetailsScreen({super.key, this.meal});

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  late Meal _meal;
  int _portions = 1;
  late List<bool> _checkedIngredients;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _meal = widget.meal ?? MockData.allMeals[5]; // Default to Moong Dal Khichdi
    _checkedIngredients = List.generate(_meal.ingredients.length, (_) => false);
    _isFavorite = _meal.isFavorite;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Meal) {
      setState(() {
        _meal = args;
        _checkedIngredients = List.generate(_meal.ingredients.length, (_) => false);
        _isFavorite = _meal.isFavorite;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final calories = _meal.calories * _portions;
    final protein = (_meal.protein * _portions).toStringAsFixed(1);
    final carbs = (_meal.carbs * _portions).toStringAsFixed(1);
    final fats = (_meal.fats * _portions).toStringAsFixed(1);
    final fiber = (_meal.fiber * _portions).toStringAsFixed(1);
    final cost = _meal.costInRupees * _portions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'વાનગી વિગત • Recipe Details',
          style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? AppColors.statusRed : null,
            ),
            tooltip: 'Favorite',
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
              MealsDataService.instance.toggleFavorite(_meal.id);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Recipe',
            onPressed: _shareRecipe,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addIngredientsToShoppingList,
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: const Text('Add Ingredients to Cart', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${_meal.title} logged to today\'s intake!'),
                        backgroundColor: AppColors.statusGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Mark as Fed', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Recipe Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusBadge(
                        label: '${_meal.category} • ${_meal.dietaryType}',
                        status: BadgeStatus.verified,
                        icon: Icons.child_care_rounded,
                        isSmall: true,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _meal.slotName,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _meal.title,
                    style: AppTypography.headline1.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _meal.gujaratiTitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _meal.subtitle,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      StatusBadge(label: 'Prep: ${_meal.prepMinutes} mins', icon: Icons.timer_outlined, isSmall: true),
                      StatusBadge(label: 'Cost: ~₹$cost', icon: Icons.payments_outlined, isSmall: true),
                      StatusBadge(label: _meal.servingSize, icon: Icons.restaurant_rounded, isSmall: true),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Portion Multiplier
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Portion Size (ભાગ / પીરસવાનું પ્રમાણ):',
                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [1, 2, 3].map((p) {
                      final isSel = _portions == p;
                      return GestureDetector(
                        onTap: () => setState(() => _portions = p),
                        child: Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${p}x',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSel ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Nutritional Breakdown Grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nutritional Value (પોષક મૂલ્ય)',
                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _macroBox('Calories', '$calories kcal', AppColors.primary),
                      const SizedBox(width: 8),
                      _macroBox('Protein', '${protein}g', AppColors.secondary),
                      const SizedBox(width: 8),
                      _macroBox('Carbs', '${carbs}g', AppColors.primaryDark),
                      const SizedBox(width: 8),
                      _macroBox('Fats', '${fats}g', AppColors.tertiaryDark),
                      const SizedBox(width: 8),
                      _macroBox('Fiber', '${fiber}g', AppColors.statusGreen),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Absorption Tip Card (Amber Tint)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.tertiaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.tertiary.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_rounded, color: AppColors.tertiaryDark, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Micronutrient Bioavailability Secret (પોષણ ગુણવત્તા)',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.tertiaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _meal.absorptionTip,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.tertiaryDark,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _meal.absorptionTipGujarati,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.tertiaryDark,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Texture Guidance Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.soup_kitchen_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Texture & Oral-Motor Chewing Guideline',
                          style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _meal.textureNote,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Ingredients Check-off List
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ingredients (જરૂરી સામગ્રી)',
                        style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_checkedIngredients.where((b) => b).length}/${_meal.ingredients.length} ready',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(_meal.ingredients.length, (idx) {
                    final ing = _meal.ingredients[idx];
                    final isChecked = _checkedIngredients[idx];
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      activeColor: AppColors.statusGreen,
                      value: isChecked,
                      onChanged: (val) {
                        setState(() => _checkedIngredients[idx] = val ?? false);
                      },
                      title: Text(
                        ing,
                        style: AppTypography.bodySmall.copyWith(
                          decoration: isChecked ? TextDecoration.lineThrough : null,
                          color: isChecked ? AppColors.textMuted : AppColors.textPrimary,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Cooking Steps
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step-by-Step Preparation (બનાવવાની રીત)',
                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_meal.cookingSteps.length, (idx) {
                    final step = _meal.cookingSteps[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              step,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _macroBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  void _addIngredientsToShoppingList() async {
    final count = await ShoppingListService.instance.generateFromMeals([_meal]);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $count ingredients to your Shopping List!'),
          backgroundColor: AppColors.statusGreen,
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () => Navigator.pushNamed(context, '/shopping_list'),
          ),
        ),
      );
    }
  }

  void _shareRecipe() {
    final buffer = StringBuffer();
    buffer.writeln('🍲 ${_meal.title} (${_meal.gujaratiTitle})');
    buffer.writeln('Nutritional Stats: ${_meal.calories} kcal | ${_meal.protein}g Protein | ${_meal.fiber}g Fiber');
    buffer.writeln('\nIngredients:');
    for (final ing in _meal.ingredients) {
      buffer.writeln('• $ing');
    }
    buffer.writeln('\nPreparation:');
    for (int i = 0; i < _meal.cookingSteps.length; i++) {
      buffer.writeln('${i + 1}. ${_meal.cookingSteps[i]}');
    }
    buffer.writeln('\nShared via Poshan Saathi Health Platform');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recipe details copied to clipboard! Ready to share.'),
        backgroundColor: AppColors.statusGreen,
      ),
    );
  }
}
