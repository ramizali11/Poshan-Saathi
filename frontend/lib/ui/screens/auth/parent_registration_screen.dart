import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/user_session.dart';
import '../../../core/widgets/social_auth_buttons.dart';

class ParentRegistrationScreen extends StatefulWidget {
  const ParentRegistrationScreen({super.key});

  @override
  State<ParentRegistrationScreen> createState() => _ParentRegistrationScreenState();
}

class _ParentRegistrationScreenState extends State<ParentRegistrationScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedLanguage = 'ગુજરાતી (Gujarati)';
  String _selectedState = 'Gujarat (ગુજરાત)';
  String _selectedDistrict = 'Ahmedabad (અમદાવાદ)';
  bool _consentAgreed = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name.')),
      );
      return;
    }

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your mobile number.')),
      );
      return;
    }

    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (phone.startsWith('g_') || phone.startsWith('a_') || cleanPhone.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number starting with 6, 7, 8, or 9.')),
      );
      return;
    }

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address for OTP verification.')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.instance.register(
      name: name,
      phone: phone,
      email: email,
      password: password,
      language: _selectedLanguage,
      state: _selectedState,
      district: _selectedDistrict,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.statusGreen,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pushNamed(context, '/otp_verify', arguments: result.email ?? email);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.statusRed,
        ),
      );
    }
  }

  void _navigateAfterAuth() {
    final user = UserSession.instance.currentUser;
    if (user != null && !user.isProfileComplete) {
      if (user.onboardingStep == 1) {
        Navigator.pushNamedAndRemoveUntil(context, '/google_onboarding_step2', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/google_onboarding_step1', (route) => false);
      }
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Parent Registration',
          style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stepper Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, size: 16, color: AppColors.primaryDark),
                    const SizedBox(width: 6),
                    Text(
                      'STEP 1 OF 2 • Parent Profile (વાલી પ્રોફાઇલ)',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Create Parent Account\n(માતા-પિતાનું ખાતું બનાવો)',
                style: AppTypography.headline1.copyWith(
                  fontSize: 22,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Join thousands of caregivers nourishing children aged 7 months to 6 years with scientifically backed guidance.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Form Inputs
              _buildFieldLabel('Full Name (પૂરું નામ)', isRequired: true),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                  suffixIcon: Icon(Icons.check_circle_rounded, color: AppColors.statusGreen, size: 20),
                  hintText: 'Enter your name',
                ),
              ),
              const SizedBox(height: 14),

              _buildFieldLabel('Mobile Number (મોબાઇલ નંબર)', isRequired: true),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🇮🇳 +91', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Container(width: 1, height: 20, color: AppColors.border),
                      ],
                    ),
                  ),
                  suffixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.textMuted, size: 20),
                  helperText: 'Used for secure OTP login & Anganwadi SMS alerts',
                  helperStyle: AppTypography.bodySmall.copyWith(fontSize: 11),
                ),
              ),
              const SizedBox(height: 14),

              _buildFieldLabel('Email Address for OTP (ઇમેઇલ સરનામું)', isRequired: true),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.primary),
                  hintText: 'name@example.com',
                  helperText: 'We will send a 6-digit verification code via Resend email',
                  helperStyle: AppTypography.bodySmall.copyWith(fontSize: 11),
                ),
              ),
              const SizedBox(height: 14),

              _buildFieldLabel('Create Password (પાસવર્ડ)', isRequired: true),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.shield_rounded, size: 14, color: AppColors.statusGreen),
                  const SizedBox(width: 4),
                  Text(
                    'Strong: 8+ chars with numbers & symbol (Level 4/4)',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.statusGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _buildFieldLabel('Confirm Password (પાસવર્ડ ખાતરી કરો)', isRequired: true),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Preferred Language Radio Cards
              _buildFieldLabel('Preferred Language for Feeding Guides'),
              Row(
                children: [
                  _languageChip('English'),
                  const SizedBox(width: 8),
                  _languageChip('ગુજરાતી (Gujarati)'),
                  const SizedBox(width: 8),
                  _languageChip('हिन्दी (Hindi)'),
                ],
              ),
              const SizedBox(height: 18),

              // State & District Dropdowns
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('State (રાજ્ય)'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedState,
                              items: ['Gujarat (ગુજરાત)', 'Maharashtra', 'Rajasthan']
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                                  .toList(),
                              onChanged: (val) => setState(() => _selectedState = val!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('District (જિલ્લો)'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedDistrict,
                              items: ['Ahmedabad (અમદાવાદ)', 'Gandhinagar', 'Vadodara', 'Kutch / Mandvi']
                                  .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13))))
                                  .toList(),
                              onChanged: (val) => setState(() => _selectedDistrict = val!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Consent Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _consentAgreed,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _consentAgreed = v ?? false),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'I agree to the Terms of Service & Privacy Policy. I understand that PoshanSaathi provides complementary feeding guidance and does not replace medical diagnosis.',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading) ...[
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      const Text('Saving to Database...'),
                    ] else ...[
                      const Text('Create Parent Account & Send OTP'),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Social Sign-Up: Google
              SocialAuthButtons(
                isRegistration: true,
                role: 'parent',
                language: _selectedLanguage,
                state: _selectedState,
                district: _selectedDistrict,
                onAuthSuccess: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account created & logged in successfully!'),
                      backgroundColor: AppColors.statusGreen,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  _navigateAfterAuth();
                },
                onAuthError: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: AppColors.statusRed,
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: Text(
                    'Already registered? Log in here',
                    style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    '256-bit Health Data Encryption • SFIC 2026 Certified',
                    style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: label,
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          children: [
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.statusRed, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _languageChip(String lang) {
    final isSelected = _selectedLanguage == lang;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedLanguage = lang),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            lang,
            style: AppTypography.labelSmall.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

