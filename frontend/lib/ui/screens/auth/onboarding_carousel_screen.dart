import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/status_badge.dart';

class OnboardingCarouselScreen extends StatefulWidget {
  const OnboardingCarouselScreen({super.key});

  @override
  State<OnboardingCarouselScreen> createState() => _OnboardingCarouselScreenState();
}

class _OnboardingCarouselScreenState extends State<OnboardingCarouselScreen> {
  int _currentPillar = 0; // 0 to 3

  final List<Map<String, dynamic>> _pillars = [
    {
      'title': "Understand Your Child's Nutritional Needs",
      'gujaratiTitle': "બાળકના પોષણની જરૂરિયાત સમજો",
      'stage': "Stage: 7m – 6 Years Guidance",
      'badge': "WHO Complementary Feeding Guidelines Aligned",
      'description':
          "Stage-appropriate complementary feeding from 7 months to 6 years with safe food textures and zero guesswork.",
      'microCard1': {
        'icon': Icons.biotech_rounded,
        'title': "Iron Bio-Availability",
        'tag': "C+Iron Pair",
        'desc': "Simple secrets like lemon drops on moong khichdi double iron absorption naturally.",
      },
      'microCard2': {
        'icon': Icons.blender_rounded,
        'title': "Gradual Texture Step",
        'tag': "Zero Choke",
        'desc': "Transition smoothly from smooth purées to soft mashed lumps avoiding feeding strikes.",
      },
      'btnLabel': "Next: Local Nutritious Foods (દેશી આહાર)",
    },
    {
      'title': "Affordable Local Foods (દેશી અને પૌષ્ટિક આહાર)",
      'gujaratiTitle': "સ્થાનિક, સુલભ અને પૌષ્ટિક ખોરાક",
      'stage': "Budget-Friendly: ₹20-30 / Day",
      'badge': "ICMR-NIN Indian Food Database",
      'description':
          "Wholesome Gujarati recipes using ragi, bajra, amla, sprouted pulses, and green bathua available at your local mandi.",
      'microCard1': {
        'icon': Icons.local_florist_rounded,
        'title': "Sprouted Millets",
        'tag': "Super Grain",
        'desc': "Sprouted ragi and bajra provide high bio-available calcium for strong bone density.",
      },
      'microCard2': {
        'icon': Icons.currency_rupee_rounded,
        'title': "Local Produce",
        'tag': "Low Cost",
        'desc': "Nutrient-dense meals cost less than ₹25 per bowl without buying expensive baby cereal cans.",
      },
      'btnLabel': "Next: WHO Growth Curves (વિકાસ ચાર્ટ)",
    },
    {
      'title': "WHO Growth Curves (વિકાસ માપન ચાર્ટ)",
      'gujaratiTitle': "વિશ્વ આરોગ્ય સંસ્થા માનક માપન",
      'stage': "Clinical Anthropometry",
      'badge': "Accredited Z-Score Tracking",
      'description':
          "Track weight-for-age, length-for-age, and MUAC percentiles in real-time. Know instantly if growth stays in the safe Green Zone.",
      'microCard1': {
        'icon': Icons.show_chart_rounded,
        'title': "WHO Green Zone",
        'tag': "50th Percentile",
        'desc': "Clear color-coded bands indicate healthy velocity and prevent hidden stunting.",
      },
      'microCard2': {
        'icon': Icons.notifications_active_rounded,
        'title': "Early Plateau Alerts",
        'tag': "Timely Care",
        'desc': "Get gentle nudges if growth falters for 30 days before acute malnutrition occurs.",
      },
      'btnLabel': "Next: Doctor & Anganwadi Link (આંગણવાડી સેતુ)",
    },
    {
      'title': "Doctor & Anganwadi Link (આંગણવાડી સેતુ)",
      'gujaratiTitle': "ડોક્ટર અને આંગણવાડી કાર્યકર સાથે જોડાણ",
      'stage': "Grassroots Integrated",
      'badge': "ICDS & Poshan Abhiyaan Network",
      'description':
          "Connect directly with your local Anganwadi worker (Kavita Ben) and pediatricians for Mamta Divas weigh-ins and consultations.",
      'microCard1': {
        'icon': Icons.medical_services_rounded,
        'title': "Mamta Divas Alerts",
        'tag': "Free Care",
        'desc': "Get reminders for monthly weigh-ins, free anthropometry, and Vitamin A doses.",
      },
      'microCard2': {
        'icon': Icons.medical_services_rounded,
        'title': "Verified Doctors",
        'tag': "Expert Advice",
        'desc': "Tele-consult pediatricians directly from the app when you need expert medical review.",
      },
      'btnLabel': "Complete Onboarding & Register (આગળ વધો)",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final p = _pillars[_currentPillar];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_currentPillar > 0) {
              setState(() => _currentPillar--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Row(
          children: [
            const Icon(Icons.eco_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 6),
            Text(
              'PoshanSaathi',
              style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
            child: Text(
              'Skip (છોડો)',
              style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pillar Progress Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PILLAR ${_currentPillar + 1} OF 4',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    '${((_currentPillar + 1) * 25)}% Completed',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Horizontal Segmented Bar
              Row(
                children: List.generate(4, (index) {
                  final isActive = index <= _currentPillar;
                  return Expanded(
                    child: Container(
                      height: 5,
                      margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Main Hero Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        StatusBadge(
                          label: p['stage'] as String,
                          status: BadgeStatus.verified,
                          isSmall: true,
                        ),
                        StatusBadge(
                          label: p['badge'] as String,
                          status: BadgeStatus.normal,
                          isSmall: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      p['title'] as String,
                      style: AppTypography.headline1.copyWith(
                        fontSize: 22,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p['gujaratiTitle'] as String,
                      style: AppTypography.gujaratiSubtitle.copyWith(
                        fontSize: 14,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      p['description'] as String,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Micro-Card 1
                    _buildMicroCard(p['microCard1'] as Map<String, dynamic>),
                    const SizedBox(height: 10),

                    // Micro-Card 2
                    _buildMicroCard(p['microCard2'] as Map<String, dynamic>),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Next CTA
              ElevatedButton(
                onPressed: () {
                  if (_currentPillar < 3) {
                    setState(() => _currentPillar++);
                  } else {
                    Navigator.pushReplacementNamed(context, '/register');
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(p['btnLabel'] as String),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                  child: Text(
                    'Skip directly to personalized dashboard >',
                    style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Footer Accreditation
              Center(
                child: Text(
                  'Seva First Innovation Challenge 2026-27 • ICMR-NIN Infant Feeding Certified • Guided by WHO Child Growth Standards (0-60 Months)',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMicroCard(Map<String, dynamic> card) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              card['icon'] as IconData,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      card['title'] as String,
                      style: AppTypography.labelLarge.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        card['tag'] as String,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 9,
                          color: AppColors.tertiaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  card['desc'] as String,
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
    );
  }
}

