import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/status_badge.dart';

class AddChildProfileScreen extends StatefulWidget {
  const AddChildProfileScreen({super.key});

  @override
  State<AddChildProfileScreen> createState() => _AddChildProfileScreenState();
}

class _AddChildProfileScreenState extends State<AddChildProfileScreen> {
  final _nameController = TextEditingController(text: 'Aarav Shah');
  String _selectedGender = 'Boy'; // 'Boy' or 'Girl'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Child Profile (બાળકની વિગત)',
          style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          StatusBadge(
            label: 'WHO Validated',
            status: BadgeStatus.verified,
            icon: Icons.shield_rounded,
            isSmall: true,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stepper Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    _stepperTab('1. Details', true),
                    _stepperTab('2. Growth', false),
                    _stepperTab('3. Feeding', false),
                    _stepperTab('4. Center', false),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Child Photo Avatar Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: const Icon(
                            Icons.child_care_rounded,
                            size: 48,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tactile avatar assigned [Change]',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Inputs
              Text(
                "Child's Full Name (બાળકનું પૂરું નામ)",
                style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primary),
                  hintText: 'Enter child name',
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Date of Birth (જન્મ તારીખ)',
                style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      '12 Dec 2024',
                      style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textMuted),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Calculated Age Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.tertiary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cake_outlined, size: 16, color: AppColors.tertiaryDark),
                    const SizedBox(width: 8),
                    Text(
                      'Exact Age: 14 Months (૧૪ મહિના પૂર્ણ)',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.tertiaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Biological Sex Radio Cards
              Text(
                'Biological Sex (જાતિ પસંદ કરો)',
                style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _genderCard(
                      'Boy / Male',
                      'દીકરો / છોકરો',
                      Icons.male_rounded,
                      _selectedGender == 'Boy',
                      () => setState(() => _selectedGender = 'Boy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _genderCard(
                      'Girl / Female',
                      'દીકરી / છોકરી',
                      Icons.female_rounded,
                      _selectedGender == 'Girl',
                      () => setState(() => _selectedGender = 'Girl'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Upcoming Steps Preview
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upcoming Configuration Steps:',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _upcomingItem(
                      icon: Icons.monitor_weight_outlined,
                      step: 'Step 2: Growth Baseline',
                      desc: 'Birth weight: 3.1 kg • Birth length: 49.5 cm',
                    ),
                    const Divider(height: 16),
                    _upcomingItem(
                      icon: Icons.dining_outlined,
                      step: 'Step 3: Feeding Stage Selector',
                      desc: 'Stage 3: Coarse Mash & Soft Finger Foods',
                    ),
                    const Divider(height: 16),
                    _upcomingItem(
                      icon: Icons.location_on_outlined,
                      step: 'Step 4: Local Anganwadi & Diet',
                      desc: 'Sector 4, Ahmedabad • Vegetarian Diet',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Educational Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.primaryDark, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Why we ask for this info: WHO growth charts and complementary feeding recipes are personalized based on your child\'s exact age in months and biological sex. We never share identifiable data.',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // CTA Button
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Save & Open Growth Dashboard'),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepperTab(String label, bool isActive) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isActive ? Colors.white : AppColors.textMuted,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _genderCard(String title, String subtitle, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textMuted, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _upcomingItem({required IconData icon, required String step, required String desc}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step, style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700)),
              Text(desc, style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

