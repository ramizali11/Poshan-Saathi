import 'package:flutter/material.dart';
import '../models/child_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/child_session.dart';
import '../services/user_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Reusable dialog to record or update a child's weight
Future<void> showAddChildWeightDialog(BuildContext context, ChildModel child) async {
  final controller = TextEditingController(
    text: child.weight != null ? child.weight!.toString() : '',
  );
  final formKey = GlobalKey<FormState>();
  bool isSaving = false;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.scale_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Update Weight for ${child.name}",
                    style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Enter ${child.name}'s current weight in kilograms. This updates the WHO growth tracking data.",
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Weight (kg)',
                      hintText: 'e.g. 11.5',
                      suffixText: 'kg',
                      prefixIcon: const Icon(Icons.monitor_weight_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a weight in kg';
                      }
                      final w = double.tryParse(val.trim());
                      if (w == null || w <= 0 || w > 100) {
                        return 'Enter a valid weight between 0.5 and 100 kg';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (formKey.currentState?.validate() != true) return;
                        final newWeight = double.parse(controller.text.trim());

                        setDialogState(() => isSaving = true);
                        final success = await ChildSession.instance.updateWeight(child.id, newWeight);
                        setDialogState(() => isSaving = false);

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Updated ${child.name}'s weight to $newWeight kg!"),
                                backgroundColor: AppColors.statusGreen,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not update weight. Please verify connection and try again.'),
                                backgroundColor: AppColors.statusRed,
                              ),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Weight'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Reusable dialog to add or update an optional caregiver profile field
Future<void> showAddParentFieldDialog({
  required BuildContext context,
  required String fieldKey,
  required String fieldTitle,
  required String hintText,
  TextInputType keyboardType = TextInputType.text,
  String? initialValue,
}) async {
  final controller = TextEditingController(text: initialValue ?? '');
  final formKey = GlobalKey<FormState>();
  bool isSaving = false;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              "Add $fieldTitle",
              style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Please provide your $fieldTitle to complete your caregiver profile.",
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller,
                    keyboardType: keyboardType,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: fieldTitle,
                      hintText: hintText,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) {
                      final str = val?.trim() ?? '';
                      if (str.isEmpty) {
                        return 'This field cannot be empty';
                      }
                      if (fieldKey == 'phone') {
                        final sanitized = UserModel.sanitizePhone(str);
                        if (sanitized == null) {
                          return 'Enter a valid 10-digit Indian phone (starts with 6-9)';
                        }
                      }
                      if (fieldKey == 'pin_code') {
                        if (str.length != 6 || !RegExp(r'^\d{6}$').hasMatch(str)) {
                          return 'Enter a valid 6-digit postal PIN code';
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (formKey.currentState?.validate() != true) return;
                        final value = controller.text.trim();

                        setDialogState(() => isSaving = true);
                        final result = await ApiService.instance.updateProfile(
                          phone: fieldKey == 'phone' ? value : null,
                          dob: fieldKey == 'dob' ? value : null,
                          address: fieldKey == 'address' ? value : null,
                          city: fieldKey == 'city' ? value : null,
                          state: fieldKey == 'state' ? value : null,
                          district: fieldKey == 'district' ? value : null,
                          pinCode: fieldKey == 'pin_code' ? value : null,
                          gender: fieldKey == 'gender' ? value : null,
                        );
                        setDialogState(() => isSaving = false);

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          if (result.success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Updated $fieldTitle successfully!"),
                                backgroundColor: AppColors.statusGreen,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result.message),
                                backgroundColor: AppColors.statusRed,
                              ),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Dialog to add a new child profile dynamically from anywhere in the app
Future<void> showAddNewChildDialog(BuildContext context) async {
  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final weightController = TextEditingController();
  String selectedGender = 'Boy';
  final formKey = GlobalKey<FormState>();
  bool isSaving = false;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.child_care_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  "Add Child Profile",
                  style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Child's Full Name *",
                        hintText: "e.g. Rehan",
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return "Child's name is required";
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: dobController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Date of Birth *",
                        hintText: "YYYY-MM-DD",
                        prefixIcon: const Icon(Icons.cake_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime(now.year - 1, now.month, now.day),
                          firstDate: DateTime(now.year - 6, now.month, now.day),
                          lastDate: now,
                        );
                        if (picked != null) {
                          final formatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                          dobController.text = formatted;
                        }
                      },
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return "Date of birth is required";
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedGender,
                      decoration: InputDecoration(
                        labelText: "Gender *",
                        prefixIcon: const Icon(Icons.wc_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Boy', child: Text('Boy (દીકરો)')),
                        DropdownMenuItem(value: 'Girl', child: Text('Girl (દીકરી)')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedGender = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Current Weight in kg (Optional)",
                        hintText: "e.g. 12.0",
                        suffixText: "kg",
                        prefixIcon: const Icon(Icons.scale_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          final w = double.tryParse(val.trim());
                          if (w == null || w <= 0 || w > 100) {
                            return 'Enter a valid weight between 0.5 and 100 kg';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (formKey.currentState?.validate() != true) return;
                        final name = nameController.text.trim();
                        final dob = dobController.text.trim();
                        double? weight;
                        if (weightController.text.trim().isNotEmpty) {
                          weight = double.tryParse(weightController.text.trim());
                        }

                        setDialogState(() => isSaving = true);
                        final created = await ChildSession.instance.addChild(
                          name: name,
                          dob: dob,
                          gender: selectedGender,
                          weight: weight,
                        );
                        setDialogState(() => isSaving = false);

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          if (created != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Child ${created.name} registered and selected!"),
                                backgroundColor: AppColors.statusGreen,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Could not save child. Please try again."),
                                backgroundColor: AppColors.statusRed,
                              ),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Add Child'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Compact inline widget that displays a value or "Not added" with a clickable "+ Add" button
class OptionalFieldDisplay extends StatelessWidget {
  final String? value;
  final VoidCallback onAdd;
  final String placeholder;
  final TextStyle? style;

  const OptionalFieldDisplay({
    super.key,
    required this.value,
    required this.onAdd,
    this.placeholder = 'Not added',
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (value != null && value!.trim().isNotEmpty && value!.trim() != 'Not added') {
      return Text(
        value!,
        style: style ?? AppTypography.bodyMedium,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          placeholder,
          style: (style ?? AppTypography.bodySmall).copyWith(
            color: AppColors.textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add_rounded, size: 12, color: AppColors.primaryDark),
                SizedBox(width: 2),
                Text(
                  'Add',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

