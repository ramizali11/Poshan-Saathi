import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'storage/app_storage.dart';

/// Central singleton session that manages the currently logged-in user,
/// selected role, and interface language.
class UserSession {
  UserSession._();
  static final UserSession instance = UserSession._();

  static const UserModel defaultUser = UserModel(
    id: 1,
    name: 'Priya Shah',
    phone: '9876543210',
    email: 'priya.shah@example.com',
    role: 'parent',
    language: 'ગુજરાતી (Gujarati)',
    state: 'Gujarat (ગુજરાત)',
    district: 'Ahmedabad (અમદાવાદ)',
    isProfileComplete: true,
  );

  final ValueNotifier<UserModel?> currentUserNotifier = ValueNotifier<UserModel?>(defaultUser);

  UserModel? get currentUser => currentUserNotifier.value;
  String? get currentToken => currentUser?.token;
  bool get isLoggedIn => currentUserNotifier.value != null;

  // Selected role for onboarding / login: 'parent', 'doctor', 'admin'
  String _selectedRole = 'parent';
  String get selectedRole => _selectedRole;

  // Selected language for interface: 'English', 'ગુજરાતી (Gujarati)', 'हिन्दी (Hindi)', 'मराठी (Marathi)'
  String _selectedLanguage = 'English';
  String get selectedLanguage => _selectedLanguage;

  void setSelectedRole(String role) {
    _selectedRole = role;
    AppStorage.instance.setString('selected_role', role);
  }

  void setSelectedLanguage(String lang) {
    _selectedLanguage = lang;
    AppStorage.instance.setString('selected_language', lang);
  }

  String get displayName => (currentUser?.name.trim().isNotEmpty == true)
      ? currentUser!.name.trim()
      : 'Priya Shah';

  String get displayPhone {
    final p = currentUser?.phone?.trim();
    if (p == null || p.isEmpty || p.startsWith('g_') || p.startsWith('a_') || p.startsWith('sub_')) {
      return '9876543210';
    }
    return p;
  }

  /// Restores session on app startup if persistent credentials exist.
  Future<void> init() async {
    try {
      final role = await AppStorage.instance.getString('selected_role');
      if (role != null && role.isNotEmpty) {
        _selectedRole = role;
      }

      final lang = await AppStorage.instance.getString('selected_language');
      if (lang != null && lang.isNotEmpty) {
        _selectedLanguage = lang;
      }

      final jsonStr = await AppStorage.instance.getString('user_session');
      if (jsonStr != null && jsonStr.trim().isNotEmpty) {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        final user = UserModel.fromJson(data, token: data['token'] as String?);
        currentUserNotifier.value = user;
        return;
      }
    } catch (e) {
      debugPrint('[UserSession] Could not load persisted session: $e');
    }

    currentUserNotifier.value = defaultUser;
  }

  /// Sets current user in memory and persists to disk.
  Future<void> setUser(UserModel user) async {
    currentUserNotifier.value = user;
    try {
      final data = user.toJson();
      await AppStorage.instance.setString('user_session', jsonEncode(data));
    } catch (e) {
      debugPrint('[UserSession] Could not persist session: $e');
    }
  }

  /// Updates user name in memory and on disk.
  Future<void> updateName(String name) async {
    if (currentUserNotifier.value != null) {
      final updated = currentUserNotifier.value!.copyWith(name: name);
      await setUser(updated);
    }
  }

  /// Clears user from memory and deletes persisted session file on logout.
  Future<void> clearUser() async {
    currentUserNotifier.value = null;
    try {
      await AppStorage.instance.remove('user_session');
    } catch (e) {
      debugPrint('[UserSession] Could not clear persisted session: $e');
    }
  }
}
