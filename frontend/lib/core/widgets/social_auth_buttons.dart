import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/social_auth_service.dart';

class SocialAuthButtons extends StatefulWidget {
  final bool isRegistration;
  final String role;
  final String language;
  final String state;
  final String district;
  final VoidCallback onAuthSuccess;
  final Function(String error) onAuthError;

  const SocialAuthButtons({
    super.key,
    this.isRegistration = false,
    this.role = 'parent',
    this.language = 'ગુજરાતી (Gujarati)',
    this.state = 'Gujarat (ગુજરાત)',
    this.district = 'Ahmedabad (અમદાવાદ)',
    required this.onAuthSuccess,
    required this.onAuthError,
  });

  @override
  State<SocialAuthButtons> createState() => _SocialAuthButtonsState();
}

class _SocialAuthButtonsState extends State<SocialAuthButtons> {
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  bool get _isProcessing => _isGoogleLoading || _isAppleLoading;

  Future<void> _handleGoogleSignIn() async {
    if (_isProcessing) return;

    setState(() => _isGoogleLoading = true);

    try {
      final result = await SocialAuthService.instance.signInWithGoogle(
        role: widget.role,
        language: widget.language,
        state: widget.state,
        district: widget.district,
      );

      if (!mounted) return;
      setState(() => _isGoogleLoading = false);

      if (result.isCancelled) {
        // User cancelled dialog - do nothing, no misleading error banner
        return;
      }

      if (result.success) {
        widget.onAuthSuccess();
      } else {
        widget.onAuthError(result.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
      widget.onAuthError('Google sign-in could not be completed. Please try again.');
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_isProcessing) return;

    setState(() => _isAppleLoading = true);

    try {
      final result = await SocialAuthService.instance.signInWithApple(
        role: widget.role,
        language: widget.language,
        state: widget.state,
        district: widget.district,
      );

      if (!mounted) return;
      setState(() => _isAppleLoading = false);

      if (result.isCancelled) {
        // User cancelled dialog - do nothing
        return;
      }

      if (result.success) {
        widget.onAuthSuccess();
      } else {
        widget.onAuthError(result.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAppleLoading = false);
      widget.onAuthError('Apple sign-in could not be completed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // "OR" Divider
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'OR CONTINUE WITH',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.divider)),
          ],
        ),
        const SizedBox(height: 16),

        // Google Sign-In Button
        OutlinedButton(
          onPressed: _isProcessing ? null : _handleGoogleSignIn,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1F1F1F),
            side: const BorderSide(color: Color(0xFFDADCE0), width: 1.2),
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isGoogleLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              else
                _buildGoogleIcon(),
              const SizedBox(width: 12),
              Text(
                widget.isRegistration ? 'Sign up with Google' : 'Continue with Google',
                style: AppTypography.labelLarge.copyWith(
                  color: const Color(0xFF1F1F1F),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Apple Sign-In Button
        ElevatedButton(
          onPressed: _isProcessing ? null : _handleAppleSignIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isAppleLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                const Icon(Icons.apple, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                widget.isRegistration ? 'Sign up with Apple' : 'Continue with Apple',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Official 4-color Google "G" icon using Canvas drawing for crisp native rendering
  Widget _buildGoogleIcon() {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Draw Google 4-color segments
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final bluePaint = Paint()..color = const Color(0xFF4285F4);

    final rect = Rect.fromLTWH(0, 0, w, h);

    // Blue arc & bar
    final bluePath = Path()
      ..moveTo(w * 0.5, h * 0.5)
      ..arcTo(rect, -0.4, 1.2, false)
      ..lineTo(w * 0.5, h * 0.5);
    canvas.drawPath(bluePath, bluePaint);

    // Green arc
    final greenPath = Path()
      ..moveTo(w * 0.5, h * 0.5)
      ..arcTo(rect, 0.8, 1.6, false)
      ..lineTo(w * 0.5, h * 0.5);
    canvas.drawPath(greenPath, greenPaint);

    // Yellow arc
    final yellowPath = Path()
      ..moveTo(w * 0.5, h * 0.5)
      ..arcTo(rect, 2.4, 1.2, false)
      ..lineTo(w * 0.5, h * 0.5);
    canvas.drawPath(yellowPath, yellowPaint);

    // Red arc
    final redPath = Path()
      ..moveTo(w * 0.5, h * 0.5)
      ..arcTo(rect, 3.6, 1.3, false)
      ..lineTo(w * 0.5, h * 0.5);
    canvas.drawPath(redPath, redPaint);

    // Inner white cutout for the "G" ring
    final innerWhite = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.32, innerWhite);

    // Center blue crossbar for the "G"
    final barRect = Rect.fromLTWH(w * 0.44, h * 0.40, w * 0.52, h * 0.20);
    canvas.drawRect(barRect, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

