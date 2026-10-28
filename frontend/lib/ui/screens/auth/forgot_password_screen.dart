import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController(text: '9876543210');
  final _newPassController = TextEditingController(text: 'PriyaCare@2027');
  final _confirmPassController = TextEditingController(text: 'PriyaCare@2027');


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
          'Account Recovery',
          style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Security Header
              Row(
                children: [
                  const Icon(Icons.security_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Account Protection & Recovery\n(સુરક્ષિત ખાતું પુનઃપ્રાપ્તિ)',
                      style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Step 1: Send Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'STEP 1 • પગલું ૧',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Verify Identity',
                      style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Enter your registered mobile or email to receive reset link.',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.contact_mail_outlined, color: AppColors.primary),
                        hintText: 'Enter mobile number',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded, size: 16, color: AppColors.statusGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Verified maternal profile linked: Aarav (14m)',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Code sent via SMS • Resend in 00:48s',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text('Change Number', style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Step 2: Set New Password
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'STEP 2 • પગલું ૨',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.secondaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Set New Password (નવો પાસવર્ડ)',
                      style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newPassController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.key_rounded, color: AppColors.primary),
                        hintText: 'Enter new password',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPassController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                        hintText: 'Confirm new password',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Live Checklist
                    _buildCheckItem('At least 8 characters (ઓછામાં ઓછા ૮ અક્ષરો)', true),
                    _buildCheckItem('Contains at least one number (ઓછામાં ઓછો ૧ અંક)', true),
                    _buildCheckItem('Contains a special symbol (!@#\$) (ખાસ ચિહ્ન)', true),
                    _buildCheckItem('Passwords match successfully (પાસવર્ડ મેળ ખાય છે)', true),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password updated successfully! Logging you in...'),
                            backgroundColor: AppColors.statusGreen,
                          ),
                        );
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      icon: const Icon(Icons.task_alt_rounded, size: 18),
                      label: const Text('Update Password & Return to Login'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Guarantee Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.statusGreenContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.statusGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.health_and_safety_rounded, color: AppColors.statusGreen, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Data Preservation Guarantee: Your child\'s meal plans and recorded growth data remain safely preserved.',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.statusGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem(String label, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: isMet ? AppColors.statusGreen : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11,
                color: isMet ? AppColors.textPrimary : AppColors.textMuted,
                fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

