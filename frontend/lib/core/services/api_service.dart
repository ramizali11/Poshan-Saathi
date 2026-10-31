import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/child_model.dart';
import 'user_session.dart';

class AuthResult {
  final bool success;
  final String message;
  final UserModel? user;
  final String? token;
  final bool isOfflineFallback;
  final bool requiresVerification;
  final bool isUnverified;
  final bool isCancelled;
  final String? email;
  final int cooldownSeconds;

  const AuthResult({
    required this.success,
    required this.message,
    this.user,
    this.token,
    this.isOfflineFallback = false,
    this.requiresVerification = false,
    this.isUnverified = false,
    this.isCancelled = false,
    this.email,
    this.cooldownSeconds = 60,
  });

  factory AuthResult.cancelled([String message = 'Sign-in was cancelled.']) {
    return AuthResult(
      success: false,
      isCancelled: true,
      message: message,
    );
  }
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  /// Configurable compile-time override via:
  /// flutter run --dart-define=API_BASE_URL=https://poshan-saathi-1.onrender.com
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Deployed production Render URL for Poshan-Saathi
  static const String _defaultProductionUrl = 'https://poshan-saathi-1.onrender.com';

  /// Potential local development hosts to check if running locally
  static final List<String> _localCandidateUrls = [
    'http://10.0.2.2:8000',     // Android Emulator host loopback
    'http://127.0.0.1:8000',    // Localhost / Web / Desktop / ADB Reverse
    'http://localhost:8000',
  ];

  String? _workingBaseUrl;

  /// Returns the configured or discovered API base URL.
  Future<String> _getBaseUrl() async {
    // 1. If explicit compile-time override is supplied, respect it unconditionally
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }

    if (_workingBaseUrl != null) {
      return _workingBaseUrl!;
    }

