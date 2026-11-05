import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/data/mock_data.dart';
import '../../../core/services/growth_data_service.dart';
import '../../../core/services/growth_report_pdf_service.dart';
import '../../../core/constants/app_images_data.dart';

class GrowthMonitoringScreen extends StatefulWidget {
  const GrowthMonitoringScreen({super.key});

  @override
  State<GrowthMonitoringScreen> createState() => _GrowthMonitoringScreenState();
}

class _GrowthMonitoringScreenState extends State<GrowthMonitoringScreen> {
  final GrowthDataService _growthService = GrowthDataService.instance;
  int _selectedChartTab = 0; // 0: Weight-for-Age (kg), 1: Length-for-Age (cm)
  GrowthMeasurement? _selectedPoint;
  bool _isExportingPdf = false;

  @override
  void initState() {
    super.initState();
    _growthService.init();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _growthService.measurementsNotifier,
        _growthService.childNotifier,
      ]),
      builder: (context, _) {
        final child = _growthService.child;
        final allMeasurements = _growthService.allMeasurements;
        final stats = _growthService.calculateStats(allMeasurements);

        // Sort measurements chronologically for charting
        final chartPoints = List<GrowthMeasurement>.from(allMeasurements)
          ..sort((a, b) => a.date.compareTo(b.date));

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9F6),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF7F9F6),
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 16,
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Growth Monitoring',
                    style: AppTypography.headline3.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                      fontSize: 18,
                    ),
                    value: isEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setModalState(() => isEnabled = val);
                    },
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${child.name} • ${child.ageInMonths}m • WHO P50 Curve',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (_isExportingPdf)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: InkWell(
                    onTap: () => _exportPdf(child, allMeasurements),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF1E293B), width: 1.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.insert_drive_file_outlined, size: 14, color: Color(0xFF1E293B)),
                          SizedBox(width: 2),
                          Text(
                            'PDF',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Hero Growth Profile Card (Actual Responsive Flutter UI)
                _buildHeroProfileCard(child, stats),
                const SizedBox(height: 12),

                // 2. WHO Growth Standards & Interactive Curve Card (Actual Responsive Flutter UI)
                _buildWhoChartCard(child, stats, chartPoints),
                const SizedBox(height: 12),

                // 3. Quick Action Cards (4 Responsive Flutter Cards)
                Row(
                  children: [
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.bar_chart_rounded,
                        iconBg: const Color(0xFFE8F5E9),
                        iconColor: const Color(0xFF2E7D32),
                        cardBg: const Color(0xFFF1F8F1),
                        borderColor: const Color(0xFFDCEFDC),
                        title: 'Growth History',
                        subtitle: 'View all records',
                        onTap: () => _showHistoryModal(context, allMeasurements),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.edit_rounded,
                        iconBg: const Color(0xFFE1F5FE),
                        iconColor: const Color(0xFF0288D1),
                        cardBg: const Color(0xFFF0F7FF),
                        borderColor: const Color(0xFFD8ECFE),
                        title: 'Add Measurement',
                        subtitle: 'Update weight & length',
                        onTap: () => _showAddMeasurementModal(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.description_rounded,
                        iconBg: const Color(0xFFFFF3E0),
                        iconColor: const Color(0xFFE65100),
                        cardBg: const Color(0xFFFFF8EE),
                        borderColor: const Color(0xFFFBE5CE),
                        title: 'Growth Report',
                        subtitle: 'PDF Report',
                        onTap: () => _exportPdf(child, allMeasurements),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.track_changes_rounded,
                        iconBg: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF7E22CE),
                        cardBg: const Color(0xFFFAF5FF),
                        borderColor: const Color(0xFFE9D8FD),
                        title: 'Milestones',
                        subtitle: 'Track development',
                        onTap: () => _showMilestonesModal(context, child),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 1. Hero Growth Profile Card (Authentic Responsive UI) ---
  Widget _buildHeroProfileCard(ChildProfile child, Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header: Badges & Baby Illustration
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Green Zone Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF2E7D32)),
                          SizedBox(width: 4),
                          Text(
                            'WHO GREEN ZONE • 50th Percentile',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2E7D32),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Cohort Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8F1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${child.gender} 0–24M Cohort',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4A6B4F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Child Name & Gujarati Name
                    Text(
                      '${child.name} (${child.gujaratiName})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Active Milestone
                    const Text(
                      'Active Milestone: 14m Complementary Transition',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Baby Illustration
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  AppImagesData.babyIllustrationBytes,
                  width: 84,
                  height: 84,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2 Metric Tiles (Weight & Length)
          Row(
            children: [
              // Weight Tile
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAF7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8EFE6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.scale_rounded, size: 16, color: Color(0xFF2E7D32)),
                          SizedBox(width: 6),
                          Text(
                            'CURRENT WEIGHT',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '${(stats['latestWeight'] as double).toStringAsFixed(1)} kg',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.trending_up, size: 14, color: Color(0xFF2E7D32)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '↑ +0.3 kg this month',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Length Tile
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAF7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8EFE6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.straighten_rounded, size: 16, color: Color(0xFFD97706)),
                          SizedBox(width: 6),
                          Text(
                            'CURRENT LENGTH',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '${(stats['latestLength'] as double).toStringAsFixed(1)} cm',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.trending_up, size: 14, color: Color(0xFF2E7D32)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Normal Range (સામાન્ય)',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Footer Attributions (Recorded by Kavita Ben & Date)
          Row(
            children: [
              const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF2E7D32)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Recorded by ${child.ashaWorkerName} (ASHA Worker)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              const Text(
                '12 Feb 2026',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 2. WHO Child Growth Standards & Interactive Curve Card ---
  Widget _buildWhoChartCard(ChildProfile child, Map<String, dynamic> stats, List<GrowthMeasurement> points) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented Toggle Buttons (Weight vs Length)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedChartTab = 0;
                    _selectedPoint = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: _selectedChartTab == 0 ? const Color(0xFF1E3A2B) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedChartTab == 0 ? const Color(0xFF1E3A2B) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.scale_rounded,
                          size: 15,
                          color: _selectedChartTab == 0 ? Colors.white : const Color(0xFF475569),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Weight-for-Age (વજન-ઉંમર)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _selectedChartTab == 0 ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedChartTab = 1;
                    _selectedPoint = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: _selectedChartTab == 1 ? const Color(0xFF1E3A2B) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedChartTab == 1 ? const Color(0xFF1E3A2B) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.straighten_rounded,
                          size: 15,
                          color: _selectedChartTab == 1 ? Colors.white : const Color(0xFF475569),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Length-for-Age (ઊંચાઈ)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _selectedChartTab == 1 ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Subtitle
          Text(
            _selectedChartTab == 0
                ? 'WHO Child Growth Standards • Weight (kg) vs Age (Months)'
                : 'WHO Child Growth Standards • Length (cm) vs Age (Months)',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Responsive CustomPaint WHO Growth Curve
          Container(
            height: 230,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(4, 8, 8, 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFCFA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EFE8)),
            ),
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                return GestureDetector(
                  onTapUp: (details) {
                    final tapped = _findNearestMeasurement(
                      details.localPosition,
                      constraints.biggest,
                      points,
                      isWeight: _selectedChartTab == 0,
                    );
                    setState(() => _selectedPoint = tapped);
                  },
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: RealWhoGrowthCurvePainter(
                      measurements: points,
                      isWeight: _selectedChartTab == 0,
                      selectedMeasurement: _selectedPoint,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Tapped Tooltip Banner (if active)
          if (_selectedPoint != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_selectedPoint!.dateString} (${_selectedPoint!.ageMonths}m): '
                      '${_selectedChartTab == 0 ? "${_selectedPoint!.weightKg} kg" : "${_selectedPoint!.lengthCm} cm"} • '
                      'Z-Score: ${_selectedPoint!.zScore}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A2B),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _selectedPoint = null),
                    child: const Icon(Icons.close, size: 14, color: Color(0xFF1E3A2B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Legend Row
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              _legendItem(const Color(0xFF2E7D32), 'Median (50th Percentile)', isLine: true),
              _legendItem(const Color(0xFFE2F0D9), '±2 SD Normal Band', isBox: true),
              _legendItem(const Color(0xFF94A3B8), '--- WHO Percentiles'),
              _legendItem(const Color(0xFF1E3A2B), "Aarav's Track", isDotTrack: true),
            ],
          ),
          const SizedBox(height: 12),

          // Growth Velocity Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD4EBD4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: Color(0xFF2E7D32), size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Growth Velocity: Healthy',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'સામાન્ય શારીરિક વિકાસ (+300g/mo)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF2E7D32)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String text, {bool isLine = false, bool isBox = false, bool isDotTrack = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLine)
          Container(width: 14, height: 3, color: color)
        else if (isBox)
          Container(width: 12, height: 10, decoration: BoxDecoration(color: color, border: Border.all(color: Colors.black12)))
        else if (isDotTrack)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              Container(width: 8, height: 2, color: color),
              Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            ],
          )
        else
          Text('---', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ],
    );
  }

  // --- 3. Responsive Action Tile ---
  Widget _buildActionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color cardBg,
    required Color borderColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 17, color: iconColor),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 9.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Measurement Finder for interactive chart tapping ---
  GrowthMeasurement? _findNearestMeasurement(
    Offset tapPosition,
    Size size,
    List<GrowthMeasurement> measurements, {
    required bool isWeight,
  }) {
    if (measurements.isEmpty) return null;
    const leftPad = 28.0;
    const rightPad = 38.0;
    final chartW = size.width - leftPad - rightPad;

    for (final m in measurements) {
      final x = leftPad + chartW * (m.ageMonths / 24.0);
      if ((tapPosition.dx - x).abs() < 18) {
        return m;
      }
    }
    return null;
  }

  // --- 4. Growth History Modal ---
  void _showHistoryModal(BuildContext context, List<GrowthMeasurement> measurements) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFFF7F9F6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Growth History (વિકાસ ઇતિહાસ)',
                        style: AppTypography.headline3.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${measurements.length} recorded measurements for Aarav',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddMeasurementModal(context);
                    },
                    icon: const Icon(Icons.add_circle, size: 18, color: AppColors.primary),
                    label: const Text(
                      'Add Entry',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: measurements.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (c, idx) {
                    final item = measurements[idx];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  DateFormat('dd').format(item.date),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM').format(item.date).toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF388E3C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${item.weightKg.toStringAsFixed(1)} kg',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '•  ${item.lengthCm.toStringAsFixed(1)} cm',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF475569),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'WHO P50',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.notes.isNotEmpty
                                      ? item.notes
                                      : 'Routine checkup by Anganwadi worker Kavita Ben',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
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
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.child_care_rounded, size: 54, color: AppColors.primary),
                        const SizedBox(height: 12),
                        Text('No Child Profile Registered', style: AppTypography.headline3),
                        const SizedBox(height: 6),
                        Text(
                          'Add your child to track height in centimetres (cm), growth differences, and WHO development milestones.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
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
                              label: hasHeight
                                  ? 'RECORDED HEIGHT • ${latestMeasurement.heightDisplay} cm'
                                  : 'NO HEIGHT RECORDED YET',
                              status: hasHeight ? BadgeStatus.normal : BadgeStatus.warning,
                              icon: hasHeight ? Icons.verified_rounded : Icons.info_outline_rounded,
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
                          hasHeight
                              ? 'Latest measurement: ${latestMeasurement.measurementDate} • $childAge'
                              : 'No height records yet • Awaiting first measurement',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 14),

                        // Metric Tiles Row: Current Height, Growth Diff, Weight
                        Row(
                          children: [
                            Expanded(
                              child: hasHeight
                                  ? MetricTile(
                                      icon: Icons.straighten_rounded,
                                      label: 'RECORDED HEIGHT',
                                      value: '${latestMeasurement.heightDisplay} cm',
                                      subtext: 'Date: ${latestMeasurement.measurementDate}',
                                      iconColor: AppColors.primary,
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.statusOrange.withOpacity(0.35)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.straighten_rounded, size: 16, color: AppColors.statusOrange),
                                              const SizedBox(width: 4),
                                              Text('HEIGHT (cm)', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 9)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'No records yet',
                                            style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                                          ),
                                          const SizedBox(height: 4),
                                          InkWell(
                                            onTap: () => _onAddHeight(activeChild),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                '+ Add Height',
                                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: MetricTile(
                                icon: Icons.trending_up_rounded,
                                label: 'GROWTH CHANGE',
                                value: hasHeight ? latestMeasurement.diffDisplay : '—',
                                subtext: _heightMeasurements.length >= 2
                                    ? 'Since previous record'
                                    : 'Awaiting 2nd record',
                                iconColor: (latestMeasurement?.isPositiveGrowth == true)
                                    ? AppColors.statusGreen
                                    : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: activeChild.hasWeight
                                  ? MetricTile(
                                      icon: Icons.scale_rounded,
                                      label: 'WEIGHT',
                                      value: '${activeChild.weightDisplay} kg',
                                      subtext: 'Tracked on DB',
                                      iconColor: AppColors.secondary,
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.statusOrange.withOpacity(0.35)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.scale_rounded, size: 16, color: AppColors.statusOrange),
                                              const SizedBox(width: 4),
                                              Text('WEIGHT', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 9)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Not added',
                                            style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                                          ),
                                          const SizedBox(height: 4),
                                          InkWell(
                                            onTap: () => showAddChildWeightDialog(context, activeChild),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.secondary,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                '+ Add Weight',
                                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Action button to record new height
                        ElevatedButton.icon(
                          onPressed: () => _onAddHeight(activeChild),
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: Text(hasHeight
                              ? '+ Record New Height Measurement (cm)'
                              : '+ Add First Height Measurement (cm)'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Monthly Reminder Settings Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (_reminderSettings?.isEnabled ?? true)
                                ? AppColors.primaryContainer
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            (_reminderSettings?.isEnabled ?? true)
                                ? Icons.alarm_on_rounded
                                : Icons.alarm_off_rounded,
                            color: (_reminderSettings?.isEnabled ?? true)
                                ? AppColors.primaryDark
                                : AppColors.textMuted,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Monthly Height Reminder',
                                style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                (_reminderSettings?.isEnabled ?? true)
                                    ? (_reminderSettings?.nextReminderText != null
                                        ? 'Next: ${_reminderSettings!.nextReminderText}'
                                        : 'Active: Scheduled on day ${_reminderSettings?.dayOfMonth ?? 1} of each month')
                                    : 'Reminders disabled for $childName',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: (_reminderSettings?.isEnabled ?? true)
                                      ? AppColors.primaryDark
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(60, 34),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: () => _showReminderSettingsModal(context, activeChild),
                          child: const Text('Configure', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Interactive Height Growth Chart
                  InteractiveHeightChart(
                    measurements: _heightMeasurements,
                    childName: childName,
                    childGender: childGender,
                    childAgeMonths: activeChild.computedAgeMonths,
                    onAddMeasurement: () => _onAddHeight(activeChild),
                  ),
                  const SizedBox(height: 16),

                  // Measurement History Table
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Growth History (પાછલી નોંધો)',
                              style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_heightMeasurements.length} ${(_heightMeasurements.length == 1) ? 'Record' : 'Records'}',
                                style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_isLoadingMeasurements)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          )
                        else if (_heightMeasurements.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.history_rounded, size: 36, color: AppColors.textMuted),
                                  const SizedBox(height: 6),
                                  Text(
                                    'No height records yet for $childName',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: () => _onAddHeight(activeChild),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Add First Measurement (cm)', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          // Table of measurements
                          Column(
                            children: [
                              // Table Header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text('Height (cm)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('Change', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                    ),
                                    SizedBox(
                                      width: 60,
                                      child: Text('Actions', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Records (sorted reverse-chronological for easy reading)
                              ..._heightMeasurements.reversed.map((record) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.divider.withOpacity(0.6)),
                                  ),
                                  child: Row(
                                    children: [
                                      // Date
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(record.measurementDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            if (record.notes.isNotEmpty)
                                              Text(
                                                record.notes,
                                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),

                                      // Height
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          '${record.heightDisplay} cm',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                        ),
                                      ),

                                      // Change
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          record.diffDisplay,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: record.isPositiveGrowth
                                                ? AppColors.statusGreen
                                                : AppColors.textMuted,
                                          ),
                                        ),
                                      ),

                                      // Actions (Edit, Delete)
                                      SizedBox(
                                        width: 60,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            InkWell(
                                              onTap: () => _onEditHeight(activeChild, record),
                                              child: const Padding(
                                                padding: EdgeInsets.all(4),
                                                child: Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            InkWell(
                                              onTap: () => _onDeleteHeight(activeChild, record),
                                              child: const Padding(
                                                padding: EdgeInsets.all(4),
                                                child: Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.statusRed),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

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
                            'WHO Child Growth Standards (ICMR-NIN Aligned): Height growth measurements reflect physiological velocity and nutritional continuity. They do not independently diagnose acute pediatric conditions.',
                            style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.statusBlue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 5. Add Measurement Modal ---
  void _showAddMeasurementModal(BuildContext context) {
    final weightCtrl = TextEditingController();
    final lengthCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return SafeArea(
              child: Padding(
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
                      'Log New Measurement (નવું માપન)',
                      style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),

                    // Date Picker Tile
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                      title: Text(DateFormat('dd MMMM yyyy').format(selectedDate)),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime(2023),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setModalState(() => selectedDate = picked);
                          }
                        },
                        child: const Text('Change Date'),
                      ),
                    ),

                    const SizedBox(height: 6),
                    TextField(
                      controller: weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Weight (kg) • વજન (e.g. 9.6)',
                        prefixIcon: const Icon(Icons.scale_rounded, color: AppColors.primary),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lengthCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Length / Height (cm) • ઊંચાઈ (e.g. 78.0)',
                        prefixIcon: const Icon(Icons.straighten_rounded, color: AppColors.primary),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        labelText: 'Clinical Notes / Feed Observation (Optional)',
                        prefixIcon: const Icon(Icons.note_alt_outlined, color: AppColors.primary),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A2B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final w = double.tryParse(weightCtrl.text.trim()) ?? 0.0;
                        final l = double.tryParse(lengthCtrl.text.trim()) ?? 0.0;

                        if (w <= 0 || l <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter valid positive numbers for weight and length.'),
                              backgroundColor: AppColors.statusRed,
                            ),
                          );
                          return;
                        }

                        _growthService.addMeasurement(
                          weightKg: w,
                          lengthCm: l,
                          date: selectedDate,
                          notes: notesCtrl.text.trim(),
                        );

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Measurement recorded successfully onto WHO curve!'),
                            backgroundColor: AppColors.statusGreen,
                          ),
                        );
                      },
                      child: const Text('Save Measurement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 6. Milestones Modal ---
  void _showMilestonesModal(BuildContext context, ChildProfile child) {
    final milestones = [
      {'title': 'Stands alone and takes independent steps', 'cat': 'Gross Motor', 'done': true},
      {'title': 'Feeds self soft finger foods (diced fruits, chapati)', 'cat': 'Feeding & Nutrition', 'done': true},
      {'title': 'Drinks water from an open cup or sipper', 'cat': 'Feeding & Nutrition', 'done': true},
      {'title': 'Says 3–5 meaningful words ("Maa", "Papa", "Pani")', 'cat': 'Language & Speech', 'done': true},
      {'title': 'Pincer grasp: picks up small peas / raisins with 2 fingers', 'cat': 'Fine Motor', 'done': true},
      {'title': 'Shows affection, hugs toys and family members', 'cat': 'Social-Emotional', 'done': true},
      {'title': 'Understands simple commands like "Come here"', 'cat': 'Cognitive', 'done': true},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Color(0xFFF7F9F6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '14-Month Milestones (વિકાસના લક્ષ્યો)',
                        style: AppTypography.headline3.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ICMR & WHO Early Childhood Development Tracker',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: milestones.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (c, idx) {
                    final m = milestones[idx];
                    final isDone = m['done'] as bool;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: isDone ? const Color(0xFF2E7D32) : Colors.grey,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m['title'] as String,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  m['cat'] as String,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 7. Export PDF Report ---
  Future<void> _exportPdf(ChildProfile child, List<GrowthMeasurement> measurements) async {
    setState(() => _isExportingPdf = true);

    try {
      final exportResult = await GrowthReportPdfService.instance.exportAndSavePdf(
        child: child,
        measurements: measurements,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Official WHO Growth Report Generated! $exportResult'),
            backgroundColor: AppColors.statusGreen,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF export error: $e'),
            backgroundColor: AppColors.statusRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
  }
}

// ============================================================================
// Real WHO Growth Curve Custom Painter (Weight/Length vs Age with WHO Percentiles)
// ============================================================================
class RealWhoGrowthCurvePainter extends CustomPainter {
  final List<GrowthMeasurement> measurements;
  final bool isWeight;
  final GrowthMeasurement? selectedMeasurement;

  RealWhoGrowthCurvePainter({
    required this.measurements,
    required this.isWeight,
    this.selectedMeasurement,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 26.0;
    const rightPad = 36.0;
    const topPad = 14.0;
    const bottomPad = 22.0;

    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;

    final double minY = isWeight ? 2.0 : 45.0;
    final double maxY = isWeight ? 14.0 : 90.0;
    const double minX = 0.0;
    const double maxX = 24.0;

    double toX(double age) => leftPad + chartW * (age / maxX);
    double toY(double val) => topPad + chartH * (1.0 - ((val - minY) / (maxY - minY)));

    // 1. Grid Lines (Horizontal & Vertical)
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 0.8;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Horizontal Y grid lines
    final ySteps = isWeight ? [2, 4, 6, 8, 10, 12, 14] : [45, 55, 65, 75, 85];
    for (final yVal in ySteps) {
      final y = toY(yVal.toDouble());
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);

      textPainter.text = TextSpan(
        text: '$yVal',
        style: const TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftPad - textPainter.width - 4, y - textPainter.height / 2));
    }

    // Vertical X grid lines (0, 3, 6, 9, 12, 15, 18, 21, 24)
    for (int age = 0; age <= 24; age += 3) {
      final x = toX(age.toDouble());
      canvas.drawLine(Offset(x, topPad), Offset(x, size.height - bottomPad), gridPaint);

      textPainter.text = TextSpan(
        text: '$age',
        style: const TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - bottomPad + 4));
    }

    // Axis Labels
    textPainter.text = TextSpan(
      text: isWeight ? 'Weight (kg)' : 'Length (cm)',
      style: const TextStyle(fontSize: 8, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
    );
    textPainter.layout();
    canvas.save();
    canvas.translate(8, topPad + chartH / 2 + textPainter.width / 2);
    canvas.rotate(-pi / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();

    textPainter.text = const TextSpan(
      text: 'Age (Months)',
      style: TextStyle(fontSize: 8.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(leftPad + chartW / 2 - textPainter.width / 2, size.height - 10));

    // 2. WHO Percentile Curves Reference Data for Boys 0-24M
    // Weight (kg): [3rd, 15th, 50th, 85th, 97th]
    final whoWeightP = {
      0: [2.5, 2.9, 3.3, 3.9, 4.4],
      3: [5.0, 5.7, 6.4, 7.2, 8.0],
      6: [6.4, 7.1, 7.9, 8.8, 9.8],
      9: [7.2, 8.0, 8.9, 9.9, 11.0],
      12: [7.8, 8.6, 9.6, 10.8, 12.0],
      15: [8.3, 9.2, 10.3, 11.5, 12.8],
      18: [8.8, 9.7, 10.9, 12.2, 13.7],
      21: [9.2, 10.2, 11.5, 12.9, 14.5],
      24: [9.7, 10.8, 12.2, 13.6, 15.3],
    };

    // Length (cm): [3rd, 15th, 50th, 85th, 97th]
    final whoLengthP = {
      0: [46.1, 47.9, 49.9, 51.8, 53.7],
      3: [57.3, 59.3, 61.4, 63.5, 65.5],
      6: [63.3, 65.5, 67.6, 69.8, 71.9],
      9: [67.5, 69.7, 72.0, 74.2, 76.5],
      12: [71.0, 73.4, 75.7, 78.1, 80.5],
      15: [74.1, 76.6, 79.1, 81.7, 84.2],
      18: [76.9, 79.6, 82.3, 85.0, 87.7],
      21: [79.4, 82.3, 85.1, 88.0, 90.9],
      24: [81.7, 84.8, 87.8, 90.9, 93.9],
    };

    final curveData = isWeight ? whoWeightP : whoLengthP;
    final ages = curveData.keys.toList()..sort();

    // 3. Shaded ±2 SD Normal Band (between 3rd and 97th or 15th and 85th)
    final bandPath = Path();
    for (int i = 0; i < ages.length; i++) {
      final a = ages[i].toDouble();
      final valUpper = curveData[ages[i]]![3]; // 85th or upper bound
      final pt = Offset(toX(a), toY(valUpper));
      if (i == 0) {
        bandPath.moveTo(pt.dx, pt.dy);
      } else {
        bandPath.lineTo(pt.dx, pt.dy);
      }
    }
    for (int i = ages.length - 1; i >= 0; i--) {
      final a = ages[i].toDouble();
      final valLower = curveData[ages[i]]![1]; // 15th or lower bound
      bandPath.lineTo(toX(a), toY(valLower));
    }
    bandPath.close();

    final bandPaint = Paint()
      ..color = const Color(0xFFC8E6C9).withOpacity(0.35)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bandPath, bandPaint);

    // 4. Draw Dashed WHO Percentiles (3rd, 15th, 85th, 97th)
    final dashedPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final pIndices = [0, 1, 3, 4];
    final pLabels = ['3rd', '15th', '85th', '97th'];

    for (int p = 0; p < pIndices.length; p++) {
      final idx = pIndices[p];
      final path = Path();
      for (int i = 0; i < ages.length; i++) {
        final a = ages[i].toDouble();
        final val = curveData[ages[i]]![idx];
        final pt = Offset(toX(a), toY(val));
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(path, dashedPaint);

      // Label at end of line
      final lastAge = ages.last.toDouble();
      final lastVal = curveData[ages.last]![idx];
      textPainter.text = TextSpan(
        text: pLabels[p],
        style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(toX(lastAge) + 2, toY(lastVal) - textPainter.height / 2));
    }

    // 5. Draw Solid Green 50th Percentile Curve (WHO Median)
    final medianPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final medianPath = Path();
    for (int i = 0; i < ages.length; i++) {
      final a = ages[i].toDouble();
      final val = curveData[ages[i]]![2];
      final pt = Offset(toX(a), toY(val));
      if (i == 0) {
        medianPath.moveTo(pt.dx, pt.dy);
      } else {
        medianPath.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(medianPath, medianPaint);

    // Green "50th" pill at end of median curve
    final lastMedianVal = curveData[ages.last]![2];
    final pillX = toX(ages.last.toDouble()) + 2;
    final pillY = toY(lastMedianVal);
    final pillRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pillX, pillY - 7, 24, 14),
      const Radius.circular(4),
    );
    canvas.drawRRect(pillRRect, Paint()..color = const Color(0xFF2E7D32));
    textPainter.text = const TextSpan(
      text: '50th',
      style: TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.w800),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(pillX + 3, pillY - textPainter.height / 2));

    // 6. Draw Aarav's Track (Dark Green line + dots)
    if (measurements.isNotEmpty) {
      final trackPaint = Paint()
        ..color = const Color(0xFF1E3A2B)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;

      final trackPath = Path();
      final dotPoints = <Offset>[];

      for (int i = 0; i < measurements.length; i++) {
        final m = measurements[i];
        final val = isWeight ? m.weightKg : m.lengthCm;
        final pt = Offset(toX(m.ageMonths.toDouble()), toY(val));
        dotPoints.add(pt);
        if (i == 0) {
          trackPath.moveTo(pt.dx, pt.dy);
        } else {
          trackPath.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(trackPath, trackPaint);

      // Draw dots
      final dotPaint = Paint()..color = const Color(0xFF1E3A2B);
      final haloPaint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < dotPoints.length; i++) {
        final pt = dotPoints[i];
        final isLatest = (i == dotPoints.length - 1);

        if (isLatest) {
          // Prominent golden halo for 14m point
          canvas.drawCircle(pt, 7, Paint()..color = const Color(0xFFFEF3C7));
          canvas.drawCircle(pt, 6, haloPaint);
          canvas.drawCircle(pt, 3.5, dotPaint);
        } else {
          canvas.drawCircle(pt, 3.5, dotPaint);
          canvas.drawCircle(pt, 2, Paint()..color = Colors.white);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant RealWhoGrowthCurvePainter oldDelegate) {
    return oldDelegate.measurements != measurements ||
        oldDelegate.isWeight != isWeight ||
        oldDelegate.selectedMeasurement != selectedMeasurement;
  }
}
