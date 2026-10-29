import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? initialToken;

  const ResetPasswordScreen({
    super.key,
    this.initialToken,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null && widget.initialToken!.isNotEmpty) {
      _tokenController.text = widget.initialToken!;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Also check if token was passed via Route arguments
    if (_tokenController.text.isEmpty) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args.isNotEmpty) {
        _tokenController.text = args;
      } else if (args is Map<String, dynamic> && args['token'] != null) {
        _tokenController.text = args['token'].toString();
      }
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Password criteria getters
  bool get _hasMinLength => _passwordController.text.length >= 6;
  bool get _hasNumberOrSymbol =>
      RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]').hasMatch(_passwordController.text);
  bool get _passwordsMatch =>
      _passwordController.text.isNotEmpty &&
      _passwordController.text == _confirmPasswordController.text;

  Future<void> _handleReset() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() {
        _errorMessage = 'Reset token is missing. Please use the link sent to your email.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final newPass = _passwordController.text;
    final result = await ApiService.instance.resetPassword(
      token: token,
      newPassword: newPass,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      setState(() {
        _isSuccess = true;
      });

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text('Password reset successfully! Please log in with your new password.'),
              ),
            ],
          ),
          backgroundColor: AppColors.statusGreen,
          duration: Duration(seconds: 4),
        ),
      );

      // Direct user to login screen
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      });
    } else {
      setState(() {
        _errorMessage = result.message;
      });
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
          'Set New Password',
          style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Badge
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.vpn_key_rounded,
                    color: AppColors.secondaryDark,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Create New Password',
                textAlign: TextAlign.center,
                style: AppTypography.headline2.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'નવો પાસવર્ડ સેટ કરો',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your new password must be different from previous passwords and at least 6 characters long.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),

              if (_isSuccess) ...[
                // Success banner
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.statusGreen.withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.statusGreen, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Password Changed!',
                        style: AppTypography.headline3.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.statusGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Redirecting you to the login screen...',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        },
                        child: const Text('Go to Login Now'),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Form Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Token Field (prefilled or editable)
                        Text(
                          'Reset Token / Verification Code',
                          style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _tokenController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.token_rounded, color: AppColors.primary),
                            hintText: 'Paste reset token here',
                            helperText: 'Automatically detected from your email reset link',
                            helperMaxLines: 2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Reset token is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // New Password Field
                        Text(
                          'New Password',
                          style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                            hintText: 'Enter at least 6 characters',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Password must be at least 6 characters long';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Confirm Password Field
                        Text(
                          'Confirm New Password',
                          style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                            hintText: 'Re-enter your new password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Live Validation Checklist
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildValidationItem(
                                'At least 6 characters (ઓછામાં ઓછા ૬ અક્ષર)',
                                _hasMinLength,
                              ),
                              const SizedBox(height: 6),
                              _buildValidationItem(
                                'Contains number or symbol (અંક અથવા ચિહ્ન)',
                                _hasNumberOrSymbol,
                              ),
                              const SizedBox(height: 6),
                              _buildValidationItem(
                                'Passwords match (પાસવર્ડ મેળ ખાય છે)',
                                _passwordsMatch,
                              ),
                            ],
                          ),
                        ),

                        // Error Banner
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.statusRedContainer,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.statusRed.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    size: 18, color: AppColors.statusRed),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.statusRed,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleReset,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLoading) ...[
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text('Updating Password...'),
                              ] else ...[
                                const Icon(Icons.check_circle_outline_rounded, size: 18),
                                const SizedBox(width: 8),
                                const Text('Reset Password & Return to Login'),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(
                      'Back to Login',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValidationItem(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 16,
          color: isValid ? AppColors.statusGreen : AppColors.textMuted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: isValid ? AppColors.statusGreen : AppColors.textMuted,
              fontWeight: isValid ? FontWeight.w600 : FontWeight.w400,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
