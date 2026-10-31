import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/services/child_session.dart';

class RecipeDetailsScreen extends StatefulWidget {
  const RecipeDetailsScreen({super.key});

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  final List<bool> _checkedIngredients = [true, true, true, true, true, true];
  bool _isCooked = false;

  final List<String> _ingredients = [
    'Yellow moong dal (પીળી મગની દાળ) Pre-soaked 15m — 2 tbsp',
    'Broken raw rice (ટુકડા ચોખા) Easier for toddler gut — 2 tbsp',
    'Tender carrot diced small (ઝીણું ગાજર) Steamed/brunoised — 1 tbsp',
    'Turmeric & Cumin (હળદર અને જીરું) Carminative herbs — 1 pinch each',
    'Pure Desi Cow Ghee (ગાયનું ઘી) A2 nutrition — 1 tsp',
    'Clean filtered water (પાણી) Porridge consistency — 1 cup',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'વાનગી વિગત • Recipe Details',
          style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
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
                  StatusBadge(
                    label: 'Stage 3: 10-18 Months • બાળ પોષણ સંગ્રહ',
                    status: BadgeStatus.verified,
                    icon: Icons.child_care_rounded,
                    isSmall: true,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Vegetable Moong Dal Khichdi\n(શાકભાજી મગની દાળની ખીચડી)',
                    style: AppTypography.headline1.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Steamed Carrots & Desi Ghee • પૌષ્ટિક બપોરનું ભોજન',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      StatusBadge(label: 'Prep: 20 mins', icon: Icons.timer_outlined, isSmall: true),
                      StatusBadge(label: 'Cost: ~₹22 / serving', icon: Icons.payments_outlined, isSmall: true),
                      StatusBadge(label: 'Iron Bio-available', status: BadgeStatus.normal, icon: Icons.water_drop_outlined, isSmall: true),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Absorption Secret Card (Amber Tint)
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
                        'Absorption Secret (પોષણ રહસ્ય)',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.tertiaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Non-heme plant iron is 3x better absorbed when paired with Vitamin C.',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Squeeze 3 drops of fresh lemon or serve with amla paste right before feeding!',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'જમતા પહેલાં ૩ ટીપાં તાજા લીંબુનો રસ ઉમેરવાથી દાળનું લોહતત્વ બાળક ઝડપથી પચાવી શકે છે.',
                    style: AppTypography.gujaratiSubtitle.copyWith(color: AppColors.secondaryDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Nutritional Balance (WHO Metrics)
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
                    'Nutritional Balance (WHO Growth Metrics)',
                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _nutrientItem('Plant Protein', 'Moong Dal 4.2g', 'Muscle growth', Icons.egg_alt_outlined)),
                      Expanded(child: _nutrientItem('Carbohydrates', 'Rice 18g', 'Active energy', Icons.grain_outlined)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _nutrientItem('Vitamin A', 'Carrots', 'Eye & immunity', Icons.visibility_outlined)),
                      Expanded(child: _nutrientItem('Healthy Fats', 'Desi Ghee 1 tsp', 'Brain lipids', Icons.local_fire_department_outlined)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ingredients Checklist (6 Items)
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
                        'Ingredients (ઘટકો) • Serves 1 Toddler',
                        style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '6 Items',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_ingredients.length, (i) {
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.primary,
                      title: Text(
                        _ingredients[i],
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12,
                          decoration: _checkedIngredients[i] ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      value: _checkedIngredients[i],
                      onChanged: (val) {
                        setState(() => _checkedIngredients[i] = val ?? false);
                      },
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Step-by-Step Cooking Guide
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
                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _cookingStep(
                    stepNum: 1,
                    time: '5 mins',
                    title: 'Cleanse & Soak',
                    desc: 'Wash moong dal and broken rice thoroughly 3 times until clear. Soak in warm water for 10-15 minutes.',
                  ),
                  const Divider(height: 20),
                  _cookingStep(
                    stepNum: 2,
                    time: '12 mins',
                    title: 'Gentle Pressure Cooking',
                    desc: 'Add grains, diced carrots, water, turmeric and cumin. Pressure cook for 3-4 whistles on medium flame.',
                  ),
                  const Divider(height: 20),
                  _cookingStep(
                    stepNum: 3,
                    time: 'Texture Critical',
                    title: 'Fork Mash (Do NOT Blend)',
                    desc: 'Let steam release naturally. Stir in ghee. Fork-mash softly with back of spoon. Soft solid lumps train oral-motor chewing and tongue lateralization.',
                    isWarning: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Allergen & Safety Check
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Contains dairy (Cow Ghee). If sensitive, substitute with cold-pressed sesame oil. Ensure carrot pieces are steamed fully soft before mashing to eliminate choking risk.',
                      style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // CTA Button
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _isCooked = true);
                final childName = ChildSession.instance.activeChildName;
                final childAge = ChildSession.instance.activeChild?.ageDisplay ?? 'Milestone';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Logged into $childName's Daily Micronutrient Tracker ($childAge)!"),
                    backgroundColor: AppColors.statusGreen,
                  ),
                );
              },
              icon: Icon(_isCooked ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded),
              label: Text(_isCooked
                  ? 'Cooked & Logged (જમા થઈ ગયું)'
                  : 'Mark as Cooked & Log Meal (જમા કરો)'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _nutrientItem(String title, String value, String benefit, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
              Text(value, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold)),
              Text(benefit, style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.statusGreen)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cookingStep({
    required int stepNum,
    required String time,
    required String title,
    required String desc,
    bool isWarning = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isWarning ? AppColors.statusOrange : AppColors.primary,
          child: Text('$stepNum', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                  Text(time, style: AppTypography.labelSmall.copyWith(color: isWarning ? AppColors.statusOrange : AppColors.textMuted, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text(desc, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

