import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum BadgeStatus {
  normal,      // WHO Green Zone
  warning,     // Needs Review / Plateau
  danger,      // Faltering / High Risk
  info,        // Protocol / Scheduled
  verified,    // Accredited / Verified
  neutral,     // General chip
}

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeStatus status;
  final IconData? icon;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.label,
    this.status = BadgeStatus.neutral,
    this.icon,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    switch (status) {
      case BadgeStatus.normal:
        bg = AppColors.statusGreenContainer;
        fg = AppColors.statusGreen;
        border = AppColors.statusGreen.withOpacity(0.3);
        break;
      case BadgeStatus.warning:
        bg = AppColors.statusOrangeContainer;
        fg = AppColors.statusOrange;
        border = AppColors.statusOrange.withOpacity(0.3);
        break;
      case BadgeStatus.danger:
        bg = AppColors.statusRedContainer;
        fg = AppColors.statusRed;
        border = AppColors.statusRed.withOpacity(0.3);
        break;
      case BadgeStatus.info:
        bg = AppColors.statusBlueContainer;
        fg = AppColors.statusBlue;
        border = AppColors.statusBlue.withOpacity(0.3);
        break;
      case BadgeStatus.verified:
        bg = AppColors.primaryContainer;
        fg = AppColors.primaryDark;
        border = AppColors.primary.withOpacity(0.3);
        break;
      case BadgeStatus.neutral:
        bg = AppColors.surfaceVariant;
        fg = AppColors.textSecondary;
        border = AppColors.border;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isSmall ? 12 : 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: fg,
              fontSize: isSmall ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

