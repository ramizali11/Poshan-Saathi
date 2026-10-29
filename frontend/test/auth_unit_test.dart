import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/models/user_model.dart';
import 'package:frontend/core/services/user_session.dart';

void main() {
  group('Auth & UserSession Unit Tests', () {
    setUp(() {
      UserSession.instance.clearUser();
    });

    test('UserModel JSON serialization and deserialization works correctly', () {
      final json = {
        'id': 42,
        'name': 'Anita Desai',
        'phone': '9898989898',
        'email': 'anita.desai@example.com',
        'role': 'parent',
        'language': 'ગુજરાતી (Gujarati)',
        'state': 'Gujarat (ગુજરાત)',
        'district': 'Vadodara',
        'created_at': '2026-10-29T10:00:00Z',
        'token': 'test_token_123',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 42);
      expect(user.name, 'Anita Desai');
      expect(user.phone, '9898989898');
      expect(user.email, 'anita.desai@example.com');
      expect(user.district, 'Vadodara');
      expect(user.token, 'test_token_123');

      final serialized = user.toJson();
      expect(serialized['id'], 42);
      expect(serialized['name'], 'Anita Desai');
      expect(serialized['phone'], '9898989898');
    });

    test('UserSession reactively updates and notifies listeners', () {
      int notifyCount = 0;
      UserSession.instance.currentUserNotifier.addListener(() {
        notifyCount++;
      });

      const user = UserModel(
        id: 101,
        name: 'Kavita Patel',
        phone: '9876500000',
        email: 'kavita@example.com',
        role: 'parent',
        language: 'ગુજરાતી (Gujarati)',
        state: 'Gujarat (ગુજરાત)',
        district: 'Surat',
      );

      UserSession.instance.setUser(user);

      expect(UserSession.instance.currentUser?.name, 'Kavita Patel');
      expect(UserSession.instance.displayName, 'Kavita Patel');
      expect(UserSession.instance.displayPhone, '9876500000');
      expect(notifyCount, 1);

      UserSession.instance.updateName('Kavita R. Patel');
      expect(UserSession.instance.displayName, 'Kavita R. Patel');
      expect(notifyCount, 2);
    });
  });
}

