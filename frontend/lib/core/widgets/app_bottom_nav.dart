import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

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
        border: Border(top: BorderSide(color: AppColors.borderSage, width: 1)),
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
                icon: Icons.home_rounded,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                gujaratiLabel: 'મુખ્ય',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.restaurant_rounded,
                activeIcon: Icons.restaurant_rounded,
                label: 'Meals',
                gujaratiLabel: 'આહારે',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.trending_up_rounded,
                activeIcon: Icons.trending_up_rounded,
                label: 'Growth',
                gujaratiLabel: 'વિકાસ',
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.auto_awesome_rounded,
                activeIcon: Icons.auto_awesome_rounded,
                label: 'Ask AI',
                gujaratiLabel: 'એઆઈ સહાય',
                isSpecial: true,
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                gujaratiLabel: 'પ્રોફાઈલ',
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
    final color = isSelected ? AppColors.primaryForestGreen : AppColors.textMuted;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.lightGreenAccent
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 22,
                color: isSelected
                    ? AppColors.primaryForestGreen
                    : color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? AppColors.primaryForestGreen : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
            Text(
              gujaratiLabel,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? AppColors.darkForestGreen : AppColors.textDisabled,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
