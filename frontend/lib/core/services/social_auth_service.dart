import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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

  /// Apple Service ID for web/Android sign-in flow
  /// Can be overridden at build time via:
  /// --dart-define=APPLE_SERVICE_ID=...
  static const String _appleServiceId = String.fromEnvironment(
    'APPLE_SERVICE_ID',
    defaultValue: 'com.poshansaathi.service',
  );

  /// Apple OAuth redirect URI for web/Android sign-in
  static const String _appleRedirectUri = String.fromEnvironment(
    'APPLE_REDIRECT_URI',
    defaultValue: 'https://poshan-saathi-1.onrender.com/api/auth/apple/callback',
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

  /// Initiates Apple Sign-In and securely validates credential on the backend
  Future<AuthResult> signInWithApple({
    String role = 'parent',
    String language = 'ગુજરાતી (Gujarati)',
    String state = 'Gujarat (ગુજરાત)',
    String district = 'Ahmedabad (અમદાવાદ)',
  }) async {
    try {
      // Configure WebAuthenticationOptions for Android/web targets
      WebAuthenticationOptions? webOptions;
      if (!kIsWeb && Platform.isAndroid) {
        webOptions = WebAuthenticationOptions(
          clientId: _appleServiceId,
          redirectUri: Uri.parse(_appleRedirectUri),
        );
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: webOptions,
      );

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        return const AuthResult(
          success: false,
          message: 'Apple did not return an identity token. Authentication could not be completed.',
        );
      }

      return await ApiService.instance.loginWithApple(
        identityToken: identityToken,
        authorizationCode: credential.authorizationCode,
        firstName: credential.givenName,
        lastName: credential.familyName,
        email: credential.email,
        role: role,
        language: language,
        state: state,
        district: district,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint('ℹ️ Apple Sign-In authorization exception: ${e.code}');
      if (e.code == AuthorizationErrorCode.canceled) {
        return AuthResult.cancelled();
      }
      return AuthResult(
        success: false,
        message: 'Apple Sign-In could not be completed (${e.message}).',
      );
    } catch (e) {
      final errStr = e.toString();
      debugPrint('ℹ️ Apple Sign-In error: $errStr');

      if (errStr.contains('canceled') || errStr.contains('cancelled') || errStr.contains('1001')) {
        return AuthResult.cancelled();
      }

      return AuthResult(
        success: false,
        message: 'Apple Sign-In encountered an issue: ${errStr.replaceAll("PlatformException(", "").replaceAll(")", "")}',
      );
    }
  }
}

