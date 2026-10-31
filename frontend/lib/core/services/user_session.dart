import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'child_session.dart';

/// Central singleton session that manages the currently logged-in user.
/// Default state is null (no hardcoded fallback user like Priya).
/// Uses [ValueNotifier] so widgets can listen and update reactively.
class UserSession {
  UserSession._();
  static final UserSession instance = UserSession._();

  final ValueNotifier<UserModel?> currentUserNotifier = ValueNotifier<UserModel?>(null);

  UserModel? get currentUser => currentUserNotifier.value;
  String? get currentToken => currentUser?.token;

  String get displayName => (currentUser?.name.trim().isNotEmpty == true)
      ? currentUser!.name.trim()
      : 'Caregiver';

  String get displayPhone {
    final p = currentUser?.phone?.trim();
    if (p == null || p.isEmpty || p.startsWith('g_') || p.startsWith('a_') || p.startsWith('sub_')) {
      return 'Not added';
    }
    return p;
  }

  File? _sessionFile;

  File _getSessionFile() {
    if (_sessionFile != null) return _sessionFile!;
    try {
      final tempDir = Directory.systemTemp;
      _sessionFile = File('${tempDir.path}/poshan_saathi_session.json');
    } catch (_) {
      _sessionFile = File('poshan_saathi_session.json');
    }
    return _sessionFile!;
  }

  /// Restores session on app startup if persistent credentials exist.
  Future<void> init() async {
    if (kIsWeb) return;
    try {
      final file = _getSessionFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final data = jsonDecode(content) as Map<String, dynamic>;
          final user = UserModel.fromJson(data, token: data['token'] as String?);
          currentUserNotifier.value = user;
          // If the cached file contained a legacy placeholder phone, clean the disk file
          if (data['phone'] != user.phone) {
            await file.writeAsString(jsonEncode(user.toJson()));
          }
        }
      }
    } catch (e) {
      debugPrint('[UserSession] Could not load persisted session: $e');
    }
  }

  /// Sets current user in memory and persists to disk.
  Future<void> setUser(UserModel user) async {
    currentUserNotifier.value = user;
    if (kIsWeb) return;
    try {
      final file = _getSessionFile();
      final data = user.toJson();
      await file.writeAsString(jsonEncode(data));
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
    ChildSession.instance.clear();
    if (kIsWeb) return;
    try {
      final file = _getSessionFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('[UserSession] Could not clear persisted session: $e');
    }
  }
}
