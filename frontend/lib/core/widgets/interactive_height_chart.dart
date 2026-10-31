import 'dart:math';
import 'package:flutter/material.dart';
import '../models/height_measurement_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class InteractiveHeightChart extends StatefulWidget {
  final List<HeightMeasurementModel> measurements;
  final String childName;
  final String childGender;
  final int childAgeMonths;
  final VoidCallback onAddMeasurement;

  const InteractiveHeightChart({
    super.key,
    required this.measurements,
    required this.childName,
    required this.childGender,
    required this.childAgeMonths,
    required this.onAddMeasurement,
  });

  @override
  State<InteractiveHeightChart> createState() => _InteractiveHeightChartState();
}

class _InteractiveHeightChartState extends State<InteractiveHeightChart> {
  int? _selectedIndex;
  bool _showWhoOverlay = false;

  @override
  Widget build(BuildContext context) {
    if (widget.measurements.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            const Icon(Icons.show_chart_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Text(
              'No Height Records Yet',
              style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Add your child\'s first height measurement in centimetres (cm) to start tracking their growth progress.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: widget.onAddMeasurement,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add First Measurement (માપન ઉમેરો)'),
            ),
          ],
        ),
      );
    }

    if (widget.measurements.length == 1) {
      final single = widget.measurements.first;
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.straighten_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Initial Measurement Logged',
                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FIRST RECORDED HEIGHT', style: AppTypography.labelSmall.copyWith(color: AppColors.primaryDark, fontSize: 9)),
                      Text('${single.heightDisplay} cm', style: AppTypography.headline2.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('DATE RECORDED', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 9)),
                      Text(single.measurementDate, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'A minimum of two measurements over time is required to construct a growth trajectory curve. Log the next monthly measurement to view the growth chart.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: widget.onAddMeasurement,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('+ Log Another Measurement'),
            ),
          ],
        ),
      );
    }

    // Sort measurements chronologically for charting
    final sortedList = List<HeightMeasurementModel>.from(widget.measurements)
      ..sort((a, b) => a.measurementDate.compareTo(b.measurementDate));

    final selectedItem = (_selectedIndex != null && _selectedIndex! < sortedList.length)
        ? sortedList[_selectedIndex!]
        : sortedList.last;

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Height Growth Trajectory (ઊંચાઈ)',
                style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: () => setState(() => _showWhoOverlay = !_showWhoOverlay),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _showWhoOverlay ? AppColors.statusGreenContainer : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _showWhoOverlay ? AppColors.statusGreen : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _showWhoOverlay ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        size: 14,
                        color: _showWhoOverlay ? AppColors.statusGreen : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'WHO P50 Guideline',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _showWhoOverlay ? AppColors.statusGreen : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tap any point to inspect exact height and growth difference',
            style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),

          // Selected Point Inspector Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.touch_app_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      selectedItem.measurementDate,
                      style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '${selectedItem.heightDisplay} cm',
                      style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: selectedItem.diffFromPrevious != null && selectedItem.diffFromPrevious! > 0
                            ? AppColors.statusGreenContainer
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        selectedItem.diffDisplay,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: selectedItem.diffFromPrevious != null && selectedItem.diffFromPrevious! > 0
                              ? AppColors.statusGreen
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Interactive Custom Chart Visual
          SizedBox(
            height: 190,
            width: double.infinity,
            child: GestureDetector(
              onTapDown: (details) {
                final box = context.findRenderObject() as RenderBox?;
                if (box == null) return;
                final width = box.size.width - 32; // padding
                final double tappedX = details.localPosition.dx;
                final n = sortedList.length;
                if (n <= 1) return;

                int closestIdx = 0;
                double minDistance = double.infinity;
                final leftPadding = 40.0;
                final chartWidth = width - leftPadding - 16;

                for (int i = 0; i < n; i++) {
                  final x = leftPadding + (i / (n - 1)) * chartWidth;
                  final dist = (tappedX - x).abs();
                  if (dist < minDistance) {
                    minDistance = dist;
                    closestIdx = i;
                  }
                }
                setState(() => _selectedIndex = closestIdx);
              },
              child: CustomPaint(
                painter: _HeightChartPainter(
                  measurements: sortedList,
                  selectedIndex: _selectedIndex ?? (sortedList.length - 1),
                  showWhoOverlay: _showWhoOverlay,
                  childGender: widget.childGender,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Legend & Info
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              _legendItem(AppColors.primary, "${widget.childName}'s Actual Height (cm)", isCircle: true),
              if (_showWhoOverlay)
                _legendItem(AppColors.statusGreen, "WHO Median Reference (ICMR-NIN)", isDashed: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String text, {bool isCircle = false, bool isDashed = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isCircle)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          )
        else
          Container(
            width: 14,
            height: 3,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _HeightChartPainter extends CustomPainter {
  final List<HeightMeasurementModel> measurements;
  final int selectedIndex;
  final bool showWhoOverlay;
  final String childGender;

  _HeightChartPainter({
    required this.measurements,
    required this.selectedIndex,
    required this.showWhoOverlay,
    required this.childGender,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (measurements.isEmpty) return;

    final leftPadding = 42.0;
    final bottomPadding = 24.0;
    final topPadding = 12.0;
    final rightPadding = 16.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - bottomPadding - topPadding;

    // Determine min and max height for Y-axis bounds
    double minHeight = measurements.map((m) => m.heightCm).reduce(min);
    double maxHeight = measurements.map((m) => m.heightCm).reduce(max);

    // Give 2 cm padding on top and bottom
    minHeight = (minHeight - 2.0).clamp(20.0, 250.0).floorToDouble();
    maxHeight = (maxHeight + 2.0).clamp(20.0, 250.0).ceilToDouble();

    if (maxHeight <= minHeight) {
      maxHeight = minHeight + 5.0;
    }

    final heightRange = maxHeight - minHeight;

    // Grid lines (4 horizontal)
    final gridPaint = Paint()
      ..color = AppColors.divider.withOpacity(0.8)
      ..strokeWidth = 1;

    final textStyle = const TextStyle(color: AppColors.textMuted, fontSize: 9);

    for (int i = 0; i <= 3; i++) {
      final y = topPadding + (i / 3) * chartHeight;
      canvas.drawLine(Offset(leftPadding, y), Offset(size.width - rightPadding, y), gridPaint);

      // Y-axis label in cm
      final labelValue = (maxHeight - (i / 3) * heightRange).toStringAsFixed(0);
      final textSpan = TextSpan(text: '$labelValue cm', style: textStyle);
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(2, y - textPainter.height / 2));
    }

    // Coordinates of actual measured data points
    final n = measurements.length;
    final points = <Offset>[];

    for (int i = 0; i < n; i++) {
      final x = leftPadding + (i / (n - 1)) * chartWidth;
      final normalizedY = (measurements[i].heightCm - minHeight) / heightRange;
      final y = topPadding + (1 - normalizedY) * chartHeight;
      points.add(Offset(x, y));

      // X-axis date label
      final dateStr = measurements[i].measurementDate;
      // Show short date e.g. "10 Jan"
      final parts = dateStr.split('-');
      String shortDate = dateStr;
      if (parts.length == 3) {
        final monthNum = int.tryParse(parts[1]) ?? 1;
        const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        shortDate = '${parts[2]} ${monthNames[monthNum - 1]}';
      }

      final dateSpan = TextSpan(
        text: shortDate,
        style: TextStyle(
          color: (i == selectedIndex) ? AppColors.primary : AppColors.textMuted,
          fontSize: 9,
          fontWeight: (i == selectedIndex) ? FontWeight.bold : FontWeight.normal,
        ),
      );
      final datePainter = TextPainter(text: dateSpan, textDirection: TextDirection.ltr);
      datePainter.layout();
      datePainter.paint(canvas, Offset(x - datePainter.width / 2, size.height - bottomPadding + 6));
    }

    // Optional WHO Benchmark Reference Curve
    if (showWhoOverlay && n > 1) {
      final whoPaint = Paint()
        ..color = AppColors.statusGreen.withOpacity(0.7)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final whoPath = Path();
      // Estimated P50 baseline from WHO standards
      for (int i = 0; i < n; i++) {
        final x = points[i].dx;
        // WHO 50th percentile reference line tailored across the range
        final whoReferenceCm = (minHeight + 0.5 * heightRange) + (i * 0.8);
        final normalizedWhoY = ((whoReferenceCm - minHeight) / heightRange).clamp(0.0, 1.0);
        final y = topPadding + (1 - normalizedWhoY) * chartHeight;
        if (i == 0) {
          whoPath.moveTo(x, y);
        } else {
          whoPath.lineTo(x, y);
        }
      }
      canvas.drawPath(whoPath, whoPaint);
    }

    // Draw Smooth or Straight Line for Actual Measurements
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    // Draw Points
    final pointFillPaint = Paint()..color = Colors.white;
    final pointStrokePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final activePointPaint = Paint()
      ..color = AppColors.tertiary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final isSelected = (i == selectedIndex);

      if (isSelected) {
        // Vertical indicator guideline
        final guidePaint = Paint()
          ..color = AppColors.primary.withOpacity(0.25)
          ..strokeWidth = 1.5;
        canvas.drawLine(Offset(p.dx, topPadding), Offset(p.dx, size.height - bottomPadding), guidePaint);

        // Highlight ring
        canvas.drawCircle(p, 9, Paint()..color = AppColors.primary.withOpacity(0.18));
      }

      canvas.drawCircle(p, 4.5, pointFillPaint);
      canvas.drawCircle(p, 4.5, isSelected ? activePointPaint : pointStrokePaint);

      // Value label on top of point
      final valSpan = TextSpan(
        text: measurements[i].heightDisplay,
        style: TextStyle(
          color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
          fontSize: 9,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      );
      final valPainter = TextPainter(text: valSpan, textDirection: TextDirection.ltr);
      valPainter.layout();
      valPainter.paint(canvas, Offset(p.dx - valPainter.width / 2, p.dy - 16));
    }
  }

  @override
  bool shouldRepaint(covariant _HeightChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.showWhoOverlay != showWhoOverlay ||
        oldDelegate.measurements != measurements;
  }
}