    // 2. Try fast check for local development backend first
    final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 900);

    for (final base in _localCandidateUrls) {
      try {
        final uri = Uri.parse('$base/health');
        final request = await client.getUrl(uri);
        final response = await request.close().timeout(const Duration(milliseconds: 1100));
        if (response.statusCode == 200) {
          _workingBaseUrl = base;
          debugPrint(' Connected to local PoshanSaathi backend at: $base');
          client.close(force: true);
          return base;
        }
      } catch (_) {
        // Continue checking
      }
    }

    client.close(force: true);

    // 3. Fallback to production Render deployed URL
    _workingBaseUrl = _defaultProductionUrl;
    debugPrint(' Using PoshanSaathi production backend at: $_workingBaseUrl');
    return _workingBaseUrl!;
  }

  /// Classifies network exceptions into helpful, user-friendly messages
  String _classifyNetworkError(Object e) {
    if (e is TimeoutException) {
      return 'Server response timed out. The backend may be waking up (Render cold start). Please wait a few seconds and try again.';
    } else if (e is SocketException) {
      return 'Unable to reach the server. Please check your internet connection or verify the server is running.';
    } else if (e is FormatException) {
      return 'Received an invalid response format from the server.';
    } else {
      final msg = e.toString().replaceAll('Exception: ', '').replaceAll('SocketException: ', '');
      return 'Connection error: $msg';
    }
  }

  /// Registers a new user into the SQLite database via backend API and triggers Resend email OTP
  Future<AuthResult> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    String role = 'parent',
    String language = 'ગુજરાતી (Gujarati)',
    String state = 'Gujarat (ગુજરાત)',
    String district = 'Ahmedabad (અમદાવાદ)',
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 25);

    try {
      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/auth/register');

      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      final payload = jsonEncode({
        'name': name.trim(),
        'phone': phone.replaceAll(' ', '').trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'role': role,
        'language': language,
        'state': state,
        'district': district,
      });

      request.write(payload);
      final response = await request.close().timeout(const Duration(seconds: 40));
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        UserModel? user;
        if (data['user'] != null) {
          user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
          UserSession.instance.setUser(user);
        }

        final isReqVerif = data['requires_verification'] == true;
        return AuthResult(
          success: true,
          message: data['message'] as String? ?? 'Registration successful! Verification code sent.',
          user: user,
          requiresVerification: isReqVerif,
          email: data['email'] as String? ?? email.trim().toLowerCase(),
          cooldownSeconds: data['cooldown_seconds'] as int? ?? 60,
        );
      } else {
        final errorMsg = data['detail'] as String? ?? 'Registration failed.';
        return AuthResult(success: false, message: errorMsg);
      }
    } catch (e) {
      debugPrint('ℹ️ Network error during register: $e. Falling back to local session.');

      final fallbackUser = UserModel(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        name: name.trim().isNotEmpty ? name.trim() : 'Parent',
        phone: phone.replaceAll(' ', '').trim(),
        email: email.trim().toLowerCase(),
        role: role,
        language: language,
        state: state,
        district: district,
        isVerified: false,
        createdAt: DateTime.now().toIso8601String(),
      );
      UserSession.instance.setUser(fallbackUser);

      return AuthResult(
        success: true,
        message: 'Account saved locally (Backend offline).',
        user: fallbackUser,
        isOfflineFallback: true,
        requiresVerification: true,
        email: email.trim().toLowerCase(),
      );
    } finally {
      client.close(force: true);
    }
  }

  /// Verifies a 6-digit OTP code against the backend SQLite database
  Future<AuthResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 25);

    try {
      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/auth/verify-otp');

      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      final payload = jsonEncode({
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
      });

      request.write(payload);
      final response = await request.close().timeout(const Duration(seconds: 35));
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        UserModel? user;
        String? token = data['token'] as String?;
        if (data['user'] != null) {
          user = UserModel.fromJson(data['user'] as Map<String, dynamic>, token: token);
          UserSession.instance.setUser(user);
        }

        return AuthResult(
          success: true,
          message: data['message'] as String? ?? 'Email verified successfully!',
          user: user,
          token: token,
          email: email,
        );
      } else {
        final errorMsg = data['detail'] as String? ?? 'Verification failed.';
        return AuthResult(success: false, message: errorMsg, email: email);
      }
    } catch (e) {
      debugPrint('ℹ️ Network error during OTP verification: $e');
      return AuthResult(
        success: false,
        message: _classifyNetworkError(e),
        email: email,
      );
    } finally {
      client.close(force: true);
    }
  }

  /// Requests a fresh OTP code with 60-second cooldown enforcement
  Future<AuthResult> resendOtp({
    required String email,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 25);

    try {
      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/auth/resend-otp');

      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      final payload = jsonEncode({
        'email': email.trim().toLowerCase(),
      });

      request.write(payload);
      final response = await request.close().timeout(const Duration(seconds: 35));
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return AuthResult(
          success: true,
          message: data['message'] as String? ?? 'A fresh verification code has been sent.',
          email: email,
          cooldownSeconds: data['cooldown_seconds'] as int? ?? 60,
        );
      } else {
        final errorMsg = data['detail'] as String? ?? 'Could not resend verification code.';
        return AuthResult(success: false, message: errorMsg, email: email);
      }
    } catch (e) {
      debugPrint('ℹ️ Network error during resend OTP: $e');
      return AuthResult(
        success: false,
        message: _classifyNetworkError(e),
        email: email,
      );
    } finally {
      client.close(force: true);
    }
  }

  /// Logs in an existing user using phone/email and password against the SQLite database
  Future<AuthResult> login({
    required String identifier,
    required String password,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 25);

    try {
      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/auth/login');

      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      final payload = jsonEncode({
        'identifier': identifier.replaceAll(' ', '').trim(),
        'password': password,
      });

      request.write(payload);
      final response = await request.close().timeout(const Duration(seconds: 40));
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final userData = data['user'] as Map<String, dynamic>;
        final token = data['token'] as String?;
        final user = UserModel.fromJson(userData, token: token);

        UserSession.instance.setUser(user);

        return AuthResult(
          success: true,
          message: data['message'] as String? ?? 'Login successful!',
          user: user,
          token: token,
        );
      } else if (response.statusCode == 403) {
        final errorMsg = data['detail'] as String? ?? 'Email not verified.';
        final unverifiedEmail = data['email'] as String? ?? identifier;
        return AuthResult(
          success: false,
          isUnverified: true,
          email: unverifiedEmail,
          message: errorMsg,
        );
      } else {
        final errorMsg = data['detail'] as String? ?? 'Invalid credentials.';
        return AuthResult(success: false, message: errorMsg);
      }
    } catch (e) {
      debugPrint('ℹ️ Backend unreachable during login: $e.');
      return AuthResult(
        success: false,
        message: _classifyNetworkError(e),
      );
    } finally {
      client.close(force: true);
    }
  }

  /// Sends a password reset link to the registered email address
  Future<AuthResult> forgotPassword({
    required String email,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);

    try {
      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/auth/forgot-password');

      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      final payload = jsonEncode({
        'email': email.trim().toLowerCase(),
      });

      request.write(payload);
      final response = await request.close().timeout(const Duration(seconds: 45));
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return AuthResult(
          success: true,
          message: data['message'] as String? ??
              'If an account exists for this email, you will receive a password reset link.',
          email: email,
        );
      } else if (response.statusCode == 429) {
        final errorMsg = data['detail'] as String? ??
            'A reset link was recently sent. Please check your inbox or wait 60 seconds.';
        return AuthResult(success: false, message: errorMsg, email: email);
      } else if (response.statusCode == 502 || response.statusCode == 503) {
        final errorMsg = data['detail'] as String? ??
            'The email service is temporarily unavailable. Please try again in a few moments.';
        return AuthResult(success: false, message: errorMsg, email: email);
      } else {
        final errorMsg = data['detail'] as String? ?? 'Could not send reset link. Please try again.';
        return AuthResult(success: false, message: errorMsg, email: email);
      }
    } catch (e) {
      debugPrint('ℹ️ Network error during forgot password: $e');
      return AuthResult(
        success: false,
        message: _classifyNetworkError(e),
        email: email,
      );
    } finally {
      client.close(force: true);
    }
  }

  /// Completes password reset using single-use token and new password
  Future<AuthResult> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);

    try {
      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/auth/reset-password');

      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      final payload = jsonEncode({
        'token': token.trim(),
        'new_password': newPassword,
      });

      request.write(payload);
      final response = await request.close().timeout(const Duration(seconds: 40));
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return AuthResult(
          success: true,
          message: data['message'] as String? ?? 'Password reset successfully. You can now log in.',
        );
      } else {
        final errorMsg = data['detail'] as String? ??
            'Invalid or expired password reset link. Please request a new one.';
        return AuthResult(success: false, message: errorMsg);
      }
    } catch (e) {
      debugPrint('ℹ️ Network error during password reset: $e');
      return AuthResult(
        success: false,
        message: _classifyNetworkError(e),
      );
    } finally {
      client.close(force: true);
    }
  }

  /// Authenticates using a verified Google ID Token
  /// Authenticates using a verified Google ID Token
  Future<AuthResult> loginWithGoogle({
    required String idToken,
    String role = 'parent',
    String? language,
    String? state,
    String? district,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);

    try {
      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/auth/google');

      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      final payload = jsonEncode({
        'id_token': idToken.trim(),
        'role': role,
        if (language != null) 'language': language,
        if (state != null) 'state': state,
        if (district != null) 'district': district,
      });

      request.write(payload);
      final response = await request.close().timeout(const Duration(seconds: 45));
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final userData = data['user'] as Map<String, dynamic>;
        final token = data['token'] as String?;
        final user = UserModel.fromJson(userData, token: token);

        await UserSession.instance.setUser(user);

        return AuthResult(
          success: true,
          message: data['message'] as String? ?? 'Signed in with Google successfully!',
          user: user,
          token: token,
        );
      } else {
        final errorMsg = data['detail'] as String? ?? 'Google authentication failed.';
        return AuthResult(success: false, message: errorMsg);
      }
    } catch (e) {
      debugPrint('ℹ️ Network error during Google sign-in: $e');
      return AuthResult(
        success: false,
        message: _classifyNetworkError(e),
      );
    } finally {
      client.close(force: true);
    }
  }

  /// Updates authenticated user profile details via PUT /api/auth/profile
  Future<AuthResult> updateProfile({
    String? name,
    String? phone,
    String? dob,
    String? gender,
    String? address,
    String? city,
    String? state,
    String? district,
    String? pinCode,
    String? avatarUrl,
    String? language,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 25);

    try {
      final token = UserSession.instance.currentToken;
      if (token == null || token.isEmpty) {
        return const AuthResult(
          success: false,
          message: 'Session token not found. Please log in again.',
        );
      }

      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/auth/profile');

      final request = await client.putUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.set('Authorization', 'Bearer $token');

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name.trim();
      if (phone != null) body['phone'] = phone.replaceAll(' ', '').trim();
      if (dob != null) body['dob'] = dob.trim();
      if (gender != null) body['gender'] = gender.trim();
      if (address != null) body['address'] = address.trim();
      if (city != null) body['city'] = city.trim();
      if (state != null) body['state'] = state.trim();
      if (district != null) body['district'] = district.trim();
      if (pinCode != null) body['pin_code'] = pinCode.trim();
      if (avatarUrl != null) body['avatar_url'] = avatarUrl.trim();
      if (language != null) body['language'] = language.trim();

      request.write(jsonEncode(body));
      final response = await request.close().timeout(const Duration(seconds: 35));
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final updatedUser = UserModel.fromJson(data, token: token);
        await UserSession.instance.setUser(updatedUser);

        return AuthResult(
          success: true,
          message: 'Profile updated successfully!',
          user: updatedUser,
          token: token,
        );
      } else {
        final errorMsg = data['detail'] as String? ?? 'Failed to update profile.';
        return AuthResult(success: false, message: errorMsg);
      }
    } catch (e) {
      debugPrint('ℹ️ Network error during profile update: $e');
      return AuthResult(
        success: false,
        message: _classifyNetworkError(e),
      );
    } finally {
      client.close(force: true);
    }
  }

  /// Refreshes the currently authenticated user details from GET /api/auth/me
  Future<UserModel?> fetchCurrentUser() async {
    final token = UserSession.instance.currentToken;
    if (token == null || token.isEmpty) return null;

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/auth/me');

      final request = await client.getUrl(uri);
      request.headers.set('Authorization', 'Bearer $token');

      final response = await request.close().timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final user = UserModel.fromJson(data, token: token);
        await UserSession.instance.setUser(user);
        return user;
      }
    } catch (e) {
      debugPrint('ℹ️ Could not refresh user profile from backend: $e');
    } finally {
      client.close(force: true);
    }
    return UserSession.instance.currentUser;
  }

  /// Saves Step 1 Caregiver Onboarding details
  Future<AuthResult> saveOnboardingStep1({
    required String name,
    String? phone,
    String? dob,
    String? gender,
    String? address,
    String? city,
    String? state,
    String? district,
    String? pinCode,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 25);
    try {
      final token = UserSession.instance.currentToken;
      if (token == null || token.isEmpty) {
        return const AuthResult(
          success: false,
          message: 'Session token missing. Please sign in again.',
        );
      }

      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/onboarding/step-1');

      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.set('Authorization', 'Bearer $token');

      final body = <String, dynamic>{
        'name': name.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.replaceAll(' ', '').trim(),
        if (dob != null && dob.trim().isNotEmpty) 'dob': dob.trim(),
        if (gender != null && gender.trim().isNotEmpty) 'gender': gender.trim(),
        if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        if (state != null && state.trim().isNotEmpty) 'state': state.trim(),
        if (district != null && district.trim().isNotEmpty) 'district': district.trim(),
        if (pinCode != null && pinCode.trim().isNotEmpty) 'pin_code': pinCode.trim(),
      };

      request.write(jsonEncode(body));
      final response = await request.close().timeout(const Duration(seconds: 35));
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final updatedUser = UserModel.fromJson(data, token: token);
        await UserSession.instance.setUser(updatedUser);
        return AuthResult(
          success: true,
          message: 'Profile information saved successfully.',
          user: updatedUser,
          token: token,
        );
      } else {
        final errorMsg = data['detail'] as String? ?? 'Could not save profile details.';
        return AuthResult(success: false, message: errorMsg);
      }
    } catch (e) {
      debugPrint('ℹ️ Network error during onboarding step 1: $e');
      return AuthResult(success: false, message: _classifyNetworkError(e));
    } finally {
      client.close(force: true);
    }
  }

  /// Saves Step 2 Child/Children Onboarding details
  Future<AuthResult> saveOnboardingStep2({
    required List<Map<String, dynamic>> children,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 25);
    try {
      final token = UserSession.instance.currentToken;
      if (token == null || token.isEmpty) {
        return const AuthResult(
          success: false,
          message: 'Session token missing. Please sign in again.',
        );
      }

      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/onboarding/step-2');

      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.set('Authorization', 'Bearer $token');

      final body = {'children': children};
      request.write(jsonEncode(body));

      final response = await request.close().timeout(const Duration(seconds: 35));
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final currentUser = UserSession.instance.currentUser;
        if (currentUser != null) {
          final completedUser = currentUser.copyWith(
            isProfileComplete: true,
            onboardingStep: 2,
          );
          await UserSession.instance.setUser(completedUser);
        }
        return AuthResult(
          success: true,
          message: data['message'] as String? ?? 'Child details saved successfully!',
          user: UserSession.instance.currentUser,
          token: token,
        );
      } else {
        final errorMsg = data['detail'] as String? ?? 'Could not save child details.';
        return AuthResult(success: false, message: errorMsg);
      }
    } catch (e) {
      debugPrint('ℹ️ Network error during onboarding step 2: $e');
      return AuthResult(success: false, message: _classifyNetworkError(e));
    } finally {
      client.close(force: true);
    }
  }

  /// Skips Step 2 Child Onboarding ("Add Later")
  Future<AuthResult> skipOnboardingStep2() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final token = UserSession.instance.currentToken;
      if (token == null || token.isEmpty) {
        return const AuthResult(
          success: false,
          message: 'Session token missing. Please sign in again.',
        );
      }

      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/onboarding/skip-step-2');

      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.set('Authorization', 'Bearer $token');

      final response = await request.close().timeout(const Duration(seconds: 25));
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final currentUser = UserSession.instance.currentUser;
        if (currentUser != null) {
          final completedUser = currentUser.copyWith(
            isProfileComplete: true,
            onboardingStep: 2,
          );
          await UserSession.instance.setUser(completedUser);
        }
        return AuthResult(
          success: true,
          message: data['message'] as String? ?? 'Child info skipped.',
          user: UserSession.instance.currentUser,
          token: token,
        );
      } else {
        final errorMsg = data['detail'] as String? ?? 'Could not skip step.';
        return AuthResult(success: false, message: errorMsg);
      }
    } catch (e) {
      debugPrint('ℹ️ Network error during skip step 2: $e');
      return AuthResult(success: false, message: _classifyNetworkError(e));
    } finally {
      client.close(force: true);
    }
  }

  /// Retrieves children profiles belonging to authenticated parent
  Future<List<ChildModel>> fetchChildren() async {
    final token = UserSession.instance.currentToken;
    if (token == null || token.isEmpty) return [];

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/children');

      final request = await client.getUrl(uri);
      request.headers.set('Authorization', 'Bearer $token');

      final response = await request.close().timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final list = jsonDecode(responseBody) as List<dynamic>;
        return list.map((item) => ChildModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('ℹ️ Could not fetch children from backend: $e');
    } finally {
      client.close(force: true);
    }
    return [];
  }

  /// Updates child details (such as weight, dob, name) via PATCH /api/children/{childId}
  Future<ChildModel?> updateChild({
    required int childId,
    String? name,
    String? dob,
    double? weight,
    String? gender,
  }) async {
    final token = UserSession.instance.currentToken;
    if (token == null || token.isEmpty) return null;

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 25);
    try {
      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/children/$childId');

      final request = await client.patchUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.set('Authorization', 'Bearer $token');

      final body = <String, dynamic>{
        if (name != null) 'name': name.trim(),
        if (dob != null) 'dob': dob.trim(),
        if (weight != null) 'weight': weight,
        if (gender != null) 'gender': gender.trim(),
      };

      request.write(jsonEncode(body));
      final response = await request.close().timeout(const Duration(seconds: 35));
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        return ChildModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('ℹ️ Could not update child in backend: $e');
    } finally {
      client.close(force: true);
    }
    return null;
  }

  /// Adds a single child profile for the authenticated parent via POST /api/children
  Future<ChildModel?> addChild({
    required String name,
    required String dob,
    required String gender,
    double? weight,
  }) async {
    final token = UserSession.instance.currentToken;
    if (token == null || token.isEmpty) return null;

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 25);
    try {
      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/children');

      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.set('Authorization', 'Bearer $token');

      final body = <String, dynamic>{
        'name': name.trim(),
        'dob': dob.trim(),
        'gender': gender.trim(),
        if (weight != null) 'weight': weight,
      };

      request.write(jsonEncode(body));
      final response = await request.close().timeout(const Duration(seconds: 35));
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        return ChildModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('ℹ️ Could not add child in backend: $e');
    } finally {
      client.close(force: true);
    }
    return null;
  }
}
