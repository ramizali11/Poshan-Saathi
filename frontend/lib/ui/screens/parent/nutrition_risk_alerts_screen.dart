import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_typography.dart';
import 'package:frontend/core/data/mock_data.dart';

class NutritionRiskAlertsScreen extends StatefulWidget {
  const NutritionRiskAlertsScreen({super.key});

  @override
  State<NutritionRiskAlertsScreen> createState() => _NutritionRiskAlertsScreenState();
}

class _NutritionRiskAlertsScreenState extends State<NutritionRiskAlertsScreen> {
  int _selectedFilter = 0; // 0: All Alerts (3), 1: Needs Review (2), 2: Resolved (4)
  final List<RiskAlertItem> _alerts = MockData.activeAlerts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrition Risk Alerts (પોષણ ચેતવણીઓ)',
              style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'Aarav Shah • 14m • Proactive Care Indicators',
              style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Caregiver Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusBlueContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.statusBlue.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.health_and_safety_outlined, color: AppColors.statusBlue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Non-diagnostic alerts generated to support timely preventive care and Anganwadi consultations. These indicators do not diagnose medical conditions.',
                      style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.statusBlue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Filter Tabs
            Row(
              children: [
                _filterTab('All Alerts (3)', 0),
                const SizedBox(width: 8),
                _filterTab('Needs Review (2)', 1),
                const SizedBox(width: 8),
                _filterTab('Resolved (4)', 2),
              ],
            ),
            const SizedBox(height: 16),

            // Alert Cards List
            ..._alerts.map((alert) => _buildAlertCard(alert)),

            const SizedBox(height: 14),

            // Frontline Support Footer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Direct Grassroot Assistance',
                          style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Speak directly to your designated ASHA worker (Kavita Ben) or Anganwadi Didi.',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(60, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/anganwadi_connect'),
                    child: const Text('Contact', style: TextStyle(fontSize: 11)),
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

  Widget _filterTab(String label, int index) {
    final isSelected = _selectedFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(RiskAlertItem alert) {
    final isWarning = alert.severity == 'moderate';
    final color = isWarning ? AppColors.statusOrange : AppColors.statusBlue;
    final bgColor = isWarning ? AppColors.statusOrangeContainer : AppColors.statusBlueContainer;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isWarning ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                      size: 14,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      alert.category.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 9),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(alert.date, style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            alert.title,
            style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            alert.description,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 10),

          // Recommendation Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.recommendation,
                    style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(36),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Marked as reviewed!')),
                    );
                  },
                  child: const Text('Mark as Reviewed', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(36),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/anganwadi_connect'),
                  child: const Text('Consultation', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
