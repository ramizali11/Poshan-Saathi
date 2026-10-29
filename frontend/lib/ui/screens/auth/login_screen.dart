import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController(text: '9876543210');
  final _passwordController = TextEditingController(text: 'PriyaCare@2026');
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your mobile number or email.')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.instance.login(
      identifier: identifier,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.statusGreen,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else if (result.isUnverified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.statusOrange,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'VERIFY NOW',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, '/otp_verify', arguments: result.email ?? identifier);
            },
          ),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.eco_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 6),
            Text(
              'PoshanSaathi',
              style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Role Switcher Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_circle_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: 'Logging in as: ',
                          style: AppTypography.bodySmall,
                          children: [
                            TextSpan(
                              text: 'Parent / Caregiver',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(context, '/welcome'),
                      child: Text(
                        '[ Change ]',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Welcome Back\n(ફરી સ્વાગત છે)',
                style: AppTypography.headline1.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 6),
              Text(
                'Log in to continue monitoring your child\'s nutrition and complementary feeding journey.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Inputs
              Text(
                'Mobile Number or Email (મોબાઈલ અથવા ઈમેઈલ)',
                style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _identifierController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.contact_phone_outlined, color: AppColors.primary),
                  hintText: 'Enter mobile or email',
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Password (પાસવર્ડ)',
                style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
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
              const SizedBox(height: 10),

              // Remember Me & Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _rememberMe = v ?? true),
                      ),
                      Text('Remember me', style: AppTypography.bodySmall),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
                    child: Text(
                      'Forgot Password?',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.secondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
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
                      const Text('Authenticating...'),
                    ] else ...[
                      const Text('Log In to PoshanSaathi'),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Or access with OTP',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              // Quick OTP Login
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/otp_verify'),
                icon: const Icon(Icons.sms_outlined, size: 18),
                label: const Text('Login with Quick OTP (ત્વરિત OTP લોગિન)'),
              ),
              const SizedBox(height: 16),

              // ABHA / ABDM Integration Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.health_and_safety_rounded, color: AppColors.primaryDark, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'ABHA / ABDM Login',
                                style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.statusGreenContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'GOVT',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 9,
                                    color: AppColors.statusGreen,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Ayushman Bharat Digital Mission Linked Account',
                            style: AppTypography.bodySmall.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: RichText(
                    text: TextSpan(
                      text: "New to PoshanSaathi? ",
                      style: AppTypography.bodyMedium,
                      children: [
                        TextSpan(
                          text: 'Create Parent Account',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

