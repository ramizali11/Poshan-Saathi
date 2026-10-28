import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

class BilingualText extends StatelessWidget {
  final String primaryText;
  final String? gujaratiText;
  final TextStyle? primaryStyle;
  final TextStyle? gujaratiStyle;
  final CrossAxisAlignment crossAxisAlignment;

  const BilingualText({
    super.key,
    required this.primaryText,
    this.gujaratiText,
    this.primaryStyle,
    this.gujaratiStyle,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          primaryText,
          style: primaryStyle ?? AppTypography.bodyLarge,
        ),
        if (gujaratiText != null && gujaratiText!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            gujaratiText!,
            style: gujaratiStyle ?? AppTypography.gujaratiSubtitle,
          ),
        ],
      ],
    );
  }
}

