import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/constants/app_images_data.dart';
import '../../../core/services/meals_data_service.dart';
import '../../../core/services/shopping_list_service.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  final MealsDataService _mealsService = MealsDataService.instance;
  final ShoppingListService _shoppingService = ShoppingListService.instance;

  int _selectedDayIndex = 2; // Index 2 is TODAY 25

  final List<Map<String, String>> _weekDays = [
    {'day': 'Mon', 'date': '23'},
    {'day': 'Tue', 'date': '24'},
    {'day': 'TODAY', 'date': '25'},
    {'day': 'Thu', 'date': '26'},
    {'day': 'Fri', 'date': '27'},
    {'day': 'Sat', 'date': '28'},
    {'day': 'Sun', 'date': '1'},
  ];

  // Interactive 5 Food Groups for Daily Diversity Tracking
  final List<Map<String, dynamic>> _foodGroups = [
    {
      'id': 'grains',
      'icon': Icons.grain_rounded,
      'iconBg': const Color(0xFFFFECC8),
      'iconColor': const Color(0xFF92400E),
      'title': 'Grains & Millets',
      'subtitle': 'Ragi, Rice, Wheat, Bajra, Jowar',
      'checked': true,
      'description': 'Provides carbohydrates, dietary fiber, and energy for growth.',
    },
    {
      'id': 'pulses',
      'icon': Icons.bubble_chart_rounded,
      'iconBg': const Color(0xFFFFD8D4),
      'iconColor': const Color(0xFFDC2626),
      'title': 'Pulses & Lentils',
      'subtitle': 'Moong, Masoor, Toor, Chana',
      'checked': true,
      'description': 'Essential plant proteins, iron, and folic acid for muscle development.',
    },
    {
      'id': 'fruits',
      'icon': Icons.energy_savings_leaf_rounded,
      'iconBg': const Color(0xFFFFE0B2),
      'iconColor': const Color(0xFFEA580C),
      'title': 'Orange Veg & Fruits',
      'subtitle': 'Carrot, Pumpkin, Papaya, Mango',
      'checked': true,
      'description': 'Rich in Vitamin A & beta-carotene for immune health and vision.',
    },
    {
      'id': 'greens',
      'icon': Icons.eco_rounded,
      'iconBg': const Color(0xFFDCFCE7),
      'iconColor': const Color(0xFF16A34A),
      'title': 'Green Leafy Veg',
      'subtitle': 'Spinach, Methi, Amaranth, Drumstick leaves',
      'checked': true,
      'description': 'Packed with Iron, Calcium, and Vitamin C to prevent childhood anemia.',
    },
    {
      'id': 'dairy',
      'icon': Icons.water_drop_rounded,
      'iconBg': const Color(0xFFE0F2FE),
      'iconColor': const Color(0xFF0284C7),
      'title': 'Dairy & Protein',
      'subtitle': 'Milk, Curd, Paneer, Egg, Fish, Chicken',
      'checked': false,
      'description': 'High-bioavailability calcium, phosphorus, and zinc for healthy bone growth.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _mealsService.init();
    _shoppingService.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28, color: Color(0xFF171B18)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Meal Planner',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17.5,
                  color: Color(0xFF171B18),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Aarav Shah • 14m • Stage 3 Coarse Mash',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF5F665F),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_basket_outlined, size: 24, color: Color(0xFF171B18)),
            tooltip: 'Shopping List',
            onPressed: () => Navigator.pushNamed(context, '/shopping_list'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Weekly Calendar Strip
            Row(
              children: List.generate(_weekDays.length, (index) {
                final isSelected = _selectedDayIndex == index;
                final d = _weekDays[index];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDayIndex = index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF176B3A) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF176B3A) : const Color(0xFFDFE6DA),
                          width: 1.1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF176B3A).withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            d['day']!,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF5F665F),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            d['date']!,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF171B18),
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),

            // 2. Clickable Daily Diversity Tracker Card (Images removed as requested)
            _buildDiversityTrackerCard(),
            const SizedBox(height: 14),

            // 3. Toddler Safety Advisory Card
            _buildAdvisoryCard(),
            const SizedBox(height: 16),

            // 4. Today's Feeding Schedule Header
            Row(
              children: [
                const Icon(Icons.access_time_rounded, color: Color(0xFF176B3A), size: 19),
                const SizedBox(width: 6),
                const Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Today's Feeding Schedule (આજનો સમયપત્રક)",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: Color(0xFF171B18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _showAddMealModal(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F3E2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_rounded, size: 14, color: Color(0xFF176B3A)),
                        SizedBox(width: 4),
                        Text(
                          'Add Meal',
                          style: TextStyle(
                            color: Color(0xFF176B3A),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 5. Feeding Schedule Meal 1: Morning Snack
            _buildMealCard(
              categoryPillColor: const Color(0xFFFFF9C4),
              categoryIcon: Icons.wb_sunny_rounded,
              categoryIconColor: const Color(0xFFF59E0B),
              categoryLabel: 'Morning Snack • 9:30 AM',
              foodImageBytes: AppImagesData.mealPapayaSheeraBytes,
              title: 'Mashed Papaya & Sprouted Ragi Sheera',
              gujaratiTitle: 'પપૈયું અને અંકુરિત રાગી શીરો',
              subtitle: 'Natural sweetness, High Calcium & Vitamin A',
              prepTime: '15m',
              textureText: 'Smooth with fine ragi granules',
              textureIcon: Icons.soup_kitchen_rounded,
            ),
            const SizedBox(height: 12),

            // 6. Feeding Schedule Meal 2: Lunch
            _buildMealCard(
              categoryPillColor: const Color(0xFFFFE0B2),
              categoryIcon: Icons.restaurant_rounded,
              categoryIconColor: const Color(0xFFE65100),
              categoryLabel: 'Lunch (બપોરનું ભોજન) • 12:30 PM',
              foodImageBytes: AppImagesData.mealKhichdiPlatterBytes,
              title: 'Moong Dal Khichdi with Carrot & Spinach',
              gujaratiTitle: 'મગ દાળ ખીચડી સાથે ગાજર અને પાલક',
              subtitle: 'Easy to digest, Rich in Iron & Fiber',
              prepTime: '20m',
              textureText: 'Soft & well mashed',
              textureIcon: Icons.eco_rounded,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- 2. Interactive Clickable Daily Diversity Tracker Card ---
  Widget _buildDiversityTrackerCard() {
    final checkedCount = _foodGroups.where((g) => g['checked'] == true).length;
    final isComplete = checkedCount == _foodGroups.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.restaurant_rounded, size: 20, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Diversity Tracker\n(દૈનિક પોષણ વિવિધતા)',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: Color(0xFF1E293B),
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Tap any group below to mark consumed or pending.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Dynamic Diversity Status Badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isComplete ? const Color(0xFFDCFCE7) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isComplete ? const Color(0xFF16A34A) : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isComplete ? Icons.star_rounded : Icons.eco_rounded,
                      size: 14,
                      color: isComplete ? const Color(0xFF16A34A) : const Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isComplete ? '5 / 5 Complete!' : '$checkedCount / 5 Groups',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isComplete ? const Color(0xFF16A34A) : const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 5 Clickable Food Group List Items (Clean, Spaced, Without Images)
          ...List.generate(_foodGroups.length, (index) {
            final group = _foodGroups[index];
            final isChecked = group['checked'] as bool;

            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Material(
                color: isChecked ? const Color(0xFFF9FCF9) : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      group['checked'] = !isChecked;
                    });
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          !isChecked
                              ? '✓ ${group['title']} marked as fed today!'
                              : '○ ${group['title']} marked as pending.',
                        ),
                        backgroundColor: !isChecked ? const Color(0xFF2E7D32) : const Color(0xFF475569),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isChecked ? const Color(0xFFD4EBD4) : const Color(0xFFE2E8F0),
                        width: 1.1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Category Icon
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: group['iconBg'] as Color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(group['icon'] as IconData, size: 19, color: group['iconColor'] as Color),
                        ),
                        const SizedBox(width: 12),

                        // Checkmark Button / Indicator
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isChecked ? const Color(0xFF2E7D32) : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isChecked ? const Color(0xFF2E7D32) : const Color(0xFF94A3B8),
                              width: 1.8,
                            ),
                          ),
                          child: isChecked
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),

                        // Title & Subtitle (Now has full available width without image!)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group['title'] as String,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: isChecked ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                group['subtitle'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isChecked ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Right Status Chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isChecked ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isChecked ? 'Fed' : '+ Add',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isChecked ? const Color(0xFF2E7D32) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- 3. Toddler Safety Advisory Card ---
  Widget _buildAdvisoryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF0E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF7D9C4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.security_rounded, color: Color(0xFFBA5D00), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'For 14-month toddlers: avoid whole nuts, raw carrots, or large round grapes. Mash or slice into thin matchsticks.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF8B4500),
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, color: Color(0xFFBA5D00), size: 18),
        ],
      ),
    );
  }

  // --- 4. Today's Feeding Schedule Meal Card ---
  Widget _buildMealCard({
    required Color categoryPillColor,
    required IconData categoryIcon,
    required Color categoryIconColor,
    required String categoryLabel,
    required Uint8List foodImageBytes,
    required String title,
    required String gujaratiTitle,
    required String subtitle,
    required String prepTime,
    required String textureText,
    required IconData textureIcon,
  }) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/recipe_details'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row (Category Badge & Status)
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryPillColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(categoryIcon, size: 13, color: categoryIconColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              categoryLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, size: 13, color: Color(0xFF2E7D32)),
                      SizedBox(width: 3),
                      Text(
                        'Fed',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.more_vert, size: 18, color: Color(0xFF94A3B8)),
              ],
            ),
            const SizedBox(height: 10),

            // Content Row (Food Photo + Details)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: Image.memory(
                      foodImageBytes,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        gujaratiTitle,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A6B4F),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Chips Row
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 3),
                          Text(
                            prepTime,
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Icon(textureIcon, size: 12, color: const Color(0xFFE65100)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              textureText,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Recipe >',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF176B3A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMealModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add Meal to Schedule',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: _mealsService.allMeals.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final meal = _mealsService.allMeals[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(meal.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: Text('${meal.calories} kcal • ${meal.prepMinutes} mins', style: const TextStyle(fontSize: 11)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF176B3A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${meal.title} added to schedule!'),
                            backgroundColor: const Color(0xFF176B3A),
                          ),
                        );
                      },
                      child: const Text('Add', style: TextStyle(fontSize: 12)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
