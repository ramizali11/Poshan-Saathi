import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/user_session.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/child_model.dart';
import '../../../core/services/child_session.dart';
import '../../../core/widgets/missing_field_dialogs.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _districtController;
  late TextEditingController _pinCodeController;
  late TextEditingController _avatarUrlController;

  String? _selectedGender;
  bool _isLoading = false;
  bool _isSaving = false;

  final List<String> _genderOptions = [
    'Female',
    'Male',
    'Other',
    'Prefer not to say',
  ];

  @override
  void initState() {
    super.initState();
    final user = UserSession.instance.currentUser;

    final initialPhone = UserModel.sanitizePhone(user?.phone) ?? '';

    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: initialPhone);
    _dobController = TextEditingController(text: user?.dob ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
    _stateController = TextEditingController(text: user?.state ?? '');
    _districtController = TextEditingController(text: user?.district ?? '');
    _pinCodeController = TextEditingController(text: user?.pinCode ?? '');
    _avatarUrlController = TextEditingController(text: user?.avatarUrl ?? '');

    _selectedGender = user?.gender;
    if (_selectedGender != null && !_genderOptions.contains(_selectedGender)) {
      _selectedGender = null;
    }

    _refreshProfileFromBackend();
  }

  Future<void> _refreshProfileFromBackend() async {
    setState(() => _isLoading = true);
    final freshUser = await ApiService.instance.fetchCurrentUser();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (freshUser != null) {
        if (_nameController.text.isEmpty && freshUser.name.isNotEmpty) {
          _nameController.text = freshUser.name;
        }
        if (_emailController.text.isEmpty && freshUser.email != null) {
          _emailController.text = freshUser.email!;
        }
        final freshPhone = UserModel.sanitizePhone(freshUser.phone);
        if (_phoneController.text.isEmpty && freshPhone != null) {
          _phoneController.text = freshPhone;
        }
        if (_dobController.text.isEmpty && freshUser.dob != null) {
          _dobController.text = freshUser.dob!;
        }
        if (_addressController.text.isEmpty && freshUser.address != null) {
          _addressController.text = freshUser.address!;
        }
        if (_cityController.text.isEmpty && freshUser.city != null) {
          _cityController.text = freshUser.city!;
        }
        if (_stateController.text.isEmpty && freshUser.state != null) {
          _stateController.text = freshUser.state!;
        }
        if (_districtController.text.isEmpty && freshUser.district != null) {
          _districtController.text = freshUser.district!;
        }
        if (_pinCodeController.text.isEmpty && freshUser.pinCode != null) {
          _pinCodeController.text = freshUser.pinCode!;
        }
        if (_avatarUrlController.text.isEmpty && freshUser.avatarUrl != null) {
          _avatarUrlController.text = freshUser.avatarUrl!;
        }
        if (_selectedGender == null && freshUser.gender != null) {
          _selectedGender = freshUser.gender;
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _pinCodeController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    DateTime initial = DateTime.now().subtract(const Duration(days: 365 * 25));
    if (_dobController.text.isNotEmpty) {
      final parsed = DateTime.tryParse(_dobController.text);
      if (parsed != null) initial = parsed;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
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
      final formatted =
          "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        _dobController.text = formatted;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final result = await ApiService.instance.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      dob: _dobController.text.trim(),
      gender: _selectedGender,
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      district: _districtController.text.trim(),
      pinCode: _pinCodeController.text.trim(),
      avatarUrl: _avatarUrlController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.statusGreen,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.statusRed,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = UserSession.instance.currentUser;
    final isGoogleUser = user?.authProvider == 'google';
    final avatar = _avatarUrlController.text.isNotEmpty ? _avatarUrlController.text : user?.avatarUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile (પ્રોફાઇલ સંપાદન)',
          style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.check_rounded, color: AppColors.primary, size: 20),
              label: Text(
                'Save',
                style: AppTypography.labelLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar & Header Card
                      _buildAvatarHeader(avatar, isGoogleUser, user),
                      const SizedBox(height: 20),

                      // Basic Info Section
                      _buildSectionTitle('Basic Information (મૂળભૂત માહિતી)'),
                      _buildCard([
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name (પૂરું નામ)',
                          hint: 'Enter your full name',
                          icon: Icons.person_outline_rounded,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter your full name.';
                            }
                            return null;
                          },
                        ),
                        const Divider(height: 20),
                        _buildGenderDropdown(),
                        const Divider(height: 20),
                        _buildDobField(),
                      ]),
                      const SizedBox(height: 20),

                      // Contact Info Section
                      _buildSectionTitle('Contact Details (સંપર્ક વિગત)'),
                      _buildCard([
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address (ઇમેઇલ)',
                          hint: 'Enter email address',
                          icon: Icons.mail_outline_rounded,
                          readOnly: isGoogleUser,
                          helperText: isGoogleUser ? 'Verified by Google Sign-In' : null,
                          suffixIcon: isGoogleUser
                              ? const Icon(Icons.verified_rounded, color: AppColors.statusGreen, size: 18)
                              : null,
                        ),
                        const Divider(height: 20),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number (મોબાઇલ નંબર)',
                          hint: UserModel.sanitizePhone(user?.phone) == null ? 'Not added' : '10-digit mobile number',
                          icon: Icons.phone_android_rounded,
                          prefixText: '+91 ',
                          keyboardType: TextInputType.phone,
                          helperText: UserModel.sanitizePhone(user?.phone) == null
                              ? 'Required for OTP alerts and clinician consultations'
                              : null,
                          validator: (v) {
                            if (v != null && v.trim().isNotEmpty) {
                              final trimmed = v.trim();
                              if (trimmed.startsWith('g_') || trimmed.startsWith('a_') || trimmed.startsWith('sub_')) {
                                return 'Google identifiers cannot be used as phone numbers.';
                              }
                              final clean = trimmed.replaceAll(RegExp(r'\D'), '');
                              if (clean.length != 10) {
                                return 'Phone number must be exactly 10 digits.';
                              }
                              if (!RegExp(r'^[6-9]\d{9}$').hasMatch(clean)) {
                                return 'Phone number must start with 6, 7, 8, or 9.';
                              }
                            }
                            return null;
                          },
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // Residential Address Section
                      _buildSectionTitle('Location & Address (સરનામું અને રહેઠાણ)'),
                      _buildCard([
                        _buildTextField(
                          controller: _addressController,
                          label: 'Street Address (ઘરનું સરનામું)',
                          hint: user?.address == null ? 'Not added' : 'Flat/House no., street, area',
                          icon: Icons.home_outlined,
                          maxLines: 2,
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _cityController,
                                label: 'City / Town (શહેર)',
                                hint: user?.city == null ? 'Not added' : 'e.g. Ahmedabad',
                                icon: Icons.location_city_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _stateController,
                                label: 'State (રાજ્ય)',
                                hint: user?.state == null ? 'Not added' : 'e.g. Gujarat',
                                icon: Icons.map_outlined,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _buildTextField(
                          controller: _pinCodeController,
                          label: 'PIN Code (પિન કોડ)',
                          hint: user?.pinCode == null ? 'Not added' : '6-digit PIN code',
                          icon: Icons.pin_drop_outlined,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v != null && v.trim().isNotEmpty) {
                              final clean = v.trim();
                              if (clean.length != 6 || !RegExp(r'^\d{6}$').hasMatch(clean)) {
                                return 'PIN code must be exactly 6 digits.';
                              }
                            }
                            return null;
                          },
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // Children Profiles Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('Registered Children (બાળકની વિગતો)'),
                          TextButton.icon(
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                            onPressed: () => showAddNewChildDialog(context),
                            icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                            label: const Text('+ Add Child', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ),
                        ],
                      ),
                      ValueListenableBuilder<List<ChildModel>>(
                        valueListenable: ChildSession.instance.childrenNotifier,
                        builder: (context, children, _) {
                          if (children.isEmpty) {
                            return _buildCard([
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Center(
                                  child: Column(
                                    children: [
                                      const Icon(Icons.child_care_rounded, size: 36, color: AppColors.textMuted),
                                      const SizedBox(height: 6),
                                      const Text('No child profile registered yet', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                                      const SizedBox(height: 8),
                                      OutlinedButton.icon(
                                        onPressed: () => showAddNewChildDialog(context),
                                        icon: const Icon(Icons.add, size: 16),
                                        label: const Text('Add Child Profile', style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ]);
                          }

                          return _buildCard(
                            children.map((child) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.primaryContainer,
                                      child: Text(
                                        child.shortInitials,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryDark,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            child.name,
                                            style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            '${child.gender.isNotEmpty ? '${child.gender} • ' : ''}${child.ageDisplay}${child.dob != null ? ' (DOB: ${child.dob})' : ''}',
                                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (child.hasWeight)
                                      InkWell(
                                        onTap: () => showAddChildWeightDialog(context, child),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceVariant,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${child.weightDisplay} kg',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.edit, size: 12, color: AppColors.textMuted),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      InkWell(
                                        onTap: () => showAddChildWeightDialog(context, child),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            '+ Add Weight',
                                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        child: _isSaving
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  ),
                                  SizedBox(width: 10),
                                  Text('Saving to SQLite Database...'),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text('Update Profile Details'),
                                ],
                              ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildAvatarHeader(String? avatar, bool isGoogleUser, UserModel? user) {
    final initials = (user?.name.trim().isNotEmpty == true)
        ? user!.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'U';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.primaryContainer,
            backgroundImage: (avatar != null && avatar.startsWith('http')) ? NetworkImage(avatar) : null,
            child: (avatar == null || !avatar.startsWith('http'))
                ? Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'User Profile',
                  style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isGoogleUser ? AppColors.statusBlueContainer : AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isGoogleUser ? 'Google Account' : 'Poshan Account',
                        style: AppTypography.labelSmall.copyWith(
                          color: isGoogleUser ? AppColors.statusBlue : AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '#${user?.id ?? 1}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? prefixText,
    String? helperText,
    Widget? suffixIcon,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            prefixText: prefixText,
            suffixIcon: suffixIcon,
            hintText: hint,
            helperText: helperText,
            helperStyle: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted),
            filled: readOnly,
            fillColor: readOnly ? AppColors.background : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender (જાતિ - વૈકલ્પિક)',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.wc_rounded, color: AppColors.primary, size: 20),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          hint: Text('Not added', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
          items: _genderOptions.map((g) {
            return DropdownMenuItem<String>(
              value: g,
              child: Text(g, style: AppTypography.bodyMedium),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedGender = val;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDobField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Birth (જન્મ તારીખ)',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _selectDateOfBirth,
          child: IgnorePointer(
            child: TextFormField(
              controller: _dobController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.cake_outlined, color: AppColors.primary, size: 20),
                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textMuted),
                hintText: 'Not added (Select Date)',
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

