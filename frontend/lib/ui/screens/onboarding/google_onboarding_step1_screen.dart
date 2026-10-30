import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/user_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class GoogleOnboardingStep1Screen extends StatefulWidget {
  const GoogleOnboardingStep1Screen({super.key});

  @override
  State<GoogleOnboardingStep1Screen> createState() => _GoogleOnboardingStep1ScreenState();
}

class _GoogleOnboardingStep1ScreenState extends State<GoogleOnboardingStep1Screen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _pinController = TextEditingController();

  String? _selectedGender;
  bool _isSaving = false;
  bool _isNextEnabled = false;

  final List<String> _genderOptions = ['Female', 'Male', 'Other'];

  @override
  void initState() {
    super.initState();
    final user = UserSession.instance.currentUser;

    // Prepopulate name if available and not a placeholder
    final initialName = (user?.name != null &&
            user!.name.trim().isNotEmpty &&
            user.name != 'Google User' &&
            user.name != 'User')
        ? user.name.trim()
        : '';
    _nameController = TextEditingController(text: initialName);

    // Prepopulate verified email (read-only)
    _emailController = TextEditingController(text: user?.email ?? '');

    // Prepopulate phone if valid existing number (never placeholder)
    if (user?.phone != null && UserModel.sanitizePhone(user!.phone) != null) {
      _phoneController.text = user.phone!;
    }

    if (user?.dob != null) _dobController.text = user!.dob!;
    if (user?.gender != null) _selectedGender = user!.gender;
    if (user?.address != null) _addressController.text = user!.address!;
    if (user?.city != null) _cityController.text = user!.city!;
    if (user?.state != null) _stateController.text = user!.state!;
    if (user?.district != null) _districtController.text = user!.district!;
    if (user?.pinCode != null) _pinController.text = user!.pinCode!;

    _updateNextButtonState();

    _nameController.addListener(_updateNextButtonState);
    _phoneController.addListener(_updateNextButtonState);
  }

  void _updateNextButtonState() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    final isNameValid = name.isNotEmpty;
    final isPhoneValid = phone.isEmpty || RegExp(r'^[6-9]\d{9}$').hasMatch(phone);

    final shouldEnable = isNameValid && isPhoneValid;
    if (_isNextEnabled != shouldEnable) {
      setState(() {
        _isNextEnabled = shouldEnable;
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateNextButtonState);
    _phoneController.removeListener(_updateNextButtonState);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 25, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: now,
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
      setState(() {
        _dobController.text = '$y-$m-$d';
      });
    }
  }

  Future<void> _handleProceedToStep2() async {
    if (!_isNextEnabled || _isSaving) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full name to proceed.'),
          backgroundColor: AppColors.statusRed,
        ),
      );
      return;
    }

    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number or leave it blank.'),
          backgroundColor: AppColors.statusRed,
        ),
      );
      return;
    }

    final pin = _pinController.text.trim();
    if (pin.isNotEmpty && (pin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pin))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit PIN code or leave it blank.'),
          backgroundColor: AppColors.statusRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final result = await ApiService.instance.saveOnboardingStep1(
      name: name,
      phone: phone.isNotEmpty ? phone : null,
      gender: _selectedGender,
      dob: _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : null,
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
      state: _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null,
      district: _districtController.text.trim().isNotEmpty ? _districtController.text.trim() : null,
      pinCode: pin.isNotEmpty ? pin : null,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      // Navigate to Step 2
      Navigator.pushReplacementNamed(context, '/google_onboarding_step2');
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
          'Profile Setup',
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
                const Icon(Icons.check_circle_outline, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Step 1 of 2',
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.5, // 50%
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
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.primaryDark,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete Your Profile',
                              style: AppTypography.headline3.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Let\'s personalize your PoshanSaathi experience with your basic caregiver information.',
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
                const SizedBox(height: 22),

                // 1. Full Name (REQUIRED)
                Row(
                  children: [
                    Text(
                      'Full Name (પૂરું નામ)',
                      style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 4),
                    const Text('*', style: TextStyle(color: AppColors.statusRed, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    helperText: 'Required. Used on growth records and caregiver certificates.',
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Email Address (READ-ONLY verified from Google)
                Row(
                  children: [
                    Text(
                      'Google Account Email',
                      style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Row(
                      children: const [
                        Icon(Icons.verified, size: 14, color: AppColors.statusGreen),
                        SizedBox(width: 4),
                        Text(
                          'Verified Google',
                          style: TextStyle(
                            color: AppColors.statusGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  readOnly: true,
                  decoration: InputDecoration(
                    fillColor: const Color(0xFFF7F8F9),
                    filled: true,
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted),
                    suffixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Mobile Number (OPTIONAL)
                Row(
                  children: [
                    Text(
                      'Mobile Number (મોબાઈલ નંબર)',
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
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '10-digit mobile number',
                    prefixText: '+91 ',
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    helperText: 'Optional. Add to receive SMS nutrition reminders.',
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Gender (OPTIONAL)
                Row(
                  children: [
                    Text(
                      'Gender (લિંગ)',
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
                const SizedBox(height: 8),
                Row(
                  children: _genderOptions.map((opt) {
                    final isSelected = _selectedGender == opt;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(opt),
                          selected: isSelected,
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            setState(() {
                              _selectedGender = val ? opt : null;
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // 5. Date of Birth (OPTIONAL)
                Row(
                  children: [
                    Text(
                      'Date of Birth (જન્મ તારીખ)',
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
                  controller: _dobController,
                  readOnly: true,
                  onTap: _pickDateOfBirth,
                  decoration: InputDecoration(
                    hintText: 'YYYY-MM-DD',
                    prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.event_outlined),
                      onPressed: _pickDateOfBirth,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 18),

                // 6. Address / Location (OPTIONAL)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      Text(
                        'Address & Location (સરનામું)',
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
                  children: [
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        hintText: 'Street / House / Village address',
                        prefixIcon: const Icon(Icons.home_outlined, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: InputDecoration(
                              hintText: 'City / Town',
                              prefixIcon: const Icon(Icons.location_city_outlined, color: AppColors.primary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: 'PIN Code (6 digits)',
                              prefixIcon: const Icon(Icons.pin_drop_outlined, color: AppColors.primary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
                const SizedBox(height: 26),

                // Next Button (disabled until valid name entered)
                ElevatedButton(
                  onPressed: (_isNextEnabled && !_isSaving) ? _handleProceedToStep2 : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: _isNextEnabled ? AppColors.primary : Colors.grey.shade400,
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
                        const Text('Saving Profile...'),
                      ] else ...[
                        const Text(
                          'Next: Child\'s Details (આગળ)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (!_isNextEnabled)
                  Center(
                    child: Text(
                      'Please enter your full name to enable the Next button',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

