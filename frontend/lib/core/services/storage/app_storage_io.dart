import 'dart:io';
import 'app_storage_platform.dart';

class AppStorageImpl implements AppStoragePlatform {
  File _getFile(String key) {
    try {
      final tempDir = Directory.systemTemp;
      // On Android, Directory.systemTemp is typically /data/user/0/<package>/cache
      // The persistent documents directory is /data/user/0/<package>/files
      final parentDir = tempDir.parent;
      final filesDir = Directory('${parentDir.path}/files');
      if (!filesDir.existsSync()) {
        try {
          filesDir.createSync(recursive: true);
        } catch (_) {}
      }
      if (filesDir.existsSync()) {
        return File('${filesDir.path}/poshan_saathi_$key.json');
      }
      return File('${tempDir.path}/poshan_saathi_$key.json');
    } catch (_) {
      try {
        return File('${Directory.systemTemp.path}/poshan_saathi_$key.json');
      } catch (_) {
        return File('poshan_saathi_$key.json');
      }
    }
  }

  @override
  Future<String?> read(String key) async {
    try {
      final file = _getFile(key);
      if (await file.exists()) {
        final content = await file.readAsString();
        return content.trim().isEmpty ? null : content;
      }
      // Fallback check temp dir if not found in files dir
      final tempFile = File('${Directory.systemTemp.path}/poshan_saathi_$key.json');
      if (await tempFile.exists()) {
        final content = await tempFile.readAsString();
        return content.trim().isEmpty ? null : content;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      final file = _getFile(key);
      await file.writeAsString(value);
    } catch (_) {
      try {
        final tempFile = File('${Directory.systemTemp.path}/poshan_saathi_$key.json');
        await tempFile.writeAsString(value);
      } catch (_) {}
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      final file = _getFile(key);
      if (await file.exists()) {
        await file.delete();
      }
      final tempFile = File('${Directory.systemTemp.path}/poshan_saathi_$key.json');
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (_) {}
  }
}

AppStoragePlatform getStoragePlatform() => AppStorageImpl();
