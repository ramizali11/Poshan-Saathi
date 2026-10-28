import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_typography.dart';
import 'package:frontend/core/widgets/metric_tile.dart';

class AssignedChildrenScreen extends StatefulWidget {
  const AssignedChildrenScreen({super.key});

  @override
  State<AssignedChildrenScreen> createState() => _AssignedChildrenScreenState();
}

class _AssignedChildrenScreenState extends State<AssignedChildrenScreen> {
  int _selectedChildIndex = 0; // 0: Aarav Shah
  int _selectedFilter = 0;

  final List<Map<String, dynamic>> _children = [
    {
      'name': 'Aarav Shah',
      'mother': 'Priya Shah',
      'abha': '91-8472-1049',
      'age': '14m',
      'stage': 'Stage 3 Coarse Mash',
      'weight': '9.4 kg',
      'length': '77.2 cm',
      'who': 'WHO P50 Green Zone',
      'diversity': '4/5 Groups',
      'status': 'Consultation Today',
      'statusColor': AppColors.statusGreen,
      'isFaltering': false,
    },
    {
      'name': 'Diya Vankar',
      'mother': 'Meena Vankar',
      'abha': '91-3829-2041',
      'age': '18m',
      'stage': 'Stage 4 Family Pot',
      'weight': '8.1 kg',
      'length': '74.8 cm',
      'who': 'P15 Faltering Slope',
      'diversity': '2/5 Groups',
      'status': 'Follow-up Due Tomorrow',
      'statusColor': AppColors.statusOrange,
      'isFaltering': true,
    },
    {
      'name': 'Vivaan Joshi',
      'mother': 'Kajal Joshi',
      'abha': '91-5829-9102',
      'age': '9m',
      'stage': 'Stage 2 Purees',
      'weight': '7.6 kg',
      'length': '69.1 cm',
      'who': 'WHO P50 Normal',
      'diversity': '3/5 Groups',
      'status': 'Next Review 28 Feb',
      'statusColor': AppColors.primary,
      'isFaltering': false,
    },
    {
      'name': 'Ananya Parmar',
      'mother': 'Rekha Parmar',
      'abha': '91-1029-4820',
      'age': '28m',
      'stage': 'Stage 5 Family Diet',
      'weight': '11.2 kg',
      'length': '86.5 cm',
      'who': 'WHO P60 Normal',
      'diversity': '5/5 Groups',
      'status': 'Routine Schedule',
      'statusColor': AppColors.statusGreen,
      'isFaltering': false,
    },
    {
      'name': 'Kabir Rathod',
      'mother': 'Hetal Rathod',
      'abha': '91-7291-3049',
      'age': '11m',
      'stage': 'Stage 3 Mash',
      'weight': '8.8 kg',
      'length': '72.4 cm',
      'who': 'WHO P45 Normal',
      'diversity': '4/5 Groups',
      'status': 'Iron Review in 14d',
      'statusColor': AppColors.primary,
      'isFaltering': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final active = _children[_selectedChildIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assigned Children Directory (બાળકોની યાદી)',
              style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              '42 Monitored Children across Sector 4 & Sector 12',
              style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filter Pills
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _filterChip('All Children (42)', 0),
                  _filterChip('Follow-up Needed (7)', 1),
                  _filterChip('Infants 7-12m (14)', 2),
                  _filterChip('Toddlers 13-24m (19)', 3),
                  _filterChip('Anganwadi Sec 4 (24)', 4),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Children List Cards
            ...List.generate(_children.length, (index) {
              final c = _children[index];
              final isSelected = _selectedChildIndex == index;

              return GestureDetector(
                onTap: () => setState(() => _selectedChildIndex = index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: (c['statusColor'] as Color).withOpacity(0.15),
                        child: Text(
                          c['name'][0],
                          style: TextStyle(color: c['statusColor'] as Color, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(c['name'], style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 6),
                                Text('(${c['age']})', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (c['statusColor'] as Color).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    c['status'],
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: c['statusColor'] as Color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Mother: ${c['mother']} • ABHA: ${c['abha']}',
                              style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted),
                            ),
                            Text(
                              '${c['weight']} • ${c['length']} • ${c['who']} • ${c['diversity']}',
                              style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.primaryDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // Deep-Dive Clinical Profile Card (Selected Child)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${active['name']} (Clinical Record)',
                          style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(60, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.print_outlined, size: 14),
                        label: const Text('Print', style: TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                  Text(
                    'DOB: 12 Dec 2024 • Linked Anganwadi: Mandvi Sec 4 • ABHA: ${active['abha']}',
                    style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const Divider(height: 20),

                  // Anthropometry Tiles
                  Row(
                    children: [
                      Expanded(
                        child: MetricTile(
                          icon: Icons.scale_rounded,
                          label: 'WEIGHT',
                          value: active['weight'],
                          subtext: 'WHO P50 Zone',
                          iconColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MetricTile(
                          icon: Icons.straighten_rounded,
                          label: 'LENGTH',
                          value: active['length'],
                          subtext: 'Tracking Expected',
                          iconColor: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MetricTile(
                          icon: Icons.dining_rounded,
                          label: 'STAGE',
                          value: 'Stage 3',
                          subtext: 'Coarse Mash',
                          iconColor: AppColors.tertiaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Parent-Reported Feeding Diary
                  Text(
                    'Parent-Reported Feeding Diary (આહાર નોંધ):',
                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _diaryItem('Meal 1: Vegetable Moong Dal Khichdi with Ghee', '1 small katori ~120g • Coarse texture • Grains + Pulses + Ghee energy density'),
                  _diaryItem('Meal 2: Ragi Sheera with mashed ripe banana', '3/4 katori • Natural fruit sweet • Calcium & Iron rich'),
                  _diaryItem('Tolerance Note', 'Good appetite, no vomiting. Active chewing observed with steamed carrot batons. Night breastfeeding: 2 sessions.'),
                  const SizedBox(height: 14),

                  // ICMR-NIN Guideline Alignment Checklist
                  Text(
                    'ICMR-NIN Guideline Alignment (12-23 Months):',
                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _auditItem('Texture Progression (Coarse mash/Finger foods)', 'Stage Confirmed', true),
                  _auditItem('Meal Frequency (Min 3-4 feeds + 1 snack)', 'Target Achieved (4/4)', true),
                  _auditItem('Active Feeding (Caregiver interaction)', 'Positive Reinforcement', true),
                  const SizedBox(height: 16),

                  // Clinical Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Clinical notes documented and synced to POSHAN Abhiyaan!')),
                            );
                          },
                          icon: const Icon(Icons.edit_note_rounded, size: 16),
                          label: const Text('Document Notes', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.translate_rounded, size: 16),
                          label: const Text('Gujarati Diet Plan', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String text, int index) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          text,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _diaryItem(String title, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
          Text(detail, style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _auditItem(String title, String status, bool isOk) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(isOk ? Icons.check_circle_rounded : Icons.info_outline, size: 14, color: AppColors.statusGreen),
          const SizedBox(width: 6),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary))),
          Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.statusGreen)),
        ],
      ),
    );
  }
}
