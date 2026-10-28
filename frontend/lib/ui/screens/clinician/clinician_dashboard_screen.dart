import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_typography.dart';

class ClinicianDashboardScreen extends StatelessWidget {
  const ClinicianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services_rounded, color: AppColors.secondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Clinician Portal (તબીબી ડેશબોર્ડ)',
                  style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Text(
              'Dr. Meera Patel • GMC: G-48291 • MD Pediatrics',
              style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline_rounded),
            tooltip: 'Assigned Children Directory',
            onPressed: () => Navigator.pushNamed(context, '/assigned_children'),
          ),
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('POSHAN Tracker & ICDS Gujarat telemetry synced!')),
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
            // KPI Metrics Row (4 Tiles)
            Row(
              children: [
                Expanded(child: _kpiCard('TOTAL COHORT', '128', '+12 this mo', AppColors.primary, Icons.groups_rounded)),
                const SizedBox(width: 8),
                Expanded(child: _kpiCard('PENDING REVIEWS', '7', '3 velocity', AppColors.statusOrange, Icons.assignment_late_outlined)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _kpiCard('FALTERING ALERTS', '4', 'Plateau slope', AppColors.statusRed, Icons.stacked_line_chart_rounded)),
                const SizedBox(width: 8),
                Expanded(child: _kpiCard('TODAY CALLS', '5', '2 Audio / 3 Video', AppColors.statusBlue, Icons.video_call_rounded)),
              ],
            ),
            const SizedBox(height: 16),

            // Sector & Quick Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search by Child Name, Mother or ABHA ID...',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Sector 04 Mandvi',
                      style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Urgent Clinical Review Queue (High Risk / Faltering Cases)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Priority Clinical Review Queue',
                  style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/assigned_children'),
                  child: const Text('View All (42) >', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Case 1: Aarav Shah
            _caseCard(
              context: context,
              name: 'Aarav Shah',
              ageSex: '14m • Male',
              metrics: '9.4 kg (+0.3kg) • 77.2 cm',
              statusLabel: 'Consultation Today 11:30 AM',
              statusColor: AppColors.primary,
              worker: 'Kavita Ben (Sec 4)',
              note: 'Complementary feeding transition - coarse texture acceptance. Parent questions iron absorption pairing.',
              actionLabel: 'Launch Audio Room',
              onTap: () => Navigator.pushNamed(context, '/assigned_children'),
            ),
            const SizedBox(height: 10),

            // Case 2: Diya Vankar
            _caseCard(
              context: context,
              name: 'Diya Vankar',
              ageSex: '18m • Female',
              metrics: '8.1 kg (-0.1kg/45d) • 75.8 cm',
              statusLabel: 'Mild Faltering Velocity',
              statusColor: AppColors.statusOrange,
              worker: 'Hansa Ben (Sec 12)',
              note: 'Poor solid food intake post-viral fever. Refuses pulses, relying on diluted cow milk.',
              actionLabel: 'Review WHO Curve',
              onTap: () => Navigator.pushNamed(context, '/assigned_children'),
            ),
            const SizedBox(height: 16),

            // Today's Scheduled Tele-Consultations
            Text(
              "Today's Consultations (આજની મુલાકાતો)",
              style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  _consultationItem('11:30 AM', 'Aarav Shah (Mother: Priya Shah)', 'Audio Call • Texture Review', true),
                  const Divider(height: 16),
                  _consultationItem('12:15 PM', 'Pooja Dave (Mother: Hetal Dave)', 'Video Call • Weaning Follow-up', false),
                  const Divider(height: 16),
                  _consultationItem('02:30 PM', 'Daksh Gohil (Mother: Bhavna Gohil)', 'Physical Visit • Solids Acceptance', false),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Frontline Cadre Escalations Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.diversity_1_rounded, color: AppColors.primaryDark, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Frontline Cadre Sync',
                          style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                        Text(
                          'Kavita Ben (3 Flagged) • Hansa Ben (1 Velocity Alert)',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Broadcasting batch clinical advice to Sector 4 Anganwadi workers...')),
                      );
                    },
                    child: const Text('Batch Guide', style: TextStyle(fontSize: 11)),
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

  Widget _kpiCard(String label, String value, String sub, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.headline1.copyWith(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(sub, style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _caseCard({
    required BuildContext context,
    required String name,
    required String ageSex,
    required String metrics,
    required String statusLabel,
    required Color statusColor,
    required String worker,
    required String note,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              CircleAvatar(
                radius: 16,
                backgroundColor: statusColor.withOpacity(0.15),
                child: Text(name[0], style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold)),
                    Text(ageSex, style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(statusLabel, style: AppTypography.labelSmall.copyWith(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(metrics, style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Worker: $worker • $note', style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onTap,
                child: Text('$actionLabel >', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _consultationItem(String time, String title, String type, bool isNext) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isNext ? AppColors.primaryContainer : AppColors.background,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(time, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isNext ? AppColors.primaryDark : AppColors.textPrimary)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
              Text(type, style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ),
        Icon(isNext ? Icons.videocam_rounded : Icons.call_rounded, size: 18, color: isNext ? AppColors.primary : AppColors.textMuted),
      ],
    );
  }
}
