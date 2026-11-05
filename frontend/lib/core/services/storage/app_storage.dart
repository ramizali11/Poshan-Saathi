import 'app_storage_platform.dart';
import 'app_storage_io.dart'
    if (dart.library.html) 'app_storage_web.dart';

class AppStorage {
  AppStorage._();
  static final AppStorage instance = AppStorage._();

  final AppStoragePlatform _platform = getStoragePlatform();

  Future<String?> getString(String key) => _platform.read(key);
  Future<void> setString(String key, String value) => _platform.write(key, value);
  Future<void> remove(String key) => _platform.delete(key);
}

