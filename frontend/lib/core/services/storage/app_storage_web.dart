// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'app_storage_platform.dart';

class AppStorageImpl implements AppStoragePlatform {
  @override
  Future<String?> read(String key) async {
    try {
      return html.window.localStorage[key];
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      html.window.localStorage[key] = value;
    } catch (_) {}
  }

  @override
  Future<void> delete(String key) async {
    try {
      html.window.localStorage.remove(key);
    } catch (_) {}
  }
}

AppStoragePlatform getStoragePlatform() => AppStorageImpl();

