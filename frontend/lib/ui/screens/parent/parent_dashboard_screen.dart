import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_typography.dart';
import 'package:frontend/core/widgets/status_badge.dart';
import 'package:frontend/core/widgets/metric_tile.dart';
import 'package:frontend/core/data/mock_data.dart';   

class ParentDashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToMeals;
  final VoidCallback? onNavigateToGrowth;
  final VoidCallback? onNavigateToAI;

  const ParentDashboardScreen({
    super.key,
    this.onNavigateToMeals,
    this.onNavigateToGrowth,
    this.onNavigateToAI,
  });

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final ChildProfile _child = MockData.defaultChild;

  @override
  void initState() {
    super.initState();
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('🚨 [DASHBOARD RENDER ERROR CAUGHT]: ${details.exceptionAsString()}');
      originalOnError?.call(details);
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.eco_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 6),
                Text(
                  'PoshanSaathi',
                  style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            Text(
              'પોષણ સાથી • SEVA FIRST',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.secondary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          // Child Switcher Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: AppColors.primary,
                  child: const Text('AS', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                Text(
                  'Aarav (14m)',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.primaryDark),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Notification Bell
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, size: 22),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.statusRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => Navigator.pushNamed(context, '/reminders'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Greeting Card
            SafeLayoutBox(
              name: 'GreetingCard',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good morning, Priya! ☀️',
                            style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'સુપ્રભાત • Happy feeding day',
                            style: AppTypography.gujaratiSubtitle.copyWith(color: AppColors.secondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Let's take a gentle, healthy step toward Aarav's growth milestone today.",
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Hero Child Growth Card (#ceeace background)
            SafeLayoutBox(
              name: 'HeroGrowthCard',
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary,
                          child: const Text('14m', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _child.name,
                                      style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
                                ],
                              ),
                              Text(
                                _child.feedingStage,
                                style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        StatusBadge(
                          label: 'WHO Green Zone',
                          status: BadgeStatus.normal,
                          icon: Icons.verified_rounded,
                          isSmall: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3 Metric Tiles
                    Row(
                      children: [
                        Expanded(
                          child: MetricTile(
                            icon: Icons.scale_rounded,
                            label: 'WEIGHT',
                            value: '${_child.currentWeightKg} kg',
                            subtext: '+0.3kg / 30d',
                            iconColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: MetricTile(
                            icon: Icons.straighten_rounded,
                            label: 'LENGTH',
                            value: '${_child.currentLengthCm} cm',
                            subtext: '50th Percentile',
                            iconColor: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: MetricTile(
                            icon: Icons.calendar_today_rounded,
                            label: 'MEASURED',
                            value: '12 Feb',
                            subtext: 'By ASHA worker',
                            iconColor: AppColors.tertiaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ASHA & Chart Link Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.volunteer_activism_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Kavita Ben • Anganwadi Sector 4',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            if (widget.onNavigateToGrowth != null) {
                              widget.onNavigateToGrowth!();
                            } else {
                              Navigator.pushNamed(context, '/growth');
                            }
                          },
                          icon: const Icon(Icons.show_chart_rounded, size: 16),
                          label: const Text('View Chart >', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Actions 2x2 Grid
            SafeLayoutBox(
              name: 'QuickActions',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions (ત્વરિત સેવાઓ)',
                    style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.auto_awesome,
                            iconColor: AppColors.tertiaryDark,
                            bgColor: AppColors.tertiaryLight,
                            title: 'Ask PoshanSaathi AI',
                            subtitle: 'Instant feeding advice & remedies (24/7 AI)',
                            onTap: () {
                              if (widget.onNavigateToAI != null) {
                                widget.onNavigateToAI!();
                              } else {
                                Navigator.pushNamed(context, '/ai_assistant');
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.straighten_rounded,
                            iconColor: AppColors.primary,
                            bgColor: AppColors.primaryLight,
                            title: 'Log Growth',
                            subtitle: 'Update height, weight & teeth',
                            onTap: () {
                              if (widget.onNavigateToGrowth != null) {
                                widget.onNavigateToGrowth!();
                              } else {
                                Navigator.pushNamed(context, '/growth');
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.restaurant_rounded,
                            iconColor: AppColors.secondary,
                            bgColor: AppColors.secondaryLight,
                            title: 'Iron & Anemia Guide',
                            subtitle: 'Desi spinach, amla & jaggery recipes',
                            onTap: () => Navigator.pushNamed(context, '/recipe_details'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.medical_services_rounded,
                            iconColor: AppColors.statusBlue,
                            bgColor: AppColors.statusBlueContainer,
                            title: 'Consult Pediatrician',
                            subtitle: 'Dr. Meera Patel • Next slot today',
                            onTap: () => Navigator.pushNamed(context, '/clinician_dashboard'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Today's Meal Plan Card
            SafeLayoutBox(
              name: 'MealPlanCard',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Meal Plan (આજનો આહાર)",
                                style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '3 / 4 Logged • 75% Diversity',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.statusGreen, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (widget.onNavigateToMeals != null) {
                              widget.onNavigateToMeals!();
                            } else {
                              Navigator.pushNamed(context, '/meals');
                            }
                          },
                          child: const Text('Full Planner >', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Featured Lunch Meal
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'LUNCH (બપોરનું ભોજન) • 12:30 PM',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.bolt_rounded, size: 16, color: AppColors.tertiaryDark),
                              Text('Iron-Rich', style: AppTypography.labelSmall.copyWith(color: AppColors.tertiaryDark, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vegetable Moong Dal Khichdi with Steamed Carrots & Desi Cow Ghee',
                            style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'શાકભાજી મગની દાળની ખીચડી અને દેશી ઘી',
                            style: AppTypography.gujaratiSubtitle.copyWith(color: AppColors.secondary),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            children: [
                              _pillChip('Soft Coarse Mash'),
                              _pillChip('⏱️ 20 mins'),
                              _pillChip('~₹22 / serving'),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Absorption Booster Box
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.tertiaryLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.tertiary.withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.tips_and_updates_rounded, color: AppColors.tertiaryDark, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Squeeze 3 drops of fresh lemon or serve with grated amla to boost plant-iron absorption by up to 300%.',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 11,
                                      color: AppColors.tertiaryDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  ),
                                  onPressed: () => Navigator.pushNamed(context, '/recipe_details'),
                                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                                  label: const Text('View Recipe & Cook', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                  ),
                                  onPressed: () {},
                                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                                  label: const Text('Swap', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Little Nutrition Secret Card (Amber Tint)
            SafeLayoutBox(
              name: 'NutritionSecretCard',
              child: Container(
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
                        Expanded(
                          child: Text(
                            'Little Nutrition Secret (પોષણ ગુણ)',
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.tertiaryDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Iron from Indian plant sources needs vitamin C buddies to be absorbed well. Avoid giving whole cow\'s milk right alongside staple grains and pulses, as excess calcium can temporarily block iron uptake.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ICMR-NIN Infant Guidelines 2024 • Clinical Team Reviewed',
                      style: AppTypography.labelSmall.copyWith(fontSize: 10, color: AppColors.tertiaryDark),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Community Care Schedule Card
            SafeLayoutBox(
              name: 'CommunityCareCard',
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.event_available_rounded, color: AppColors.primaryDark, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next Anganwadi Growth Day',
                            style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Thursday, 26 Feb (in 12 days) • Sector 4 Center',
                            style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.alarm_add_rounded, color: AppColors.primary),
                      onPressed: () => Navigator.pushNamed(context, '/reminders'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(fontSize: 10, color: AppColors.textSecondary),
      ),
    );
  }
}

class SafeLayoutBox extends SingleChildRenderObjectWidget {
  final String name;

  const SafeLayoutBox({super.key, required super.child, required this.name});

  @override
  RenderObject createRenderObject(BuildContext context) => RenderSafeBox(name: name);
}

class RenderSafeBox extends RenderProxyBox {
  final String name;
  bool _hasLayoutError = false;

  RenderSafeBox({required this.name});

  @override
  void performLayout() {
    if (child != null) {
      try {
        child!.layout(constraints, parentUsesSize: true);
        size = child!.size;
        _hasLayoutError = false;
      } catch (e, stack) {
        _hasLayoutError = true;
        size = constraints.constrain(Size.zero);
        debugPrint('🚨 [SAFE_LAYOUT_BOX CAUGHT IN $name]: $e');
        debugPrint('$stack');
      }
    } else {
      size = constraints.smallest;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_hasLayoutError && child != null) {
      context.paintChild(child!, offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (_hasLayoutError || child == null) return false;
    return super.hitTestChildren(result, position: position);
  }
}

