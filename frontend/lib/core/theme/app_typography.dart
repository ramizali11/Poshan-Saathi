import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  static const String headlineFont = 'Manrope';
  static const String bodyFont = 'Manrope';
  static const String labelFont = 'Inter';
  static const List<String> gujaratiFallback = ['Noto Sans Gujarati', 'NotoSansGujarati', 'sans-serif'];

  // Headlines
  static TextStyle get displayLarge => const TextStyle(
    fontFamily: headlineFont,
    fontFamilyFallback: gujaratiFallback,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle get headline1 => const TextStyle(
    fontFamily: headlineFont,
    fontFamilyFallback: gujaratiFallback,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get headline2 => const TextStyle(
    fontFamily: headlineFont,
    fontFamilyFallback: gujaratiFallback,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get headline3 => const TextStyle(
    fontFamily: headlineFont,
    fontFamilyFallback: gujaratiFallback,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // Body text
  static TextStyle get bodyLarge => const TextStyle(
    fontFamily: bodyFont,
    fontFamilyFallback: gujaratiFallback,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => const TextStyle(
    fontFamily: bodyFont,
    fontFamilyFallback: gujaratiFallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static TextStyle get bodySmall => const TextStyle(
    fontFamily: bodyFont,
    fontFamilyFallback: gujaratiFallback,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  // Labels & Buttons
  static TextStyle get labelLarge => const TextStyle(
    fontFamily: labelFont,
    fontFamilyFallback: gujaratiFallback,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );

  static TextStyle get labelMedium => const TextStyle(
    fontFamily: labelFont,
    fontFamilyFallback: gujaratiFallback,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle get labelSmall => const TextStyle(
    fontFamily: labelFont,
    fontFamilyFallback: gujaratiFallback,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );

  // Vernacular Gujarati Script
  static TextStyle get gujaratiSubtitle => const TextStyle(
    fontFamily: 'Noto Sans Gujarati',
    fontFamilyFallback: ['NotoSansGujarati', 'sans-serif'],
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.3,
  );
}
