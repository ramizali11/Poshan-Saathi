import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock_data.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  int _selectedDayIndex = 2; // Index 2 is TODAY 25
  final List<Meal> _meals = MockData.todayMeals;

  final List<Map<String, String>> _weekDays = [
    {'day': 'Mon', 'date': '23'},
    {'day': 'Tue', 'date': '24'},
    {'day': 'TODAY', 'date': '25'},
    {'day': 'Thu', 'date': '26'},
    {'day': 'Fri', 'date': '27'},
    {'day': 'Sat', 'date': '28'},
    {'day': 'Sun', 'date': '1'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meal Planner (આહાર આયોજન)',
              style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'Aarav Shah • 14m • Stage 3 Coarse Mash',
              style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_basket_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Weekly local produce ingredients exported to shopping list!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Horizontal Date Picker Strip
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: List.generate(_weekDays.length, (index) {
                  final isSelected = _selectedDayIndex == index;
                  final d = _weekDays[index];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDayIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.divider,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              d['day']!,
                              style: AppTypography.labelSmall.copyWith(
                                color: isSelected ? Colors.white : AppColors.textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              d['date']!,
                              style: AppTypography.labelLarge.copyWith(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 14),

            // Daily Diversity Tracker (WHO 5-Food-Group Metric)
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
                      Row(
                        children: [
                          const Icon(Icons.restaurant_menu_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Daily Diversity Tracker\n(દૈનિક પોષણ વિવિધતા)',
                            style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '4 / 5 Groups',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _diversityItem('1. Grains & Millets (ધાન્ય / બાજરી-રાગી)', true),
                  _diversityItem('2. Pulses & Lentils (કઠોળ / મગ દાળ)', true),
                  _diversityItem('3. Yellow/Orange Veg & Fruits (ગાજર / પપૈયું)', true),
                  _diversityItem('4. Green Leafy Veg (લીલા શાકભાજી)', true),
                  _diversityItem('5. Dairy & Animal Sourced (દૂધ-દહીં) — Target for dinner', false),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Choking Safety Guide
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tertiaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.tertiary.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_user_rounded, color: AppColors.tertiaryDark, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For 14-month toddlers: avoid whole nuts, raw carrots, or large round grapes. Mash or slice into thin matchsticks.',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11,
                        color: AppColors.tertiaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Today's Meal Routine Timeline (4 Meals)
            Text(
              "Today's Feeding Schedule (આજનો સમયપત્રક)",
              style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),

            ..._meals.map((meal) => _buildMealCard(meal)),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Generating personalized weekly AI meal plan for 14-month cohort...')),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('Generate Weekly Plan', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.shopping_basket_rounded, size: 16),
                    label: const Text('Shopping List', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _diversityItem(String label, bool isAchieved) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            isAchieved ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: isAchieved ? AppColors.statusGreen : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11,
                color: isAchieved ? AppColors.textPrimary : AppColors.textMuted,
                fontWeight: isAchieved ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(Meal meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: meal.isLogged ? AppColors.primaryContainer : AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: meal.isLogged ? AppColors.statusGreenContainer : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${meal.slotName} • ${meal.slotTime}',
                  style: AppTypography.labelSmall.copyWith(
                    color: meal.isLogged ? AppColors.statusGreen : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              if (meal.isLogged)
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.statusGreen),
                    const SizedBox(width: 4),
                    Text('Fed', style: AppTypography.labelSmall.copyWith(color: AppColors.statusGreen, fontWeight: FontWeight.bold)),
                  ],
                )
              else
                Text('₹${meal.costInRupees}/serving', style: AppTypography.labelSmall.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            meal.title,
            style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            meal.gujaratiTitle,
            style: AppTypography.gujaratiSubtitle.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: 6),
          Text(
            meal.subtitle,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('⏱️ ${meal.prepMinutes}m', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '🥣 ${meal.textureNote}',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.primaryDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/recipe_details'),
                child: const Text('Recipe >', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

