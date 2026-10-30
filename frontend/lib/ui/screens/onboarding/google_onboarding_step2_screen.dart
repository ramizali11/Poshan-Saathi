import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class _ChildFormData {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  String gender = 'Boy'; // 'Boy', 'Girl', 'Other'
  String agePreview = '';

  void dispose() {
    nameController.dispose();
    dobController.dispose();
    weightController.dispose();
  }
}

class GoogleOnboardingStep2Screen extends StatefulWidget {
  const GoogleOnboardingStep2Screen({super.key});

  @override
  State<GoogleOnboardingStep2Screen> createState() => _GoogleOnboardingStep2ScreenState();
}

class _GoogleOnboardingStep2ScreenState extends State<GoogleOnboardingStep2Screen> {
  final List<_ChildFormData> _children = [];
  bool _isSaving = false;
  bool _isSkipping = false;

  @override
  void initState() {
    super.initState();
    // Start with 1 child card by default
    _addNewChild();
  }

  void _addNewChild() {
    setState(() {
      _children.add(_ChildFormData());
    });
  }

  void _removeChild(int index) {
    if (_children.length > 1) {
      setState(() {
        _children[index].dispose();
        _children.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    for (final child in _children) {
      child.dispose();
    }
    super.dispose();
  }

  Future<void> _pickChildDob(int index) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 6, now.month, now.day); // Children 0 to 6 years
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 1, now.month, now.day),
      firstDate: firstDate,
      lastDate: now,
      helpText: "Select Child's Date of Birth",
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
      final y = picked.year.toString().padLeft(4, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');

      // Calculate age preview
      int years = now.year - picked.year;
      int months = now.month - picked.month;
      int days = now.day - picked.day;

      if (days < 0) months -= 1;
      if (months < 0) {
        years -= 1;
        months += 12;
      }

      String preview;
      if (years > 0) {
        preview = months > 0 ? '$years yr $months mo old' : '$years yr old';
      } else if (months > 0) {
        preview = '$months month${months > 1 ? 's' : ''} old';
      } else {
        final totalDays = now.difference(picked).inDays;
        preview = '$totalDays day${totalDays > 1 ? 's' : ''} old';
      }

      setState(() {
        _children[index].dobController.text = '$y-$m-$d';
        _children[index].agePreview = preview;
      });
    }
  }

