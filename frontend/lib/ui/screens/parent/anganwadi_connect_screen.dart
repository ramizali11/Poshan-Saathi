import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_typography.dart';
import 'package:frontend/core/widgets/status_badge.dart';

class AnganwadiConnectScreen extends StatelessWidget {
  const AnganwadiConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anganwadi Connectivity (આંગણવાડી સેવા)',
              style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'ICDS Grassroots Support & Mamta Divas',
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
            // Designated Worker Profile Card
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
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.volunteer_activism_rounded, color: AppColors.primaryDark, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Kavita Ben',
                                  style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.verified_rounded, color: AppColors.primary, size: 16),
                              ],
                            ),
                            Text(
                              'મુખ્ય આંગણવાડી કાર્યકર • Sector 4 Mandvi',
                              style: AppTypography.gujaratiSubtitle.copyWith(color: AppColors.secondary),
                            ),
                            Text(
                              'ICDS Certified • 12 Years Community Experience',
                              style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                            backgroundColor: AppColors.primary,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Calling Kavita Ben: +91 98250 12345...')),
                            );
                          },
                          icon: const Icon(Icons.call_rounded, size: 16),
                          label: const Text('Call Worker', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Direct chat thread with Sector 4 Center opened.')),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                          label: const Text('Send Message', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Growth & Counseling Notes from Last Visit
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
                  StatusBadge(
                    label: 'Normal WHO Growth Velocity (Green Zone)',
                    status: BadgeStatus.normal,
                    icon: Icons.check_circle_rounded,
                    isSmall: true,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Last In-Person Visit Record (પાછલી મુલાકાત)',
                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '12 January 2026 • Mandvi Center • 9.1 kg | 75.8 cm',
                    style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Counseling Notes: Encouraged coarse mashing, avoid whole grains. Suggested locally available Bajra porridge with cow\'s ghee and mashed yellow moong dal for texture acceptance.',
                            style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Next Mamta Divas Event Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.tertiaryLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.tertiary.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.tertiary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('FEB 26', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upcoming Mamta Divas (મમતા દિવસ)',
                              style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Mandvi Sector 4 Center • 9:30 AM – 1:00 PM',
                              style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _serviceItem('Free WHO Anthropometry (Weight, Height, MUAC tape)'),
                  _serviceItem('Vitamin A Supplementation Drops (ડોઝ)'),
                  _serviceItem('One-on-One Maternal Counseling & Complementary Diets'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/reminders'),
                          icon: const Icon(Icons.notifications_active_outlined, size: 16),
                          label: const Text('Set Reminder', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.map_outlined, size: 16),
                          label: const Text('View Center Map', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Gujarati Audio Guides
            Text(
              'Gujarati Audio Guides (માર્ગદર્શન ઑડિયો)',
              style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),

            _audioCard(
              'પૂરક આહાર શરૂ કરવાની રીત',
              'Complementary Feeding Basics for 7-18m • 4:12 mins',
            ),
            _audioCard(
              'બાળકમાં લોહતત્વ વધારવાના દેશી ઉપાયો',
              'Local Iron Boosters & Moringa Leaves • 3:45 mins',
            ),
            const SizedBox(height: 14),

            // Download Record Slip
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Downloading Anganwadi Record Slip PDF...')),
                );
              },
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Download Anganwadi Growth Slip (માસિક સ્લિપ)'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _serviceItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.statusGreen),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary))),
        ],
      ),
    );
  }

  Widget _audioCard(String titleGuj, String sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded, color: AppColors.primaryDark, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titleGuj, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                Text(sub, style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
