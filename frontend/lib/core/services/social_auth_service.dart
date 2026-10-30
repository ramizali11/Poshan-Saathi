import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

class SocialAuthService {
  SocialAuthService._();
  static final SocialAuthService instance = SocialAuthService._();

  /// Server client ID for Google OAuth backend verification
  /// Can be overridden at build time via:
  /// --dart-define=GOOGLE_SERVER_CLIENT_ID=...
  static const String _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: _googleServerClientId.isNotEmpty ? _googleServerClientId : null,
  );

  /// Initiates Google Sign-In and securely validates credential on the backend
  Future<AuthResult> signInWithGoogle({
    String role = 'parent',
    String language = 'ગુજરાતી (Gujarati)',
    String state = 'Gujarat (ગુજરાત)',
    String district = 'Ahmedabad (અમદાવાદ)',
  }) async {
    try {
      // Disconnect previous session if any so user can select account
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled the Google sign-in dialog
        debugPrint('ℹ️ Google Sign-In cancelled by user.');
        return AuthResult.cancelled();
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        return const AuthResult(
          success: false,
          message: 'Google did not return an identity token. Please ensure Google Play Services is configured.',
        );
      }

      return await ApiService.instance.loginWithGoogle(
        idToken: idToken,
        role: role,
        language: language,
        state: state,
        district: district,
      );
    } catch (e) {
      final errStr = e.toString();
      debugPrint('ℹ️ Google Sign-In error: $errStr');

      // Check common cancellation codes (e.g. 12501, sign_in_canceled)
      if (errStr.contains('12501') || errStr.contains('sign_in_canceled') || errStr.contains('canceled')) {
        return AuthResult.cancelled();
      }

      return AuthResult(
        success: false,
        message: 'Google Sign-In failed: ${errStr.replaceAll("PlatformException(", "").replaceAll(")", "")}',
      );
    }
  }
}

