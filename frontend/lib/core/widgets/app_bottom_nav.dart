import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../constants/app_strings.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.eco_rounded,
                activeIcon: Icons.eco,
                label: AppStrings.navHome,
                gujaratiLabel: AppStrings.navHomeGuj,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.restaurant_menu_rounded,
                activeIcon: Icons.restaurant_menu,
                label: AppStrings.navMeals,
                gujaratiLabel: AppStrings.navMealsGuj,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.show_chart_rounded,
                activeIcon: Icons.show_chart,
                label: AppStrings.navGrowth,
                gujaratiLabel: AppStrings.navGrowthGuj,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.auto_awesome_outlined,
                activeIcon: Icons.auto_awesome,
                label: AppStrings.navAI,
                gujaratiLabel: AppStrings.navAIGuj,
                isSpecial: true,
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: AppStrings.navProfile,
                gujaratiLabel: AppStrings.navProfileGuj,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String gujaratiLabel,
    bool isSpecial = false,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textMuted;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isSpecial
                            ? AppColors.tertiaryLight
                            : AppColors.primaryContainer.withOpacity(0.5))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    size: 22,
                    color: isSelected
                        ? (isSpecial ? AppColors.tertiaryDark : AppColors.primary)
                        : color,
                  ),
                ),
                if (isSpecial && !isSelected)
                  Positioned(
                    right: 4,
                    top: 2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.tertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
            Text(
              gujaratiLabel,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? AppColors.primaryDark : AppColors.textDisabled,
                fontSize: 9,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

