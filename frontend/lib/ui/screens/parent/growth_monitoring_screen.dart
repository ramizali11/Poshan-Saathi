import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_typography.dart';
import 'package:frontend/core/widgets/status_badge.dart';
import 'package:frontend/core/widgets/metric_tile.dart';
import 'package:frontend/core/models/child_model.dart';
import 'package:frontend/core/models/height_measurement_model.dart';
import 'package:frontend/core/services/child_session.dart';
import 'package:frontend/core/services/api_service.dart';
import 'package:frontend/core/services/growth_notification_service.dart';
import 'package:frontend/core/widgets/child_selector_widget.dart';
import 'package:frontend/core/widgets/missing_field_dialogs.dart';
import 'package:frontend/core/widgets/interactive_height_chart.dart';
import 'package:frontend/core/widgets/height_measurement_dialogs.dart';

class GrowthMonitoringScreen extends StatefulWidget {
  const GrowthMonitoringScreen({super.key});

  @override
  State<GrowthMonitoringScreen> createState() => _GrowthMonitoringScreenState();
}

class _GrowthMonitoringScreenState extends State<GrowthMonitoringScreen> {
  List<HeightMeasurementModel> _heightMeasurements = [];
  bool _isLoadingMeasurements = true;
  GrowthReminderSettings? _reminderSettings;
  int? _loadedChildId;

  @override
  void initState() {
    super.initState();
    // Initialize notification service in background
    GrowthNotificationService.instance.initialize();

    final activeChild = ChildSession.instance.activeChild;
    if (activeChild != null) {
      _loadChildGrowthData(activeChild.id);
    }
  }

  Future<void> _loadChildGrowthData(int childId) async {
    setState(() {
      _isLoadingMeasurements = true;
      _loadedChildId = childId;
    });

    final measurements = await ApiService.instance.fetchHeightMeasurements(childId);
    final settings = await GrowthNotificationService.instance.getSettings(childId);

    if (!mounted) return;

    setState(() {
      _heightMeasurements = measurements;
      _reminderSettings = settings;
      _isLoadingMeasurements = false;
    });
  }

  Future<void> _onAddHeight(ChildModel child) async {
    final result = await showHeightMeasurementDialog(
      context: context,
      child: child,
    );
    if (result != null) {
      await _loadChildGrowthData(child.id);
    }
  }

  Future<void> _onEditHeight(ChildModel child, HeightMeasurementModel item) async {
    final result = await showHeightMeasurementDialog(
      context: context,
      child: child,
      existingRecord: item,
    );
    if (result != null) {
      await _loadChildGrowthData(child.id);
    }
  }

  Future<void> _onDeleteHeight(ChildModel child, HeightMeasurementModel item) async {
    final confirmed = await showDeleteHeightConfirmationDialog(
      context: context,
      record: item,
      childName: child.name,
    );

    if (confirmed) {
      final success = await ApiService.instance.deleteHeightMeasurement(
        childId: child.id,
        measurementId: item.id,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Measurement record deleted successfully.'),
            backgroundColor: AppColors.statusGreen,
          ),
        );
        await _loadChildGrowthData(child.id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete measurement record. Please try again.'),
            backgroundColor: AppColors.statusRed,
          ),
        );
      }
    }
  }

  Future<void> _showReminderSettingsModal(BuildContext context, ChildModel child) async {
    final current = _reminderSettings ?? await GrowthNotificationService.instance.getSettings(child.id);

    bool isEnabled = current.isEnabled;
    int dayOfMonth = current.dayOfMonth;
    int hour = current.hour;
    int minute = current.minute;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final period = hour >= 12 ? 'PM' : 'AM';
            final hour12 = hour % 12 == 0 ? 12 : hour % 12;
            final timeStr = '$hour12:${minute.toString().padLeft(2, '0')} $period';

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Monthly Reminder Settings',
                        style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Configure recurring monthly notification for ${child.name}. Reminders run locally on device.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Enable Monthly Reminder for ${child.name}',
                      style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isEnabled ? 'Active: Will notify monthly' : 'Disabled: No reminders will fire',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                    value: isEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setModalState(() => isEnabled = val);
                    },
                  ),
                  const Divider(height: 20),

                  if (isEnabled) ...[
                    // Day of month picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Day of the Month',
                              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Triggers on this day each month',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                        DropdownButton<int>(
                          value: dayOfMonth,
                          items: List.generate(28, (i) => i + 1).map((d) {
                            return DropdownMenuItem<int>(
                              value: d,
                              child: Text('Day $d'),
                            );
                          }).toList(),
                          onChanged: (newDay) {
                            if (newDay != null) {
                              setModalState(() => dayOfMonth = newDay);
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Time Picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reminder Time',
                              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Preferred time of day',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(hour: hour, minute: minute),
                            );
                            if (picked != null) {
                              setModalState(() {
                                hour = picked.hour;
                                minute = picked.minute;
                              });
                            }
                          },
                          icon: const Icon(Icons.access_time_rounded, size: 16),
                          label: Text(timeStr),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Notification Text Preview Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.notifications_active_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Preview Message:',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Time to measure ${child.name}\'s height! Record this month\'s measurement to keep track of their growth.',
                                  style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),

                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await GrowthNotificationService.instance.saveSettings(
                        childId: child.id,
                        childName: child.name,
                        isEnabled: isEnabled,
                        dayOfMonth: dayOfMonth,
                        hour: hour,
                        minute: minute,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEnabled
                                ? 'Monthly reminder for ${child.name} updated!'
                                : 'Monthly reminder for ${child.name} disabled.'),
                            backgroundColor: AppColors.statusGreen,
                          ),
                        );
                        await _loadChildGrowthData(child.id);
                      }
                    },
                    child: const Text('Save Reminder Preferences'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ChildModel?>(
      valueListenable: ChildSession.instance.selectedChildNotifier,
      builder: (context, activeChild, _) {
        if (activeChild != null && activeChild.id != _loadedChildId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadChildGrowthData(activeChild.id);
          });
        }

        final childName = activeChild?.name ?? 'Child';
        final childAge = activeChild?.ageDisplay ?? '';
        final childGender = (activeChild?.gender.isNotEmpty == true) ? activeChild!.gender : 'Child';

        final latestMeasurement = _heightMeasurements.isNotEmpty ? _heightMeasurements.last : null;
        final hasHeight = latestMeasurement != null;

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
                      ? '$childName • $childAge • Height Tracking in Centimetres'
                      : 'Select a child profile • WHO Height Curve',
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
}
