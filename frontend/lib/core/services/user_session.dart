import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Central singleton session that manages the currently logged-in user in memory.
/// Uses [ValueNotifier] so widgets can listen and update reactively without breaking existing UI.
class UserSession {
  UserSession._();
  static final UserSession instance = UserSession._();

  final ValueNotifier<UserModel?> currentUserNotifier = ValueNotifier<UserModel?>(
    const UserModel(
      id: 1,
      name: 'Priya Shah',
      phone: '9876543210',
      email: 'priya.shah@example.com',
      role: 'parent',
      language: 'ગુજરાતી (Gujarati)',
      state: 'Gujarat (ગુજરાત)',
      district: 'Ahmedabad (અમદાવાદ)',
    ),
  );

  UserModel? get currentUser => currentUserNotifier.value;

  String get displayName => currentUser?.name ?? 'Caregiver';

  String get displayPhone => currentUser?.phone.isNotEmpty == true ? currentUser!.phone : '9876543210';

  void setUser(UserModel user) {
    currentUserNotifier.value = user;
  }

  void updateName(String name) {
    if (currentUserNotifier.value != null) {
      currentUserNotifier.value = currentUserNotifier.value!.copyWith(name: name);
    }
  }

  void clearUser() {
    currentUserNotifier.value = null;
  }
}

