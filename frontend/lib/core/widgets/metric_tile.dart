import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtext;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? subtextColor;

  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subtext,
    this.iconColor,
    this.backgroundColor,
    this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EDE2), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor ?? AppColors.primaryForestGreen),
              const SizedBox(width: 4),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(
                      color: const Color(0xFF737871),
                      fontWeight: FontWeight.w700,
                      fontSize: 9.5,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.headline2.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.mainText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtext != null) ...[
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F3DF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  subtext!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF176B3A),
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
