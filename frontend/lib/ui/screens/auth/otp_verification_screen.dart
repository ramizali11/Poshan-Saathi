import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/user_session.dart';
import '../../../core/services/api_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
  }

  void _startCooldownTimer([int seconds = 60]) {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = seconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _getTargetEmail(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) {
      return args.trim();
    }
    final sessionEmail = UserSession.instance.currentUser?.email;
    if (sessionEmail != null && sessionEmail.isNotEmpty) {
      return sessionEmail.trim();
    }
    return 'caregiver@example.com';
  }

  Future<void> _handleVerify(String email) async {
    final code = _controllers.map((c) => c.text.trim()).join();
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit verification code.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final result = await ApiService.instance.verifyOtp(
      email: email,
      otp: code,
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.statusGreen,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pushReplacementNamed(context, '/add_child');
    } else {
      setState(() {
        _errorMessage = result.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.statusRed,
        ),
      );
    }
  }

  Future<void> _handleResend(String email) async {
    if (_secondsRemaining > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final result = await ApiService.instance.resendOtp(email: email);

    if (!mounted) return;
    setState(() => _isResending = false);

    if (result.success) {
      _startCooldownTimer(result.cooldownSeconds);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.statusGreen,
          duration: const Duration(seconds: 3),
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

  @override
  Widget build(BuildContext context) {
    final email = _getTargetEmail(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Email Verification',
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
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    color: AppColors.primaryDark,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Verify Your Email Address\n(ઇમેઇલ ઓટીપી ચકાસણી)',
                textAlign: TextAlign.center,
                style: AppTypography.headline1.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'We have sent a 6-digit secure verification code via Resend to\n',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  children: [
                    TextSpan(
                      text: email,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // 5-minute expiry pill
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: AppColors.primaryDark),
                      const SizedBox(width: 4),
                      Text(
                        'Code valid for 5 minutes (300s)',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
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
                        if (_controllers.every((c) => c.text.isNotEmpty)) {
                          _handleVerify(email);
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),

              // Inline error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.statusRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Resend Timer Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh_rounded, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  if (_secondsRemaining > 0) ...[
                    Text(
                      'Resend code in 00:${_secondsRemaining.toString().padLeft(2, '0')}s',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ] else ...[
                    GestureDetector(
                      onTap: _isResending ? null : () => _handleResend(email),
                      child: Text(
                        _isResending ? 'Sending new code...' : 'Resend Code via Email',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // Verify & Continue Button
              ElevatedButton(
                onPressed: _isVerifying ? null : () => _handleVerify(email),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isVerifying) ...[
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      const Text('Verifying Code...'),
                    ] else ...[
                      const Text('Verify & Activate Account (ચકાસો)'),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Change Email option
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                  label: Text(
                    'Wrong email address? Go back to edit',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 20),

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
                        'Security Notice: An encrypted verification code has been dispatched to your email via Resend. Maximum 5 attempts allowed. Never share your OTP with anyone.',
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
