import 'package:flutter/material.dart';
import '../models/child_model.dart';
import '../models/height_measurement_model.dart';
import '../services/api_service.dart';
import '../services/growth_notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Shows modal bottom sheet / dialog to log or edit an accurate height measurement in centimetres (cm).
Future<HeightMeasurementModel?> showHeightMeasurementDialog({
  required BuildContext context,
  required ChildModel child,
  HeightMeasurementModel? existingRecord,
}) async {
  final isEditing = existingRecord != null;
  final formKey = GlobalKey<FormState>();

  final heightController = TextEditingController(
    text: isEditing ? existingRecord.heightCm.toStringAsFixed(1) : '',
  );
  final notesController = TextEditingController(
    text: isEditing ? existingRecord.notes : '',
  );

  String selectedDate = isEditing
      ? existingRecord.measurementDate
      : _formatIsoDate(DateTime.now());

  bool isSaving = false;
  String? errorMessage;

  return showModalBottomSheet<HeightMeasurementModel?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickDate() async {
            DateTime initialDate = DateTime.now();
            final parsed = DateTime.tryParse(selectedDate);
            if (parsed != null) initialDate = parsed;

            final picked = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime(2015),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primary,
                      onPrimary: Colors.white,
                      onSurface: AppColors.textPrimary,
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (picked != null) {
              setModalState(() {
                selectedDate = _formatIsoDate(picked);
              });
            }
          }

          Future<void> onSave() async {
            if (!formKey.currentState!.validate()) return;

            final val = double.tryParse(heightController.text.trim());
            if (val == null || val <= 0) {
              setModalState(() {
                errorMessage = 'Please enter a valid numeric height in centimetres.';
              });
              return;
            }

            setModalState(() {
              isSaving = true;
              errorMessage = null;
            });

            HeightMeasurementModel? result;
            if (isEditing) {
              result = await ApiService.instance.updateHeightMeasurement(
                childId: child.id,
                measurementId: existingRecord.id,
                heightCm: val,
                measurementDate: selectedDate,
                notes: notesController.text.trim(),
              );
            } else {
              result = await ApiService.instance.addHeightMeasurement(
                childId: child.id,
                heightCm: val,
                measurementDate: selectedDate,
                notes: notesController.text.trim(),
              );

              // Update next monthly reminder since parent measured today
              if (result != null) {
                GrowthNotificationService.instance.onMeasurementRecorded(
                  childId: child.id,
                  childName: child.name,
                );
              }
            }

            if (!ctx.mounted) return;

            setModalState(() => isSaving = false);

            if (result != null) {
              Navigator.pop(ctx, result);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEditing
                      ? 'Height measurement updated to ${val.toStringAsFixed(1)} cm!'
                      : 'Logged ${val.toStringAsFixed(1)} cm for ${child.name}!'),
                  backgroundColor: AppColors.statusGreen,
                ),
              );
            } else {
              setModalState(() {
                errorMessage = 'Could not save measurement to server. Please check connection.';
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Height Record' : 'Record Height (ઊંચાઈ માપો)',
                          style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Child Name Display (read-only, prepopulated)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.face_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CHILD (બાળક)',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${child.name} • ${child.ageDisplay}',
                                style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Height Input in CM
                    TextFormField(
                      controller: heightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: !isEditing,
                      decoration: InputDecoration(
                        labelText: 'Height in Centimetres (cm) *',
                        hintText: 'e.g. 72.5 or 85.0',
                        prefixIcon: const Icon(Icons.straighten_rounded, color: AppColors.primary),
                        suffixText: 'cm',
                        suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        helperText: 'Standard WHO metric. Enter accurate decimal measurement.',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter height in centimetres (cm).';
                        }
                        final numVal = double.tryParse(value.trim());
                        if (numVal == null) {
                          return 'Please enter a valid decimal number (e.g. 75.5).';
                        }
                        if (numVal <= 25.0) {
                          return 'Height must be greater than 25.0 cm.';
                        }
                        if (numVal >= 220.0) {
                          return 'Height must be a reasonable value under 220.0 cm.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Date of Measurement Selector
                    InkWell(
                      onTap: pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, color: AppColors.secondary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Measurement Date (તારીખ)',
                                    style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 10),
                                  ),
                                  Text(
                                    selectedDate,
                                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Optional Notes Field
                    TextFormField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes (વધારાની નોંધ) - Optional',
                        hintText: 'e.g. Measured at Anganwadi center or home checkup',
                        prefixIcon: Icon(Icons.notes_rounded, color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.statusRedContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: AppColors.statusRed, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Save Button
                    ElevatedButton(
                      onPressed: isSaving ? null : onSave,
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(isEditing ? 'Update Measurement' : 'Save Height Measurement'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// Shows confirmation dialog before deleting an existing height record
Future<bool> showDeleteHeightConfirmationDialog({
  required BuildContext context,
  required HeightMeasurementModel record,
  required String childName,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Height Record?'),
        content: Text(
          'Are you sure you want to delete the measurement of ${record.heightDisplay} cm recorded on ${record.measurementDate} for $childName?\n\nThis historical record cannot be recovered.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Record', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );

  return confirmed ?? false;
}

String _formatIsoDate(DateTime dt) {
  final year = dt.year.toString().padLeft(4, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final day = dt.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

