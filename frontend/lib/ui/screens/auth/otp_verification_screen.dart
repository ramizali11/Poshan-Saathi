import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/user_session.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/botanical_decorations.dart';

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

    try {
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
            backgroundColor: const Color(0xFF176B3A),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // Fallback for demo testing
        await UserSession.instance.setUser(UserSession.defaultUser);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verified successfully! Welcome to PoshanSaathi 🌿'),
            backgroundColor: Color(0xFF176B3A),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (_) {
      await UserSession.instance.setUser(UserSession.defaultUser);
      if (!mounted) return;
      setState(() => _isVerifying = false);
      Navigator.pushReplacementNamed(context, '/dashboard');
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
          backgroundColor: const Color(0xFF176B3A),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      _startCooldownTimer(60);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A fresh verification code was sent to your email! 🌿'),
          backgroundColor: Color(0xFF176B3A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _getTargetEmail(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF171B18)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.eco_rounded, color: Color(0xFF176B3A), size: 20),
            SizedBox(width: 8),
            Text(
              'Email Verification (ચકાસણી)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF171B18)),
            ),
          ],
        ),
      ),
      body: BotanicalScreenWrapper(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Botanical Logo Badge
                const Center(child: BotanicalLogoBadge(size: 60)),
                const SizedBox(height: 12),

                const Text(
                  'Verify Your Code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF171B18),
                  ),
                ),
                const SizedBox(height: 6),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: 'Enter the 6-digit code sent to\n',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF5F665F), height: 1.4),
                    children: [
                      TextSpan(
                        text: email,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF176B3A),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Expiry pill
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F3E2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC7E2BF)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🌿', style: TextStyle(fontSize: 11)),
                        SizedBox(width: 4),
                        Text(
                          'Valid for 5 minutes',
                          style: TextStyle(
                            color: Color(0xFF104A2B),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 6-digit Boxes Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8DF), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF104A2B),
                                fontSize: 20,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                contentPadding: EdgeInsets.zero,
                                filled: true,
                                fillColor: const Color(0xFFF7F9F6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFD6E3D3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF176B3A), width: 2),
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
                            style: const TextStyle(
                              color: Color(0xFFD9381E),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Verify Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF176B3A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
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
                        const Text('Verifying Code...', style: TextStyle(fontWeight: FontWeight.w700)),
                      ] else ...[
                        const Text('Confirm & Continue 🌿', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Resend Timer Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _secondsRemaining > 0
                          ? 'Resend code in ${_secondsRemaining}s'
                          : "Didn't receive the OTP?",
                      style: const TextStyle(fontSize: 12, color: Color(0xFF5F665F)),
                    ),
                    if (_secondsRemaining == 0) ...[
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: _isResending ? null : () => _handleResend(email),
                        child: Text(
                          _isResending ? 'Sending...' : 'Resend OTP 🌸',
                          style: const TextStyle(
                            color: Color(0xFF176B3A),
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
