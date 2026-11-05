import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_typography.dart';
import 'package:frontend/core/models/child_model.dart';
import 'package:frontend/core/services/child_session.dart';
import 'package:frontend/core/widgets/child_selector_widget.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool _growthToggle = true;
  bool _mealToggle = true;
  bool _doctorToggle = true;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ChildModel?>(
      valueListenable: ChildSession.instance.selectedChildNotifier,
      builder: (context, activeChild, _) {
        final childName = activeChild?.name ?? 'Child';
        final childAge = activeChild?.ageDisplay ?? 'Toddler';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminders & Alerts (યાદ અપાવનાર)',
                  style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  activeChild != null
                      ? '$childName • $childAge • Feeding & Routine Alarms'
                      : 'Feeding & Routine Alarms',
                  style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            actions: const [
              ChildSelectorPill(isCompact: true),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Care Trackers & Alerts (Settings Toggles)
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
                      Text(
                        'Active Notification Trackers for $childName',
                        style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _toggleRow('Growth Weigh-in Reminders (Monthly)', 'Alerts 3 days before Mamta Divas', _growthToggle, (v) => setState(() => _growthToggle = v)),
                      const Divider(height: 16),
                      _toggleRow('Meal & Feeding Routine (4x Daily)', 'Timely notifications for toddler meal slots', _mealToggle, (v) => setState(() => _mealToggle = v)),
                      const Divider(height: 16),
                      _toggleRow('Doctor / ASHA Follow-ups', 'Clinical appointment and checkup notifications', _doctorToggle, (v) => setState(() => _doctorToggle = v)),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add_alarm_rounded, size: 16),
                        label: const Text('+ Add Custom Reminder (Vitamin D drops, etc.)', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Timeline History
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TODAY (આજે)',
                      style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textMuted),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text('Mark all as read', style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),

                // Item 1: Mamta Divas Session
                _notificationCard(
                  icon: Icons.calendar_month_rounded,
                  iconColor: AppColors.tertiaryDark,
                  bgColor: AppColors.tertiaryLight,
                  title: 'Mamta Divas Session in 2 Days',
                  time: 'In 2 Days • 09:30 AM',
                  body: 'Sector 4 Anganwadi Center routine anthropometry check on Thursday for $childName. Free height, weight and Vitamin A booster.',
                  isUnread: true,
                  actionLabel: 'View Center Details',
                  onAction: () => Navigator.pushNamed(context, '/anganwadi_connect'),
                ),
                const SizedBox(height: 10),

                // Item 2: Mid-morning Snack
                _notificationCard(
                  icon: Icons.local_dining_rounded,
                  iconColor: AppColors.primary,
                  bgColor: AppColors.primaryLight,
                  title: 'Mid-morning Snack Planned',
                  time: 'Today, 10:15 AM',
                  body: 'Mashed Papaya & Sprouted Ragi Sheera for $childName scheduled at 10:30 AM (High Vitamin A, Calcium Rich).',
                  isUnread: false,
                  actionLabel: 'View Recipe',
                  onAction: () => Navigator.pushNamed(context, '/recipe_details'),
                ),
                const SizedBox(height: 16),

                Text(
                  'EARLIER THIS WEEK (આ અઠવાડિયે)',
                  style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),

                // Item 3: Daily Pediatric Tip
                _notificationCard(
                  icon: Icons.lightbulb_rounded,
                  iconColor: AppColors.secondary,
                  bgColor: AppColors.secondaryLight,
                  title: 'Daily Pediatric Nutrition Tip',
                  time: 'Yesterday • 8:00 AM',
                  body: 'Iron Bio-availability Tip: Remember to pair moong dal with a few drops of fresh lemon juice today for maximum uptake.',
                  isUnread: false,
                ),
                const SizedBox(height: 10),

                // Item 4: Tele-Consultation
                _notificationCard(
                  icon: Icons.medical_services_rounded,
                  iconColor: AppColors.statusBlue,
                  bgColor: AppColors.statusBlueContainer,
                  title: 'Pediatrician Follow-up Scheduled',
                  time: '3 days ago',
                  body: 'Audio consultation confirmed with Dr. Meera Patel on 28 Feb at 11:30 AM for $childName\'s solids acceptance review.',
                  isUnread: false,
                  actionLabel: 'Consultation Details',
                  onAction: () => Navigator.pushNamed(context, '/clinician_dashboard'),
                ),
                const SizedBox(height: 16),

                // Quiet Hours Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bedtime_outlined, color: AppColors.textMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quiet Hours & Frequency', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
                            Text('No audible alerts between 10:00 PM – 7:00 AM', style: AppTypography.bodySmall.copyWith(fontSize: 10)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Configure', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _toggleRow(String title, String sub, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold)),
              Text(sub, style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _notificationCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String time,
    required String body,
    required bool isUnread,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isUnread ? AppColors.primary.withOpacity(0.5) : AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                    Text(time, style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4)),
          if (actionLabel != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: Text('$actionLabel >', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
