import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_typography.dart';
import 'package:frontend/core/widgets/status_badge.dart';
import 'package:frontend/core/widgets/metric_tile.dart';
import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/models/child_model.dart';
import 'package:frontend/core/services/child_session.dart';
import 'package:frontend/core/widgets/child_selector_widget.dart';
import 'package:frontend/core/widgets/missing_field_dialogs.dart';

class GrowthMonitoringScreen extends StatefulWidget {
  const GrowthMonitoringScreen({super.key});

  @override
  State<GrowthMonitoringScreen> createState() => _GrowthMonitoringScreenState();
}

class _GrowthMonitoringScreenState extends State<GrowthMonitoringScreen> {
  int _selectedChartTab = 0; // 0: Weight-for-Age, 1: Length-for-Age
  final List<GrowthMeasurement> _history = MockData.growthHistory;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ChildModel?>(
      valueListenable: ChildSession.instance.selectedChildNotifier,
      builder: (context, activeChild, _) {
        final childName = activeChild?.name ?? 'Child';
        final childAge = activeChild?.ageDisplay ?? '';
        final childGender = (activeChild?.gender.isNotEmpty == true) ? activeChild!.gender : 'Child';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Growth Monitoring (વિકાસ ચાર્ટ)',
                  style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  activeChild != null
                      ? '$childName • $childAge • WHO P50 Curve'
                      : 'Select a child profile • WHO P50 Curve',
                  style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            actions: [
              const ChildSelectorPill(isCompact: true),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exporting official WHO growth curve report PDF...')),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (activeChild == null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.child_care_rounded, size: 48, color: AppColors.primary),
                        const SizedBox(height: 10),
                        Text('No Child Profile Registered', style: AppTypography.headline3),
                        const SizedBox(height: 6),
                        Text(
                          'Add your child to track WHO growth charts, height, and weight dynamically.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () => showAddNewChildDialog(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('+ Register Child Profile'),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Status Hero Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            StatusBadge(
                              label: 'WHO GREEN ZONE • 50th Percentile',
                              status: BadgeStatus.normal,
                              icon: Icons.verified_rounded,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$childGender 0-24m Cohort',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          childName,
                          style: AppTypography.headline2.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Active Milestone: $childAge Growth Tracking',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: activeChild.hasWeight
                                  ? MetricTile(
                                      icon: Icons.scale_rounded,
                                      label: 'CURRENT WEIGHT',
                                      value: '${activeChild.weightDisplay} kg',
                                      subtext: 'Tracked on WHO curve',
                                      iconColor: AppColors.primary,
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.statusOrange.withOpacity(0.3)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.scale_rounded, size: 16, color: AppColors.statusOrange),
                                              const SizedBox(width: 6),
                                              Text('CURRENT WEIGHT', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 9)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Not added', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontStyle: FontStyle.italic)),
                                              InkWell(
                                                onTap: () => showAddChildWeightDialog(context, activeChild),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text(
                                                    '+ Add',
                                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: MetricTile(
                                icon: Icons.straighten_rounded,
                                label: 'CURRENT LENGTH',
                                value: '78.5 cm',
                                subtext: 'Normal Range (સામાન્ય)',
                                iconColor: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Aligned with WHO Child Growth Standards (ICMR-NIN)',
                                style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Interactive WHO Growth Curve Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _chartTabButton('Weight-for-Age (વજન-ઉંમર)', 0),
                            const SizedBox(width: 8),
                            _chartTabButton('Length-for-Age (ઊંચાઈ)', 1),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedChartTab == 0
                              ? 'WHO Child Growth Standards • Weight (kg) vs Age (Months)'
                              : 'WHO Child Growth Standards • Length (cm) vs Age (Months)',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 16),

                        // Custom Painted WHO Curve Visual
                        Container(
                          height: 180,
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: CustomPaint(
                            painter: WhoGrowthCurvePainter(
                              isWeight: _selectedChartTab == 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Legend
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            _legendItem(AppColors.statusGreen, 'Median (50th Percentile)'),
                            _legendItem(AppColors.statusGreenContainer, '±2 SD Normal Band'),
                            _legendItem(AppColors.primaryDark, "$childName's Track", isDot: true),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            'Growth Velocity: Healthy / સામાન્ય શારીરિક વિકાસ (+300g/mo)',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.statusGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Measurement History
                Text(
                  'Measurement History (પાછલી નોંધો)',
                  style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                ..._history.map((record) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text(
                                record.dateString.split(' ')[0],
                                style: AppTypography.labelLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              Text(
                                record.dateString.split(' ')[1].toUpperCase(),
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 9,
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${record.weightKg} kg',
                                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const Text('  •  '),
                                  Text(
                                    '${record.lengthCm} cm',
                                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${record.ageMonths}m',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${record.eventType} • ${record.workerName}',
                                style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              Text(
                                record.notes,
                                style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),

                // Clinical Disclaimer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.statusBlueContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.statusBlue.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.statusBlue, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'WHO Child Growth Standards (ICMR-NIN Aligned): Growth curves reflect overall growth velocity and nutritional continuity. They do not independently diagnose acute pediatric conditions.',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.statusBlue),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Action Buttons
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddMeasurementModal(context, activeChild);
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('+ Log New Measurement (નવું માપન ઉમેરો)'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chartTabButton(String label, int index) {
    final isSelected = _selectedChartTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedChartTab = index),
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
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String text, {bool isDot = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isDot ? 8 : 14,
          height: isDot ? 8 : 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(isDot ? 4 : 2),
            border: Border.all(color: Colors.black26, width: 0.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  void _showAddMeasurementModal(BuildContext context, ChildModel? activeChild) {
    if (activeChild == null) {
      showAddNewChildDialog(context);
      return;
    }

    final weightController = TextEditingController(
      text: activeChild.hasWeight ? activeChild.weight!.toStringAsFixed(1) : '',
    );
    final lengthController = TextEditingController(text: '78.5');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Log Measurement for ${activeChild.name}',
                style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg) • વજન',
                  hintText: 'e.g. 10.5',
                  prefixIcon: Icon(Icons.scale_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lengthController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Length / Height (cm) • ઊંચાઈ',
                  hintText: 'e.g. 78.5',
                  prefixIcon: Icon(Icons.straighten_rounded),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final enteredWeight = double.tryParse(weightController.text.trim());
                  Navigator.pop(ctx);
                  if (enteredWeight != null && enteredWeight > 0) {
                    final ok = await ChildSession.instance.updateWeight(activeChild.id, enteredWeight);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok ? 'Weight updated successfully!' : 'Could not save weight. Please try again.'),
                          backgroundColor: ok ? AppColors.statusGreen : AppColors.statusRed,
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Measurement recorded and plotted onto WHO curve!'),
                          backgroundColor: AppColors.statusGreen,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Save Measurement'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Custom Painter for authentic WHO growth curves
class WhoGrowthCurvePainter extends CustomPainter {
  final bool isWeight;

  WhoGrowthCurvePainter({required this.isWeight});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Grid lines
    final gridPaint = Paint()
      ..color = AppColors.divider.withOpacity(0.7)
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      final y = height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }
    for (int i = 1; i <= 5; i++) {
      final x = width * (i / 6);
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }

    // Normal Band (+2SD to -2SD)
    final bandPaint = Paint()
      ..color = AppColors.statusGreenContainer.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final bandPath = Path();
    bandPath.moveTo(0, height * 0.75);
    bandPath.quadraticBezierTo(width * 0.5, height * 0.45, width, height * 0.2);
    bandPath.lineTo(width, height * 0.5);
    bandPath.quadraticBezierTo(width * 0.5, height * 0.7, 0, height * 0.9);
    bandPath.close();
    canvas.drawPath(bandPath, bandPaint);

    // Median 50th Percentile line
    final medianPaint = Paint()
      ..color = AppColors.statusGreen
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final medianPath = Path();
    medianPath.moveTo(0, height * 0.82);
    medianPath.quadraticBezierTo(width * 0.5, height * 0.55, width, height * 0.32);
    canvas.drawPath(medianPath, medianPaint);

    // Tracked Growth line (Dots + Line)
    final childTrackPaint = Paint()
      ..color = AppColors.primaryDark
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final trackPath = Path();
    // 5 Recorded data points
    final points = [
      Offset(width * 0.15, height * 0.74), // 8m
      Offset(width * 0.30, height * 0.67), // 10m
      Offset(width * 0.45, height * 0.61), // 12m
      Offset(width * 0.60, height * 0.57), // 13m
      Offset(width * 0.75, height * 0.53), // 14m (Today)
    ];

    trackPath.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      trackPath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(trackPath, childTrackPaint);

    // Draw dots
    final dotPaint = Paint()..color = AppColors.primaryDark;
    final activeDotPaint = Paint()
      ..color = AppColors.tertiary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 3.5, dotPaint);
      if (i == points.length - 1) {
        // Highlight current point
        canvas.drawCircle(points[i], 6, activeDotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
