import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/status_badge.dart';

class WelcomeRoleScreen extends StatefulWidget {
  const WelcomeRoleScreen({super.key});

  @override
  State<WelcomeRoleScreen> createState() => _WelcomeRoleScreenState();
}

class _WelcomeRoleScreenState extends State<WelcomeRoleScreen> {
  int _selectedRoleIndex = 0; // 0: Parent, 1: Doctor, 2: Admin
  bool _isGujarati = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Accredited Banner & Language Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'SFIC 2026-27 Accredited',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Language Toggle Pill
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _langButton('EN', !_isGujarati, () {
                          setState(() => _isGujarati = false);
                        }),
                        _langButton('ગુજરાતી', _isGujarati, () {
                          setState(() => _isGujarati = true);
                        }),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Brand Hero Section
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33526B55),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'PoshanSaathi',
                      style: AppTypography.displayLarge.copyWith(
                        color: AppColors.primaryDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'પોષણસાથી • MATERNAL & INFANT CARE',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isGujarati
                          ? 'નાના બાળકોનું સ્વસ્થ પોષણ અને ઉજ્જવળ ભવિષ્ય'
                          : 'Nourishing Little Lives, One Meal at a Time.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        StatusBadge(
                          label: 'Evidence-Based Infant Feeding',
                          icon: Icons.restaurant_rounded,
                          status: BadgeStatus.verified,
                          isSmall: true,
                        ),
                        StatusBadge(
                          label: 'WHO Standards',
                          icon: Icons.verified_user,
                          status: BadgeStatus.normal,
                          isSmall: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Select Role Header
              Text(
                _isGujarati ? 'તમારી ભૂમિકા પસંદ કરો' : 'Choose Your Role to Begin',
                style: AppTypography.headline3.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isGujarati
                  ? 'તમારા ઉપયોગ અનુસાર વ્યક્તિગત અનુભવ મેળવો'
                  : 'Select how you will be using PoshanSaathi today',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 14),

              // Role Cards
              _buildRoleCard(
                index: 0,
                title: 'Parent / Caregiver',
                gujaratiTitle: 'માતા-પિતા અથવા પાલક',
                badgeText: 'Most Popular • 7m - 6 yrs',
                description:
                    'Track growth with WHO curves, get tailored complementary feeding recipes, and consult verified nutritionists.',
                icon: Icons.family_restroom_rounded,
                accentColor: AppColors.primary,
              ),
              const SizedBox(height: 12),
              _buildRoleCard(
                index: 1,
                title: 'Doctor & Nutritionist',
                gujaratiTitle: 'ડોક્ટર / બાળ પોષણ નિષ્ણાત',
                badgeText: 'Clinical & ASHA Network',
                description:
                    'Review growth curves, assess clinical risk factors, and guide parents with verified complementary care plans.',
                icon: Icons.medical_services_outlined,
                accentColor: AppColors.secondary,
              ),
              const SizedBox(height: 12),
              _buildRoleCard(
                index: 2,
                title: 'Administrator',
                gujaratiTitle: 'આંગણવાડી સંયોજક / સંચાલક',
                badgeText: 'Official Access Only',
                description:
                    'Oversee sector centers, verify medical credentials, and manage community nutrition programs.',
                icon: Icons.admin_panel_settings_outlined,
                accentColor: AppColors.textSecondary,
              ),
              const SizedBox(height: 24),

              // CTA Action Button
              ElevatedButton(
                onPressed: () {
                  if (_selectedRoleIndex == 0) {
                    Navigator.pushNamed(context, '/onboarding');
                  } else if (_selectedRoleIndex == 1) {
                    Navigator.pushNamed(context, '/clinician_register');
                  } else {
                    Navigator.pushNamed(context, '/clinician_dashboard');
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedRoleIndex == 0
                          ? (_isGujarati ? 'આગળ વધો (વાલી તરીકે)' : 'Continue as Parent')
                          : (_selectedRoleIndex == 1
                              ? 'Continue to Clinical Portal'
                              : 'Access Admin Dashboard'),
                      style: AppTypography.labelLarge.copyWith(color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Log In Option
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: AppTypography.bodyMedium,
                      children: [
                        TextSpan(
                          text: 'Log In (પ્રવેશ કરો)',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Credibility Anchor Footer
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CLINICAL CREDIBILITY ANCHOR',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'In alignment with ICMR-NIN Infant Nutrition Guidelines & WHO Growth Standards. Govt. of Gujarat • Poshan Abhiyaan Digital Support Partner',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required int index,
    required String title,
    required String gujaratiTitle,
    required String badgeText,
    required String description,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = _selectedRoleIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedRoleIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer.withOpacity(0.6)
                    : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primaryDark : accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTypography.headline3.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isSelected ? AppColors.primary : AppColors.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                  Text(
                    gujaratiTitle,
                    style: AppTypography.gujaratiSubtitle.copyWith(
                      color: AppColors.secondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.tertiaryDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