  Future<void> _handleSaveAndFinish() async {
    if (_isSaving || _isSkipping) return;

    // Validate all child entries
    final payloadChildren = <Map<String, dynamic>>[];

    for (int i = 0; i < _children.length; i++) {
      final child = _children[i];
      final name = child.nameController.text.trim();
      final dob = child.dobController.text.trim();
      final rawWeight = child.weightController.text.trim();

      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter Child #${i + 1}\'s name.'),
            backgroundColor: AppColors.statusRed,
          ),
        );
        return;
      }

      if (dob.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select Child #${i + 1}\'s date of birth.'),
            backgroundColor: AppColors.statusRed,
          ),
        );
        return;
      }

      double? weight;
      if (rawWeight.isNotEmpty) {
        weight = double.tryParse(rawWeight);
        if (weight == null || weight <= 0 || weight > 50) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please enter a valid weight in kg for Child #${i + 1} (or leave it blank).'),
              backgroundColor: AppColors.statusRed,
            ),
          );
          return;
        }
      }

      payloadChildren.add({
        'name': name,
        'dob': dob,
        'gender': child.gender,
        if (weight != null) 'weight': weight,
      });
    }

    setState(() => _isSaving = true);

    final result = await ApiService.instance.saveOnboardingStep2(children: payloadChildren);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile setup complete! Welcome to PoshanSaathi.'),
          backgroundColor: AppColors.statusGreen,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.statusRed,
        ),
      );
    }
  }

  Future<void> _handleSkip() async {
    if (_isSaving || _isSkipping) return;

    setState(() => _isSkipping = true);

    final result = await ApiService.instance.skipOnboardingStep2();

    if (!mounted) return;
    setState(() => _isSkipping = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to PoshanSaathi! You can add child details anytime from the dashboard.'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.statusRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Child Details',
          style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Step 2 of 2',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Bar: 100%
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 1.0, // 100%
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 20),

              // Hero Title Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.child_care_rounded,
                        color: AppColors.primaryDark,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Your Child\'s Details',
                            style: AppTypography.headline3.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Help us personalize nutrition recommendations and track your child\'s growth.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Dynamic Children Cards
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _children.length,
                separatorBuilder: (context, index) => const SizedBox(height: 18),
                itemBuilder: (context, index) => _buildChildCard(index),
              ),
              const SizedBox(height: 16),

              // "+ Add Another Child" Button
              OutlinedButton.icon(
                onPressed: _addNewChild,
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 20),
                label: const Text(
                  '+ Add Another Child (બીજું બાળક ઉમેરો)',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Finish & Save Button
              ElevatedButton(
                onPressed: (_isSaving || _isSkipping) ? null : _handleSaveAndFinish,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppColors.primary,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSaving) ...[
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      const Text('Saving Child Profiles...'),
                    ] else ...[
                      const Text(
                        'Finish & Go to Dashboard (સમાપ્ત કરો)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.check_rounded, size: 20, color: Colors.white),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // "Add Later" / Skip Option
              Center(
                child: TextButton(
                  onPressed: (_isSaving || _isSkipping) ? null : _handleSkip,
                  child: _isSkipping
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary),
                        )
                      : Text(
                          'Add Later / Skip for Now (હમણાં માટે છોડો)',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildCard(int index) {
    final child = _children[index];
    final isMultiple = _children.length > 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with child numbering and optional remove button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Child #${index + 1}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (child.agePreview.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    child.agePreview,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (isMultiple)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.statusRed, size: 20),
                  tooltip: 'Remove child',
                  onPressed: () => _removeChild(index),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Child Name (REQUIRED)
          Row(
            children: [
              Text(
                'Child\'s Full Name (બાળકનું પૂરું નામ)',
                style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(color: AppColors.statusRed, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: child.nameController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'e.g. Aarav / Ananya',
              prefixIcon: const Icon(Icons.face_outlined, color: AppColors.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Date of Birth (REQUIRED)
          Row(
            children: [
              Text(
                'Date of Birth (જન્મ તારીખ)',
                style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(color: AppColors.statusRed, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: child.dobController,
            readOnly: true,
            onTap: () => _pickChildDob(index),
            decoration: InputDecoration(
              hintText: 'Select child\'s birth date',
              prefixIcon: const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: const Icon(Icons.event_outlined),
                onPressed: () => _pickChildDob(index),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              helperText: 'Required to generate WHO-standard growth charts.',
            ),
          ),
          const SizedBox(height: 14),

          // 3. Gender (REQUIRED)
          Row(
            children: [
              Text(
                'Gender (લિંગ)',
                style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(color: AppColors.statusRed, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildGenderChip(index, 'Boy', '👦 Boy (છોકરો)'),
              const SizedBox(width: 8),
              _buildGenderChip(index, 'Girl', '👧 Girl (છોકરી)'),
              const SizedBox(width: 8),
              _buildGenderChip(index, 'Other', '👶 Other'),
            ],
          ),
          const SizedBox(height: 14),

          // 4. Weight in kg (OPTIONAL)
          Row(
            children: [
              Text(
                'Current Weight in kg (વજન - કિ.ગ્રા.)',
                style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Optional',
                  style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: child.weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'e.g. 7.5',
              suffixText: 'kg',
              prefixIcon: const Icon(Icons.monitor_weight_outlined, color: AppColors.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              helperText: 'Optional. Leave blank if unknown; measure & add later.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderChip(int childIndex, String value, String label) {
    final isSelected = _children[childIndex].gender == value;
    return Expanded(
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        selectedColor: AppColors.primaryLight,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
        ),
        onSelected: (val) {
          if (val) {
            setState(() {
              _children[childIndex].gender = value;
            });
          }
        },
      ),
    );
  }
}

