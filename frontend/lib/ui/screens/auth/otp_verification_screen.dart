import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void initState() {
    super.initState();
    // Prepopulate realistic OTP: 4 8 2 9 1 0
    final digits = ['4', '8', '2', '9', '1', '0'];
    for (int i = 0; i < 6; i++) {
      _controllers[i].text = digits[i];
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
          'OTP Verification',
          style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon Header
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    color: AppColors.primaryDark,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Verify Your Mobile Number\n(ઓટીપી ચકાસણી કરો)',
                textAlign: TextAlign.center,
                style: AppTypography.headline1.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'We have sent a 6-digit verification code to\n',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  children: [
                    TextSpan(
                      text: '+91 98765 43210 ',
                      style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                  label: Text(
                    'Edit mobile number',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 6-digit Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 44,
                    height: 52,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: AppTypography.headline2.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (val.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Resend Timer Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Resend code in 00:00 seconds  •  ',
                    style: AppTypography.bodySmall,
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Resend SMS',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Alternative Delivery Options
              Text(
                'Alternative Delivery Options:',
                style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                      label: const Text('Get on WhatsApp', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.phone_outlined, size: 16),
                      label: const Text('Call with OTP', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Verify & Continue Button
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/add_child'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Verify & Continue (ચકાસો અને આગળ વધો)'),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Accessibility Voice
              Center(
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.record_voice_over_outlined, size: 16, color: AppColors.secondary),
                  label: Text(
                    'Having trouble receiving SMS? Click here for voice verification.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.secondary,
                      decoration: TextDecoration.underline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Safety Notice Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.tertiary.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.tertiaryDark, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Digital Safety Notice: Never share your PoshanSaathi verification OTP with anyone, including healthcare volunteers or Anganwadi workers.',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.tertiaryDark,
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
}

